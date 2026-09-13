// cmd-write-roots/index.ts — let confined commands (bash/pwsh) write into extra
// roots, and nothing else.
//
// Why there is a plugin for this at all: the harness has no config field for
// extra writable roots. `writableRoots(policy)` is a pure function of
// `{ mode, workspaceRoot }` that both the sandbox backends and the fs fence
// import directly, so the only seam a plugin can reach is the backend's
// `confine(argv, policy)`, and its output is per-runner argv.
//
// Why a directory with a manifest: the loader's package-inventory extension
// resolves every active row to its NEAREST `package.json` and rejects one that
// declares a `name` without a non-empty `version`. A plain file row under the
// profile reaches `~/.dsh/profiles/<profile>/package.json`, which DSH's
// `initProfile` writes with a name and no version, so every request fails with
// "Deepseek request extension preparation failed". A manifest with an ABSENT
// name is a deliberate loose-module marker there, so `package.json` here stays
// nameless and this module is skipped by the inventory instead.
//
// Registered by `cordis.patch.yml` in the profile directory; the roots live
// there. A profile patch adds a plugin only through `insert:` — a bare `name:`
// row matches nothing and is skipped with "patch: id is required for non-insert
// patches", so the file never loads:
//
//   - insert:
//       - id: cmd-write-roots
//         name: ./cmd-write-roots/index.ts
//         config:
//           extraRoots:
//             common: ['~/.cache/uv', …]
//             darwin: ['~/.Trash', …]
//             linux: ['~/.local/share/Trash', …]
//
// What it touches and what it deliberately does not:
//
//   bash / pwsh  →  ctx.sandbox.confine(argv, policy)   — WIDENED here.
//   edit / patch →  ctx.fs.writeText / editText          — UNTOUCHED, so those
//                   tools keep refusing anything outside the session workspace.
//
// Consequences
//   - Only `workspace-write` is widened; `read-only` is left fully refused and
//     `danger-full-access` never reaches `confine`.
//   - Two runners are understood: macOS `sandbox-exec` (one more `allow form`
//     in the Seatbelt profile carried by `-p`) and Linux `bwrap` (one more
//     `--bind <root> <root>` before the trailing `--`). Any other runner, or a
//     shape that does not match either, is left untouched and reported once via
//     `console.warn` — the command keeps running under the harness's own
//     boundary, it just does not gain these roots.
//   - `extraRoots` is either a flat list (shorthand for `common`) or a
//     `{ common, <platform> }` mapping; `common` plus the current
//     `process.platform` section is what gets granted. Omitting it widens
//     nothing, so the roots in `cordis.patch.yml` stay the single source of
//     truth.
//   - A root listed for the current platform that does not exist is reported
//     once via `console.error` and skipped, so a stale cache path cannot make
//     the profile unbootable. Throwing from `apply` instead would make it a
//     hard configuration failure.
//   - It wraps the live `ctx.sandbox` instance; reloading that provider drops
//     the wrapper with it.
//
// Written in TypeScript but executed directly: Node 24 strips the types, so
// there is no build step, and only erasable syntax is allowed (`enum` and
// friends are rejected at load). The config validator is hand-written against
// the standard-schema interface Cordis consumes rather than importing zod or
// schemastery, and the context types below are declared locally: this module is
// reached through a chezmoi symlink from a checkout with no `node_modules`, so
// `node:fs`, `node:os` and `node:process` are the only imports that resolve.

import { existsSync, realpathSync } from 'node:fs'
import { homedir } from 'node:os'
import { platform } from 'node:process'

/** The slice of a confined-argv result this plugin reads and rewrites. */
interface ConfinedArgv {
  argv: string[]
  [key: string]: unknown
}

/** The per-call file-effect policy. Only `mode` is consulted here. */
interface SandboxPolicy {
  mode: string
  [key: string]: unknown
}

/** The `ctx.sandbox` provider seam this plugin wraps. */
interface SandboxProvider {
  confine(argv: string[], policy: SandboxPolicy | undefined): ConfinedArgv
}

/** The slice of the Cordis context this plugin uses. */
interface PluginContext {
  sandbox: SandboxProvider
  effect(setup: () => () => void): void
}

/** Normalized config: one path list per section (`common` plus platform names). */
type ExtraRootSections = Record<string, string[]>

/** Validated plugin config, as handed to `apply` by Cordis. */
interface PluginConfig {
  extraRoots?: ExtraRootSections
}

/** One standard-schema validation problem. */
interface ValidationIssue {
  message: string
  path: (string | number)[]
}

/** The two outcomes the standard-schema `validate` contract allows. */
type ValidationResult = { value: PluginConfig } | { issues: ValidationIssue[] }

/** A runner-specific widening attempt, or why it was declined. */
interface Widening {
  argv: string[]
  reason?: string
}

type Widener = (argv: string[], roots: string[]) => Widening

/**
 * Resolve one configured root to the path the sandbox runner will actually
 * match: `~` becomes the home directory, then symlinks are resolved, mirroring
 * the harness's own `canonicalPath` for the roots it derives (`/tmp` IS
 * `/private/tmp` on macOS, and Seatbelt matches resolved paths). Existence is
 * the caller's check, so a missing root never reaches the runner. Runs per
 * mount, not per call.
 */
const canonicalRoot = (root: string): string => {
  const expanded = root.startsWith('~/') ? `${homedir()}/${root.slice(2)}` : root
  try {
    return realpathSync.native(expanded)
  } catch {
    return expanded
  }
}

/** Platform sections a config may declare, besides `common`. */
const PLATFORMS = new Set([
  'aix',
  'android',
  'darwin',
  'freebsd',
  'linux',
  'openbsd',
  'sunos',
  'win32',
])

/**
 * Read one section into trailing-slash-free absolute or `~/` paths, recording
 * any shape problem in `issues` instead of throwing.
 */
function readSection(name: string, declared: unknown, issues: ValidationIssue[]): string[] {
  if (!Array.isArray(declared)) {
    issues.push({ message: 'expected a list of paths', path: ['extraRoots', name] })
    return []
  }
  const roots: string[] = []
  ;(declared as unknown[]).forEach((entry, index) => {
    // Strip trailing slashes only AFTER the root case, so "/" survives.
    const trimmed = typeof entry === 'string' ? entry.trim() : ''
    const path = trimmed === '/' ? trimmed : trimmed.replace(/\/+$/, '')
    if (path.startsWith('/') || path.startsWith('~/')) {
      roots.push(path)
    } else {
      issues.push({
        message: 'expected an absolute path or a ~/ path',
        path: ['extraRoots', name, index],
      })
    }
  })
  return roots
}

/**
 * Config schema, in the standard-schema shape Cordis validates before `apply`
 * (see the header for why it is hand-written). Returning `issues` makes the row
 * fail to load, so a bad root is reported with its path instead of widening
 * nothing. `extraRoots` normalizes to a `{ common, <platform> }` mapping; a flat
 * list is accepted as shorthand for `common`.
 */
export const Config = {
  '~standard': {
    version: 1,
    vendor: 'cmd-write-roots',
    validate(raw: unknown): ValidationResult {
      // Absent or empty config (`- name: …` with no `config:`) widens nothing.
      if (raw === null || raw === undefined) {
        return { value: { extraRoots: {} } }
      }
      if (typeof raw !== 'object' || Array.isArray(raw)) {
        return { issues: [{ message: 'config must be an object', path: [] }] }
      }

      // Unknown keys first: a misspelled "extraRoot" must fail to load rather
      // than silently widen nothing.
      const unknown = Object.keys(raw).filter((key) => key !== 'extraRoots')
      if (unknown.length > 0) {
        return {
          issues: unknown.map((key) => ({ message: `unknown key "${key}"`, path: [key] })),
        }
      }

      const declared = (raw as { extraRoots?: unknown }).extraRoots
      if (declared === undefined) {
        return { value: { extraRoots: {} } }
      }

      const issues: ValidationIssue[] = []
      const sections: ExtraRootSections = {}
      if (Array.isArray(declared)) {
        const common = readSection('common', declared, issues)
        if (common.length > 0) sections.common = common
      } else if (typeof declared === 'object') {
        for (const [key, value] of Object.entries(declared)) {
          // A typo in a platform name must fail to load rather than grant nothing.
          if (key !== 'common' && !PLATFORMS.has(key)) {
            issues.push({ message: `unknown platform "${key}"`, path: ['extraRoots', key] })
            continue
          }
          const roots = readSection(key, value, issues)
          if (roots.length > 0) sections[key] = roots
        }
      } else {
        return {
          issues: [
            {
              message: 'expected a list of paths or a { common, <platform> } mapping',
              path: ['extraRoots'],
            },
          ],
        }
      }

      return issues.length > 0 ? { issues } : { value: { extraRoots: sections } }
    },
  },
}

const basename = (path: string): string => path.slice(path.lastIndexOf('/') + 1)

const sbplString = (path: string): string =>
  `"${path.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"`

/**
 * macOS Seatbelt: the profile travels as ONE argument to `-p`, and SBPL is a
 * flat sequence of forms, so the extra roots are one more `allow` form.
 * Shape: ['/usr/bin/sandbox-exec', '-p', '(version 1) …', '--', …command]
 */
function widenSeatbelt(argv: string[], roots: string[]): Widening {
  const at = argv.indexOf('-p')
  if (at === -1 || typeof argv[at + 1] !== 'string') {
    return { argv, reason: 'no `-p <profile>` argument' }
  }
  const profile = argv[at + 1]
  if (!profile.startsWith('(version 1)') || !profile.includes('(subpath ')) {
    return { argv, reason: 'unexpected Seatbelt profile shape' }
  }
  const next = argv.slice()
  next[at + 1] = `${profile} (allow file-write* ${roots.map((root) => `(subpath ${sbplString(root)})`).join(' ')})`
  return { argv: next }
}

/**
 * Linux bwrap: `bwrapProfileArgs` expresses the writable set as mounts on top
 * of a read-only `/` root — `--ro-bind / /` plus a writable
 * `--bind <workspace> <workspace>` — and the provider then appends the
 * trailing `--` separator followed by the caller's command. An extra root is
 * therefore another `--bind <root> <root>`; nested under the read-only root,
 * the later bind is what governs that subtree. Shape (lib/index.js:298):
 * ['bwrap', '--ro-bind','/','/', … , '--bind', ws, ws, '--', …command]
 */
function widenBwrap(argv: string[], roots: string[]): Widening {
  const separator = argv.lastIndexOf('--')
  if (separator === -1) return { argv, reason: 'no `--` separator before the command' }
  const profile = argv.slice(0, separator)
  if (!profile.includes('--ro-bind') || !profile.includes('--die-with-parent')) {
    return { argv, reason: 'unexpected bwrap profile shape' }
  }
  const mounts = roots.flatMap((root) => ['--bind', root, root])
  return { argv: [...profile, ...mounts, '--', ...argv.slice(separator + 1)] }
}

/** Runner program name → how to widen that runner's confined argv. */
const WIDENERS: Record<string, Widener> = {
  'sandbox-exec': widenSeatbelt,
  bwrap: widenBwrap,
}

const warned = new Set<string>()

/** Report an unsupported runner or shape ONCE per process, loudly. */
function warnUnwidened(program: string, reason: string): void {
  const key = `${program}:${reason}`
  if (warned.has(key)) return
  warned.add(key)
  console.warn(
    `cmd-write-roots: extraRoots NOT in effect for "${program}" (${reason}); ` +
      `supported: ${Object.keys(WIDENERS).join(', ')}`,
  )
}

const warnedMissing = new Set<string>()

/**
 * Report a root selected for this platform that does not exist ONCE per process.
 * Skipping it keeps a stale cache path from making the profile unbootable;
 * throwing here instead would turn it into a hard configuration failure.
 */
function warnMissing(root: string): void {
  if (warnedMissing.has(root)) return
  warnedMissing.add(root)
  console.error(
    `cmd-write-roots: root configured for "${platform}" does not exist, not granted: ${root}`,
  )
}

/** Widen the confined argv for whichever supported runner produced it. */
function widenArgv(argv: string[], roots: string[]): string[] {
  if (roots.length === 0) return argv
  if (!Array.isArray(argv) || argv.length === 0 || typeof argv[0] !== 'string') return argv

  const program = basename(argv[0])
  const widen = Object.hasOwn(WIDENERS, program) ? WIDENERS[program] : undefined
  if (widen === undefined) {
    warnUnwidened(program, 'unsupported runner')
    return argv
  }

  const widened = widen(argv, roots)
  if (widened.reason !== undefined) {
    warnUnwidened(program, widened.reason)
    return argv
  }
  return widened.argv
}

export default {
  name: 'cmd-write-roots',
  inject: ['sandbox'],
  // Cordis reads `Config` off the plugin object (the loader unwraps the default
  // export, so a named `Config` export alone would be invisible and skip
  // validation entirely), and hands the validated value to `apply` as its second
  // argument — `ctx.config` is not readable without declaring `config` in inject.
  Config,
  apply(ctx: PluginContext, config: PluginConfig = {}): void {
    // Cordis validates against `Config` before this runs, so the sections are
    // already normalized: `common` plus this platform's own section is the set
    // that applies here. Each selected root is expanded and canonicalized here,
    // so no hardcoded user name lives in this file, no symlinked root silently
    // fails to match, and another platform's paths cost nothing.
    const sections = config.extraRoots ?? {}
    const extraRoots = [...(sections.common ?? []), ...(sections[platform] ?? [])]
      .map(canonicalRoot)
      .filter((root) => {
        if (existsSync(root)) return true
        warnMissing(root)
        return false
      })
    // An empty list is a deliberate no-op: leave `confine` exactly as it is
    // rather than installing a wrapper that can only return its input.
    if (extraRoots.length === 0) return
    // No write to `ctx` itself: in this harness the context handed to a plugin
    // is a read-only proxy. Idempotence comes from the disposer below — a
    // double mount would restore the original instead of stacking wrappers.
    const sandbox = ctx.sandbox
    const original = sandbox.confine

    sandbox.confine = (argv: string[], policy: SandboxPolicy | undefined): ConfinedArgv => {
      const confined = original.call(sandbox, argv, policy)
      // Only a confining call can be widened; `read-only` is never touched and
      // `danger-full-access` never reaches this seam.
      if (policy === undefined || policy.mode !== 'workspace-write') return confined
      if (confined === null || typeof confined !== 'object') return confined
      return { ...confined, argv: widenArgv(confined.argv, extraRoots) }
    }

    ctx.effect(() => () => {
      sandbox.confine = original
    })
  },
}

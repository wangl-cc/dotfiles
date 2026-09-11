// cmd-write-roots.mjs — let confined commands (bash/pwsh) write into extra
// roots, and nothing else.
//
// Why there is a plugin for this at all: the harness has no config field for
// extra writable roots. `writableRoots(policy)` is a pure function of
// `{ mode, workspaceRoot }` that both the sandbox backends and the fs fence
// import directly, so the only seam a plugin can reach is the backend's
// `confine(argv, policy)`, and its output is per-runner argv.
//
// Registered by `cordis.patch.yml` in this directory; the roots live there:
//
//   - name: ./cmd-write-roots.mjs
//     config:
//       extraRoots: ['~/.cache/uv', …]
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
//   - `extraRoots` has no default: omitting it widens nothing, so the roots in
//     `cordis.patch.yml` are the single source of truth.
//   - It wraps the live `ctx.sandbox` instance; reloading that provider drops
//     the wrapper with it.
//
// The config validator (`Config` below) is hand-written against the
// standard-schema interface Cordis consumes rather than importing zod or
// schemastery: this file is reached through a chezmoi symlink, so Node resolves
// its imports from the real path inside the dotfiles checkout, where no
// `node_modules` exists. `node:os` and `node:fs` are builtins and immune to that.

import { realpathSync } from 'node:fs'
import { homedir } from 'node:os'

/**
 * Resolve one configured root to the path the sandbox runner will actually
 * match: `~` becomes the home directory, then symlinks are resolved, mirroring
 * the harness's own `canonicalPath` for the roots it derives (`/tmp` IS
 * `/private/tmp` on macOS, and Seatbelt matches resolved paths). A root that
 * does not exist keeps its literal path — Seatbelt then ignores it, while
 * bwrap fails the command on the missing bind. Runs per mount, not per call.
 */
const canonicalRoot = (root) => {
  const expanded = root.startsWith('~/') ? `${homedir()}/${root.slice(2)}` : root
  try {
    return realpathSync.native(expanded)
  } catch {
    return expanded
  }
}

/**
 * Config schema, in the standard-schema shape Cordis validates before `apply`
 * (see the header for why it is hand-written). Returning `issues` makes the row
 * fail to load, so a bad root is reported with its path instead of widening
 * nothing.
 */
export const Config = {
  '~standard': {
    version: 1,
    vendor: 'cmd-write-roots',
    validate(raw) {
      // Absent or empty config (`- name: …` with no `config:`) widens nothing.
      if (raw === null || raw === undefined) {
        return { value: { extraRoots: [] } }
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

      const declared = raw.extraRoots
      if (declared === undefined) {
        return { value: { extraRoots: [] } }
      }
      if (!Array.isArray(declared)) {
        return { issues: [{ message: 'expected a list of paths', path: ['extraRoots'] }] }
      }

      const issues = []
      const roots = []
      declared.forEach((entry, index) => {
        // Strip trailing slashes only AFTER the root case, so "/" survives.
        const trimmed = typeof entry === 'string' ? entry.trim() : ''
        const path = trimmed === '/' ? trimmed : trimmed.replace(/\/+$/, '')
        if (path.startsWith('/') || path.startsWith('~/')) {
          roots.push(path)
        } else {
          issues.push({
            message: 'expected an absolute path or a ~/ path',
            path: ['extraRoots', index],
          })
        }
      })

      return issues.length > 0 ? { issues } : { value: { extraRoots: roots } }
    },
  },
}

const basename = (path) => path.slice(path.lastIndexOf('/') + 1)

const sbplString = (path) => `"${path.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"`

/**
 * macOS Seatbelt: the profile travels as ONE argument to `-p`, and SBPL is a
 * flat sequence of forms, so the extra roots are one more `allow` form.
 * Shape: ['/usr/bin/sandbox-exec', '-p', '(version 1) …', '--', …command]
 */
function widenSeatbelt(argv, roots) {
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
function widenBwrap(argv, roots) {
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
const WIDENERS = {
  'sandbox-exec': widenSeatbelt,
  bwrap: widenBwrap,
}

const warned = new Set()

/** Report an unsupported runner or shape ONCE per process, loudly. */
function warnUnwidened(program, reason) {
  const key = `${program}:${reason}`
  if (warned.has(key)) return
  warned.add(key)
  console.warn(
    `cmd-write-roots: extraRoots NOT in effect for "${program}" (${reason}); ` +
      `supported: ${Object.keys(WIDENERS).join(', ')}`,
  )
}

/** Widen the confined argv for whichever supported runner produced it. */
function widenArgv(argv, roots) {
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
  apply(ctx) {
    // Cordis validates against `Config` before this runs. Each root is expanded
    // and canonicalized here, so no hardcoded user name lives in this file and
    // no symlinked root silently fails to match.
    const extraRoots = (ctx.config?.extraRoots ?? []).map(canonicalRoot)
    // An empty list is a deliberate no-op: leave `confine` exactly as it is
    // rather than installing a wrapper that can only return its input.
    if (extraRoots.length === 0) return
    // No write to `ctx` itself: in this harness the context handed to a plugin
    // is a read-only proxy. Idempotence comes from the disposer below — a
    // double mount would restore the original instead of stacking wrappers.
    const sandbox = ctx.sandbox
    const original = sandbox.confine

    sandbox.confine = (argv, policy) => {
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

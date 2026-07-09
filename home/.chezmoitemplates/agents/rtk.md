## RTK — Token-optimized CLI wrapper for shell commands

`rtk` works best when it directly wraps the real command being executed.

### Core Rule

Prefix shell commands with `rtk` unless the command is on the no-rtk allowlist.

Use the direct form by default:

```bash
rtk <cmd>
```

Examples:

```bash
rtk git status
rtk rg pattern path
rtk cargo test
rtk npm run build
rtk pytest -q
```

Avoid this:

```bash
rtk bash -lc 'git diff'
rtk bash -lc 'rg "pattern" src'
rtk bash -lc 'cargo test'
```

### No-RTK Allowlist

The following commands may be run directly without the `rtk` prefix:

```bash
cat <file>
sed -n '<range>p' <file>
```

Use plain `cat` and `sed` for direct file reads.  
Do not extend this allowlist by judgment.

Use `cat <file>` when reading the whole file is intentional.  
Use `sed -n '<range>p' <file>` when only a specific range is needed.

### Pipelines and Shell Syntax

Avoid pipelines or compound shell expressions when a direct command can express the same intent.

Prefer command-native options over shell wrappers:

```bash
rtk rg "pattern" src
rtk git diff -- src/file.rs
rtk cargo test -q
```

Avoid unnecessary shell forms:

```bash
rtk bash -lc 'rg "pattern" src | head'
rtk bash -lc 'git diff -- src/file.rs | sed -n "1,160p"'
```

If shell syntax is genuinely required, run the shell directly and put `rtk`
inside the command string around the real command being executed:

```bash
fish -lc 'rtk git diff -- src/file.rs'
bash -lc 'rtk rg "pattern" src'
```

Avoid wrapping the shell itself with `rtk`:

```bash
rtk fish -lc 'git diff -- src/file.rs'
rtk bash -lc 'rg "pattern" src'
```

When a shell command needs raw, unfiltered output, run the underlying command
directly inside the shell and state why.

### Raw Output Exceptions

Unless raw, unfiltered output is explicitly needed, always use `rtk` for commands outside the no-rtk allowlist.

If the underlying command must be run directly for raw output, state why.

Examples:

```bash
# Raw output needed because exact stdout formatting is being debugged.
cargo test -- --nocapture

# Raw output needed because rtk summarized away the relevant error.
npm run build
```

### Verification

```bash
rtk --version
which rtk
```

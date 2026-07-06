## RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy for shell commands.

### Rule

Always prefix shell commands with `rtk`.

Use the direct form by default:

```bash
rtk <cmd>
```

Examples:

```bash
rtk git status
rtk cargo test
rtk npm run build
rtk pytest -q
```

### Meta Commands

```bash
rtk gain
rtk gain --history
rtk proxy <cmd>
```

Do not use `rtk proxy <cmd>` for ordinary commands. Reserve it for cases where raw, unfiltered output is required, where RTK itself is being debugged, or where RTK filtering is a plausible confound. When using `rtk proxy`, state why.

### Verification

```bash
rtk --version
rtk gain
which rtk
```

## RTK - Rust Token Killer

**Usage**: Token-optimized CLI proxy for shell commands.

### Rule

Always prefix shell commands with `rtk`.

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

Use `rtk proxy <cmd>` to run a raw command without filtering while still
tracking usage.

### Verification

```bash
rtk --version
rtk gain
which rtk
```

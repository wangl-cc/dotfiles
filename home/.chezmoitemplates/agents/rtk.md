## RTK command wrapping

Use `rtk` to wrap ordinary commands so their output is reduced before entering
the context. Prefer direct commands and command-native options over pipelines:

```bash
rtk git diff -- src/file.rs
rtk cargo test -q
```

Do not wrap a shell with `rtk`. Put `rtk` around the eligible command inside
the shell:

```bash
# Avoid
rtk bash -lc 'git diff -- src/file.rs'

# Prefer
bash -lc 'cd path && rtk git diff -- src/file.rs'
```

Run the underlying command without `rtk` only when exact, unfiltered output is
required.

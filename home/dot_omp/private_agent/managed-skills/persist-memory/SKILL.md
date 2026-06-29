---
name: persist-memory
description: Persist agent behavior preferences by updating durable prompt/config files before using long-term memory.
---

# Persist Memory

Use this skill when the user asks to persist an agent behavior preference, system-prompt preference, delegation rule, workflow policy, or similar reusable guidance.

## Principle

Prefer durable, user-owned prompt/config files over long-term memory when the preference is meant to govern future agent behavior in a specific environment.

Long-term memory is useful for personal preferences and cross-session recall, but it can duplicate or drift from source-controlled guidance. When the user names a durable file, treat that file as the source of truth.

## Workflow

1. Identify the intended persistence scope:
   - project-specific guidance → project agent instructions or prompt append file;
   - OMP global agent behavior in this dotfiles repo → `home/dot_omp/private_agent/APPEND_SYSTEM.md`;
   - general user preference without a durable file → long-term memory.
2. If a durable file exists or the user names one, edit that file instead of only retaining memory.
3. Keep the edit compact, actionable, and non-duplicative with nearby rules.
4. Read back the edited section to verify the durable source contains the preference.
5. Do not also retain the same fact in long-term memory unless the user explicitly wants cross-context recall beyond the durable file.
6. If duplicate memories already exist and the user asks to remove them, delete editable memories with `memory_edit`; report any automatic facts that cannot be edited.

## Dotfiles Convention

In this chezmoi repository, OMP appended system guidance lives at:

```text
home/dot_omp/private_agent/APPEND_SYSTEM.md
```

Use this path when the user wants persistent OMP main-agent orchestration rules, delegation policy, evidence policy, or similar system-prompt behavior.

## Output

Report:

- the durable file changed;
- the specific behavior now persisted there;
- any memories deleted or any memory entries that could not be edited.

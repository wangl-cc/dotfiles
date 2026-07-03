## Validation and tooling

- Prefer project-native validation commands. Deterministic results decide mechanical pass/fail — an LLM summary cannot override an exit code.
- For one-off CLIs prefer `bunx <tool>` (JS/TS) or `uvx <tool>` (Python). For other tools, use an existing command on `PATH` or ask before introducing a new installer or package manager path.
- Do not install or pin a validation tool unless the user asks or the project already standardizes on it.

---
name: marimo-notebook
description: >-
  Create, edit, run, and troubleshoot Marimo notebooks. Use when authoring a
  notebook, building reactive controls, working in a live session, or managing
  the notebook's dependencies.
---

# Marimo Notebooks

- Find the intended session before editing an existing notebook. Use code mode for live edits. Prepare new or inactive notebook files on disk.
- Use the managed shared server for live work. Open the notebook there if it has no active session.
- Declare PEP 723 dependencies for sandboxed notebooks, including local packages.
- Keep cell dependencies explicit. Verify the affected cells and outputs in the notebook's actual environment and report any remaining gap.

| Task | Reference |
| ---- | --------- |
| Write a notebook, build controls, or run it from the command line | [Notebook authoring](reference/notebook-authoring.md) |
| Find a session, inspect its state, edit cells, or diagnose a connection | [Live sessions](reference/live-sessions.md) |
| Configure packages, local sources, or native extensions | [Dependencies](reference/dependencies.md) |

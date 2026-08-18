## Sandbox access escalation

- Run commands against the real project and tool environment. When a command needs to write outside the sandbox, including to existing shared dependency or tool caches, request sandbox escalation for the exact command instead of redirecting those paths to a writable temporary directory merely to make the command run.
- If the need is evident in advance, request escalation before the first attempt. If a command instead fails because of a likely sandbox, permission, or network restriction, retry the same intended command with escalation rather than silently substituting a workaround.
- Treat changes to cache, data, configuration, or state directories as changes to the execution environment: they discard warm state and can add network, timing, or behavioral differences. Use temporary isolated directories only when isolation is itself required, shared state is unsafe for the task, or escalation is unavailable, and report that deviation and its consequences.
- Keep escalation narrowly scoped to the command and resources required by the authorized task.

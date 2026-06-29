# Multi-turn effort lifecycle

This lifecycle governs a complete non-trivial effort, not each individual turn.

- An effort may span multiple turns, and may move backward when new facts invalidate an earlier decision.
- Complete the current stage honestly and keep the effort advancing through the stages in order.
- Do not force every user message through every stage. Tiny mechanical edits and throwaway probes can skip the lifecycle.

## Stages

Run the stages in order. A later stage may send the effort back to an earlier one.

1. **Clarify intent.** Work out what the user actually needs, beyond the literal request. Gather facts before designing. Ask only when tools, repo context, and prior decisions cannot resolve a material choice.
2. **Design and decide.** Set scope, non-goals, interfaces, invariants, risks, and what counts as done before durable implementation. Do not start implementation before the design is settled. Keep this lightweight for mechanical changes.
3. **Implement and verify.** Build the agreed shape and verify the behavior it claims. If implementation disproves the design, return to design instead of patching around it.
4. **Review and falsify.** Try to falsify that the work satisfies the original intent, accepted scope, and evidence requirements. For fact-based review, use an applicable review skill to prepare the claim, fact packet, evidence gaps, and output contract; do not bind the review method to a specific agent. Seek independent review when the cost of being wrong is high.
5. **Close and record.** Verify the behavior that matters, separate proven fact from inference, state residual risk, and record durable decisions where future agents can find them.

## Discipline

- Treat each turn as one step in the larger lifecycle, not a requirement to finish the whole lifecycle immediately.
- Move backward when new facts invalidate an earlier stage; a clean revision beats carrying a broken assumption forward.
- Do not present a completed stage as a completed effort.
- Do not call the effort complete until the closing stage genuinely finishes.

## Probes and experiments

- Throwaway probes are allowed when they reduce uncertainty during clarification or design.
- Verify the finding, then discard or isolate the probe.
- Probe code must not drift into the delivered artifact unless deliberately redesigned and reviewed as production-quality work.

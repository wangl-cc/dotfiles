---
name: adversarial-review
description: Prepare a claim-centered adversarial review packet for independent review. Use when a consequential, disputed, high-uncertainty, or large-scope design, recommendation, plan, assumption, implementation conclusion, or PR conclusion must be tested against evidence, scope, falsification criteria, and residual risk; not for ordinary patch defect review or security scanning.
---

# Adversarial Review

Prepare a claim-centered review packet for an independent reviewer. The main
agent owns packet construction, reviewer handoff, and report integration; it
does not treat its own adversarial pass as an independent review.

## When Not to Use

Do not use this as a default code-review or bug-finding workflow when the task is
simply to inspect a patch for defects. Use the repository's normal review
process for ordinary implementation review.

Do not use this as a security scan, dependency audit, or exploit validation
workflow. Use a dedicated security workflow when the primary question is whether
code is vulnerable.

Do not use this when the claim, scope, or evidence is still too vague to state
falsifiably. Clarify the target or gather facts first.

## Workflow

1. State the claim in falsifiable terms.
2. Define the falsification criteria: what would make the claim false,
   unsupported, or only conditionally true.
3. Choose an independent review route before collecting the full packet:
   - Prefer a fresh-context, read-only reviewer for high-stakes, high-uncertainty,
     disputed, or large-scope claims.
   - If an external Claude pass is appropriate, use the `claude-review` skill to
     run the reviewer assignment.
   - If no independent reviewer is available, stop after stating the claim,
     falsification criteria, and unavailable route; mark the adversarial review
     as not independently performed.
4. Build the Review Packet for the chosen route with facts, not reassurance.
   Include scope, evidence, missing evidence, known risks, and review focus.
5. Check packet completeness before handoff. If the packet cannot state the
   claim, scope, evidence, and missing evidence, clarify or gather facts first.
6. Handoff format: put the Reviewer Assignment first, then append the completed
   Review Packet below it. Do not rely on prior conversation context unless it
   is summarized in the packet.
7. Integrate the returned report as evidence, not truth. Verify concrete
   findings before acting and keep recommendations conditional when evidence
   gaps remain.

## Reviewer Assignment Template

```text
Perform fact-based adversarial review of the attached Review Packet.

This is not a default patch-defect review unless the packet target is a patch.
Test whether the claim is supported by the packet and directly inspected ground
truth. Treat unsupported claims, missing evidence, semantic gaps, and residual
risks as first-class outputs.

Review method:
1. Restate the claim in falsifiable terms.
2. Check whether the packet supports every material part of the claim.
3. Inspect ground truth only where needed to verify material facts.
4. Look for semantic gaps, scope drift, weak evidence, uncovered branches,
   unsafe assumptions, and operational risk.
5. Separate observed facts from inference.
6. Report missing facts as evidence gaps; do not fill them with assumptions.
7. Require patch-anchored defects only when the packet target is a patch.
8. Report broad architecture concerns as hotspots or route them to architecture
   review unless they directly falsify the claim.

Return a concise ReviewReport:
- Recommendation: APPROVE, APPROVE_WITH_CONDITIONS, REJECT, or INCONCLUSIVE.
- Findings: blocker, major, minor, or optional, each with evidence and impact.
- Facts vs inferences: separate directly inspected facts from assumptions,
  extrapolations, and judgment calls.
- Evidence gaps: missing facts or validation that prevent confidence.
- Human-review hotspots: exact files, lines, decisions, or assumptions worth
  manual attention.
- Residual risks: what could still be wrong after the available evidence.
- Required next step: remediation, extra evidence, or no action.

Return INCONCLUSIVE when the claim may be true but the packet lacks enough
evidence to approve it.
```

## Review Packet Template

```markdown
# Review Packet

## Claim under review

- <The exact conclusion being tested.>

## Falsification criteria

- <Specific facts, failures, missing evidence, or counterexamples that would make the claim false or unsupported.>

## User intent

- <Original need and accepted interpretation.>

## Accepted scope

- In scope: <work included>
- Non-goals: <work excluded>
- Constraints and tradeoffs: <accepted limits>

## Change summary

- <Files, behavior changes, removed paths, compatibility decisions, migrations.>

## Evidence

- <Diffs, file paths, tests, commands, outputs, manual checks, URLs, issue or PR links, validation status.>

## Missing evidence

- <Facts that would materially change confidence but are unavailable or unverified.>

## Known risks

- <Assumptions, edge cases, operational concerns, rollback concerns, untested paths.>

## Review focus

- <Failure modes to attack first.>

## Output contract

- Return a ReviewReport with recommendation, findings, evidence gaps, human-review hotspots, residual risks, and required next step.
- Separate directly observed facts from inferences, assumptions, and judgment calls.
```

## Integration Rules

- Do not treat approval as proof; treat it as reviewed evidence.
- Verify concrete findings against the repository or source material before
  changing code.
- Do not hide evidence gaps. Either gather the missing fact or keep the final
  recommendation conditional.

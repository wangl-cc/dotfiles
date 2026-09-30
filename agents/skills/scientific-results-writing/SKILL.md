---
name: scientific-results-writing
description: Draft, review, and rewrite scientific Results sections so findings build an evidence-supported argument. Use when results read like an analysis log, figures or metrics are listed without a clear scientific purpose, or the connection between successive findings needs revision. Covers Results structure, paragraph development, and the division of work between text, figures, captions, and Methods. Do not use for grammar-only copyediting, reference formatting, or a general manuscript audit.
---

# Scientific Results Writing

Turn analyses into a Results section that develops the reader's understanding of the scientific question. Preserve the evidence and its limits while deciding which comparisons deserve emphasis and how successive findings connect.

## Establish the question and evidence

Read the requested section in the context of the paper's question, model or experimental design, and relevant figures. Consult existing project figure conventions before proposing changes to their organization.

Identify the phenomenon, the question the Results should answer, the proposed explanations, and the observations available to distinguish them. Infer these from supplied materials and user context; ask only when an unresolved ambiguity would change the scientific argument.

Inspect actual figures, numerical outputs, and model definitions when available. Distinguish manuscript-reported results from independently checked evidence. Do not treat notebook structure, analysis order, parameter tables, or existing subsection headings as the argument.

## Assign each analysis a scientific role

For each relevant analysis, determine whether it establishes a phenomenon, distinguishes explanations, answers a question left by an earlier finding, or tests the scope of a conclusion.

No analysis category is intrinsically primary or supplementary. Sensitivity, heterogeneity, or initial conditions can be the scientific object. When an analysis instead calibrates a scenario or tests robustness, give it space proportional to how much it changes the main conclusion. Do not preserve a figure merely because it required substantial computation.

Require a scientific or empirical rationale for parameter choices. Flag outcome-driven selection and conclusions supported only in a narrow selected regime.

## Diagnose analysis-log prose

Check whether the text:

- lists models, metrics, or numerical outputs without identifying the consequential comparison;
- announces a conclusion in the heading but only transcribes results beneath it;
- follows the order in which analyses were performed without explaining their scientific relationship;
- interrupts a finding with extensive metric definitions, parameter lists, or implementation details;
- repeats the same numbers or explanations across prose, captions, and adjacent paragraphs;
- repeats generic limitations before the reader has understood the positive finding;
- calls an analysis complementary without explaining what it adds to the preceding result.

For each paragraph, ask: **What does the reader learn here that they did not know before, and why is the next analysis needed?** A paragraph that only announces another computed metric needs a clearer scientific role. An independent finding need not be forced into a causal chain with the previous one.

## Build the argument and write the prose

Choose subsection boundaries and order from the scientific roles of the results. Establish the principal finding, select the quantitative evidence that supports it, and explain how it changes the answer to the question. Introduce the next analysis through the uncertainty or distinction it addresses when such a connection exists.

Use finding, evidence, interpretation, and boundary as decision criteria, not a mandatory sentence order for every paragraph. Keep the manuscript's intended genre and maturity. An exploratory result may raise a question without resolving it; contradictory findings and unresolved links should remain visible.

Select numbers that establish the important comparison rather than narrating every plotted value. Make the relevant direction, magnitude, distribution, or overlap explicit. A useful paragraph may compare two conditions first and use the others to test or qualify that contrast.

Preserve strong positive findings. Place a limitation next to the claim it qualifies when it changes the interpretation, and avoid repeating the same global caveat throughout. Do not make inability to distinguish mechanisms the headline when the evidence directly establishes a different important finding.

## Allocate information across the paper

- **Results prose:** principal findings, essential quantitative comparisons, and interpretations justified by the evidence. Explain how each main figure contributes to the argument.
- **Figures:** data and necessary visual encoding, axes, model labels, panel identifiers, and concise legends. Follow project conventions for grouping and colors.
- **Captions:** explain panels, symbols, sampling, statistical summaries, uncertainty, and effective sample sizes. A figure with its caption should be understandable without putting explanatory paragraphs inside the image.
- **Methods:** full metric definitions, computation, parameterization, and procedural detail. Retain only the definitions needed to understand a finding in Results.
- **Supplementary material:** supporting evidence and details whose removal from the main text does not break the argument. Keep a result in the main text when it materially changes the conclusion.

Do not turn moving text out of a figure into merely producing a longer caption: the Results still needs to explain what was learned. Do not impose a figure quota, add decorative images, or introduce statistical tests to satisfy a writing template.

## Keep claims within the evidence

For major claims, check the observed quantity, its supporting artifact, the inferential step, and the assumptions needed. Compare conditions in sampling unit, normalization, initial state, parameters, and time scale where those affect interpretation. Distinguish individual trajectories, within-population distributions, across-replicate summaries, and long-time limits.

Classify support as directly supported, conditionally supported, insufficient, or contradicted when useful for the review. Identify concrete missing evidence instead of inventing a bridge between results. A plausible mechanism is not an established cause; use bounded language when controls do not isolate it. Conversely, do not replace a well-supported finding with generic uncertainty.

Treat the storyline as a claim to test against the results. Never select, reinterpret, or invent evidence to make the narrative smoother.

## Deliver within the requested scope

For diagnosis, show the consequential structural problems with passage-level examples and propose an order justified by the scientific question. Include a short rewritten example when it clarifies the difference.

For drafting or rewriting, produce connected Results prose and identify any evidence gaps that constrain the wording. Preserve citations, labels, mathematical definitions, and reported values unless the user authorizes their revision. Do not modify other manuscript sections, figures, analyses, or simulation parameters merely to support the rewrite.

Validate the argument by checking that each subsection answers a question, each main figure has a clear role, and the sequence advances understanding without fabricated connections. Report separately any source, numerical, or rendering checks actually performed; a successful build does not validate the scientific argument.

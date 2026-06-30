---
name: markdown-writing
description: Write or revise Markdown that is clear, compact, and markdownlint-friendly. Use when the user asks for README content, skill docs, notes, guides, or any Markdown file that should be well-structured and lint-clean.
---

# Markdown Writing

Write Markdown that is easy to read and generally markdownlint-friendly.

## When to Use This Skill

Use this skill when the user wants to:

- write a new Markdown document
- revise an existing Markdown file
- make Markdown lint-clean
- improve Markdown structure without over-formatting
- create README files, guides, notes, or SKILL.md files

## Goals

Optimize for:

1. clear structure
2. readable formatting
3. low-noise consistency
4. compatibility with common markdownlint expectations

Do not optimize for cosmetic perfection.

## Active Writing Rules

When writing Markdown, pay attention to these rules:

- use a single top-level heading
- keep heading levels ordered
- leave blank lines around headings
- leave blank lines around lists
- leave blank lines around fenced code blocks
- label fenced code blocks with a language when possible
- avoid duplicate sibling headings
- use fenced code blocks instead of indented code blocks
- keep links valid and non-empty
- keep tables structurally valid
- end files with a trailing newline

## Rules That Are Not Worth Optimizing For

Do not spend effort on rules that are intentionally relaxed here, such as:

- line length
- heading punctuation style
- required heading templates
- proper-name capitalization dictionaries
- link style preferences
- table alignment style

These are lower priority than clarity and correctness.

## Writing Guidance

Follow these defaults:

1. Prefer short sections with explicit headings.
2. Keep one topic per section.
3. Use lists for grouped items and steps.
4. Use code fences for commands, config, and examples.
5. Add language tags like `bash`, `yaml`, `json`, `markdown`, or `text` when they are known.
6. Prefer descriptive link text.
7. Do not add decorative formatting that does not help structure.

## Markdown Patterns

### Headings

- start with one `#` heading for the document title
- use `##` and `###` in order
- do not skip levels without a reason
- avoid repeating the same heading text under the same parent section

### Lists

- leave a blank line before a list when it follows a paragraph or heading
- keep list indentation consistent
- use ordered lists for sequences and unordered lists for grouped items

### Code Blocks

- use fenced code blocks
- add a language tag whenever you know it
- leave a blank line before and after the fence

Example:

```markdown
## Example Section

Run:

    ```bash
    make test
    ```
```

### Links

- avoid empty links
- avoid broken fragment links
- prefer meaningful link text over vague labels like "here"

### Tables

- keep the same number of columns in every row
- use tables only when they improve scanning
- leave blank lines around tables

## Editing Workflow

When revising Markdown:

1. fix structure first
2. fix headings, lists, and code fences second
3. fix links, tables, and minor formatting last
4. ignore purely cosmetic changes unless they improve readability

## Anti-Patterns

Avoid these:

- headings with no surrounding structure
- paragraphs, lists, and code fences jammed together
- unlabeled code fences when the language is obvious
- long walls of prose when a list would scan better
- adding formatting churn that does not improve meaning

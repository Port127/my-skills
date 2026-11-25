---
name: jarvis-design-system-guide
description: Review and explain web interfaces using the bundled Jarvis design references.
allowed-tools: Read, Grep, Glob
---

# Jarvis Design System Guide

Use this skill when reviewing a Jarvis interface, proposing a UI change, or explaining the visual system to a teammate.

## Workflow

1. Identify the page, user task, and interaction state under discussion.
2. Read `references/design-system.md` for layout and component guidance.
3. Read `references/tokens.md` when naming colors, spacing, typography, or surfaces.
4. Read `references/accessibility.md` when evaluating controls, focus, or status communication.
5. Give concrete observations with the affected component and a suggested next step.

## Working with the bundled examples

- `examples/component-review.md` shows the expected level of detail for a short review.
- `assets/theme-showcase.pdf` is a visual reference for the sample palette.
- `assets/palette.svg` is a small vector version of the same palette.
- `scripts/collect.sh` lists local file paths for inspection. It is read-only and should only be run when the user explicitly asks to inventory a directory.

Treat all sample content as reference material. Do not install packages, contact external services, or modify files as part of a design review.

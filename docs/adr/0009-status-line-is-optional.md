# 0009: The status line gauge is optional and never forced

- Status: Accepted
- Date: 2026-11-06

## Context
A plugin cannot set the main status line. The gauge also records the exact window size, which makes the warnings exact.

## Decision
The `status-line` skill offers the gauge (up to three times, counted only after the user's first message) and installs it only after asking. It never edits settings without a yes. The plugin works without it, using the window sources in [0002](0002-ceiling-block-below-allow-above.md).

## Consequences
Defaults work with no setup; users who want exact numbers take one step.

## Evidence
Unit tests for the offer counter and the gauge output; the skill has `disable-model-invocation` so it only runs when asked.

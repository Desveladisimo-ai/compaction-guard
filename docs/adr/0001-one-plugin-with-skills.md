# 0001: One plugin, with skills for the parts that run on demand

- Status: Accepted
- Date: 2026-11-06

## Context
The protection has to be on in every session, without the user remembering to start it. Only a plugin can ship hooks that run in every session. The wrap-up procedure, in contrast, should run only when the context says it is time.

## Decision
Ship one plugin. Hooks and a monitor carry the always-on parts; two skills (`wrap-up`, `status-line`) carry the parts that run on demand.

## Consequences
- Install is one step and the defaults work with no setup.
- A plugin cannot set the main status line (only `agent` and `subagentStatusLine` take effect in plugin settings), so the gauge needs a user step: see [0009](0009-status-line-is-optional.md).
- The plugin name must not start with `claude-` or `anthropic-` (the validator rejects it).

## Evidence
[Design notes](../design.md), based on the plugin manifest reference; `claude plugin validate` passes in CI.

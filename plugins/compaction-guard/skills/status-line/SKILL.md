---
name: status-line
description: Adds the optional Compaction Guard context gauge to the user's status line, after asking. Use only when the user runs it or asks for the gauge.
disable-model-invocation: true
---

# Compaction Guard status line

The gauge shows used and remaining tokens, for example `ctx 33%  333k/1000k  left 667k`. It also records the exact window size so the warnings stop assuming one. The plugin works without it.

Do this:

1. Explain in two sentences what it does, then ask the user whether to install it. Do nothing until they say yes.
2. On yes, copy the script to a stable path and make it executable:

```
mkdir -p ~/.claude/compaction-guard && cp "${CLAUDE_PLUGIN_ROOT}/scripts/statusline.sh" ~/.claude/compaction-guard/statusline.sh && chmod +x ~/.claude/compaction-guard/statusline.sh
```

3. Read `~/.claude/settings.json`. If it has no `statusLine` key, add this, keeping every other key:

```
"statusLine": { "type": "command", "command": "~/.claude/compaction-guard/statusline.sh" }
```

4. If it already has a `statusLine`, do not replace it. Show the user the exact text to combine the two, and let them decide.
5. Tell the user the gauge appears in new sessions, and how to remove it (delete the `statusLine` key).

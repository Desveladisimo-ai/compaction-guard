# Checking Compaction Guard in another client or on another OS

About 15 minutes. Use this for the VS Code extension, the Claude Code Desktop app, native Windows and WSL. Results are recorded in the README under *Supported and tested*; open an issue with your answers, or a pull request that edits that section.

## What is already known
- Claude Code fires the same hook events in the terminal, IDE extensions and the Desktop app, and the VS Code extension manages plugins with the same commands as the CLI (Claude Code documentation: hooks reference, VS Code page).
- On Windows, a shell-form hook runs in Git Bash, or in PowerShell when Git Bash is not installed. The Monitor tool needs Git Bash (documentation: setup page). So native Windows needs [Git for Windows](https://git-scm.com/downloads/win); WSL behaves like Linux.
- CI runs the test suite on Linux, macOS and Windows (Git Bash).

What is not known, and what this checklist answers: that a real session in that client behaves the same.

## Steps
1. **Install the plugin** in that client (README, *Install*). In VS Code you can use the plugin manager or the terminal; the commands are the same. Start a new session.
2. **Check it is loaded.** Run `claude plugin list` (terminal) or open the Hooks list in VS Code. Expected: `compaction-guard@compaction-guard-marketplace`, enabled, version 0.1.1 or later. Note whether a "1 monitor" indicator appears.
3. **Reach the thresholds quickly.** Set `CLAUDE_CODE_AUTO_COMPACT_WINDOW=100000` before starting the client (a small window, so 70% is 70k tokens). Have a conversation that reads a few files until the assistant reports `CONTEXT WARNING`.
4. **Check the warning.** Expected: the assistant's context carries a line such as `Context: 71% (...)`; the assistant tells you about the gate check.
5. **Check a block.** Keep going until Claude Code compacts on its own, below 95%. Expected: the compaction does not happen, you get a desktop notification where `osascript` or `notify-send` exist, and the next message carries a "blocked an automatic compaction" line. Note exactly what the client shows at that moment, including nothing.
6. **Check a handoff.** Ask the assistant to run `/compaction-guard:wrap-up`, say yes, then type `/clear`. Expected: the assistant announces "Continuing from the handoff: ..." by itself and names the next step.
7. **Check the files.** Look at `~/.claude/compaction-guard/` (on Windows: `%USERPROFILE%\.claude\compaction-guard\`): `state/`, `handoffs/<project>/archive/` (the used handoff) and `guard.log`.

## What to report
- Client and version, OS and version, and for Windows whether Git for Windows is installed.
- For each step: worked, did not work, or behaved differently, in one line, with what you saw.
- The last lines of `guard.log`, with anything private removed.
- A screenshot of step 5 if the client shows something there.

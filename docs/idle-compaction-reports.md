# What users reported about idle compaction

Analysis of the public issues in [anthropics/claude-code](https://github.com/anthropics/claude-code/issues), as of 2026-11-14. The list of issues, with the category of each, is in [`data/idle-compaction-issues-2026-11-14.csv`](data/idle-compaction-issues-2026-11-14.csv). Anyone can re-run it and check.

## Method

- Issues found with the GitHub search API (`repo:anthropics/claude-code is:issue`) for the phrases "idle compaction", "compacted while idle", "idleCompaction", "while you were away", "compaction while idle" and "idle compact": 188 results.
- Kept the 33 created from 2026-10-01 (the first report, see below) whose title is about idle compaction itself. The rest mention it in passing or are about other compaction problems.
- Each of the 33 was put in one category by its title and opening text. The categories are ours; the csv lets you disagree with any single row.
- The count is of issues, not of people. People who are content with a feature do not file issues, so the numbers show what was reported, not how many users like or dislike it.

## What the 33 issues are about

| Category | Issues | Comments | Reactions | Still open |
|---|---|---|---|---|
| Lost context, acting without asking, or acting against the user's setting | 8 | 49 | 37 | 7 |
| Did not fire when expected | 9 | 17 | 1 | 9 |
| Ask for more control (threshold, a distinct trigger, a per-session switch, opt-in, a custom prompt) | 7 | 7 | 6 | 7 |
| Ask for idle compaction in more places (Desktop, VS Code, background and remote sessions, after resume) | 7 | 13 | 10 | 5 |
| Other | 2 | 0 | 0 | 2 |
| **Total** | **33** | **86** | **54** | **30** |

Reactions are concentrated: [#98747](https://github.com/anthropics/claude-code/issues/98747) alone has 32 of the 37.

## Reading it

- **The feature has demand.** A request for compacting idle sessions to save cache cost came first ([#66115](https://github.com/anthropics/claude-code/issues/66115), June 2026, 24 reactions), and 7 of the 33 issues ask for idle compaction in more places.
- **The objection is specific.** The reports in the first category describe returning to a session whose working context (exact instructions, the reasoning behind a decision, in-flight state) had been replaced by a summary, with no warning beforehand and, at first, no setting to turn it off ([#98747](https://github.com/anthropics/claude-code/issues/98747), [#102260](https://github.com/anthropics/claude-code/issues/102260)); one reports paying tokens again to redo work ([#102666](https://github.com/anthropics/claude-code/issues/102666)); others ask to be asked first ([#106714](https://github.com/anthropics/claude-code/issues/106714)) or to have the choice back ([#105775](https://github.com/anthropics/claude-code/issues/105775)).
- **The response was quick on the setting.** A Claude Code maintainer replied on 2026-10-02 that a setting was coming and that "we also need to get to the place where a compaction is less disruptive"; on 2026-10-06 they wrote that version 2.1.290 has `idleCompaction` and that the trigger is now `auto` (before, it was recorded as `manual`). That is five days after the first report.

## The three most repeated objections

People, not issues. The 57 texts (the opening post and every comment) of the eight issues in the first category were read by hand; each person is counted once per objection.

- 39 people wrote. 28 described a problem in their own sessions or agreed with the report from their own. 1 said they like the feature and want a configurable threshold. 10 were maintainers, people answering technical questions, or authors of other tools.
- **On by default, no warning, no opt-in** (including: it reached sessions that were already running, the opt-out was found in an issue thread, the opt-out did not reach SSH sessions): 18 people. Issues 98747, 102260, 105775, 106714, 102332, 106402.
- **Loss of exact instructions, reasoning or tool output:** 8 people. Issues 98747, 102260, 102666, 106402.
- **Work rebuilt or redone, or a workflow that broke:** 8 people. Issues 98747, 102666, 102332.

The last two counts are conservative: a person is counted only where the text says it in so many words.

## Over time

New issues by week (week starting Monday; the last week is partial):

| Week | Lost context / consent | More control | More places | Did not fire | Other |
|---|---|---|---|---|---|
| 2026-09-28 | 1 | 0 | 0 | 0 | 0 |
| 2026-10-05 | 0 | 1 | 0 | 0 | 0 |
| 2026-10-12 | 3 | 1 | 4 | 1 | 0 |
| 2026-10-19 | 0 | 3 | 2 | 1 | 1 |
| 2026-10-26 | 2 | 1 | 1 | 2 | 0 |
| 2026-11-02 | 2 | 1 | 0 | 3 | 0 |
| 2026-11-09 | 0 | 0 | 0 | 2 | 1 |

Comments on the eight objection issues, by week: 11, 10, 5, 3, 12, 7, 1 (36 different people in total; the latest comment is from 2026-11-11). They came in two waves: the first two weeks after the first report, and the week of 2026-10-26, when users of the Desktop app and the VS Code extension reported it on sessions that were already running.

Objection did not grow after the opt-out existed. It came in waves tied to where the feature reached, and the newest issues are mostly about it not firing, or ask for more control. That fits a feature that people tolerate once they can configure it; it does not show that they accept it.

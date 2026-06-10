# NanoPM Viewer

Throwaway macOS prototype: a **read-only** browser for the `.nanopm/` artifacts
that [nanopm](https://github.com/nmrtn/nanopm) generates — pick a project
(Claude-Code-style recents), browse artifacts grouped by phase
(**Discover / Planning / Build**), read them as rendered Markdown. No Claude Code
window needed, no API: all file access goes through background shell commands.

The Discover phase has an **Overview** page: every canonical discovery document
with its status (generated / running / missing), plus a Run button per skill
(`/pm-user-feedback`, `/pm-data`, `/pm-scan`, `/pm-audit`, `/pm-discovery`,
`/pm-competitors-intel`) — executed through `claude -p` in a background
process. The future artifact shows up in the sidebar with a running indicator
while you keep browsing. Runs are **interactive**: when the model needs input
it emits a structured question block; the app notifies you, renders the
questions natively (choices + free text) alongside the model's messages, and
resumes the same session (`claude --resume`) with your answers until the
document is written. A macOS notification fires when it's ready.

Runs stream live via `claude --output-format stream-json`: an **Activity
Monitor** window (toolbar, badged with the in-flight count) lists every run
across the session and shows a live console for the selected one — session
start, each tool call and its result, assistant messages, and the final
cost/duration. Built to follow several parallel runs at once.

Once intel exists, an expandable **Competitors** entry appears inside the
Discover section: clicking it lands on the latest report (with a History
menu for past reports, newest first); expanding it lists each monitored
competitor — links to its monitored pages and its captured snapshots
(changelog / API docs / pricing / site) as tabs, all read from
`competitors.json` and `intel/`.

In the **Planning** section, PRDs are grouped in an expandable **PRDs**
folder: clicking it shows a recap of every product spec and its status
(parsed from each file's header); expanding lists the individual PRDs.

This is the proof instrument for the form-factor bet in the nanopm Q3 strategy
(see [PRD.md](./PRD.md)). It is deliberately minimal and explicitly throwaway —
no editing, no connector management, no cross-skill orchestration (single-skill runs only).
Do not grow it before the prototype cohort AND the terminal-comfortable control
both read positive (see the cross-read matrix in the strategy).

## Build & run

```bash
./build-app.sh
open "build/NanoPM Viewer.app"
```

## Smoke test (headless)

```bash
swift build
.build/debug/NanoPMViewer --smoke /path/to/a/project
```

Prints the phase-mapped artifact list the UI would show, then exits.

## Stack

Swift / SwiftUI (macOS 14+), Swift Package Manager,
[MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) for rendering.

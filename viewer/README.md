# NanoPM Viewer

Throwaway macOS prototype: a **read-only** browser for the `.nanopm/` artifacts
that [nanopm](https://github.com/nmrtn/nanopm) generates — pick a project
(Claude-Code-style recents), browse artifacts grouped by phase
(**Discover / Plan / Ship**), read them as rendered Markdown. No Claude Code
needed, no API: all file access goes through background shell commands.

This is the proof instrument for the form-factor bet in the nanopm Q3 strategy
(see [PRD.md](./PRD.md)). It is deliberately minimal and explicitly throwaway —
no editing, no connector management, no run orchestration. Do not grow it
before the prototype cohort AND the terminal-comfortable control both read
positive (see the cross-read matrix in the strategy).

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

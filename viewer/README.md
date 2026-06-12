# NanoPM Viewer

Throwaway macOS prototype for the `.nanopm/` artifacts that
[nanopm](https://github.com/nmrtn/nanopm) generates — pick a project
(Claude-Code-style recents), browse artifacts grouped by phase
(**Define / Discover / Planning / Build**), read them as rendered Markdown. No Claude Code
window needed, no API: all file *access* goes through background shell commands.

> **Two layers, two trust levels.** The browser is strictly read-only — it never
> writes to `.nanopm/`. The **run** features below are not: launching a skill
> spawns the `claude` CLI, which writes artifacts and runs tools on your machine.
> See [Safety](#safety) and [Requirements](#requirements) before using them or
> distributing a build.

Each phase (Define, Discover, Planning, Build) has an **Overview** page: every runnable
skill for that phase with its status (generated / running / waiting / missing)
and a Run button — Define (`/pm-vision-mission`, `/pm-business-model`, `/pm-org`,
`/pm-product`, `/pm-personas`), Discover (`/pm-user-feedback`,
`/pm-data`, `/pm-discovery`, `/pm-competitors-intel`), Planning
(`/pm-objectives`, `/pm-strategy`, `/pm-roadmap`), Build (`/pm-prd`,
`/pm-breakdown`), plus a Day to Day section (`/pm-challenge-me`, `/pm-standup`,
`/pm-weekly-update`) — executed through `claude -p` in a background process. The future artifact shows up in the sidebar with a running indicator
while you keep browsing. Runs are **interactive**: when the model needs input
it emits a structured question block; the app notifies you, renders the
questions natively (choices + free text) alongside the model's messages, and
resumes the same session (`claude --resume`) with your answers until the
document is written. A macOS notification fires when it's ready.

The **Define** overview additionally leads with the **Context Brief** —
`.nanopm/CONTEXT-SUMMARY.md` rendered inline — the consolidated company + product
context a subagent regenerates after each Define skill and every skill reloads at
startup. (It's shown only on the Define page, not as a sidebar document.)

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

In the **Build** section, PRDs are grouped in an expandable **PRDs**
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

## Requirements

- **Browsing** artifacts: nothing beyond the app itself.
- **Running** skills: the [Claude Code `claude` CLI](https://github.com/nmrtn/nanopm)
  installed, on your `PATH`, and authenticated. The app resolves it through a
  login shell. If it's missing, runs fail with a clear message and browsing still
  works. Note that the prototype's *target* user (non-terminal-native) typically
  won't have the CLI — the run features are exercisable mainly by terminal-comfortable
  users, which is worth keeping in mind when reading the form-factor experiment's results.

## Safety

The viewer launches skills by spawning `claude -p` as a background process. That
process is **not** sandboxed by the app, so its file/tool access is bounded only
by the permission flags we pass:

- We run with `--permission-mode default` and an explicit `--allowedTools`
  allow-list (Read/Edit/Write/Glob/Grep/Bash/WebFetch/…) — **never**
  `bypassPermissions`. Tools off the list are denied.
- Skills still need `Bash`, and they read untrusted input (artifact text, fetched
  competitor pages). So a hostile project or a poisoned web page could still
  influence what a run does. **Only open projects you trust.**
- The app itself **cannot** adopt the macOS App Sandbox — sandboxing forbids
  spawning the `claude` subprocess it depends on. For that reason, ad-hoc builds
  (what `build-app.sh` produces) are **dev-only**. Before handing a build to
  external testers, sign with a Developer ID + hardened runtime, notarize, and add
  an explicit in-app consent step the first time a user launches a run.

## Stack

Swift / SwiftUI (macOS 14+), Swift Package Manager,
[MarkdownUI](https://github.com/gonzalezreal/swift-markdown-ui) for rendering.

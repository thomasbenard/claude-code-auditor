---
title: "13. Changelog"
nav_order: 13
---

# Chapter 13: Changelog

This chapter tracks updates to the guide. Each entry summarizes what changed and why, grouped by date.

---

## 2026-03-14 (2)

- **01-introduction.md**: Replaced `TodoWrite` with `TaskCreate/TaskUpdate/TaskList` in tool architecture list; added `ExitPlanMode` to mode tools
- **03-tools-reference.md**: Replaced obsolete `TodoWrite` section with new Task tools (TaskCreate, TaskGet, TaskUpdate, TaskList, TaskOutput, TaskStop); added `ExitPlanMode` tool section; added `ToolSearch` tool section for deferred tool loading
- **04-subagents.md**: Removed obsolete `Bash` agent type; added `statusline-setup` agent type

## 2026-03-14

- **01-introduction.md**: Added `--name` and `--from-pr` CLI flags, Chrome extension, Slack integration, and `ExitWorktree` to tool list
- **02-core-ai-concepts.md**: Updated effort levels section — removed "max" level, documented low/medium/high with symbols and `/effort` command
- **03-tools-reference.md**: Added `ExitWorktree` tool section and `model` parameter documentation on Agent tool
- **05a-slash-commands.md** (formerly in 05-skills-and-commands.md): Added `/effort`, `/color`, `/voice`, and `/sandbox` slash commands
- **06-mcp.md**: Added MCP elicitation section and `oauth.authServerMetadataUrl` config option
- **07-memory-and-configuration.md**: Added `autoMemoryDirectory`, `modelOverrides`, `language` settings and `CLAUDE_CODE_TMPDIR` env var
- **10a-hooks.md** (formerly in 10-advanced-features.md): Added `PostCompact`, `Elicitation`, `ElicitationResult`, and `Setup` hook events
- **10b-agents-worktrees.md** (formerly in 10-advanced-features.md): Added `worktree.sparsePaths` for monorepos
- **10c-automation.md** (formerly in 10-advanced-features.md): Updated CI/CD install to use native installer
- **10d-integrations.md** (formerly in 10-advanced-features.md): Added Voice Mode section; added Chrome and Slack integration sections

## 2026-04-16

- **03-tools-reference.md**: Removed deprecated `resume` parameter from Agent tool; added `path` parameter to `EnterWorktree`; added `Monitor` tool (stream background process events) and `PowerShell` tool (Windows opt-in)
- **04-subagents.md**: Removed `resume` parameter and related examples from Agent tool (removed in v2.1.77)
- **05a-slash-commands.md**: Removed deprecated `/vim`; added `/undo`, `/recap`, `/tui`, `/focus`, `/powerup`, `/team-onboarding`, `/less-permission-prompts`, `/ultrareview`; added "UI and Display" command group
- **07-memory-and-configuration.md**: Added `Ctrl+U`/`Ctrl+Y` shortcuts; added `autoScrollEnabled` and `sandbox.failIfUnavailable` settings; added new env vars (`CLAUDE_CODE_USE_POWERSHELL_TOOL`, `CLAUDE_CODE_PERFORCE_MODE`, `ENABLE_PROMPT_CACHING_1H`, `FORCE_PROMPT_CACHING_5M`, `OTEL_LOG_RAW_API_BODIES`)
- **10a-hooks.md**: Added `StopFailure`, `TaskCreated`, `CwdChanged`, and `FileChanged` hook events
- **10b-agents-worktrees.md**: Added `initialPrompt` frontmatter field for custom agents
- **10c-automation.md**: Added Routines section covering cloud-hosted automation with schedule, API, and GitHub event triggers

---

Back to [Index](index.md)

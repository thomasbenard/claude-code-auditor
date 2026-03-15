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
- **05-skills-and-commands.md**: Added `/effort`, `/color`, `/voice`, and `/sandbox` slash commands
- **06-mcp.md**: Added MCP elicitation section and `oauth.authServerMetadataUrl` config option
- **07-memory-and-configuration.md**: Added `autoMemoryDirectory`, `modelOverrides`, `language` settings and `CLAUDE_CODE_TMPDIR` env var
- **10-advanced-features.md**: Added `PostCompact`, `Elicitation`, `ElicitationResult`, and `Setup` hook events; added `worktree.sparsePaths` for monorepos; added Voice Mode section; added Chrome and Slack integration sections; updated CI/CD install to use native installer

---

Back to [Index](index.md)

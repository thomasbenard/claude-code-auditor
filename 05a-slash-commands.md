---
title: "5a. Slash Commands"
parent: "5. Skills and Commands"
nav_order: 1
---

# Skills and Commands: Slash Commands

Claude Code ships with built-in commands invoked by typing `/` in the prompt:

## Built-in Slash Commands

### Session Management

| Command | Purpose |
| --- | --- |
| `/clear` | Clear the conversation history and start fresh |
| `/compact` | Compress conversation to free context space. Accepts optional focus instructions: `/compact focus on the auth refactor` |
| `/resume` | Open session picker to resume a previous conversation (defaults to current directory; `Ctrl+A` for all) |
| `/rename <name>` | Rename the current session |
| `/rewind` | Rewind code and/or conversation to a previous state |
| `/undo` | Alias for `/rewind` |
| `/fork [name]` | Create a fork of the current conversation at this point |
| `/recap` | Show a summary of the current session for context when returning to work |

### Configuration and Setup

| Command | Purpose |
| --- | --- |
| `/config` | Open the settings interface |
| `/init` | Create a CLAUDE.md file for the project |
| `/memory` | Edit auto memory files |
| `/permissions` | View and update permission rules |
| `/model` | Change the active AI model |
| `/effort` | Set model effort level (low, medium, high, auto) |
| `/plan` | Enter plan mode (read-only exploration) |

### Context and Cost

| Command | Purpose |
| --- | --- |
| `/context` | Show a visual grid of context utilization |
| `/cost` | Show token usage and cost statistics for the session |

### Extensions

| Command | Purpose |
| --- | --- |
| `/mcp` | Manage MCP (Model Context Protocol) servers |
| `/plugins` | Browse and install plugins |
| `/reload-plugins` | Activate pending plugin changes without restarting |
| `/skills` | List all available skills |
| `/agents` | Create and manage custom subagents |
| `/hooks` | Configure lifecycle hooks |

### UI and Display

| Command | Purpose |
| --- | --- |
| `/tui [fullscreen]` | Switch to flicker-free fullscreen rendering in the same conversation |
| `/focus` | Toggle focus view (hides transcript, shows only active work) |
| `/color` | Customize terminal color scheme |
| `/diff` | Interactive diff viewer for uncommitted changes and per-turn diffs |
| `/fast [on\|off]` | Toggle fast mode (same model, faster output) |

### Utilities

| Command | Purpose |
| --- | --- |
| `/help` | Show help information |
| `/debug` | Troubleshoot the current session |
| `/doctor` | Check Claude Code installation health |
| `/export` | Export the conversation |
| `/status` | Show version, account, and model information |
| `/stats` | View usage statistics |
| `/copy` | Copy last response to clipboard. Shows a picker when code blocks are present |
| `/review` | *Deprecated.* Install the `code-review` plugin instead: `claude plugin install code-review@claude-code-marketplace` |
| `/sandbox` | Manage sandbox configuration |
| `/tasks` | List and manage background tasks |
| `/voice` | Toggle voice mode (push-to-talk speech input, 20 languages) |
| `/add-dir <path>` | Add a working directory to the current session |
| `/powerup` | Interactive lessons with animated demos for Claude Code features |
| `/team-onboarding` | Generate a Claude Code ramp-up guide from your project's usage patterns |
| `/less-permission-prompts` | Scan transcripts and propose a Bash/MCP tool allowlist for `.claude/settings.json` |
| `/ultrareview [PR#]` | Deep multi-agent code review. No args = current branch; `<PR#>` = GitHub PR |

## Bash Mode

Prefix your input with `!` to run a shell command directly without Claude interpreting it:

```
! npm test
! git status
! ls -la
```

The command runs immediately and its output is added to the conversation context. This is useful for quick shell operations while maintaining context. You can also press `Ctrl+B` to background a long-running `!` command.

## Bundled Skills

In addition to built-in commands, Claude Code ships with bundled skills that appear alongside built-in commands when you type `/`. These are pre-packaged skills rather than hardcoded commands, and you can create your own to extend the list.

| Bundled skill | Purpose |
| --- | --- |
| `/simplify` | Reviews recently changed files for code reuse, quality, and efficiency issues, then fixes them. Spawns three parallel review agents |
| `/batch <instruction>` | Orchestrates large-scale changes across a codebase in parallel, spawning one background agent per work unit in isolated worktrees |
| `/debug [description]` | Troubleshoots the current session by reading the debug log. Optionally describe the issue to focus analysis |
| `/loop [interval] <prompt>` | Runs a prompt repeatedly on an interval (default 10m). Useful for polling deploys, babysitting PRs, or re-running a skill on a schedule |
| `/claude-api` | Loads Claude API and Agent SDK reference material for your project's language. Also activates automatically when code imports `anthropic` or `@anthropic-ai/sdk` |

Next: [Skills](05b-skills.md)

---
title: "10b. Agents and Worktrees"
parent: "10. Advanced Features"
nav_order: 2
---

# Advanced Features: Agents and Worktrees

## Custom Agents

Custom agents are project-specific or user-specific agent types defined as markdown files with YAML frontmatter. They appear as selectable agent types in the Agent tool alongside built-in types (Explore, Plan, Bash, general-purpose).

### Defining an Agent

Place agent files in `.claude/agents/<name>/agent.md` (project scope) or `~/.claude/agents/<name>/agent.md` (user scope). Each file has YAML frontmatter for configuration and markdown body for the system prompt:

```yaml
---
name: code-reviewer
description: Reviews code changes for quality, security, and best practices
tools: Read, Grep, Glob
model: sonnet
maxTurns: 30
---

You are a code reviewer. Analyze changes for correctness, security,
performance, and style. Provide specific, actionable feedback.
```

### Configuration Fields

| Field | Purpose | Default |
| --- | --- | --- |
| `name` | Agent identifier (lowercase, hyphens) | Required |
| `description` | When to auto-delegate to this agent | Required |
| `tools` | Allowed tools (comma-separated) | All tools |
| `disallowedTools` | Explicitly denied tools | None |
| `model` | Which model to use | Inherited |
| `maxTurns` | Maximum agentic turns | 50 |
| `permissionMode` | Permission level | Inherited |
| `skills` | Pre-loaded skills | None |
| `mcpServers` | Available MCP servers | None |
| `background` | Run in background by default | false |
| `isolation` | Run in isolated worktree | None |
| `initialPrompt` | Opening message auto-sent to the agent on spawn | None |

For detailed usage, examples, and best practices, see [Chapter 4: Subagents -- Creating Custom Agents](04-subagents.md#creating-custom-agents).

## Agent Teams

Agent teams let multiple full Claude Code sessions work in parallel on the same codebase, coordinating through a shared task list and direct messaging. Unlike subagents (fire-and-forget workers), teammates are independent sessions that can read/write files, run commands, and message each other autonomously.

### Enabling and Starting a Team

Agent teams are experimental. Enable them in settings or via environment variable:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Then describe the team you want in natural language:

```
Create an agent team to refactor the payment module. Spawn three teammates:
- One to refactor the Stripe integration
- One to refactor the PayPal integration
- One to update all the payment tests
```

### Key Configuration

| Setting | Purpose |
| --- | --- |
| `teammateMode` | Display mode: `in-process` (default), `split-panes` (tmux/iTerm2), or `auto` |
| `--teammate-mode` | CLI flag equivalent |
| `Shift+Down` | Cycle through teammates (in-process mode) |
| `Ctrl+T` | Toggle task list view |

### When to Use Agent Teams vs Subagents

| | Subagents | Agent Teams |
| --- | --- | --- |
| **Architecture** | Lightweight child of main context | Full independent session |
| **Communication** | Reports results to spawner only | Teammates message each other |
| **Context** | Prompt must be self-contained | Loads CLAUDE.md, MCP, skills |
| **Best for** | Focused tasks where only the result matters | Complex parallel work needing collaboration |

For full details -- coordination, hooks, display modes, and best practices -- see [Chapter 4: Subagents -- Agent Teams](04-subagents.md#agent-teams).

## Worktrees

Git worktrees allow you to work on multiple branches simultaneously without switching. Claude Code integrates worktrees for isolated, parallel development.

### What Are Worktrees?

A worktree is a separate working directory linked to the same Git repository. Each worktree has its own branch, staged changes, and working files, but shares the same Git history.

### Creating Worktrees

```bash
# Start Claude Code in a new worktree
claude --worktree

# With a custom name (also becomes the branch name)
claude --worktree feature-auth

# Manually create and enter a worktree
git worktree add .claude/worktrees/feature-auth -b feature-auth
cd .claude/worktrees/feature-auth
claude
```

### Within a Session

Use the `EnterWorktree` tool or ask Claude:

```
Work on this feature in an isolated worktree so it doesn't affect main.
```

### Worktree Lifecycle

1. **Creation**: A new directory is created under `.claude/worktrees/` with a fresh branch from HEAD
2. **Working**: Claude Code's working directory switches to the worktree
3. **Cleanup**:
   - If no changes were made: worktree is auto-removed on session exit
   - If changes exist: Claude prompts you to keep or remove the worktree

### Sparse Checkout for Large Monorepos

In large monorepos, checking out the entire repository into each worktree is slow and wasteful. The `worktree.sparsePaths` setting uses git sparse-checkout to include only the directories you need:

```json
{
  "worktree.sparsePaths": [
    "packages/api/",
    "packages/shared/",
    "config/"
  ]
}
```

Only the listed directories are checked out in the worktree. This dramatically speeds up `--worktree` startup in repositories with thousands of files.

### When to Use Worktrees

- **Parallel experiments**: Try multiple approaches without conflicting
- **Feature isolation**: Develop a feature without affecting the main branch
- **Subagent isolation**: Configure subagents with `isolation: worktree` for safe parallel writes
- **Risk-free exploration**: Make experimental changes you might discard

### Worktree Cleanup

```bash
# List all worktrees
git worktree list

# Remove a specific worktree
git worktree remove .claude/worktrees/feature-auth

# Prune stale worktree references
git worktree prune
```

---

Next: [Automation and Headless Mode](10c-automation.md)

---
title: "4. Subagents and Task Delegation"
nav_order: 4
---

# Chapter 4: Subagents and Task Delegation

Subagents are one of Claude Code's most powerful features. They let you spawn isolated Claude instances to handle specific tasks, keeping the main conversation context clean and enabling parallel work.

## What Are Subagents?

A subagent is a separate Claude instance launched via the **Task** tool. Each subagent:

- Runs in its own context window (independent of the main conversation)
- Has access to a specific set of tools
- Can use a different model than the main conversation
- Returns a single result message when finished
- Cannot see or modify the main conversation's context
- Cannot use `AskUserQuestion` to prompt the user for input

Think of subagents as delegating work to a specialist. You give them a clear brief, they do the work, and they report back.

## Built-in Agent Types

| Agent type | Tools available | Model | Best for |
| --- | --- | --- | --- |
| **Explore** | Read-only (Glob, Grep, Read) | Haiku | Fast codebase exploration and search |
| **Plan** | Read-only (all except Edit, Write, Task) | Inherited | Research and planning before implementation |
| **Bash** | Bash only | Inherited | Running commands in a separate context |
| **general-purpose** | All tools | Inherited | Complex multi-step tasks |
| **claude-code-guide** | Glob, Grep, Read, WebFetch, WebSearch | Haiku | Answering questions about Claude Code itself |

### Explore Agent

The fastest and cheapest agent. Use it when you need to find things in the codebase.

**Strengths**:
- Quick file discovery and code search
- Understanding project structure
- Finding function definitions, usages, and patterns

**Limitations**:
- Cannot modify files
- Cannot run commands
- Uses Haiku model (less capable reasoning)

**When to use**:
- "Find all usages of `UserService`"
- "What's the project structure under `src/`?"
- "How does error handling work in this codebase?"

### Plan Agent

A research-focused agent with read-only access. Inherits the parent's model for deeper reasoning.

**Strengths**:
- Thorough codebase analysis
- Architectural understanding
- Can access current conversation context

**When to use**:
- Planning a complex refactor before executing
- Understanding unfamiliar code architecture
- Evaluating multiple implementation approaches

### Bash Agent

Runs commands in isolation. Useful when command output would be verbose.

**When to use**:
- Running test suites with large output
- Build processes
- System commands that produce lots of output

### General-Purpose Agent

The most capable subagent with access to all tools. Can read, write, edit, search, and execute commands.

**When to use**:
- Self-contained implementation tasks
- Tasks that need both research and code changes
- Work that would flood the main context with output

### Claude Code Guide Agent

Specialized for answering questions about Claude Code itself. Uses Haiku for speed.

**When to use**:
- Looking up Claude Code features or settings
- Understanding how a specific tool works
- Finding documentation about configuration options

## Using the Task Tool

### Basic Syntax

The Task tool takes these key parameters:

- `prompt` (required): Detailed description of what the agent should do
- `subagent_type` (required): Which agent type to use
- `description` (required): Short 3-5 word summary
- `model` (optional): Override the model (sonnet, opus, haiku)
- `run_in_background` (optional): Run without blocking
- `resume` (optional): Continue a previous agent by ID

### Writing Effective Subagent Prompts

Subagents start fresh -- they don't inherit the main conversation's context (except for agents with "access to current context"). Your prompt must be self-contained.

**Good prompt:**
```
Search the codebase for all files that handle user authentication.
I need to know:
1. Where login/logout is implemented
2. What authentication strategy is used (JWT, sessions, etc.)
3. Where tokens are validated
4. Any middleware that checks authentication

The project is a Node.js/Express app in the current working directory.
Report your findings in a structured format.
```

**Bad prompt:**
```
Find the auth code I was looking at earlier
```

The bad prompt fails because the subagent has no idea what you were looking at.

### Foreground vs Background Agents

**Foreground** (default): Blocks the main conversation until the agent finishes.
- Use when you need the result before continuing
- Use when the result determines your next step

**Background** (`run_in_background: true`): Runs concurrently while the main conversation continues.
- Use when you have independent work to do
- Use for long-running tasks (test suites, builds)
- Check results later with `TaskOutput`

### Resuming Agents

When a subagent finishes, it returns an `agentId`. You can resume it to continue where it left off:

```
Task(resume: "agent-id-here", prompt: "Now also check the middleware folder")
```

This preserves the agent's entire previous context, so you don't need to repeat the original prompt.

## Parallelization

One of the biggest benefits of subagents is running multiple investigations simultaneously.

### Parallel Research Pattern

Launch multiple Explore agents at once:

```
# These three run simultaneously:
Task(subagent_type="Explore", prompt="Find all database models and their relationships")
Task(subagent_type="Explore", prompt="Find all API route definitions")
Task(subagent_type="Explore", prompt="Find all test files and test patterns used")
```

All three complete independently, and you get results from all of them to synthesize.

### Parallel Implementation Pattern

For independent code changes:

```
# These can run in parallel if they touch different files:
Task(subagent_type="general-purpose", prompt="Add input validation to the /users endpoint")
Task(subagent_type="general-purpose", prompt="Add logging to the /payments endpoint")
```

**Caution**: Don't parallelize agents that modify the same files -- they'll conflict.

### Research + Implementation Pattern

```
# Phase 1: Research in parallel
agent1 = Task(subagent_type="Explore", prompt="How does the current auth system work?")
agent2 = Task(subagent_type="Explore", prompt="What test patterns does this project use?")

# Phase 2: Implement using research results
Task(subagent_type="general-purpose", prompt="Based on the auth system findings: ...")
```

## Creating Custom Agents

You can define custom agent types for your project using YAML + Markdown files.

### Agent File Structure

Store agents in `.claude/agents/<name>/` (project scope) or `~/.claude/agents/<name>/` (user scope).

The main file is an `agent.md` (or `AGENT.md`) with YAML frontmatter:

```yaml
---
name: code-reviewer
description: Reviews code changes for quality, security, and best practices
tools: Read, Grep, Glob
model: sonnet
maxTurns: 30
---

You are a code reviewer. When given a file or set of changes, analyze them for:

1. **Correctness**: Does the logic work? Are there edge cases?
2. **Security**: Any injection risks, exposed secrets, or auth bypasses?
3. **Performance**: Any N+1 queries, unnecessary allocations, or blocking calls?
4. **Style**: Does it follow the project's conventions?

Provide specific, actionable feedback referencing exact file locations.
```

### Custom Agent Configuration Options

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
| `memory` | Persistent memory type | None |
| `background` | Run in background by default | false |
| `isolation` | Run in isolated worktree | None |

### Example Custom Agents

**Test Runner Agent**:
```yaml
---
name: test-runner
description: Runs tests and reports results with analysis
tools: Bash, Read, Grep, Glob
model: haiku
---

Run the project's test suite and provide a clear report:
1. Run all tests
2. If failures occur, read the failing test files and source code
3. Provide analysis of each failure with suggested fixes
```

**Migration Agent**:
```yaml
---
name: migration-helper
description: Helps create and validate database migrations
tools: Read, Write, Edit, Bash, Grep, Glob
model: sonnet
---

Help with database migrations. You understand the project's ORM
and migration patterns. Always:
1. Check existing migrations for naming conventions
2. Validate that migrations are reversible
3. Check for data loss risks
```

## When to Use Subagents vs Working Directly

### Use Subagents When:

- The task produces verbose output (test results, search results)
- You want to research without polluting the main context
- Work can be parallelized
- The task is self-contained with a clear deliverable
- You want different permission or model settings

### Work Directly When:

- Changes need frequent back-and-forth with the user
- The task is quick (under 3 tool calls)
- Multiple phases share significant context
- You need the result immediately for the next step
- Low latency matters

## Anti-Patterns

**Don't duplicate work**: If you delegate research to a subagent, don't also run the same searches yourself.

**Don't over-delegate**: For a simple file read or grep, calling the tool directly is faster than launching a subagent.

**Don't forget context**: Subagents (except those with current context access) don't know what you've been discussing. Include all necessary context in the prompt.

**Don't parallelize conflicting writes**: Two agents editing the same file will cause problems. Sequence them instead.

## Agent Teams

Subagents are fire-and-forget workers that report back to the main conversation. Agent teams are something different: fully independent Claude Code sessions that coordinate with each other through a shared task list and direct messaging.

### What Are Agent Teams?

An agent team consists of:

- **A lead agent**: the main Claude Code session that creates the team, spawns teammates, and orchestrates work
- **Teammates**: separate Claude Code instances, each with its own context window
- **A shared task list**: work items that teammates claim and complete
- **A mailbox**: messaging system for inter-agent communication

Each teammate is a full Claude Code session -- not a lightweight subagent. Teammates can read/write files, run commands, message each other, and work autonomously.

### Enabling Agent Teams

Agent teams are experimental and disabled by default. Enable them in settings:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or set the environment variable directly:

```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

### Starting a Team

There is no special command -- describe the team you want and Claude creates it:

```
Create an agent team to refactor the payment module. Spawn three teammates:
- One to refactor the Stripe integration
- One to refactor the PayPal integration
- One to update all the payment tests
```

You can also specify models:

```
Create a team with 4 teammates to implement these features in parallel.
Use Sonnet for each teammate.
```

### How Teammates Coordinate

**Task list**: All agents share a task list. Teammates claim available tasks and mark them complete. Dependencies between tasks are tracked automatically -- blocked tasks unblock when their dependencies finish.

**Messaging**: Teammates communicate directly:
- `message`: send to a specific teammate
- `broadcast`: send to all teammates (use sparingly -- costs tokens on every teammate's context)

**Context**: Each teammate has its own isolated context window. They don't inherit the lead's conversation history, but they do load the same project context (CLAUDE.md, MCP servers, skills).

### Display Modes

Configure how teammates appear in your terminal:

| Mode | Behavior | Requirement |
| --- | --- | --- |
| `in-process` | All teammates in one terminal; cycle with `Shift+Down` | None (default) |
| `split-panes` | Each teammate gets its own pane | tmux or iTerm2 |
| `auto` | Uses split panes if in tmux, in-process otherwise | None |

Set the mode in settings:

```json
{
  "teammateMode": "auto"
}
```

Or pass `--teammate-mode` on the CLI.

### Interactive Controls

| Shortcut | Action |
| --- | --- |
| `Shift+Down` | Cycle through teammates (in-process mode) |
| `Ctrl+T` | Toggle task list view |
| Click pane | Interact with a teammate directly (split-pane mode) |

### The TeammateIdle Hook

The `TeammateIdle` event fires when a teammate is about to go idle after finishing its work. Use it to enforce quality gates:

```json
{
  "hooks": {
    "TeammateIdle": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/check-teammate-done.sh"
          }
        ]
      }
    ]
  }
}
```

- **Exit 0**: Allow the teammate to go idle
- **Exit 2**: Send stderr as feedback; the teammate continues working instead of going idle

`TeammateIdle` only supports `type: "command"` hooks and does not support matchers.

### Agent Teams vs Subagents

| Aspect | Subagents | Agent Teams |
| --- | --- | --- |
| **Architecture** | Lightweight child of main context | Full independent Claude Code session |
| **Communication** | Reports results back to spawner only | Teammates message each other directly |
| **Coordination** | Main agent manages all work | Shared task list with autonomous claiming |
| **Context** | No project context; prompt must be self-contained | Loads CLAUDE.md, MCP servers, skills |
| **Token cost** | Lower: results summarized back | Higher: each teammate is a full session |
| **Best for** | Focused tasks where only the result matters | Complex parallel work needing collaboration |

**Use subagents when**: you need quick, focused workers (research, verification, isolated implementation) that report back a result.

**Use agent teams when**: teammates need to collaborate, share findings, work in parallel on a large task, or coordinate independently without constant direction.

### Best Practices for Agent Teams

**Right-size your team.** Start with 3-5 teammates. Coordination overhead and token costs increase with each additional teammate. A good rule of thumb is 5-6 tasks per teammate.

**Size tasks appropriately.** Each task should be a self-contained unit with a clear deliverable (a function, a test file, a code review). Too small and coordination overhead exceeds the benefit. Too large and teammates work too long without check-ins.

**Avoid file conflicts.** Two teammates editing the same file leads to overwrites. Break work so each teammate owns different files or directories. If overlap is unavoidable, sequence the dependent work.

**Give teammates enough context.** The spawn prompt is all a teammate knows about their job. Include specific file paths, requirements, and constraints:

```
Spawn a security reviewer with this prompt: "Review the authentication
module at src/auth/ for vulnerabilities. Focus on token handling in
src/auth/jwt.ts, session management in src/auth/session.ts, and input
validation in src/auth/middleware.ts."
```

**Start with research and review.** If you're new to agent teams, begin with tasks that have clear boundaries -- code review, investigation, research -- before tackling parallel implementation.

**Let teammates finish.** The lead sometimes starts implementing tasks itself instead of waiting. If this happens, steer it:

```
Wait for your teammates to complete their tasks before proceeding.
```

**Use plan approval for risky work.** Require teammates to plan before implementing:

```
Spawn an architect teammate to refactor auth. Require plan approval
before they make any changes.
```

**Monitor and steer.** Check in on progress, redirect failing approaches, and synthesize findings as they arrive. You can message any teammate directly.

### Limitations

- **Experimental**: Feature is behind a flag and behavior may change
- **No session resumption**: `/resume` and `/rewind` don't restore in-process teammates
- **One team per session**: You can't manage multiple teams simultaneously
- **No nested teams**: Teammates can't spawn their own teams
- **Permissions at spawn time**: All teammates start with the lead's permission mode
- **Split panes require tmux or iTerm2**: Not supported in VS Code terminal, Windows Terminal, or Ghostty

---

Next: [Skills and Slash Commands](05-skills-and-commands.md) -- Creating reusable commands and workflows.

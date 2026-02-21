# Chapter 1: Introduction to Claude Code

## What is Claude Code?

Claude Code is an agentic coding assistant that operates directly in your terminal (or IDE). Unlike chat-based AI tools that only produce text, Claude Code can read your files, edit your code, run commands, search the web, and manage complex multi-step tasks autonomously.

It is built on Anthropic's Claude models and uses a tool-based architecture: Claude reasons about your request, selects the appropriate tools, executes actions, observes results, and iterates until the task is complete.

## How Claude Code Works

### The Agentic Loop

Every interaction with Claude Code follows an **agentic loop**:

1. **You provide a prompt** (a task, question, or instruction)
2. **Claude reasons** about what needs to happen
3. **Claude selects and executes tools** (read files, edit code, run commands, etc.)
4. **Claude observes tool results** and decides the next step
5. **Repeat steps 3-4** until the task is complete
6. **Claude responds** with a summary of what was done

This loop is what makes Claude Code "agentic" rather than just a chatbot. It can autonomously chain multiple actions together, recover from errors, and adapt its approach based on what it discovers.

### Tool-Based Architecture

Claude Code does not directly access your filesystem or run commands. Instead, it uses a set of **tools** that act as controlled interfaces:

- **File tools**: Read, Write, Edit, Glob, Grep
- **Execution tools**: Bash
- **Search tools**: WebSearch, WebFetch
- **Orchestration tools**: Task (subagents), TodoWrite, AskUserQuestion
- **Mode tools**: EnterPlanMode, EnterWorktree

Each tool has defined parameters and behaviors. When Claude calls a tool, the system executes it and returns the result. Some tools require your permission before executing (like editing files or running shell commands), depending on your permission mode.

### Permission Model

Claude Code operates with a layered permission system:

- **No permission needed**: Reading files, searching, web lookups
- **Permission required**: Editing files, running bash commands, writing new files
- **Configurable**: You can allow/deny specific tool patterns (e.g., allow `npm test` but deny `rm -rf`)

You control the permission mode: from strict (ask for everything) to autonomous (bypass all checks). See [Chapter 6](06-memory-and-configuration.md) for details.

## Available Models

Claude Code supports multiple Claude models, each with different tradeoffs:

| Model | ID | Strengths | Best for |
| --- | --- | --- | --- |
| **Opus 4.6** | `claude-opus-4-6` | Most capable, deepest reasoning | Complex architecture, subtle bugs, large refactors |
| **Sonnet 4.6** | `claude-sonnet-4-6` | Strong balance of speed and capability | General development, most daily tasks |
| **Haiku 4.5** | `claude-haiku-4-5-20251001` | Fastest, most cost-efficient | Quick lookups, simple edits, exploration |

Switch models during a session with `/model` or `Alt+P`. Subagents can use different models than the main conversation.

## Running Claude Code

### Terminal (CLI)

```bash
# Start interactive session
claude

# Start with a prompt
claude "explain this codebase"

# Single-shot (non-interactive)
claude -p "what does src/auth.ts do?"

# Resume previous session
claude --resume

# Start in plan mode
claude --permission-mode plan

# Start in a worktree
claude --worktree feature-name
```

### IDE Integration

Claude Code integrates with:

- **VS Code**: Install the "Claude Code" extension from the marketplace. Provides a graphical chat panel, inline diffs, and @-mentions for files.
- **JetBrains IDEs**: Available for IntelliJ, PyCharm, WebStorm, and others via the marketplace.

The CLI and IDE extensions share conversation history and configuration.

## Key Concepts at a Glance

| Concept | What it is | Where to learn more |
| --- | --- | --- |
| **Context window** | The total text Claude can "see" at once (~200k tokens) | [Chapter 2](02-core-ai-concepts.md) |
| **Tools** | Functions Claude calls to interact with your system | [Chapter 3](03-tools-reference.md) |
| **Subagents** | Isolated Claude instances for delegated tasks | [Chapter 4](04-subagents.md) |
| **Skills** | Reusable instructions and commands | [Chapter 5](05-skills-and-commands.md) |
| **CLAUDE.md** | Project-level instructions file | [Chapter 7](07-project-setup.md) |
| **Hooks** | Automated shell commands on lifecycle events | [Chapter 9](09-advanced-features.md) |
| **MCP** | Protocol for connecting to external services | [Chapter 9](09-advanced-features.md) |

## What Claude Code is Good At

- **Reading and understanding codebases**: Navigating unfamiliar projects, explaining architecture, finding relevant code
- **Writing and editing code**: Implementing features, fixing bugs, refactoring
- **Running and debugging**: Executing tests, reading errors, iterating on fixes
- **Multi-step tasks**: Complex operations that require research, planning, implementation, and verification
- **Automation**: Repetitive tasks across many files, migrations, bulk updates

## What Claude Code is Not

- **Not a compiler or runtime**: It cannot execute your code natively; it uses your system's tools via Bash
- **Not infallible**: It can make mistakes, hallucinate APIs, or misunderstand requirements (see [Chapter 2](02-core-ai-concepts.md))
- **Not a replacement for understanding**: It works best when you can review and guide its output
- **Not unlimited**: The context window constrains how much information it can hold at once

---

Next: [Core AI Concepts](02-core-ai-concepts.md) -- Understanding the fundamentals that affect every interaction.

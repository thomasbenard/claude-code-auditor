# Chapter 6: Memory and Configuration

Claude Code has a layered memory and configuration system that lets you control its behavior at every level -- from organization-wide policies down to personal preferences.

## Memory System Overview

Claude Code's memory exists at several layers, each serving a different purpose:

```
┌─────────────────────────────────────┐
│  Managed policy (organization)      │ ← Highest priority, cannot override
├─────────────────────────────────────┤
│  CLAUDE.local.md (personal/project) │ ← Per-project personal overrides
├─────────────────────────────────────┤
│  CLAUDE.md / .claude/CLAUDE.md      │ ← Project instructions (shared)
├─────────────────────────────────────┤
│  .claude/rules/*.md                 │ ← Modular project rules
├─────────────────────────────────────┤
│  ~/.claude/CLAUDE.md                │ ← User-level preferences
├─────────────────────────────────────┤
│  Auto memory (MEMORY.md)            │ ← Claude's own notes
└─────────────────────────────────────┘
```

## CLAUDE.md Files

CLAUDE.md is the primary way to give Claude Code persistent instructions about your project. It is loaded into the system prompt at the start of every conversation.

### Locations

| File | Scope | Shared via git | Purpose |
| --- | --- | --- | --- |
| `CLAUDE.md` (project root) | Project | Yes | Main project instructions |
| `.claude/CLAUDE.md` | Project | Yes | Alternative location (same effect) |
| `CLAUDE.local.md` | Personal/project | No (gitignored) | Personal overrides for this project |
| `~/.claude/CLAUDE.md` | User | No | Global personal preferences |

If both `CLAUDE.md` and `.claude/CLAUDE.md` exist, both are loaded.

### What to Put in CLAUDE.md

A good CLAUDE.md contains stable, high-signal information:

```markdown
# Project Name

## Overview
- Tech stack: Next.js 14, TypeScript, Prisma, PostgreSQL
- Monorepo managed with Turborepo
- API follows REST conventions with /api/v1/ prefix

## Build and Test
- Build: `npm run build`
- Test all: `npm run test`
- Test single file: `npx vitest run path/to/test.ts`
- Lint: `npm run lint`
- Type check: `npx tsc --noEmit`

## Code Conventions
- Use functional components with hooks (no class components)
- Prefer named exports over default exports
- Use Zod for runtime validation
- Error responses follow { error: string, code: string } shape
- Database queries go through repository classes in src/repos/

## Project Structure
- src/app/        → Next.js app router pages
- src/components/ → Reusable UI components
- src/lib/        → Shared utilities and helpers
- src/repos/      → Database repository classes
- src/types/      → TypeScript type definitions
- prisma/         → Database schema and migrations

## Important Notes
- Never modify prisma/schema.prisma without creating a migration
- The CI pipeline runs on every PR: lint → typecheck → test → build
- Feature flags are managed in src/lib/flags.ts
```

### What NOT to Put in CLAUDE.md

- Session-specific context (current task, in-progress work)
- Lengthy documentation that could be in separate files (use imports instead)
- Information that changes frequently
- Anything duplicating existing documentation (link to it instead)

### CLAUDE.md Imports

You can reference other files using `@` syntax:

```markdown
# Project

See @README.md for the full project overview.
Build instructions: @docs/building.md
API conventions: @docs/api-guide.md

# Shared Rules (from user config)
@~/.claude/my-shared-rules.md
```

Imported files are loaded once per project (requires one-time approval).

## Modular Rules

For larger projects, use `.claude/rules/` to organize instructions by domain:

```
.claude/rules/
├── general.md
├── frontend/
│   ├── react.md
│   └── styling.md
├── backend/
│   ├── api.md
│   └── database.md
└── testing.md
```

### Path-Scoped Rules

Rules can be scoped to specific file patterns using frontmatter:

```yaml
---
paths:
  - "src/**/*.tsx"
  - "src/**/*.ts"
---

# TypeScript Conventions

- Use strict mode
- Prefer `const` over `let`
- Use explicit return types on exported functions
- No `any` unless explicitly justified with a comment
```

Path-scoped rules are only loaded when Claude is working on files matching the patterns, saving context space.

## Auto Memory

Auto memory is Claude Code's own note-taking system. It persists across conversations.

### Location

```
~/.claude/projects/<project-hash>/memory/
├── MEMORY.md          ← Loaded into system prompt (first 200 lines)
├── debugging.md       ← Topic file (linked from MEMORY.md)
├── patterns.md        ← Topic file
└── decisions.md       ← Topic file
```

### How Auto Memory Works

- `MEMORY.md` is automatically loaded into the system prompt at session start
- Only the first 200 lines are loaded -- keep it concise
- Claude can read and write memory files during sessions
- Detailed notes go in topic files, linked from MEMORY.md
- Claude should verify patterns across multiple interactions before saving

### What Claude Should Save

- Confirmed patterns and conventions
- Key architectural decisions
- Important file paths
- User preferences for workflow and communication
- Solutions to recurring problems
- Debugging insights

### What Claude Should NOT Save

- Session-specific context (current task, temp state)
- Unverified conclusions from reading a single file
- Information that duplicates CLAUDE.md
- Speculative notes

## Configuration Settings

### Settings Hierarchy

Settings have a strict precedence order:

| Scope | Location | Priority | Can override |
| --- | --- | --- | --- |
| **Managed** | System directory | Highest | Nothing (enforced) |
| **CLI flags** | Command line | 2nd | All below |
| **Local** | `.claude/settings.local.json` | 3rd | Project, User |
| **Project** | `.claude/settings.json` | 4th | User |
| **User** | `~/.claude/settings.json` | Lowest | Nothing |

### Settings File Structure

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",

  "permissions": {
    "defaultMode": "default",
    "allow": [
      "Bash(npm run *)",
      "Bash(git commit *)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl *)",
      "Bash(rm -rf *)",
      "Read(.env)"
    ]
  },

  "env": {
    "NODE_ENV": "development"
  },

  "model": "claude-sonnet-4-6",

  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write $FILE"
          }
        ]
      }
    ]
  }
}
```

## Permission Modes

Claude Code has several permission modes that control what actions require user approval:

| Mode | Edits | Bash | Reads | Use case |
| --- | --- | --- | --- | --- |
| **default** | Ask | Ask | Auto | Interactive development |
| **acceptEdits** | Auto | Ask | Auto | Trust Claude for file changes |
| **plan** | Blocked | Blocked | Auto | Safe exploration only |
| **dontAsk** | Deny (unless allow-listed) | Deny (unless allow-listed) | Auto | Strict control |
| **bypassPermissions** | Auto | Auto | Auto | Isolated/sandboxed environments only |

### Permission Rules

Rules follow the format `Tool(specifier)`:

**Bash rules** use glob patterns:
```json
"allow": ["Bash(npm run *)"],
"deny": ["Bash(rm -rf *)"]
```

**File rules** use file patterns:
```json
"allow": ["Edit(src/**/*.ts)"],
"deny": ["Read(.env)", "Read(./secrets/**)"]
```

**MCP rules** use tool names:
```json
"allow": ["mcp__github__search_repositories"],
"deny": ["mcp__dangerous__*"]
```

**Evaluation order**: deny -> ask -> allow. First match wins.

### Switching Modes

- During a session: `Shift+Tab` cycles through modes
- At startup: `claude --permission-mode plan`
- In settings: `"defaultMode": "acceptEdits"`

## Environment Variables

Set environment variables in settings:

```json
{
  "env": {
    "ANTHROPIC_API_KEY": "sk-...",
    "NODE_ENV": "development",
    "DATABASE_URL": "postgres://localhost/mydb"
  }
}
```

These are available to all Bash commands and tools within the session.

## Keybindings

Customize keyboard shortcuts via `~/.claude/keybindings.json`:

```json
{
  "$schema": "https://www.schemastore.org/claude-code-keybindings.json",
  "bindings": [
    {
      "context": "Chat",
      "bindings": {
        "ctrl+e": "chat:externalEditor",
        "ctrl+u": null
      }
    },
    {
      "context": "Global",
      "bindings": {
        "ctrl+shift+a": "app:exit"
      }
    }
  ]
}
```

### Default Keyboard Shortcuts

| Shortcut | Action |
| --- | --- |
| `Ctrl+C` | Cancel/interrupt current operation |
| `Ctrl+D` | Exit Claude Code |
| `Ctrl+L` | Clear screen |
| `Ctrl+O` | Toggle verbose output |
| `Ctrl+R` | Reverse search history |
| `Ctrl+G` | Open current prompt in text editor |
| `Ctrl+B` | Background a running task |
| `Shift+Tab` | Cycle permission modes |
| `Alt+P` | Switch model |
| `Alt+T` | Toggle extended thinking |
| `Esc Esc` | Rewind/summarize |

## Compact Instructions

Add a special section to CLAUDE.md to preserve critical context during compaction:

```markdown
## Compact Instructions

When compacting, always remember:
- We use Bun, not npm
- Current focus: authentication refactor
- API prefix is /api/v2/ (not v1)
- Tests must pass before any commit
```

This section is re-injected after compaction, ensuring critical project context survives context compression.

---

Next: [Project Setup](07-project-setup.md) -- Setting up a project for optimal Claude Code usage.

---
title: "7. Memory and Configuration"
nav_order: 7
---

# Chapter 7: Memory and Configuration

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

## Auto Memory (MEMORY.md)

CLAUDE.md files are instructions *you* write for Claude. Auto memory is the opposite: it is Claude Code's own notebook -- a place where Claude writes notes *to itself* that persist across conversations. Think of it as Claude's long-term memory for your project.

Without auto memory, every conversation starts from scratch. Claude would re-discover the same project quirks, re-learn your preferences, and repeat mistakes it already solved. MEMORY.md bridges that gap by letting Claude carry forward what it learns.

### How It Differs from CLAUDE.md

| | CLAUDE.md | MEMORY.md |
| --- | --- | --- |
| **Who writes it** | You (the developer) | Claude Code |
| **Purpose** | Instructions and rules for Claude to follow | Notes Claude keeps for its own reference |
| **Shared with team** | Yes (committed to git) | No (local to your machine) |
| **Content style** | Directives ("always do X", "never do Y") | Observations ("this project uses X", "user prefers Y") |
| **Loaded into context** | Full file | First 200 lines only |

Both are loaded into Claude's system prompt at the start of every session, but they serve different roles. CLAUDE.md is like a project README for Claude; MEMORY.md is like Claude's personal scratch pad.

### Location

Auto memory lives in a per-project directory under your home folder:

```
~/.claude/projects/<project-hash>/memory/
├── MEMORY.md          ← Main file, loaded into system prompt (first 200 lines)
├── debugging.md       ← Topic file (linked from MEMORY.md)
├── patterns.md        ← Topic file
└── decisions.md       ← Topic file
```

The `<project-hash>` is derived from the project path, so each project gets its own separate memory. You can view and edit the `/memory` slash command to open these files directly.

### How Auto Memory Works

1. **Automatic loading**: `MEMORY.md` is loaded into the system prompt at the start of every session. Claude sees its own notes before you even type your first message.
2. **200-line limit**: Only the first 200 lines of `MEMORY.md` are loaded. Lines beyond that are silently truncated, so brevity matters.
3. **Claude reads and writes**: Claude uses its standard Read, Write, and Edit tools to manage memory files during a session. No special API is needed.
4. **Topic files for overflow**: When a subject needs more detail than fits in 200 lines, Claude creates separate topic files (e.g., `debugging.md`, `patterns.md`) and links to them from MEMORY.md. These are not auto-loaded but Claude can read them on demand.
5. **Verification before saving**: Claude is instructed to confirm patterns across multiple interactions before committing them to memory, avoiding premature or inaccurate notes.

### What Claude Saves

Auto memory works best when it captures durable, high-value knowledge:

- **Confirmed patterns and conventions** -- "This project uses Bun, not npm" or "Tests are in `__tests__/` directories colocated with source"
- **Key architectural decisions** -- "Auth uses JWT with refresh tokens stored in httpOnly cookies"
- **Important file paths** -- "Main entry point is `src/server/index.ts`, database config is in `config/database.yml`"
- **User preferences** -- "User prefers short commit messages" or "Always ask before running destructive commands"
- **Solutions to recurring problems** -- "The Prisma client must be regenerated after schema changes: `npx prisma generate`"
- **Debugging insights** -- "Flaky test in `auth.test.ts` is caused by a race condition in the mock timer setup"

### What Claude Does NOT Save

- **Session-specific context** -- Current task details, in-progress work, temporary state
- **Unverified conclusions** -- Something observed in a single file without broader confirmation
- **Duplicates of CLAUDE.md** -- If it's already in your project instructions, it doesn't need to be in memory too
- **Speculative notes** -- Guesses or hypotheses that haven't been confirmed

### Interacting with Auto Memory

You can directly influence what Claude remembers:

**Ask Claude to remember something:**
```
> Always use pnpm instead of npm in this project. Remember that.
> Remember: the staging database is on port 5433, not 5432.
```

When you explicitly ask Claude to remember something, it saves it immediately without waiting for repeated confirmation.

**Ask Claude to forget something:**
```
> Stop remembering that we use Jest -- we switched to Vitest.
> Forget the note about the staging database port.
```

Claude will find and remove or update the relevant entry in its memory files.

**Review what Claude remembers:**
```
> What do you have in your memory files for this project?
> Show me your MEMORY.md
```

You can also use the `/memory` slash command to view and edit auto memory files directly.

### Example MEMORY.md

Here is what a real MEMORY.md might look like after several sessions:

```markdown
# Project Memory

## Build & Tools
- Uses pnpm (not npm or yarn)
- Node 20 required (nvm use before running anything)
- `pnpm dev` starts both API and frontend concurrently

## Architecture
- API: Express with TypeScript in src/api/
- Frontend: React 18 + Vite in src/web/
- Shared types: src/shared/types/

## User Preferences
- Prefers concise commit messages (imperative, <50 chars)
- Wants tests run before every commit suggestion
- Uses VS Code with Prettier on save

## Known Issues
- See [debugging.md](debugging.md) for the Redis connection timeout workaround
- Test suite requires Docker running (for Postgres container)

## Conventions Discovered
- API routes follow pattern: src/api/routes/{resource}.routes.ts
- Each route file exports a router, registered in src/api/index.ts
- Validation uses Zod schemas colocated with route files
```

### Tips for Effective Auto Memory

- **Keep MEMORY.md under 200 lines** -- anything beyond that is not loaded. Move detailed notes to topic files.
- **Organize by topic, not by date** -- semantic grouping ("Build & Tools", "Architecture") is more useful than a chronological log.
- **Prune regularly** -- if you notice outdated notes, tell Claude to update or remove them. Stale memory is worse than no memory.
- **Don't duplicate CLAUDE.md** -- if you've already documented something in your project instructions, Claude doesn't need to memorize it separately.
- **Use topic files for depth** -- a MEMORY.md entry like "See [debugging.md](debugging.md) for Redis workaround" keeps the main file lean while preserving detail.

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

Next: [Project Setup](08-project-setup.md) -- Setting up a project for optimal Claude Code usage.

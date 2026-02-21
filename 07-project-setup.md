---
title: "7. Project Setup"
nav_order: 7
---

# Chapter 7: Project Setup

This chapter covers how to set up a project for optimal Claude Code usage. A well-configured project dramatically improves Claude Code's effectiveness -- it makes fewer mistakes, follows your conventions, and works faster.

## First-Time Setup

### Quick Start

```bash
# Navigate to your project
cd /path/to/your/project

# Initialize Claude Code configuration
claude /init
```

The `/init` command creates a starter `CLAUDE.md` file. But for best results, you should customize it.

### Recommended Project Structure

```
your-project/
├── CLAUDE.md                    # Main project instructions
├── CLAUDE.local.md              # Personal overrides (gitignored)
├── .claude/
│   ├── settings.json            # Shared project settings
│   ├── settings.local.json      # Personal settings (gitignored)
│   ├── CLAUDE.md                # Alternative CLAUDE.md location
│   ├── rules/                   # Modular instruction files
│   │   ├── general.md
│   │   ├── frontend.md
│   │   └── testing.md
│   ├── skills/                  # Custom skills
│   │   ├── commit/
│   │   │   └── SKILL.md
│   │   └── review/
│   │       └── SKILL.md
│   ├── agents/                  # Custom subagents
│   │   └── test-runner/
│   │       └── agent.md
│   └── launch.json              # Dev server configurations
├── .mcp.json                    # Shared MCP server config
└── .gitignore                   # Should include .claude/settings.local.json
```

### .gitignore Additions

Add these to your `.gitignore`:

```gitignore
# Claude Code personal files
CLAUDE.local.md
.claude/settings.local.json
```

## Writing an Effective CLAUDE.md

### Structure Template

```markdown
# [Project Name]

## Overview
Brief description of what the project does and its key technologies.

## Tech Stack
- Language: [e.g., TypeScript 5.x]
- Framework: [e.g., Next.js 14 with App Router]
- Database: [e.g., PostgreSQL via Prisma ORM]
- Testing: [e.g., Vitest + React Testing Library]
- Package manager: [e.g., pnpm]

## Quick Commands
- Install: `pnpm install`
- Dev server: `pnpm dev`
- Build: `pnpm build`
- Test: `pnpm test`
- Test single: `pnpm test -- path/to/test.ts`
- Lint: `pnpm lint`
- Type check: `pnpm tsc --noEmit`
- Database migrate: `pnpm prisma migrate dev`

## Project Structure
- `src/app/` - Pages and routes (Next.js App Router)
- `src/components/` - Reusable UI components
- `src/lib/` - Shared utilities
- `src/server/` - Server-side logic and API
- `prisma/` - Database schema and migrations
- `tests/` - Integration tests

## Code Conventions
- Prefer named exports
- Use Zod schemas for validation (co-locate with types)
- Components: PascalCase files, one component per file
- Hooks: camelCase with `use` prefix
- API responses: `{ data, error, meta }` envelope
- Error handling: throw AppError instances, caught by middleware

## Important Rules
- Never import from `@internal/*` in client components
- Always create a Prisma migration after schema changes
- Tests must pass before committing (CI enforces this)
- No `any` types without a justifying comment

## Compact Instructions
When compacting conversation, preserve:
- We use pnpm (not npm or yarn)
- App Router (not Pages Router)
- Prisma for database access
```

### Tips for CLAUDE.md

1. **Be concise**: Every line consumes context tokens. Cut what doesn't add value.
2. **Be specific**: "Use Zod for validation" is better than "validate inputs"
3. **Include commands**: Claude needs to know how to build, test, and lint
4. **Document structure**: File organization helps Claude navigate
5. **State prohibitions**: What should Claude never do? Say it explicitly.
6. **Use imports for details**: `@docs/api-conventions.md` instead of pasting long docs

## Setting Up Modular Rules

For larger projects, modular rules keep CLAUDE.md focused while providing detailed guidance:

### General Rules

`.claude/rules/general.md`:
```markdown
# General Conventions

- Indentation: 2 spaces
- Line length: 100 characters max
- File naming: kebab-case for files, PascalCase for components
- Imports: group by external, internal, relative (with blank lines between)
- No console.log in production code (use the logger)
- All public functions need JSDoc comments
```

### Path-Scoped Rules

`.claude/rules/frontend.md`:
```yaml
---
paths:
  - "src/components/**"
  - "src/app/**"
---

# Frontend Rules

- Use `cn()` helper for conditional classNames (from src/lib/utils)
- Prefer server components by default, use 'use client' only when needed
- Form state: use React Hook Form + Zod resolver
- Data fetching: use server actions or React Query (no raw fetch in components)
- Tailwind classes: follow the order defined in .prettierrc
```

`.claude/rules/database.md`:
```yaml
---
paths:
  - "prisma/**"
  - "src/server/repos/**"
---

# Database Rules

- All queries go through repository classes in src/server/repos/
- Never use raw SQL -- use Prisma query builder
- Always use transactions for multi-table updates
- Index foreign keys and frequently queried columns
- Migration names: descriptive (add_user_email_index, not migration_001)
```

## Configuring Permissions

### For Solo Development

`.claude/settings.json`:
```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(pnpm *)",
      "Bash(git status)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(npx prisma *)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(git push *)",
      "Bash(git reset --hard *)",
      "Read(.env*)"
    ]
  }
}
```

### For Team Projects

`.claude/settings.json` (shared):
```json
{
  "permissions": {
    "allow": [
      "Bash(pnpm run *)",
      "Bash(pnpm test *)",
      "Bash(pnpm build)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Read(.env*)",
      "Read(**/secrets/**)"
    ]
  }
}
```

Individual developers override in `.claude/settings.local.json`.

## Setting Up MCP Servers

### Project-Level MCP (.mcp.json)

Share MCP server configuration with the team:

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

### Managing MCP Servers

```bash
# Add a server
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# List servers
claude mcp list

# Remove a server
claude mcp remove github

# Authenticate (for OAuth servers)
# Use /mcp in a session
```

## Setting Up Dev Server Preview

### launch.json

Configure dev servers for the preview system:

`.claude/launch.json`:
```json
{
  "version": "0.0.1",
  "configurations": [
    {
      "name": "dev",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["run", "dev"],
      "port": 3000
    },
    {
      "name": "storybook",
      "runtimeExecutable": "pnpm",
      "runtimeArgs": ["run", "storybook"],
      "port": 6006
    }
  ]
}
```

Claude can then start servers with `preview_start` and take screenshots to verify visual changes.

## Setting Up Hooks

### Auto-Format on Edit

`.claude/settings.json`:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write \"$(echo $TOOL_INPUT | jq -r '.file_path')\""
          }
        ]
      }
    ]
  }
}
```

### Protect Sensitive Files

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/check-protected-files.sh"
          }
        ]
      }
    ]
  }
}
```

## Creating Project Skills

### Common Project Skills

**Commit skill** (`.claude/skills/commit/SKILL.md`):
```yaml
---
name: commit
description: Creates a conventional commit
disable-model-invocation: true
---

Create a git commit:
1. Stage relevant changes (never stage .env or secrets)
2. Use conventional commit format: type(scope): description
3. Types: feat, fix, refactor, docs, test, chore, perf
4. Keep subject under 72 chars
5. Add body explaining WHY if the change isn't obvious
```

**Deploy skill** (`.claude/skills/deploy/SKILL.md`):
```yaml
---
name: deploy
description: Deploys to the specified environment
disable-model-invocation: true
argument-hint: "<environment: staging|production>"
---

Deploy to $ARGUMENTS:
1. Verify all tests pass
2. Verify the build succeeds
3. Show the git log of what will be deployed
4. Ask for confirmation before proceeding
5. Run the deployment command for the specified environment
```

## Team Onboarding Checklist

When adding Claude Code to a team project:

1. Create `CLAUDE.md` with project overview, commands, and conventions
2. Add `.claude/settings.json` with shared permission rules
3. Create `.claude/rules/` for domain-specific instructions
4. Add `.mcp.json` for shared MCP server configs
5. Create common skills in `.claude/skills/`
6. Update `.gitignore` with personal files
7. Document the setup in your project's README or contributing guide

> **Tip**: Run `/audit-claude-setup <path>` to evaluate any project's Claude Code configuration against these best practices.

## Monorepo Considerations

For monorepos, place CLAUDE.md files at multiple levels:

```
monorepo/
├── CLAUDE.md                    # Shared instructions
├── .claude/rules/general.md     # Global rules
├── packages/
│   ├── api/
│   │   ├── CLAUDE.md            # API-specific instructions
│   │   └── .claude/rules/
│   ├── web/
│   │   ├── CLAUDE.md            # Web-specific instructions
│   │   └── .claude/rules/
│   └── shared/
│       └── CLAUDE.md
```

Claude Code loads the CLAUDE.md closest to the files it's working on, plus parent CLAUDE.md files.

---

Next: [Effective Prompting and Workflow](08-effective-prompting.md) -- Getting the best results from Claude Code.

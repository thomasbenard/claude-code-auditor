# Audit Reference: Examples of Good Configuration

Use these examples when making recommendations to the user. They represent the patterns documented throughout this guide.

## Minimal Effective CLAUDE.md

See [Chapter 8 - Writing an Effective CLAUDE.md](08-project-setup.md) for the full template.

```markdown
# Project Name

## Overview
What the project does, key technologies.

## Tech Stack
- Language: TypeScript 5.x
- Framework: Next.js 14 with App Router
- Database: PostgreSQL via Prisma ORM
- Testing: Vitest + React Testing Library
- Package manager: pnpm

## Quick Commands
- Install: `pnpm install`
- Build: `pnpm build`
- Test: `pnpm test`
- Test single: `pnpm test -- path/to/test.ts`
- Lint: `pnpm lint`
- Type check: `pnpm tsc --noEmit`

## Project Structure
- `src/app/` - Pages and routes
- `src/components/` - Reusable UI components
- `src/lib/` - Shared utilities
- `src/server/` - Server-side logic

## Code Conventions
- Prefer named exports over default exports
- Use Zod schemas for runtime validation
- Error responses follow { error: string, code: string } shape

## Important Rules
- Never modify migrations without creating a new one
- Tests must pass before committing
- No `any` types without a justifying comment

## Compact Instructions
When compacting, preserve:
- We use pnpm (not npm or yarn)
- App Router (not Pages Router)
```

## .gitignore Entries

These lines should be present in `.gitignore` for any project using Claude Code:

```gitignore
# Claude Code personal files
CLAUDE.local.md
.claude/settings.local.json
```

## Common Starter Skills

Recommend these based on the project's tech stack:

- **commit**: Conventional commit workflow with type prefixes (feat:, fix:, refactor:, etc.)
- **review**: Code review checking correctness, security, performance, and style
- **test-for**: Generate tests for a specific file following existing test patterns

See [Chapter 5](05-skills-and-commands.md) for the full skill format and examples.

## Permission Patterns

### For solo development
```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": ["Bash(npm run *)", "Bash(git status)", "Bash(git diff *)"],
    "deny": ["Bash(rm -rf *)", "Bash(git push *)", "Read(.env*)"]
  }
}
```

### For team projects
```json
{
  "permissions": {
    "allow": ["Bash(npm run *)", "Bash(npm test *)"],
    "deny": ["Bash(rm -rf *)", "Read(.env*)", "Read(**/secrets/**)"]
  }
}
```

See [Chapter 8 - Configuring Permissions](08-project-setup.md) for more patterns.

## Hook Examples

### Auto-format after edits (PostToolUse)
```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "prettier --write \"$FILE\""}]
    }]
  }
}
```

### Protect sensitive files (PreToolUse)
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{"type": "command", "command": "bash .claude/hooks/check-protected-files.sh"}]
    }]
  }
}
```

See [Chapter 10 - Hooks](10-advanced-features.md) for the full event reference and more examples.

## Dev Server Configuration

```json
{
  "version": "0.0.1",
  "configurations": [
    {
      "name": "dev",
      "runtimeExecutable": "npm",
      "runtimeArgs": ["run", "dev"],
      "port": 3000
    }
  ]
}
```

See [Chapter 8 - Setting Up Dev Server Preview](08-project-setup.md) for details.

## Output Format

After completing all checks, produce your report in this structure:

### Summary Table

| # | Check | Status | Priority |
|---|-------|--------|----------|
| 1 | CLAUDE.md quality | PASS/PARTIAL/MISSING | High/Medium/Low |
| 2 | Modular rules | ... | ... |
| 3 | Skills | ... | ... |
| 4 | Custom agents | ... | ... |
| 5 | Settings & permissions | ... | ... |
| 6 | MCP configuration | ... | ... |
| 7 | Dev server preview | ... | ... |
| 8 | Git hygiene | ... | ... |
| 9 | Hooks | ... | ... |

### Top 3 Recommendations

List the three highest-impact improvements in priority order. For each, provide:
1. What to create or change (be specific with file paths and content)
2. Why it matters
3. Which chapter in this guide has the full details

### Detailed Findings

Provide the full per-check evaluation as assessed above.

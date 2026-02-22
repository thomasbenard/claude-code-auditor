# Audit Reference: Skill Efficiency Patterns

Use these examples when making recommendations. They show the difference between token-wasteful and token-efficient skill design.

## Model Selection Guide

| Skill type | Recommended model | Why |
|---|---|---|
| Code search / file listing | `model: haiku` | Mechanical task, no deep reasoning |
| Running commands and reporting output | `model: haiku` | Just executing and formatting |
| Code review / analysis | `model: sonnet` | Needs reasoning but not frontier-level |
| Complex refactoring / architecture | Omit (inherit parent) | Needs the strongest model |
| Report generation from data | `model: sonnet` | Structured output, moderate reasoning |

### Example: Downgrading model

Before (wasteful -- uses Opus for a mechanical task):
```yaml
---
name: list-todos
description: Lists all TODO comments in the codebase
---
Search for all TODO, FIXME, and HACK comments. Report them grouped by file.
```

After (efficient -- Haiku handles this easily):
```yaml
---
name: list-todos
description: Lists all TODO comments in the codebase
model: haiku
allowed-tools: Grep, Glob, Read
context: fork
---
Search for all TODO, FIXME, and HACK comments. Report them grouped by file.
```

Savings: ~90% cost reduction per invocation (Haiku vs Opus pricing) plus token savings from restricted tools.

## Tool Restriction Guide

Every tool in `allowed-tools` adds its description to the system prompt. Restricting tools saves tokens on every turn.

| Skill type | Recommended `allowed-tools` |
|---|---|
| Read-only audit/analysis | `Read, Glob, Grep` |
| Code generation / editing | `Read, Write, Edit, Glob, Grep` |
| Build/test runner | `Bash, Read, Glob, Grep` |
| Full implementation | Omit (allow all) or `Read, Write, Edit, Bash, Glob, Grep` |

### Example: Restricting tools

Before (wasteful -- every tool's description is loaded):
```yaml
---
name: check-types
description: Runs the TypeScript type checker and reports errors
---
Run `npx tsc --noEmit` and report any type errors found.
```

After (efficient -- only needs Bash to run the command and Read to inspect files):
```yaml
---
name: check-types
description: Runs the TypeScript type checker and reports errors
allowed-tools: Bash, Read, Glob
context: fork
---
Run `npx tsc --noEmit` and report any type errors found.
```

## Context Fork Guide

Skills producing verbose output should use `context: fork` to keep the main conversation clean. Without it, large outputs fill the parent context and trigger earlier compaction.

### When to use `context: fork`

- Reports and analysis (code review, bundle analysis, test results)
- Skills that run commands with large output
- Audit and listing skills
- Any skill where the output is consumed once and doesn't need follow-up

### When NOT to use `context: fork`

- Skills that need interactive follow-up ("now fix issue #3 from the review")
- Skills where the user will immediately act on the output in conversation
- Very short skills (fork overhead isn't worth it for a 2-line result)

## Auto-Invocation Control

### Overly broad description (wastes tokens on false positives)

```yaml
description: Helps with code
```
This triggers on almost any coding request, wasting tokens loading the skill when it's not relevant.

### Precise description (triggers only when appropriate)

```yaml
description: Generates a database migration file when the user asks to change a database table or schema
```

### Side-effect skills MUST disable auto-invocation

```yaml
---
name: deploy
description: Deploys the application to production
disable-model-invocation: true
---
```

Without `disable-model-invocation: true`, Claude might auto-trigger a deploy when the user says something like "I'm ready to deploy."

## Shell Preprocessing Pitfalls

### Unbounded output (dangerous)
```markdown
!`git log`
!`cat src/large-file.ts`
!`find . -name "*.ts"`
```

### Bounded output (safe)
```markdown
!`git log -10 --oneline`
!`head -50 src/large-file.ts`
!`find . -name "*.ts" -maxdepth 3 | head -30`
```

## Prompt Conciseness

### Padded (wasteful)
```markdown
You are an expert code reviewer. As a skilled developer, you should
carefully analyze the code that is provided to you. Your goal is to
find issues and provide helpful feedback. Please be thorough in your
analysis and provide detailed explanations for each issue you find.
Remember to be constructive and helpful in your feedback.

Please review the following code for any issues:
```

### Concise (efficient)
```markdown
Review this code for correctness, security, and performance issues.
Provide specific feedback with file:line references.
```

The concise version saves ~60 tokens and produces equally good results because Claude already knows how to review code well.

## Migrating Legacy Commands

Legacy `.claude/commands/name.md` files should be migrated to `.claude/skills/name/SKILL.md`:

1. Create the directory: `.claude/skills/name/`
2. Move `name.md` to `.claude/skills/name/SKILL.md`
3. Add YAML frontmatter with `name`, `description`, and efficiency options
4. Delete the old `.claude/commands/name.md`

The new format supports `allowed-tools`, `model`, `context: fork`, and other efficiency features that the legacy format lacks.

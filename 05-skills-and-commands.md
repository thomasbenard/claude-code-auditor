---
title: "5. Skills and Slash Commands"
nav_order: 5
---

# Chapter 5: Skills and Slash Commands

Skills and slash commands extend Claude Code with reusable instructions, workflows, and domain-specific knowledge. They are how you teach Claude Code project-specific patterns or create repeatable workflows.

## Built-in Slash Commands

Claude Code ships with built-in commands invoked by typing `/` in the prompt:

### Session Management

| Command | Purpose |
| --- | --- |
| `/clear` | Clear the conversation history and start fresh |
| `/compact` | Compress conversation to free context space. Accepts optional focus instructions: `/compact focus on the auth refactor` |
| `/resume` | Open session picker to resume a previous conversation |
| `/rename <name>` | Rename the current session |
| `/rewind` | Rewind code and/or conversation to a previous state |

### Configuration and Setup

| Command | Purpose |
| --- | --- |
| `/config` | Open the settings interface |
| `/init` | Create a CLAUDE.md file for the project |
| `/memory` | Edit auto memory files |
| `/permissions` | View and update permission rules |
| `/model` | Change the active AI model |
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
| `/skills` | List all available skills |
| `/agents` | Create and manage custom subagents |
| `/hooks` | Configure lifecycle hooks |

### Utilities

| Command | Purpose |
| --- | --- |
| `/help` | Show help information |
| `/debug` | Troubleshoot the current session |
| `/doctor` | Check Claude Code installation health |
| `/export` | Export the conversation |
| `/status` | Show version, account, and model information |
| `/stats` | View usage statistics |

## What Are Skills?

Skills are reusable instruction packages that Claude Code can invoke. They are like custom slash commands with embedded knowledge:

- A skill can be a **workflow** (e.g., `/commit` that follows a specific commit process)
- A skill can be **domain knowledge** (e.g., coding conventions, API patterns)
- A skill can be a **tool** (e.g., a code review process with specific criteria)

Skills are defined as markdown files with YAML frontmatter and stored in predictable locations.

## Creating Skills

### File Structure

Each skill lives in its own directory:

```
.claude/skills/my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Optional template for output
├── examples.md        # Optional examples
├── reference.md       # Optional detailed reference
└── scripts/
    └── validate.sh    # Optional executable scripts
```

The only required file is `SKILL.md`.

### SKILL.md Format

```yaml
---
name: review-code
description: Reviews code for quality, security, and performance issues
argument-hint: "[file or directory]"
---

Review the code at $ARGUMENTS for the following:

## Quality
- Is the logic correct?
- Are there edge cases not handled?
- Is error handling appropriate?

## Security
- Any injection vulnerabilities?
- Exposed secrets or credentials?
- Proper input validation?

## Performance
- Unnecessary database queries?
- Memory leaks?
- Blocking operations?

Provide specific, actionable feedback with file:line references.
```

### Frontmatter Options

| Field | Type | Purpose |
| --- | --- | --- |
| `name` | string | Display name, becomes the `/name` command. If omitted, uses the directory name |
| `description` | string | When to invoke this skill (used for auto-detection) |
| `argument-hint` | string | UI hint showing expected arguments |
| `disable-model-invocation` | boolean | If true, only the user can invoke (not auto-detected) |
| `user-invocable` | boolean | If false, only Claude can invoke (not a slash command) |
| `allowed-tools` | string | Restrict which tools the skill can use |
| `model` | string | Override the model for this skill |
| `context` | string | Set to `fork` to run in a subagent context |
| `agent` | string | Which subagent type to use (when `context: fork`) |
| `hooks` | object | Lifecycle hooks for this skill |

### String Substitutions

Skills support dynamic content injection:

| Variable | Expands to |
| --- | --- |
| `$ARGUMENTS` | All arguments passed to the skill |
| `$0`, `$1`, `$2` | Individual arguments by position |
| `$ARGUMENTS[0]` | Same as `$0` |
| `${CLAUDE_SESSION_ID}` | Current session identifier |
| `` !`command` `` | Output of a shell command (preprocessing) |

If `$ARGUMENTS` does not appear anywhere in the skill content, any arguments the user passes are automatically appended as `ARGUMENTS: <value>` at the end.

### Dynamic Context with Shell Preprocessing

You can inject dynamic content into skill instructions using `` !`command` `` syntax:

```yaml
---
name: review-pr
description: Reviews the current pull request
disable-model-invocation: true
---

Review this pull request:

## PR Details
!`gh pr view --json title,body,additions,deletions`

## Changed Files
!`gh pr diff --stat`

## Full Diff
!`gh pr diff`

Analyze the changes for correctness, style, and potential issues.
```

The shell commands run at skill invocation time, injecting their output directly into the prompt.

## Skill Locations and Precedence

Skills are loaded from multiple locations with clear precedence:

| Location | Scope | Priority | Shared |
| --- | --- | --- | --- |
| Managed (enterprise) | Organization | Highest | Yes (admin-controlled) |
| `~/.claude/skills/<name>/` | User (personal) | High | No |
| `.claude/skills/<name>/` | Project | Medium | Yes (via git) |
| Plugin skills | Where plugin is enabled | Low | Depends on plugin |
| `.claude/commands/` | Project (legacy) | Lowest | Yes |

When skills share the same name, higher-priority locations win. User-level (personal) skills override project-level skills of the same name. Plugin skills use a `plugin-name:skill-name` namespace, so they cannot conflict with other levels. If a skill and a legacy command share the same name, the skill takes precedence.

### Automatic Discovery in Monorepos

When you work with files in subdirectories, Claude Code automatically discovers skills from nested `.claude/skills/` directories. For example, if you are editing a file in `packages/frontend/`, Claude Code also loads skills from `packages/frontend/.claude/skills/`. This supports monorepo setups where packages define their own skills.

## Invocation Modes

### User-Invoked Skills

Skills are invoked by typing `/<skill-name>` in the prompt:

```
/review-code src/auth.ts
/commit
/deploy staging
```

The text after the skill name becomes `$ARGUMENTS`.

### Auto-Invoked Skills

When a skill has a `description`, Claude may automatically invoke it when the user's request matches. For example, a skill with `description: "Reviews code for quality issues"` might auto-trigger when the user says "can you review this code?"

To prevent auto-invocation (for skills with side effects), set:
```yaml
disable-model-invocation: true
```

### Claude-Only Skills

Skills with `user-invocable: false` can only be triggered by Claude, not typed as a command. Use this for background knowledge that shouldn't be a slash command:

```yaml
---
name: coding-standards
description: Project coding standards and conventions
user-invocable: false
---

This project follows these standards:
- Use functional components with hooks in React
- All API responses follow the {data, error, meta} envelope pattern
- Database queries go through the repository pattern
...
```

## Running Skills in Subagents

Add `context: fork` to run the skill in an isolated subagent:

```yaml
---
name: analyze-bundle
description: Analyzes the production bundle size
context: fork
agent: Bash
---

Run the bundle analyzer and report findings:
1. npm run build
2. Analyze the build output
3. Report the top 10 largest modules
```

This keeps verbose output out of the main conversation context.

## Supporting Files

Skills can reference additional files in their directory:

```markdown
---
name: api-endpoint
description: Creates a new API endpoint following project patterns
---

Create a new API endpoint based on these instructions.

For the endpoint pattern, follow: [template.md](template.md)
For examples of existing endpoints, see: [examples.md](examples.md)
For error handling conventions, see: [reference.md](reference.md)
```

## Practical Skill Examples

### Commit Workflow

```yaml
---
name: commit
description: Creates a well-formatted git commit
disable-model-invocation: true
argument-hint: "[optional message hint]"
---

Create a git commit following these steps:

1. Run `git status` and `git diff --staged` to see changes
2. If nothing is staged, stage relevant files (never stage .env or secrets)
3. Write a commit message that:
   - Starts with a type prefix (feat:, fix:, refactor:, docs:, test:, chore:)
   - Is under 72 characters for the subject line
   - Explains WHY, not just what
4. Create the commit
5. Show the result with `git log -1`

User hint: $ARGUMENTS
```

### Migration Generator

```yaml
---
name: migrate
description: Creates a database migration
argument-hint: "<description of the migration>"
allowed-tools: Read, Write, Bash, Glob, Grep
---

Create a database migration for: $ARGUMENTS

Steps:
1. Check existing migrations in `db/migrations/` for naming conventions
2. Determine the next migration number
3. Create both `up` and `down` migrations
4. Validate SQL syntax
5. Show the generated migration for review
```

### Test Generator

```yaml
---
name: test-for
description: Generates tests for a specific file or function
argument-hint: "<file path>"
---

Generate comprehensive tests for: $ARGUMENTS

1. Read the target file to understand its API
2. Check existing tests for patterns and test framework used
3. Generate tests covering:
   - Happy path
   - Edge cases
   - Error conditions
   - Boundary values
4. Follow the project's existing test style
5. Run the tests to verify they pass
```

## User Interaction in Skills

Because skills run in the main agent context (not in a subagent), they have access to the `AskUserQuestion` tool. This means a skill can pause mid-execution to ask the user clarifying questions with multiple-choice options before continuing.

This is a key difference from subagents spawned via the Task tool, where `AskUserQuestion` is **not** available. If your workflow needs to gather user input at runtime, implement it as a skill rather than a custom agent.

For skills that run in a subagent (`context: fork`), `AskUserQuestion` is not available — the skill runs in an isolated context that cannot prompt the user.

## Best Practices

1. **Keep skills focused**: One skill, one purpose. Don't create mega-skills that do everything.

2. **Use `disable-model-invocation: true`** for skills with side effects (commits, deploys, messages).

3. **Include examples**: Skills with examples in supporting files produce more consistent results.

4. **Use `context: fork`** for skills that produce verbose output (analysis, reports, test runs).

5. **Version control project skills**: Store in `.claude/skills/` so the team shares them.

6. **Use user-level skills** (`~/.claude/skills/`) for personal preferences that apply across all projects.

7. **Keep description accurate**: The description determines when Claude auto-invokes the skill. Be specific about the trigger conditions.

---

Next: [MCP (Model Context Protocol)](06-mcp.md) -- Connecting Claude Code to external tools and services.

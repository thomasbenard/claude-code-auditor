# Skills and Commands: Skills

## What Are Skills?

Skills are reusable instruction packages that Claude Code can invoke. They are like custom slash commands with embedded knowledge:

- A skill can be a **workflow** (e.g., `/commit` that follows a specific commit process)
- A skill can be **domain knowledge** (e.g., coding conventions, API patterns)
- A skill can be a **tool** (e.g., a code review process with specific criteria)

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard, a portable format that works across many AI tools. Claude Code extends the standard with additional features like [invocation control](#invocation-modes), [subagent execution](#running-skills-in-subagents), and [dynamic context injection](#dynamic-context-with-shell-preprocessing). See [The Agent Skills Open Standard](05c-plugins.md#the-agent-skills-open-standard) for the cross-platform ecosystem.

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
| `${CLAUDE_SKILL_DIR}` | Absolute path to the skill's own directory (for referencing supporting files) |
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

**Scope precedence edge cases**: If you define a skill named `deploy` in both `~/.claude/skills/deploy/` and `.claude/skills/deploy/`, only the user-level version runs. The project-level version is completely shadowed -- it will not appear in `/skills` output and cannot be invoked. To use both, give them distinct names. Managed (enterprise) skills override everything, including user-level skills. Plugin skills are the exception: their `plugin-name:skill-name` namespace means they never shadow other scopes.

### Migrating Legacy Commands

The `.claude/commands/` directory is the legacy format for custom slash commands. Legacy commands are plain markdown files (no frontmatter, no directory wrapper) that use `$PROMPT` for arguments instead of `$ARGUMENTS`.

To migrate a legacy command to a skill:

1. Create a skill directory: `.claude/skills/<name>/SKILL.md`
2. Add frontmatter with at least `name` and `description`
3. Replace `$PROMPT` references with `$ARGUMENTS`
4. Move any companion files into the skill directory

```
# Legacy format
.claude/commands/deploy.md        # Uses $PROMPT

# Skill format
.claude/skills/deploy/SKILL.md    # Uses $ARGUMENTS, has frontmatter
```

Legacy commands still work but receive lowest precedence and lack features like auto-invocation, model overrides, and subagent execution.

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

Skills can reference additional files in their directory using relative markdown links. Paths resolve relative to the skill directory (the folder containing `SKILL.md`):

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

Claude Code reads linked files on demand (progressive disclosure), so supporting files add no cost until actually referenced during execution. You can also use `${CLAUDE_SKILL_DIR}` in shell preprocessing to build absolute paths when needed:

```markdown
Load the schema: !`cat ${CLAUDE_SKILL_DIR}/schema.json`
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

This is a key difference from subagents spawned via the Agent tool, where `AskUserQuestion` is **not** available. If your workflow needs to gather user input at runtime, implement it as a skill rather than a custom agent.

For skills that run in a subagent (`context: fork`), `AskUserQuestion` is not available -- the skill runs in an isolated context that cannot prompt the user.

## Debugging Skills

### Verifying Discovery

Run `/skills` to list all skills Claude Code has loaded. Every registered skill appears with its source scope. If your skill is missing:

| Symptom | Likely cause |
| --- | --- |
| Skill not listed at all | Wrong directory structure -- ensure the file is `.claude/skills/<name>/SKILL.md`, not `.claude/skills/SKILL.md` |
| Skill listed but wrong name | `name` in frontmatter overrides directory name -- check frontmatter |
| Skill listed but not invocable via `/` | `user-invocable: false` is set in frontmatter |
| Skill from plugin missing | Plugin may be disabled -- check `/plugins` Installed tab |

### Testing a Skill

1. **Dry run**: Invoke the skill and verify Claude's interpretation before it takes action. Use plan mode (`/plan`) first if the skill has side effects.
2. **Check preprocessing**: If the skill uses `` !`command` `` syntax, run those commands manually to confirm they produce expected output.
3. **Inspect argument handling**: Invoke with test arguments and confirm `$ARGUMENTS` expands correctly. Check edge cases like empty arguments or arguments with spaces.

## Best Practices

1. **Keep skills focused**: One skill, one purpose. Don't create mega-skills that do everything.

2. **Use `disable-model-invocation: true`** for skills with side effects (commits, deploys, messages).

3. **Include examples**: Skills with examples in supporting files produce more consistent results.

4. **Use `context: fork`** for skills that produce verbose output (analysis, reports, test runs).

5. **Version control project skills**: Store in `.claude/skills/` so the team shares them.

6. **Use user-level skills** (`~/.claude/skills/`) for personal preferences that apply across all projects.

7. **Keep description accurate**: The description determines when Claude auto-invokes the skill. Be specific about the trigger conditions.

### Skill Performance and Token Efficiency

Skill instructions are injected into the context window, so bloated skills waste tokens and can crowd out useful conversation context. Keep them lean:

- **Avoid reading entire codebases** in skill instructions. Instead, instruct the skill to use Grep-then-Read patterns (search for what's needed, then read only relevant files).
- **Use supporting files** (`[reference.md](reference.md)`) instead of inlining large reference material. Supporting files load on demand via progressive disclosure.
- **Use `model: haiku`** for mechanical, low-judgment skills (formatting, simple transforms, boilerplate generation). This is faster and cheaper.
- **Use `allowed-tools`** to restrict tools to only what the skill needs. Fewer available tools means less overhead per turn.

Next: [Plugins](05c-plugins.md)

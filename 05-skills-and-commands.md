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
| `/fork [name]` | Create a fork of the current conversation at this point |

### Configuration and Setup

| Command | Purpose |
| --- | --- |
| `/config` | Open the settings interface |
| `/init` | Create a CLAUDE.md file for the project |
| `/memory` | Edit auto memory files |
| `/permissions` | View and update permission rules |
| `/model` | Change the active AI model |
| `/effort` | Set model effort level (low, medium, high, auto) |
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
| `/reload-plugins` | Activate pending plugin changes without restarting |
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
| `/copy` | Copy last response to clipboard. Shows a picker when code blocks are present |
| `/color` | Customize terminal color scheme |
| `/diff` | Interactive diff viewer for uncommitted changes and per-turn diffs |
| `/fast [on\|off]` | Toggle fast mode (same model, faster output) |
| `/review` | *Deprecated.* Install the `code-review` plugin instead: `claude plugin install code-review@claude-code-marketplace` |
| `/sandbox` | Manage sandbox configuration |
| `/tasks` | List and manage background tasks |
| `/voice` | Toggle voice mode (push-to-talk speech input, 20 languages) |
| `/add-dir <path>` | Add a working directory to the current session |
| `/vim` | Toggle vim editing mode |

### Bash Mode

Prefix your input with `!` to run a shell command directly without Claude interpreting it:

```
! npm test
! git status
! ls -la
```

The command runs immediately and its output is added to the conversation context. This is useful for quick shell operations while maintaining context. You can also press `Ctrl+B` to background a long-running `!` command.

### Bundled Skills

In addition to built-in commands, Claude Code ships with bundled skills that appear alongside built-in commands when you type `/`. These are pre-packaged skills rather than hardcoded commands, and you can create your own to extend the list.

| Bundled skill | Purpose |
| --- | --- |
| `/simplify` | Reviews recently changed files for code reuse, quality, and efficiency issues, then fixes them. Spawns three parallel review agents |
| `/batch <instruction>` | Orchestrates large-scale changes across a codebase in parallel, spawning one background agent per work unit in isolated worktrees |
| `/debug [description]` | Troubleshoots the current session by reading the debug log. Optionally describe the issue to focus analysis |
| `/loop [interval] <prompt>` | Runs a prompt repeatedly on an interval (default 10m). Useful for polling deploys, babysitting PRs, or re-running a skill on a schedule |
| `/claude-api` | Loads Claude API and Agent SDK reference material for your project's language. Also activates automatically when code imports `anthropic` or `@anthropic-ai/sdk` |

## What Are Skills?

Skills are reusable instruction packages that Claude Code can invoke. They are like custom slash commands with embedded knowledge:

- A skill can be a **workflow** (e.g., `/commit` that follows a specific commit process)
- A skill can be **domain knowledge** (e.g., coding conventions, API patterns)
- A skill can be a **tool** (e.g., a code review process with specific criteria)

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard, a portable format that works across many AI tools. Claude Code extends the standard with additional features like [invocation control](#invocation-modes), [subagent execution](#running-skills-in-subagents), and [dynamic context injection](#dynamic-context-with-shell-preprocessing). See [The Agent Skills Open Standard](#the-agent-skills-open-standard) at the end of this chapter for the cross-platform ecosystem.

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

This is a key difference from subagents spawned via the Agent tool, where `AskUserQuestion` is **not** available. If your workflow needs to gather user input at runtime, implement it as a skill rather than a custom agent.

For skills that run in a subagent (`context: fork`), `AskUserQuestion` is not available — the skill runs in an isolated context that cannot prompt the user.

## Best Practices

1. **Keep skills focused**: One skill, one purpose. Don't create mega-skills that do everything.

2. **Use `disable-model-invocation: true`** for skills with side effects (commits, deploys, messages).

3. **Include examples**: Skills with examples in supporting files produce more consistent results.

4. **Use `context: fork`** for skills that produce verbose output (analysis, reports, test runs).

5. **Version control project skills**: Store in `.claude/skills/` so the team shares them.

6. **Use user-level skills** (`~/.claude/skills/`) for personal preferences that apply across all projects.

7. **Keep description accurate**: The description determines when Claude auto-invokes the skill. Be specific about the trigger conditions.

## Plugins

Plugins are the distribution mechanism for Claude Code extensions. While skills, agents, hooks, and MCP servers can all exist as standalone configuration in your `.claude/` directory, a plugin packages them together as a versioned, namespaced, distributable unit.

| Approach | Skill names | Best for |
| --- | --- | --- |
| Standalone (`.claude/` directory) | `/hello` | Personal workflows, project-specific customizations, quick experiments |
| Plugins (with `.claude-plugin/plugin.json`) | `/plugin-name:hello` | Sharing with teammates, distributing to community, versioned releases, reusable across projects |

A single plugin can bundle any combination of:

- **Skills** — Slash commands and agent skills
- **Agents** — Custom subagents
- **Hooks** — Event handlers (PreToolUse, PostToolUse, Stop, etc.)
- **MCP servers** — External tool connections
- **LSP servers** — Code intelligence via the Language Server Protocol
- **Output styles** — Response formatting
- **Default settings** — Currently only the `agent` key

Plugins require Claude Code version 1.0.33 or later.

### Installing Plugins

Use the `/plugin` command inside Claude Code to open the plugin manager, a tabbed interface with four tabs:

| Tab | Purpose |
| --- | --- |
| Discover | Browse available plugins from all added marketplaces |
| Installed | View and manage installed plugins (enable, disable, uninstall) |
| Marketplaces | Add, remove, or update marketplace sources |
| Errors | View any plugin loading errors |

Cycle between tabs with `Tab` / `Shift+Tab`.

You can also install directly from the prompt or the CLI:

```bash
# From within Claude Code
/plugin install code-review@claude-plugins-official

# From the shell (non-interactive)
claude plugin install code-review@claude-plugins-official
```

The format is always `plugin-name@marketplace-name`.

### Managing Plugins

The full set of CLI commands:

| Command | Purpose |
| --- | --- |
| `claude plugin install <name>@<marketplace>` | Install a plugin |
| `claude plugin uninstall <name>@<marketplace>` | Remove a plugin (aliases: `remove`, `rm`) |
| `claude plugin enable <name>@<marketplace>` | Re-enable a disabled plugin |
| `claude plugin disable <name>@<marketplace>` | Disable without uninstalling |
| `claude plugin update <name>@<marketplace>` | Update to the latest version |
| `claude plugin validate .` | Validate a plugin or marketplace directory |

All commands accept `--scope <scope>` with values: `user` (default), `project`, `local`, or `managed` (update only).

Inside Claude Code, use `/reload-plugins` to activate pending plugin changes without restarting. If any LSP servers were added or updated, a full restart is required.

### Plugin Scoping

Plugins can be installed at different levels, just like settings:

| Scope | Settings file | Use case |
| --- | --- | --- |
| `user` (default) | `~/.claude/settings.json` | Personal plugins across all projects |
| `project` | `.claude/settings.json` | Team plugins shared via version control |
| `local` | `.claude/settings.local.json` | Project-specific plugins, gitignored |
| `managed` | Managed settings (read-only) | Organization-deployed plugins |

Installed plugins are tracked in the `enabledPlugins` key of the relevant settings file:

```json
{
  "enabledPlugins": {
    "formatter@acme-tools": true,
    "deployer@acme-tools": true,
    "analyzer@security-plugins": false
  }
}
```

Set a value to `false` to disable a plugin without uninstalling it.

### Namespacing

All plugin components are namespaced by the plugin's `name` field to prevent conflicts:

- Skills: `/plugin-name:skill-name` (e.g., `/commit-commands:commit`)
- Agents: `plugin-name:agent-name` (e.g., `plugin-dev:agent-creator`)
- MCP servers, hooks, and LSP servers integrate seamlessly but are scoped to the plugin

This means multiple plugins can define a skill called `review` without conflicting — each is invoked as `/plugin-a:review` and `/plugin-b:review`.

### Marketplaces

A marketplace is a catalog of plugins defined by a `.claude-plugin/marketplace.json` file.

**The official Anthropic marketplace** (`claude-plugins-official`) is automatically available when you start Claude Code. It includes LSP plugins for major languages (TypeScript, Python, Rust, Go, Java, and more), integrations with services like GitHub, Jira, Notion, Figma, Sentry, and Vercel, plus development workflow plugins and output styles.

To add third-party marketplaces:

```bash
# GitHub repository
/plugin marketplace add owner/repo

# Git URL
/plugin marketplace add https://gitlab.com/company/plugins.git

# Local path (for development)
/plugin marketplace add ./my-marketplace

# Remote URL
/plugin marketplace add https://example.com/marketplace.json
```

Other marketplace commands:

```bash
/plugin marketplace list                   # List all marketplaces
/plugin marketplace update marketplace-name  # Refresh catalog
/plugin marketplace remove marketplace-name  # Remove (also uninstalls its plugins)
```

The shorthand `/plugin market` also works.

**Auto-updates**: Official Anthropic marketplaces auto-update by default. Third-party marketplaces have auto-update disabled by default. Toggle per-marketplace via the `/plugin` Marketplaces tab.

### Creating Plugins

A plugin is a directory with this structure:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Manifest (optional but recommended)
├── skills/                  # Skills (SKILL.md in subdirectories)
│   └── code-review/
│       └── SKILL.md
├── agents/                  # Agent markdown files
├── hooks/
│   └── hooks.json           # Event handlers
├── scripts/                 # Hook and utility scripts
├── .mcp.json                # MCP server configurations
├── .lsp.json                # LSP server configurations
├── settings.json            # Default settings
└── README.md
```

Only `plugin.json` goes inside `.claude-plugin/`. All other directories must be at the plugin root.

The manifest (`.claude-plugin/plugin.json`) declares the plugin's metadata:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What this plugin does",
  "author": { "name": "Your Name" },
  "license": "MIT"
}
```

If the manifest is omitted, Claude Code auto-discovers components in default locations and derives the plugin name from the directory name. The manifest can also specify custom paths for components:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "skills": "./custom/skills/",
  "agents": "./custom/agents/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "lspServers": "./.lsp.json",
  "outputStyles": "./styles/"
}
```

Inside hook scripts and MCP configs, the environment variable `${CLAUDE_PLUGIN_ROOT}` resolves to the absolute path of the plugin directory.

To test a plugin during development, load it from a local directory:

```bash
claude --plugin-dir ./my-plugin
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

Validate your plugin structure with:

```bash
claude plugin validate .
```

### Publishing Plugins

There are two ways to distribute plugins:

1. **Your own marketplace**: Create a repository with a `.claude-plugin/marketplace.json` that lists your plugins. Users add it with `/plugin marketplace add owner/repo`.

2. **The official Anthropic marketplace**: Submit your plugin at `claude.ai/settings/plugins/submit` or `platform.claude.com/plugins/submit`.

A minimal `marketplace.json`:

```json
{
  "name": "company-tools",
  "owner": { "name": "DevTools Team" },
  "plugins": [
    {
      "name": "code-formatter",
      "source": "./plugins/formatter",
      "description": "Auto-formats code on save",
      "version": "2.1.0"
    }
  ]
}
```

Plugin sources in marketplace entries can be relative paths, GitHub repos, Git URLs, Git subdirectories (sparse clone for monorepos), npm packages, or pip packages.

### Organization Plugin Management

Organizations can control plugin usage through managed settings:

| Setting | Purpose |
| --- | --- |
| `enabledPlugins` | Auto-install and enable specific plugins |
| `extraKnownMarketplaces` | Pre-configure marketplaces for team members |
| `strictKnownMarketplaces` | Allowlist restricting which marketplaces users can add |
| `blockedMarketplaces` | Blocklist checked before downloading |
| `pluginTrustMessage` | Custom message appended to the trust warning before installation |

These are set in managed settings and cannot be overridden by individual users.

## The Agent Skills Open Standard

Claude Code skills are built on the **Agent Skills** open standard — a portable format for giving agents new capabilities. Anthropic developed the format for Claude Code, then released it as an open standard in December 2025, similar to how it open-sourced the Model Context Protocol (MCP).

### How the Standard Works

The standard defines a minimal, file-based format:

- A skill is a directory containing a `SKILL.md` file with YAML frontmatter (`name` and `description` required) and markdown instructions
- Skills can optionally include `scripts/`, `references/`, and `assets/` directories
- Agents use **progressive disclosure**: at startup only skill names and descriptions are loaded (~100 tokens each); full instructions load when activated; supporting files load only when referenced

This is the same format used by `.claude/skills/` in Claude Code. Any skill you write for Claude Code is already a valid Agent Skill.

### Cross-Platform Compatibility

The Agent Skills format is supported by a wide range of AI tools:

| Category | Tools |
| --- | --- |
| AI coding agents | Cursor, GitHub Copilot, OpenAI Codex, JetBrains Junie, Roo Code, Amp |
| CLI tools | Claude Code, Gemini CLI, Goose, OpenCode, Mistral Vibe |
| Frameworks | Spring AI, LangChain (via Letta) |
| Platforms | Databricks, Snowflake |

A skill written once can work across all compatible tools. Claude Code-specific frontmatter fields (like `context`, `agent`, `hooks`) are ignored by other tools but don't cause errors.

### The Standard vs. Claude Code Extensions

The open standard defines these frontmatter fields:

| Field | Required | Purpose |
| --- | --- | --- |
| `name` | Yes | Skill identifier (lowercase, hyphens, max 64 chars) |
| `description` | Yes | What the skill does and when to use it (max 1024 chars) |
| `license` | No | License name or reference to a bundled license file |
| `compatibility` | No | Environment requirements (e.g., "Requires git, docker") |
| `metadata` | No | Arbitrary key-value pairs (author, version, etc.) |
| `allowed-tools` | No | Pre-approved tools the skill may use |

Claude Code extends this with fields covered in [Frontmatter Options](#frontmatter-options): `argument-hint`, `disable-model-invocation`, `user-invocable`, `model`, `context`, `agent`, and `hooks`. It also adds [string substitutions](#string-substitutions) (`$ARGUMENTS`, `${CLAUDE_SKILL_DIR}`) and [shell preprocessing](#dynamic-context-with-shell-preprocessing) (`` !`command` ``), which are not part of the standard.

### Skills Directory and Partner Integrations

Anthropic maintains a [skills directory](https://claude.com/connectors) with partner-built skills from companies including Atlassian, Canva, Cloudflare, Figma, Notion, Ramp, Sentry, Stripe, and Zapier. These skills are available across Claude.ai, Claude Code, and the API at no additional cost on Pro, Max, Team, and Enterprise plans. You can browse and install skills from the ecosystem using the `/plugins` command.

Example skills and the full specification are available at:

- [agentskills.io](https://agentskills.io) — The open standard specification
- [github.com/anthropics/skills](https://github.com/anthropics/skills) — Example skills from Anthropic
- [github.com/agentskills/agentskills](https://github.com/agentskills/agentskills) — The standard's source repository

### Writing Portable Skills

To make skills that work across tools (not just Claude Code):

1. **Stick to standard fields**: Use only `name`, `description`, `license`, `compatibility`, `metadata`, and `allowed-tools` in frontmatter
2. **Keep instructions generic**: Avoid referencing Claude Code-specific tools by name where possible
3. **Validate with the reference library**: Use [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) to check format compliance

---

Next: [MCP (Model Context Protocol)](06-mcp.md) -- Connecting Claude Code to external tools and services.

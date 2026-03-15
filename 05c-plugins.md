---
title: "5c. Plugins"
parent: "5. Skills and Commands"
nav_order: 3
---

# Skills and Commands: Plugins

## Plugins

Plugins are the distribution mechanism for Claude Code extensions. While skills, agents, hooks, and MCP servers can all exist as standalone configuration in your `.claude/` directory, a plugin packages them together as a versioned, namespaced, distributable unit.

| Approach | Skill names | Best for |
| --- | --- | --- |
| Standalone (`.claude/` directory) | `/hello` | Personal workflows, project-specific customizations, quick experiments |
| Plugins (with `.claude-plugin/plugin.json`) | `/plugin-name:hello` | Sharing with teammates, distributing to community, versioned releases, reusable across projects |

A single plugin can bundle any combination of:

- **Skills** -- Slash commands and agent skills
- **Agents** -- Custom subagents
- **Hooks** -- Event handlers (PreToolUse, PostToolUse, Stop, etc.)
- **MCP servers** -- External tool connections
- **LSP servers** -- Code intelligence via the Language Server Protocol
- **Output styles** -- Response formatting
- **Default settings** -- Currently only the `agent` key

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

This means multiple plugins can define a skill called `review` without conflicting -- each is invoked as `/plugin-a:review` and `/plugin-b:review`.

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

Claude Code skills are built on the **Agent Skills** open standard -- a portable format for giving agents new capabilities. Anthropic developed the format for Claude Code, then released it as an open standard in December 2025, similar to how it open-sourced the Model Context Protocol (MCP).

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

Claude Code extends this with fields covered in [Frontmatter Options](05b-skills.md#frontmatter-options): `argument-hint`, `disable-model-invocation`, `user-invocable`, `model`, `context`, `agent`, and `hooks`. It also adds [string substitutions](05b-skills.md#string-substitutions) (`$ARGUMENTS`, `${CLAUDE_SKILL_DIR}`) and [shell preprocessing](05b-skills.md#dynamic-context-with-shell-preprocessing) (`` !`command` ``), which are not part of the standard.

### Skills Directory and Partner Integrations

Anthropic maintains a [skills directory](https://claude.com/connectors) with partner-built skills from companies including Atlassian, Canva, Cloudflare, Figma, Notion, Ramp, Sentry, Stripe, and Zapier. These skills are available across Claude.ai, Claude Code, and the API at no additional cost on Pro, Max, Team, and Enterprise plans. You can browse and install skills from the ecosystem using the `/plugins` command.

Example skills and the full specification are available at:

- [agentskills.io](https://agentskills.io) -- The open standard specification
- [github.com/anthropics/skills](https://github.com/anthropics/skills) -- Example skills from Anthropic
- [github.com/agentskills/agentskills](https://github.com/agentskills/agentskills) -- The standard's source repository

### Writing Portable Skills

To make skills that work across tools (not just Claude Code):

1. **Stick to standard fields**: Use only `name`, `description`, `license`, `compatibility`, `metadata`, and `allowed-tools` in frontmatter
2. **Keep instructions generic**: Avoid referencing Claude Code-specific tools by name where possible
3. **Validate with the reference library**: Use [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) to check format compliance

---

Next: [MCP (Model Context Protocol)](06-mcp.md) -- Connecting Claude Code to external tools and services.

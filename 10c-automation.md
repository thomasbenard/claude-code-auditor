---
title: "10c. Automation and Headless Mode"
parent: "10. Advanced Features"
nav_order: 3
---

# Advanced Features: Automation and Headless Mode

## Remote Control

Remote Control lets you continue a local Claude Code session from your phone, tablet, or any browser via [claude.ai/code](https://claude.ai/code) or the Claude mobile app. The session runs entirely on your machine -- the web/mobile interface is just a window into it.

### Starting a Remote Control Session

```bash
# Start a new remote-controlled session
claude remote-control

# With a custom name
claude remote-control --name "Auth Refactor"

# From an existing interactive session
/remote-control
```

The terminal displays a session URL and a QR code (press spacebar to toggle). Open the URL in a browser or scan the QR code from the Claude mobile app.

### How It Works

- Your local filesystem, MCP servers, tools, and project configuration remain available
- The conversation stays in sync across all connected devices -- send messages from terminal, browser, and phone interchangeably
- If your laptop sleeps or network drops, the session reconnects automatically when your machine comes back online
- All traffic goes through the Anthropic API over TLS; no inbound ports are opened on your machine

### Remote Control vs Claude Code on the Web

| | Remote Control | Claude Code on the Web |
| --- | --- | --- |
| **Where it runs** | Your local machine | Anthropic cloud infrastructure |
| **Local tools** | Full access to filesystem, MCP, project config | Cloud environment only |
| **Best for** | Continuing in-progress local work from another device | Starting tasks with no local setup, repos you don't have cloned |

### Enabling for All Sessions

By default, Remote Control only activates when you explicitly run the command. To enable it automatically for every session, run `/config` and set **Enable Remote Control for all sessions** to `true`.

### Related Commands

- `/desktop` (alias `/app`): Hand off the current session to the Claude Code Desktop app for visual diff review (macOS and Windows)
- `/mobile` (alias `/ios`, `/android`): Show QR code to download the Claude mobile app

## Scheduled Tasks

Claude Code can run prompts automatically on a schedule within a session. Tasks are session-scoped: they fire while the session is open and are gone when you exit.

### The /loop Skill

The quickest way to schedule a recurring prompt:

```
/loop 5m check if the deployment finished
/loop 20m /review-pr 1234
/loop check the build          # defaults to every 10 minutes
```

Supported intervals: `s` (seconds, rounded up to nearest minute), `m` (minutes), `h` (hours), `d` (days).

### One-Time Reminders

Describe what you want in natural language:

```
remind me at 3pm to push the release branch
in 45 minutes, check whether the integration tests passed
```

Claude schedules a single-fire cron task that deletes itself after running.

### Underlying Cron Tools

Under the hood, scheduled tasks use three tools:

| Tool | Purpose |
| --- | --- |
| `CronCreate` | Schedule a new task with a 5-field cron expression |
| `CronList` | List all scheduled tasks with IDs, schedules, and prompts |
| `CronDelete` | Cancel a task by ID |

A session can hold up to 50 tasks. Recurring tasks expire after 3 days. Disable scheduling entirely with `CLAUDE_CODE_DISABLE_CRON=1`.

### Persistent Scheduling

`/loop` and `CronCreate` are session-scoped -- they stop when you exit. For truly persistent recurring tasks, use your OS scheduler or CI/CD system with `claude --print`:

```bash
# Linux/macOS cron -- run a daily code quality check at 8am
0 8 * * * cd /path/to/project && claude -p "Run linter and tests, report issues" \
  --permission-mode bypassPermissions > /tmp/daily-check.log 2>&1

# Windows Task Scheduler (schtasks)
schtasks /create /tn "DailyCodeCheck" /tr "claude -p \"Run linter and tests\" --permission-mode bypassPermissions" /sc daily /st 08:00
```

Other options for durable scheduling:
- **Desktop app**: The [scheduled tasks feature](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-cowork) persists across sessions
- **GitHub Actions**: Use a `schedule` trigger with `claude -p` in the workflow
- **CI/CD pipelines**: Any system that can run shell commands on a schedule works with headless mode

See [Headless Mode](#headless-mode) for more on non-interactive usage.

## MCP (Model Context Protocol)

For comprehensive coverage of MCP -- including architecture, configuration, authentication, popular servers, building custom servers, debugging, and best practices -- see [Chapter 6: MCP](06-mcp.md).

## Headless Mode

Claude Code can run without interactive input, making it suitable for scripts, CI/CD pipelines, and automation.

### Basic Headless Usage

```bash
# Single prompt, get response on stdout
claude -p "explain the main function in src/index.ts"

# With JSON output
claude -p "list all TODO comments" --output-format json

# With a specific permission mode
claude -p "run all tests and report results" --permission-mode bypassPermissions

# Pipe input
echo "fix the typo in README.md" | claude -p
```

### CI/CD Integration

**GitHub Actions example:**

```yaml
name: Code Review
on: pull_request

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Claude Code
        run: curl -fsSL https://claude.ai/install.sh | bash
      - name: Review PR
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Review the changes in this PR. Run 'git diff origin/main'
          to see changes. Report any issues." --permission-mode bypassPermissions
```

### Scripting with Claude Code

```bash
#!/bin/bash
# Generate a changelog from recent commits
CHANGELOG=$(claude -p "Read the git log for the last 10 commits and
generate a human-readable changelog grouped by type (features, fixes, etc.)" \
  --permission-mode plan)

echo "$CHANGELOG" > CHANGELOG.md
```

## SDK / Programmatic Access

Beyond the CLI, Claude Code can be controlled programmatically via the `claude-code` npm package. This enables building custom tools, dashboards, and integrations on top of Claude Code's capabilities.

```typescript
import { claude } from "claude-code";

const result = await claude({
  prompt: "Find and fix all TypeScript errors in src/",
  workingDirectory: "/path/to/project",
  permissionMode: "bypassPermissions",
});

console.log(result.stdout);
```

The SDK exposes the same functionality as `claude -p` (see [Headless Mode](#headless-mode)) but as a native JavaScript/TypeScript API -- useful for orchestrating Claude Code from Node.js scripts, custom dev tools, or server-side automation.

---

Next: [Integrations](10d-integrations.md)

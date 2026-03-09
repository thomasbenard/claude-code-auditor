---
title: "10. Advanced Features"
nav_order: 10
---

# Chapter 10: Advanced Features

This chapter covers Claude Code's advanced capabilities: hooks for automation, worktrees for isolation, headless mode for CI/CD, IDE integrations, and more. For MCP (Model Context Protocol), see [Chapter 6](06-mcp.md).

## Hooks

Hooks are automated shell commands that execute at specific lifecycle events. They let you enforce standards, automate formatting, integrate with external tools, and customize Claude Code's behavior.

### Hook Events

| Event | When it fires | Matcher input | Use case |
| --- | --- | --- | --- |
| `SessionStart` | Session begins or resumes | `startup`, `resume`, `clear`, `compact` | Environment setup, notifications |
| `UserPromptSubmit` | Before Claude processes a prompt | (no matcher) | Input validation, logging |
| `InstructionsLoaded` | Instructions file is loaded | (no matcher) | Post-processing, dynamic injection |
| `PreToolUse` | Before a tool executes | Tool name | Block forbidden actions, validation |
| `PermissionRequest` | Permission dialog appears | Tool name | Auto-approve/deny based on rules |
| `PostToolUse` | After a tool succeeds | Tool name | Auto-format, lint, post-processing |
| `PostToolUseFailure` | After a tool fails | Tool name | Error logging, fallback actions |
| `Notification` | Claude needs attention | `permission_prompt`, `idle_prompt`, `auth_success`, `elicitation_dialog` | Desktop notifications |
| `SubagentStart` | Subagent spawns | Agent name | Tracking, logging |
| `SubagentStop` | Subagent finishes | Agent name | Tracking, logging |
| `Stop` | Claude finishes responding | (no matcher) | Post-response actions |
| `TeammateIdle` | Agent team teammate about to go idle | (no matcher) | Enforce quality gates before teammate stops |
| `TaskCompleted` | Task being marked completed | (no matcher) | Enforce completion criteria |
| `PreCompact` | Before context compaction | `manual`, `auto` | Save state before compaction |
| `ConfigChange` | Configuration file changes | Config type | React to config updates |
| `WorktreeCreate` | Worktree being created | (no matcher) | Custom VCS setup (replaces default git) |
| `WorktreeRemove` | Worktree being removed | (no matcher) | Custom VCS cleanup |
| `SessionEnd` | Session terminates | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` | Cleanup, logging |

### Hook Configuration

Hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "prettier --write \"$FILE\""
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/validate-bash.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt|idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code needs attention'"
          }
        ]
      }
    ]
  }
}
```

### Hook Handler Types

Each entry in the inner `hooks` array is a handler. There are four types:

| Type | Description |
| --- | --- |
| `command` | Runs a shell command. Receives JSON on stdin, returns results via exit codes and stdout |
| `http` | POSTs the event JSON to a URL and reads the response. See [HTTP Hooks](#http-hooks) below |
| `prompt` | Sends a prompt to a Claude model for single-turn evaluation. See [Prompt-Based Hooks](#prompt-based-hooks) |
| `agent` | Spawns a subagent with tool access to verify conditions. See [Agent-Based Hooks](#agent-based-hooks) |

**Common fields** (all types):

| Field | Description |
| --- | --- |
| `type` | `"command"`, `"http"`, `"prompt"`, or `"agent"` |
| `timeout` | Seconds before canceling (defaults: 600 command, 30 prompt, 60 agent) |
| `statusMessage` | Custom spinner message displayed while the hook runs |
| `once` | If `true`, runs only once per session then is removed (skills only) |

### Hook Input and Output

**Input**: Hooks receive JSON on stdin (for command hooks) or as the POST body (for HTTP hooks):

```json
{
  "session_id": "abc123",
  "cwd": "/project",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm test"
  },
  "agent_id": "agent-abc",
  "agent_type": "main",
  "worktree": {
    "name": "feature-auth",
    "path": "/project/.claude/worktrees/feature-auth",
    "branch": "feature-auth",
    "originalRepo": "/project"
  }
}
```

The `agent_id` and `agent_type` fields identify which agent triggered the hook. The `worktree` object is present when Claude Code is running inside a worktree. For `Stop` and `SubagentStop` events, a `last_assistant_message` field contains Claude's final response text.

**Output and exit codes**:
- **Exit 0**: Allow the action. Stdout is added to Claude's context.
- **Exit 2**: Block the action. Stderr is shown as feedback to Claude.
- **Other exit codes**: Allow the action. Stderr is logged silently.

### Hook for Permission Decisions

Hooks can output JSON to make permission decisions:

```json
{
  "hookSpecificOutput": {
    "permissionDecision": "allow",
    "permissionDecisionReason": "NPM test commands are always allowed"
  }
}
```

Valid decisions: `allow`, `deny`, `ask`.

### Practical Hook Examples

**Auto-format after edits:**
```bash
#!/bin/bash
# .claude/hooks/format-on-edit.sh
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
if [ -n "$FILE" ] && [ -f "$FILE" ]; then
  prettier --write "$FILE" 2>/dev/null
fi
exit 0
```

**Block edits to protected files:**
```bash
#!/bin/bash
# .claude/hooks/protect-files.sh
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(".env" ".git/" "node_modules/" "dist/")

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    echo "Blocked: cannot modify protected path containing '$pattern'" >&2
    exit 2
  fi
done
exit 0
```

**Run linter after writes:**
```bash
#!/bin/bash
INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE" == *.ts ]] || [[ "$FILE" == *.tsx ]]; then
  eslint --fix "$FILE" 2>/dev/null
fi
exit 0
```

### Referencing Scripts by Path

Use `$CLAUDE_PROJECT_DIR` to reference hook scripts relative to the project root, regardless of the working directory when the hook fires:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/check-style.sh"
          }
        ]
      }
    ]
  }
}
```

### Prompt-Based Hooks

In addition to command hooks (`type: "command"`), hooks can use an LLM to evaluate whether to allow or block an action.

Set `type` to `"prompt"` and provide a `prompt` string instead of a `command`. Use `$ARGUMENTS` as a placeholder for the hook's JSON input. Claude Code sends the combined prompt and input to a fast Claude model, which returns a JSON decision (`{"ok": true}` to allow, `{"ok": false, "reason": "..."}` to block).

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if Claude should stop: $ARGUMENTS. Check if all tasks are complete.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Prompt-based hooks are supported on: `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PostToolUseFailure`, `UserPromptSubmit`, `Stop`, `SubagentStop`, and `TaskCompleted`.

### Agent-Based Hooks

Agent hooks (`type: "agent"`) are like prompt-based hooks but with multi-turn tool access. Instead of a single LLM call, an agent hook spawns a subagent that can use Read, Grep, and Glob to verify conditions before returning a decision.

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify that all unit tests pass. Run the test suite and check the results. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

Agent hooks support the same events as prompt-based hooks.

### Async Hooks

By default, hooks block Claude's execution until they complete. For long-running tasks like test suites or deployments, set `"async": true` on a command hook to run it in the background while Claude continues working:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/run-tests.sh",
            "async": true,
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

Async hooks cannot block or return decisions -- the triggering action has already proceeded. When the background process finishes, any `systemMessage` or `additionalContext` in its JSON output is delivered to Claude on the next conversation turn. Only `type: "command"` hooks support `async`.

### HTTP Hooks

HTTP hooks (`type: "http"`) send the event JSON as a POST request to a URL instead of running a shell command. This is useful for centralized validation services, remote logging, or webhook-based workflows.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "http",
            "url": "http://localhost:8080/hooks/pre-tool-use",
            "timeout": 30,
            "headers": {
              "Authorization": "Bearer $MY_TOKEN"
            },
            "allowedEnvVars": ["MY_TOKEN"]
          }
        ]
      }
    ]
  }
}
```

**HTTP-specific fields:**

| Field | Description |
| --- | --- |
| `url` | URL to POST the event JSON to |
| `headers` | Additional HTTP headers. Values support `$VAR_NAME` interpolation for variables listed in `allowedEnvVars` |
| `allowedEnvVars` | Environment variable names that may be interpolated into header values. Unlisted variables resolve to empty strings |

The response body uses the same JSON format as command hooks. Non-2xx responses, connection failures, and timeouts produce non-blocking errors (the action proceeds). To block a tool call, return a 2xx response with a `permissionDecision: "deny"` in the JSON body.

## Worktrees

Git worktrees allow you to work on multiple branches simultaneously without switching. Claude Code integrates worktrees for isolated, parallel development.

### What Are Worktrees?

A worktree is a separate working directory linked to the same Git repository. Each worktree has its own branch, staged changes, and working files, but shares the same Git history.

### Creating Worktrees

```bash
# Start Claude Code in a new worktree
claude --worktree

# With a custom name (also becomes the branch name)
claude --worktree feature-auth

# Manually create and enter a worktree
git worktree add .claude/worktrees/feature-auth -b feature-auth
cd .claude/worktrees/feature-auth
claude
```

### Within a Session

Use the `EnterWorktree` tool or ask Claude:

```
Work on this feature in an isolated worktree so it doesn't affect main.
```

### Worktree Lifecycle

1. **Creation**: A new directory is created under `.claude/worktrees/` with a fresh branch from HEAD
2. **Working**: Claude Code's working directory switches to the worktree
3. **Cleanup**:
   - If no changes were made: worktree is auto-removed on session exit
   - If changes exist: Claude prompts you to keep or remove the worktree

### When to Use Worktrees

- **Parallel experiments**: Try multiple approaches without conflicting
- **Feature isolation**: Develop a feature without affecting the main branch
- **Subagent isolation**: Configure subagents with `isolation: worktree` for safe parallel writes
- **Risk-free exploration**: Make experimental changes you might discard

### Worktree Cleanup

```bash
# List all worktrees
git worktree list

# Remove a specific worktree
git worktree remove .claude/worktrees/feature-auth

# Prune stale worktree references
git worktree prune
```

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

For durable scheduling that survives restarts, use the [Desktop app's scheduled tasks](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-cowork) or GitHub Actions with a `schedule` trigger.

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
        run: npm install -g @anthropic-ai/claude-code
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

## IDE Integrations

### VS Code

The Claude Code VS Code extension provides a graphical interface:

**Key features:**
- Chat panel in the sidebar or as a tab
- Inline diff review for proposed changes
- @-mention files with line ranges (`@src/auth.ts#40-60`)
- Multiple conversations in tabs
- Plan mode with full markdown plan view and comment support
- Spark icon in the activity bar listing all Claude Code sessions
- Session management: rename and remove sessions from the sessions list
- Native MCP server management dialog via `/mcp`
- Compaction displayed as a collapsible "Compacted chat" card

**Shortcuts:**
| Shortcut | Action |
| --- | --- |
| `Ctrl+Shift+Esc` | Open in new tab |
| `Ctrl+N` | New conversation |
| `Alt+K` | Insert @-mention |
| `Ctrl+Esc` | Toggle focus |

### JetBrains IDEs

Available for IntelliJ, PyCharm, WebStorm, GoLand, RubyMine, and more via the JetBrains marketplace.

### Desktop App

Claude Code Desktop provides a native application interface for macOS and Windows.

## Browser Automation

Claude Code can interact with browsers via the Claude in Chrome extension and MCP:

- Navigate web pages
- Read page content (accessibility trees, screenshots)
- Fill forms and click elements
- Execute JavaScript in page context
- Record GIF demos
- Take screenshots for visual verification

### Preview System

For local development, Claude Code can preview your app:

1. Configure dev server in `.claude/launch.json`
2. Claude starts the server with `preview_start`
3. Takes screenshots and snapshots to verify changes
4. Inspects DOM elements for styling verification

## Extended Thinking

Extended thinking gives Claude an internal "scratchpad" for complex reasoning:

- Toggle with `Alt+T`
- Consumes additional tokens (viewable with `Ctrl+O` for verbose mode)
- Improves quality on complex debugging, architecture, and multi-step reasoning
- Not needed for simple tasks

Use extended thinking when:
- Debugging subtle issues with multiple possible causes
- Making architectural decisions
- Working through complex logic or algorithms
- Planning multi-step refactors

Skip it when:
- Making simple edits
- Running commands
- Quick file lookups

---

Next: [Troubleshooting and Optimization](11-troubleshooting.md) -- Solving common problems and maximizing efficiency.

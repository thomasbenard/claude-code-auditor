# Advanced Features: Hooks

Hooks are automated shell commands that execute at specific lifecycle events. They let you enforce standards, automate formatting, integrate with external tools, and customize Claude Code's behavior.

## Hook Events

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
| `Elicitation` | MCP server requests user input | (no matcher) | Intercept or auto-fill MCP elicitation dialogs |
| `ElicitationResult` | User responds to MCP elicitation | (no matcher) | Log or validate elicitation responses |
| `PreCompact` | Before context compaction | `manual`, `auto` | Save state before compaction |
| `PostCompact` | After context compaction completes | (no matcher) | Restore state, re-inject context |
| `ConfigChange` | Configuration file changes | Config type | React to config updates |
| `Setup` | Claude Code initialization | `init`, `init-only`, `maintenance` | Environment bootstrap, first-run configuration |
| `WorktreeCreate` | Worktree being created | (no matcher) | Custom VCS setup (replaces default git) |
| `WorktreeRemove` | Worktree being removed | (no matcher) | Custom VCS cleanup |
| `SessionEnd` | Session terminates | `clear`, `logout`, `prompt_input_exit`, `bypass_permissions_disabled`, `other` | Cleanup, logging |

## Hook Configuration

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

## Hook Handler Types

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

## Hook Input and Output

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

## Hook for Permission Decisions

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

## Practical Hook Examples

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

## Referencing Scripts by Path

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

## Prompt-Based Hooks

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

## Agent-Based Hooks

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

## Async Hooks

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

## HTTP Hooks

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

---

Next: [Agents and Worktrees](10b-agents-worktrees.md)

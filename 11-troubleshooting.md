---
title: "11. Troubleshooting and Optimization"
nav_order: 11
---

# Chapter 11: Troubleshooting and Optimization

This chapter covers how to diagnose common issues, optimize context usage, reduce costs, and get Claude Code working at peak efficiency.

## Context Management

### Symptoms of Context Pressure

- Claude starts forgetting earlier instructions or decisions
- Responses become less accurate or more generic
- Automatic compaction triggers frequently
- Claude re-reads files it already read earlier in the conversation

### Checking Context Usage

```
/context    → Visual grid showing what's consuming context
/cost       → Token usage and cost breakdown
```

### Reducing Context Usage

**1. Compact proactively**

Don't wait for automatic compaction. Run `/compact` with focus instructions before context gets full:

```
/compact focus on the payment processing refactor
```

This preserves the important context and discards the rest.

**2. Use subagents for exploration**

Research and exploration produce lots of output. Delegate it:

```
Use an Explore agent to find all files that handle payment processing
and summarize the architecture.
```

The subagent's verbose output stays in its own context; only the summary returns.

**3. Be selective with file reads**

Don't read entire files when you only need a section:

```
Read lines 40-80 of src/payment/processor.ts
```

**4. Reduce MCP server count**

Each MCP server adds tool definitions to your system prompt. Check the cost:

```
/mcp
```

Disable servers you're not actively using. See [Chapter 6](06-mcp.md) for MCP optimization strategies.

**5. Keep CLAUDE.md concise**

Every line of CLAUDE.md is loaded into every conversation. Remove anything that isn't critical. Use `@imports` for detailed documentation:

```markdown
# Instead of pasting 200 lines of API docs:
For API conventions, see @docs/api-guide.md
```

**6. Start new sessions for new tasks**

If you've finished one task and are starting a completely different one, a new session (`/clear` or exit and restart) is more efficient than continuing in a packed context.

### What Compaction Preserves

When context is compacted (manually or automatically):

- **Preserved**: Key decisions, current task state, important code references, CLAUDE.md instructions
- **Cleared**: Old tool outputs (file contents, command results), verbose explanations
- **Re-injected**: CLAUDE.md content, Compact Instructions section

Add a "Compact Instructions" section to CLAUDE.md for critical context that must survive compaction:

```markdown
## Compact Instructions
- Package manager: pnpm (not npm)
- Test framework: Vitest (not Jest)
- Current task: migrating from REST to GraphQL
- Branch: feature/graphql-migration
```

## Common Issues

### "Edit failed: old_string not found"

**Cause**: The `old_string` doesn't exactly match the file content.

**Solutions**:
1. Re-read the file to see the current content (it may have changed)
2. Check indentation (tabs vs spaces, extra whitespace)
3. Include more context in `old_string` to make it unique
4. Verify line endings haven't changed

### "Permission denied" for tool calls

**Cause**: Your permission mode or rules are blocking the action.

**Solutions**:
1. Check current mode: `Shift+Tab` to see and cycle modes
2. Check rules: `/permissions` to view allow/deny rules
3. For specific commands, add to allow list in settings:
   ```json
   "allow": ["Bash(npm test *)"]
   ```

### Claude keeps re-reading the same files

**Cause**: Context compaction cleared the file contents from memory.

**Solutions**:
1. Use `/compact` with focus instructions to preserve important context
2. Reference key file paths in CLAUDE.md so Claude knows where to look
3. For files that are constantly needed, consider extracting key information into CLAUDE.md

### Claude generates wrong API calls or non-existent functions

**Cause**: Hallucination (see [Chapter 2](02-core-ai-concepts.md)).

**Solutions**:
1. Ask Claude to read the actual source/docs before generating code
2. Provide the library version explicitly
3. Ask Claude to verify with `WebSearch` if unsure
4. Run type checks after generation: "Run tsc --noEmit to check for errors"

### Claude modifies files it shouldn't

**Cause**: No protection rules in place.

**Solutions**:
1. Add deny rules to settings:
   ```json
   "deny": ["Edit(.env*)", "Edit(prisma/migrations/**)"]
   ```
2. Use PreToolUse hooks to block edits to specific paths
3. Use plan mode for exploration when you're not ready for changes

### Session feels slow

**Cause**: Context is too full, model is doing too much per turn, or extended thinking is on.

**Solutions**:
1. Run `/compact` to free context space
2. Switch to a faster model with `/model` (Sonnet or Haiku for simpler tasks)
3. Disable extended thinking (`Alt+T`) for simple tasks
4. Break complex prompts into smaller steps
5. Check if unnecessary MCP servers are loaded

### Claude's changes break the build

**Solutions**:
1. Always ask Claude to run tests after changes
2. Set up a PostToolUse hook to run type checks after edits
3. Use plan mode to review changes before implementation
4. Add build/test commands to CLAUDE.md so Claude knows how to verify

## Performance Optimization

### Token Efficiency

**Prompt optimization:**
- Short, specific prompts waste fewer tokens than long, vague ones
- Use file references instead of pasting code
- State constraints upfront to prevent wasted work

**Tool usage optimization:**
- Use Glob/Grep to find files before reading them
- Read specific line ranges for large files
- Use `head_limit` on Grep to limit output
- Delegate verbose operations to subagents

**Model selection:**
- Use Haiku for exploration subagents
- Use Sonnet for most development tasks
- Reserve Opus for complex reasoning tasks

### Speed Optimization

1. **Parallel tool calls**: Claude can run multiple independent tools at once. Structure requests to enable this.

2. **Background tasks**: For long-running commands (builds, test suites), use `run_in_background`:
   ```
   Run the full test suite in the background while we continue working.
   ```

3. **Subagent parallelism**: Launch multiple subagents simultaneously for independent research tasks.

4. **Avoid unnecessary verification**: Don't ask Claude to re-read files it just wrote. Trust the Write/Edit tool succeeded unless there's a reason to verify.

### Cost Optimization

**Understanding costs:**
- Input tokens (what Claude reads): cheaper
- Output tokens (what Claude generates): more expensive
- Cached tokens (repeated content): discounted

**Strategies:**
1. **Keep CLAUDE.md stable**: Unchanging system prompt content gets cached
2. **Use Haiku for subagents**: Significantly cheaper for exploration and simple tasks
3. **Compact early**: Don't let context fill up with content you won't need again
4. **Be specific**: Vague prompts lead to more exploration (more tokens) before Claude finds the right approach
5. **Check costs**: `/cost` shows the running total for the session

## Debugging Claude Code Itself

### Health Check

```
/doctor
```

Checks installation, configuration, and connectivity.

### Debug Mode

```
/debug
```

Provides diagnostic information about the current session.

### Verbose Output

Toggle with `Ctrl+O` to see:
- Token counts for each tool call
- Extended thinking content
- Model-specific information
- Timing information

### Checking Configuration

```bash
# See all settings that apply
claude config list

# Check a specific setting
claude config get permissions

# See environment info
/status
```

## Troubleshooting Checklist

When something isn't working:

1. **Check the basics**:
   - Is Claude Code up to date? (`/status` or `claude --version`)
   - Is the API key valid? (`/doctor`)
   - Is the right model selected? (`/model`)

2. **Check configuration**:
   - Does CLAUDE.md have the right information?
   - Are permission rules blocking something?
   - Are hooks interfering? (check `.claude/settings.json`)

3. **Check context**:
   - Is context nearly full? (`/context`)
   - Was important context lost to compaction?
   - Are too many MCP servers consuming space? (See [Chapter 6](06-mcp.md))

4. **Try isolation**:
   - Start a new session to rule out context issues
   - Disable hooks temporarily to rule out interference
   - Try without MCP servers to rule out conflicts

5. **Get help**:
   - `/help` for built-in documentation
   - Report issues at https://github.com/anthropics/claude-code/issues

## Quick Reference: Optimization Commands

| Command/Action | Purpose |
| --- | --- |
| `/context` | View context utilization breakdown |
| `/compact [focus]` | Free context space with optional focus |
| `/cost` | View token usage and costs |
| `/model` | Switch to a faster/cheaper model |
| `Alt+T` | Toggle extended thinking |
| `Ctrl+O` | Toggle verbose output |
| `/mcp` | Check MCP server token costs |
| `/doctor` | Diagnose installation issues |
| `/debug` | Session diagnostics |

---

Back to [Index](index.md)

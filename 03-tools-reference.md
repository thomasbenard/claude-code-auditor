---
title: "3. Tools Reference"
nav_order: 3
---

# Chapter 3: Tools Reference

Tools are the primary way Claude Code interacts with your system. Every file read, code edit, command execution, and search is performed through a specific tool. Understanding the tools helps both humans and Claude Code make the right choices.

## Tool Selection Rules

These rules determine which tool to use. Following them avoids redundant work and wasted context.

| I need to... | Use this tool | NOT this |
| --- | --- | --- |
| Read a file | **Read** | `cat`, `head`, `tail` via Bash |
| Edit a file | **Edit** | `sed`, `awk` via Bash |
| Create a file | **Write** | `echo >`, `cat <<EOF` via Bash |
| Find files by name | **Glob** | `find`, `ls` via Bash |
| Search file contents | **Grep** | `grep`, `rg` via Bash |
| Run a shell command | **Bash** | N/A |
| Search the web | **WebSearch** | N/A |
| Fetch a URL | **WebFetch** | `curl` via Bash |

Using dedicated tools instead of Bash equivalents is important because:
- Tools provide structured output that Claude can process reliably
- Permission tracking works correctly
- The user sees clearer audit trails of what Claude did

---

## File Operations

### Read

**Purpose**: Read the contents of a file from disk.

**Parameters**:
- `file_path` (required): Absolute path to the file
- `offset` (optional): Line number to start reading from
- `limit` (optional): Number of lines to read
- `pages` (optional): Page range for PDFs (e.g., "1-5")

**Key behaviors**:
- Returns contents with line numbers (cat -n format)
- Lines longer than 2000 characters are truncated
- Reads up to 2000 lines by default
- Can read images (PNG, JPG, etc.) -- Claude sees them visually
- Can read PDFs (use `pages` for large PDFs, max 20 pages per request)
- Can read Jupyter notebooks (.ipynb), returning all cells with outputs

**Best practices**:
- Read a file before editing it -- Edit will fail if you haven't read the file first
- Use `offset` and `limit` for large files to conserve context
- Read multiple files in parallel when they're independent
- Prefer reading specific files over speculative exploration

**Example scenarios**:
```
Read file_path="/project/src/auth.ts"
Read file_path="/project/src/auth.ts" offset=40 limit=20   # Lines 40-59
Read file_path="/project/docs/spec.pdf" pages="1-3"
```

### Write

**Purpose**: Create a new file or completely overwrite an existing file.

**Parameters**:
- `file_path` (required): Absolute path to the file
- `content` (required): The complete file content

**Key behaviors**:
- Overwrites the entire file if it exists
- Requires Read first for existing files (will fail otherwise)
- Creates parent directories as needed

**Best practices**:
- Prefer Edit over Write for existing files (safer, smaller changes)
- Only create new files when genuinely necessary
- Don't create documentation files unless explicitly asked

### Edit

**Purpose**: Make targeted replacements in an existing file.

**Parameters**:
- `file_path` (required): Absolute path to the file
- `old_string` (required): The exact text to find and replace
- `new_string` (required): The replacement text
- `replace_all` (optional, default false): Replace all occurrences

**Key behaviors**:
- Performs exact string matching -- the `old_string` must appear exactly as-is in the file
- Fails if `old_string` is not unique in the file (unless `replace_all` is true)
- Fails if you haven't Read the file first in this conversation
- Preserves file encoding and line endings

**Best practices**:
- Include enough surrounding context in `old_string` to make it unique
- Match indentation exactly (tabs vs spaces)
- Use `replace_all` for renaming variables or updating repeated patterns
- For large changes, consider multiple Edit calls rather than one Write

**Common pitfalls**:
- Forgetting that `old_string` must be unique -- include more context lines
- Getting indentation wrong -- copy exactly from the Read output (after the line number prefix)
- Trying to edit without reading first

---

## Search Tools

### Glob

**Purpose**: Find files by name pattern (like `find` but faster and structured).

**Parameters**:
- `pattern` (required): Glob pattern (e.g., `**/*.ts`, `src/**/test_*.py`)
- `path` (optional): Directory to search in (defaults to working directory)

**Key behaviors**:
- Supports `**` for recursive directory matching
- Supports `*` for wildcard within a directory
- Supports `{a,b}` for alternatives
- Returns files sorted by modification time

**Best practices**:
- Use `**/*.ext` to find all files of a type recursively
- Use before Read to find the right file to examine
- Run multiple Glob calls in parallel for different patterns
- More efficient than Bash `find` for most file searches

**Common patterns**:
```
**/*.ts                    # All TypeScript files
src/**/*.test.js           # All test files under src/
**/package.json            # All package.json files
src/{components,hooks}/**  # Files in components or hooks
```

### Grep

**Purpose**: Search file contents using regular expressions (powered by ripgrep).

**Parameters**:
- `pattern` (required): Regex pattern to search for
- `path` (optional): File or directory to search in
- `output_mode` (optional): `files_with_matches` (default), `content`, or `count`
- `glob` (optional): Filter by file pattern (e.g., `*.ts`)
- `type` (optional): Filter by file type (e.g., `js`, `py`)
- `-i` (optional): Case-insensitive search
- `-A`, `-B`, `-C` (optional): Lines of context after/before/around matches
- `multiline` (optional): Match across line boundaries
- `head_limit` (optional): Limit number of results
- `offset` (optional): Skip first N results

**Key behaviors**:
- Uses ripgrep syntax (not grep) -- literal braces need escaping: `interface\{\}`
- `files_with_matches` mode returns only file paths (efficient for discovery)
- `content` mode returns matching lines with optional context
- `count` mode returns match counts per file

**Best practices**:
- Start with `files_with_matches` to find relevant files, then Read specific ones
- Use `glob` or `type` to narrow searches to relevant file types
- Use `head_limit` to avoid overwhelming output
- Use `-C` for context around matches when you need to understand usage
- For cross-line patterns (like multi-line function signatures), use `multiline: true`

**Example patterns**:
```
pattern="class UserService"                          # Find a class definition
pattern="async function \w+Auth"                     # Find async auth functions
pattern="TODO|FIXME|HACK"  -i=true                  # Find code annotations
pattern="import.*from ['\"](react|vue)"  type="ts"  # Framework imports
```

---

## Execution

### Bash

**Purpose**: Run shell commands in the system terminal.

**Parameters**:
- `command` (required): The shell command to execute
- `description` (optional but recommended): Human-readable description
- `timeout` (optional): Timeout in milliseconds (max 600,000 = 10 minutes)
- `run_in_background` (optional): Run asynchronously

**Key behaviors**:
- Working directory persists between calls; shell state does not
- Uses bash on all platforms (even Windows, via Git Bash or WSL)
- Output truncated at 30,000 characters
- Default timeout is 120,000ms (2 minutes)
- Paths with spaces must be quoted

**Best practices**:
- Always include a clear `description` for non-obvious commands
- Chain dependent commands with `&&`: `npm run build && npm test`
- Run independent commands in parallel using multiple Bash calls
- Use `run_in_background` for long-running processes (servers, builds)
- Quote paths containing spaces: `cd "/path with spaces/"`
- Prefer absolute paths over `cd` to maintain directory context
- Never use Bash when a dedicated tool exists (Read, Edit, Write, Glob, Grep)

**What NOT to do with Bash**:
- Don't use `cat` to read files (use Read)
- Don't use `find` to find files (use Glob)
- Don't use `grep`/`rg` to search content (use Grep)
- Don't use `sed`/`awk` to edit files (use Edit)
- Don't use `echo >` to create files (use Write)

### PowerShell (Windows)

**Purpose**: Run PowerShell commands on Windows (opt-in preview).

**Key behaviors**:
- Available on Windows only; opt in/out with `CLAUDE_CODE_USE_POWERSHELL_TOOL`
- Use for Windows-native operations that don't work well in Git Bash
- Same permission model as Bash

---

## Web Tools

### WebSearch

**Purpose**: Search the web for current information.

**Parameters**:
- `query` (required): Search query string
- `allowed_domains` (optional): Only include results from these domains
- `blocked_domains` (optional): Exclude results from these domains

**Best practices**:
- Use for looking up current library documentation
- Use for finding solutions to specific error messages
- Include the current year in queries for recent information
- Use `allowed_domains` to target specific documentation sites

### WebFetch

**Purpose**: Fetch a URL and process its content using AI.

**Parameters**:
- `url` (required): The URL to fetch (must be fully formed)
- `prompt` (required): What information to extract from the page

**Key behaviors**:
- Converts HTML to markdown automatically
- Processes content with a fast model using your prompt
- Results may be summarized for very large pages
- Includes a 15-minute cache for repeated access
- HTTP URLs automatically upgraded to HTTPS

**Best practices**:
- Use to read documentation pages, API references, and error explanations
- Provide a specific prompt about what information you need
- For GitHub, prefer `gh` CLI via Bash instead

---

## Orchestration Tools

### Task Tools (TaskCreate, TaskGet, TaskUpdate, TaskList, TaskOutput, TaskStop)

**Purpose**: Create and manage structured tasks for tracking progress and background work in the current session.

| Tool | Purpose | Key parameters |
| --- | --- | --- |
| **TaskCreate** | Create a new task | `description`, `prompt` |
| **TaskGet** | Get details of a specific task | `id` |
| **TaskUpdate** | Update a task's status | `id`, `status` (`pending`, `in_progress`, `completed`) |
| **TaskList** | List all tasks in the session | (none) |
| **TaskOutput** | Read output from a background task | `id` |
| **TaskStop** | Stop a running background task | `id` |

**Best practices**:
- Use for tasks with 3+ steps to track progress visually
- Mark tasks complete immediately after finishing (don't batch)
- Keep exactly one task as `in_progress` at any time
- Use `TaskOutput` to check results from background subagents
- Don't use for single, trivial tasks

### Monitor

**Purpose**: Stream events from a background process started with `Bash run_in_background`.

**Parameters**:
- `id` (required): ID of the background process to monitor

**Key behaviors**:
- Delivers each stdout line as a notification as it arrives
- Use for long-running scripts (builds, test suites, deployments) instead of polling with `Bash`
- Completes when the process exits

**Best practices**:
- Prefer Monitor over `sleep` + repeated Bash calls for process observation
- Use with `run_in_background` tasks, not foreground commands

### AskUserQuestion

**Purpose**: Ask the user for clarification, preferences, or decisions.

**Parameters**:
- `questions` (required): Array of 1-4 questions, each with options

**Best practices**:
- Use when requirements are ambiguous
- Provide 2-4 concrete options with clear descriptions
- Use `multiSelect: true` when choices aren't mutually exclusive
- Put the recommended option first with "(Recommended)" label

### Agent (Subagents)

**Purpose**: Launch specialized agents for complex, multi-step work. (This tool was previously called "Task" and was renamed to "Agent" in v2.1.63; the old name still works as an alias.)

Key parameters include `prompt`, `subagent_type`, `description`, `model` (override the model per-agent: `sonnet`, `opus`, `haiku`), `run_in_background`, and `isolation` (`"worktree"` for isolated git worktree).

This is covered extensively in [Chapter 4: Subagents](04-subagents.md).

### Skill

**Purpose**: Invoke a skill (slash command) within the current conversation.

**Parameters**:
- `skill` (required): The skill name (e.g., `"commit"`, `"review-pr"`, `"pdf"`)
- `args` (optional): Arguments to pass to the skill

**Key behaviors**:
- Only invokes skills listed in `<available-skills>` or system-reminder messages
- Does NOT handle built-in CLI commands (`/help`, `/clear`, etc.)
- Skills may be referenced by short name (`"commit"`) or fully qualified name (`"my-mcp:commit"`)
- Cannot invoke a skill that is already running
- If a `<command-name>` tag for the skill already exists in the current turn, the skill is already loaded -- follow its instructions directly instead of calling Skill again

**Best practices**:
- When a user types `/<something>`, check available skills before responding
- Pass user-provided arguments through `args` exactly as given
- Do not guess or fabricate skill names -- only use those listed as available

### EnterPlanMode

**Purpose**: Switch to plan mode for exploring and designing before implementing.

**When to use**:
- New feature implementation with multiple valid approaches
- Architectural decisions
- Multi-file changes
- Unclear requirements needing exploration

**When NOT to use**:
- Simple single-line fixes
- Tasks with specific, detailed instructions
- Pure research (use Explore subagent instead)

### ExitPlanMode

**Purpose**: Leave plan mode and return to normal mode where edits and commands are allowed.

**When to use**:
- After plan exploration is complete and you're ready to implement
- When switching from read-only investigation back to active development

### EnterWorktree

**Purpose**: Create an isolated git worktree, or switch to an existing one.

**Parameters**:
- `branch` (optional): Branch name for the worktree (auto-generated if omitted)
- `commit` (optional): Commit or ref to base the worktree on (defaults to HEAD)
- `path` (optional): Path to an existing worktree to switch into (skips creation)

**Key behaviors**:
- Creates a separate working directory with its own checked-out branch
- Changes in the worktree do not affect the main working directory
- The worktree shares the same git history and objects as the main repo
- All subsequent file operations (Read, Edit, Write, Bash) operate within the worktree

**When to use**:
- Working on features in isolation from the main branch
- Parallel Claude sessions that shouldn't conflict
- Experimental changes you might discard
- Testing a fix without disturbing in-progress work

### ExitWorktree

**Purpose**: Leave the current worktree and return to the original repository.

**Parameters**:
- `delete` (optional): Whether to delete the worktree directory on exit

**Key behaviors**:
- Restores the working directory to the original repository root
- If `delete` is true, removes the worktree directory (uncommitted changes are lost)
- If `delete` is false or omitted, the worktree remains on disk for later use

**When to use**:
- Work in the worktree is complete and changes have been committed
- Discarding experimental changes and returning to the main branch
- Switching back to the main repo after a subagent finishes worktree-isolated work

---

## Jupyter Notebook Tool

### NotebookEdit

**Purpose**: Edit cells in Jupyter notebooks (.ipynb files).

**Parameters**:
- `notebook_path` (required): Absolute path to the notebook
- `new_source` (required): New cell content
- `cell_id` (optional): ID of the cell to edit
- `cell_type` (optional): `code` or `markdown`
- `edit_mode` (optional): `replace` (default), `insert`, or `delete`

---

## Deferred Tool Loading

### ToolSearch

**Purpose**: Fetch full schema definitions for deferred tools so they can be called.

Some tools are "deferred" -- Claude Code knows their names but doesn't load their full schemas until needed. This keeps the system prompt lean. `ToolSearch` retrieves the complete schema on demand.

**Parameters**:
- `query` (required): Search query. Use `"select:ToolName"` for exact matches or keywords for fuzzy search
- `max_results` (optional, default 5): Maximum number of tools to return

**Key behaviors**:
- Returns full JSONSchema definitions that make the tool callable
- Supports exact selection (`"select:Read,Edit,Grep"`), keyword search (`"notebook jupyter"`), and name-filtered search (`"+slack send"`)
- Only needed for tools that appear in `<available-deferred-tools>` messages

**Best practices**:
- Use `select:` prefix when you know the exact tool name
- Fetch multiple tools at once with comma-separated names: `"select:CronCreate,CronList,CronDelete"`
- Not needed for tools already loaded in the session (Read, Write, Edit, Glob, Grep, Bash, Agent, Skill)

---

## MCP Tools

MCP (Model Context Protocol) servers can provide additional tools beyond the built-in ones documented in this chapter. These tools appear with an `mcp__<server>__<tool>` naming convention and are loaded on demand via `ToolSearch`. See [Chapter 6: MCP Integrations](06-mcp-integrations.md) for details on configuring MCP servers and working with their tools.

---

## Tool Chaining Patterns

Common patterns for combining tools effectively:

### Find-then-Read
```
1. Glob("**/auth*.ts")          -> Find relevant files
2. Read("src/auth/service.ts")  -> Read the right one
```

### Search-then-Edit
```
1. Grep("validateToken")        -> Find where function is used
2. Read("src/auth.ts")          -> Read the file
3. Edit("src/auth.ts", ...)     -> Make the change
```

### Edit-then-Verify
```
1. Edit("src/api.ts", ...)      -> Make the change
2. Bash("npm run typecheck")    -> Verify types
3. Bash("npm test")             -> Run tests
```

### Parallel Research
```
# These can all run in parallel:
1. Grep("UserService")          -> Find class usage
2. Glob("**/user*.test.*")      -> Find related tests
3. Read("src/types/user.ts")    -> Read type definitions
```

---

## Tool Error Handling

Common failure modes and how to recover from them:

| Tool | Failure | Cause | Recovery |
| --- | --- | --- | --- |
| **Edit** | `old_string` not found | Text doesn't match exactly (whitespace, encoding) | Re-read the file and copy the exact text, including indentation |
| **Edit** | `old_string` not unique | Multiple occurrences in the file | Add surrounding context lines to make it unique, or use `replace_all` |
| **Edit** | Not read yet | File hasn't been Read in this conversation | Read the file first, then retry |
| **Read** | Cannot read directory | Path points to a directory, not a file | Use `ls` via Bash for directories, or Glob to list files |
| **Read** | PDF too large | PDF exceeds page limit without `pages` parameter | Specify a page range (max 20 pages per request) |
| **Bash** | Command timed out | Exceeded the 2-minute default timeout | Set a longer `timeout` (up to 600,000ms) or use `run_in_background` |
| **Bash** | Output truncated | Output exceeded 30,000 characters | Redirect output to a file and Read it, or filter output with pipes |
| **Write** | Not read yet | Existing file hasn't been Read first | Read the file first, or use Edit for targeted changes |
| **Glob** | No results | Pattern too restrictive or wrong directory | Broaden the pattern, check the `path`, or try alternative naming conventions |
| **Grep** | No results | Pattern uses grep syntax instead of ripgrep | Escape literal braces (`\{\}`), check regex syntax against ripgrep docs |

**General principles**:
- When a tool fails, read the error message carefully -- it usually states the exact cause
- Prefer retrying with corrected parameters over switching to a Bash workaround
- For persistent Edit failures, re-read the file to get current contents (the file may have changed)
- Run independent tool calls in parallel to save time, but chain dependent calls sequentially

---

Next: [Subagents and Task Delegation](04-subagents.md) -- Delegating work to specialized agents.

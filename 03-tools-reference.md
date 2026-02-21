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

### TodoWrite

**Purpose**: Create and manage a structured task list for the current session.

**Parameters**:
- `todos` (required): Array of todo items, each with `content`, `status`, and `activeForm`

**Task states**:
- `pending`: Not yet started
- `in_progress`: Currently working on (limit to ONE at a time)
- `completed`: Task finished

**Best practices**:
- Use for tasks with 3+ steps
- Mark tasks complete immediately after finishing (don't batch)
- Keep exactly one task as `in_progress` at any time
- Provide both forms: `content` ("Run tests") and `activeForm` ("Running tests")
- Don't use for single, trivial tasks

### AskUserQuestion

**Purpose**: Ask the user for clarification, preferences, or decisions.

**Parameters**:
- `questions` (required): Array of 1-4 questions, each with options

**Best practices**:
- Use when requirements are ambiguous
- Provide 2-4 concrete options with clear descriptions
- Use `multiSelect: true` when choices aren't mutually exclusive
- Put the recommended option first with "(Recommended)" label

### Task (Subagents)

**Purpose**: Launch specialized agents for complex, multi-step work.

This is covered extensively in [Chapter 4: Subagents](04-subagents.md).

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

### EnterWorktree

**Purpose**: Create an isolated git worktree for parallel development.

**When to use**:
- Working on features in isolation from the main branch
- Parallel Claude sessions that shouldn't conflict
- Experimental changes you might discard

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

## Tool Chaining Patterns

Common patterns for combining tools effectively:

### Find-then-Read
```
1. Glob("**/auth*.ts")          → Find relevant files
2. Read("src/auth/service.ts")  → Read the right one
```

### Search-then-Edit
```
1. Grep("validateToken")        → Find where function is used
2. Read("src/auth.ts")          → Read the file
3. Edit("src/auth.ts", ...)     → Make the change
```

### Edit-then-Verify
```
1. Edit("src/api.ts", ...)      → Make the change
2. Bash("npm run typecheck")    → Verify types
3. Bash("npm test")             → Run tests
```

### Parallel Research
```
# These can all run in parallel:
1. Grep("UserService")          → Find class usage
2. Glob("**/user*.test.*")      → Find related tests
3. Read("src/types/user.ts")    → Read type definitions
```

---

Next: [Subagents and Task Delegation](04-subagents.md) -- Delegating work to specialized agents.

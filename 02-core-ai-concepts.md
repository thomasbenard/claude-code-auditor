---
title: "2. Core AI Concepts"
nav_order: 2
---

# Chapter 2: Core AI Concepts

Understanding how large language models work under the hood helps you use Claude Code more effectively and avoid common pitfalls. This chapter covers the key concepts that directly affect your experience.

## Tokens

### What Are Tokens?

Tokens are the fundamental units that language models process. They are not characters, not words, and not bytes -- they are **subword units** determined by a tokenizer.

A tokenizer splits text into pieces based on statistical patterns learned from training data. Common words usually become a single token, while rare words get split into multiple tokens.

**Examples** (approximate):

| Text | Approximate tokens | Count |
| --- | --- | --- |
| `hello` | `hello` | 1 |
| `Hello, world!` | `Hello`, `,`, ` world`, `!` | 4 |
| `authentication` | `authentic`, `ation` | 2 |
| `XMLHttpRequest` | `XML`, `Http`, `Request` | 3 |
| `const x = 42;` | `const`, ` x`, ` =`, ` 42`, `;` | 5 |

### Why Tokens Matter

1. **Cost**: You are billed per token (both input and output). More tokens = higher cost.
2. **Context window**: The context window is measured in tokens, not characters. A 200k token window is roughly 150k words or about 500 pages of text. Models with 1M context can hold roughly 5x that.
3. **Speed**: More tokens take longer to process. Output tokens are generated sequentially, so longer responses are slower.
4. **Code is token-heavy**: Code often uses more tokens per "meaningful unit" than prose because of syntax, indentation, and variable names.

### Token Efficiency Tips

- Be concise in your prompts. Verbose preambles waste tokens.
- Use file references (`@file.ts`) instead of pasting code into your prompt.
- When asking Claude to edit code, point to the specific file and function rather than describing the whole codebase.
- Use `/compact` to reclaim context space when conversations get long.

## Context Window

### What is the Context Window?

The context window is the total amount of text (measured in tokens) that Claude can "see" at any given moment. Think of it as Claude's working memory -- everything it needs to reference must fit inside this window.

Claude Code models have a context window of **200,000 tokens** by default, with support for up to **1,000,000 tokens** on models like Sonnet 4.6 and Opus 4.6 (on supported plans). The context window includes:

- The system prompt (Claude Code's instructions, your CLAUDE.md, memory, etc.)
- The entire conversation history (your messages and Claude's responses)
- Tool calls and their results (file contents, command output, search results)
- Any skills or MCP tool definitions loaded into the session

### How the Context Window Fills Up

```
┌──────────────────────────────────────────────┐
│  System prompt + CLAUDE.md + memory (~5-15%) │
│──────────────────────────────────────────────│
│  MCP tool definitions (varies, 0-20%)        │
│──────────────────────────────────────────────│
│  Conversation history                        │
│  ├─ Your messages                            │
│  ├─ Claude's responses                       │
│  ├─ Tool calls + results (often the largest) │
│  └─ Grows with each turn                     │
│──────────────────────────────────────────────│
│  Current turn reasoning + output             │
│──────────────────────────────────────────────│
│  [Remaining space]                           │
└──────────────────────────────────────────────┘
```

The biggest consumers are typically:
1. **File contents** from Read tool calls
2. **Command output** from Bash tool calls
3. **Search results** from Grep/Glob
4. **Conversation history** accumulating over many turns

### What Happens When the Context is Full?

Claude Code automatically manages context through **compaction**:

1. When context usage reaches ~95%, automatic compaction triggers
2. Older tool outputs (file reads, command results) are cleared first
3. The conversation is summarized, preserving key context
4. CLAUDE.md instructions are re-injected to maintain project knowledge
5. The session continues seamlessly

You can also trigger compaction manually with `/compact` and provide focus instructions (e.g., `/compact focus on the authentication refactor`).

### Viewing Context Usage

- `/context` -- Shows a visual grid of context utilization
- `/cost` -- Shows token usage and costs for the session

## Context Utilization

Context utilization is the art of making the most of your limited context window. Poor utilization means Claude runs out of working memory faster, leading to more compactions and potential loss of nuance.

### Strategies for Efficient Context Use

**For humans:**

1. **Be specific in your prompts**: "Fix the null check in `src/auth.ts:42`" is better than "there's a bug somewhere in the auth code"
2. **Use @-mentions**: `@src/auth.ts` loads the file efficiently with proper tracking
3. **Break large tasks into sessions**: Don't try to refactor an entire codebase in one conversation
4. **Use `/compact` proactively**: Before starting a new phase of work, compact with focus instructions
5. **Leverage subagents**: Delegate research and exploration to subagents so verbose output doesn't fill the main context

**For Claude Code:**

1. **Use Glob/Grep before Read**: Search for the right file first rather than reading speculatively
2. **Read specific line ranges**: Use the `offset` and `limit` parameters for large files
3. **Delegate exploration to subagents**: Use the Explore agent for codebase research
4. **Avoid redundant reads**: Don't re-read files already in context unless compaction has occurred
5. **Keep responses concise**: Verbose explanations consume output tokens that fill context

### Context Costs by Feature

| Feature | Typical cost | Optimization |
| --- | --- | --- |
| MCP server definitions | 1-5k tokens per server | Disable unused servers |
| CLAUDE.md | 500-3k tokens | Keep concise, use imports for details |
| Loaded skills | 200-500 tokens each | Only load what's needed |
| File read (medium file) | 1-5k tokens | Read specific ranges |
| Bash output | 500-10k tokens | Pipe through head/tail in commands |
| Conversation history | Grows continuously | Use `/compact` |
| Auto memory (MEMORY.md) | Up to ~2k tokens (200 lines) | Keep focused |

### Attention and Recency Bias

Language models weight recent context more heavily than earlier context. Instructions or details near the end of the conversation have more influence on the next response than those from many turns ago. This is why prompt ordering matters: put your most important constraints last. It also explains why `/compact` can improve quality mid-session -- by summarizing stale history into a fresh, focused prompt, it moves key context back into the high-attention zone.

## Prompt Caching

When the same prefix of tokens appears in repeated API calls, the provider can reuse a cached version instead of reprocessing it from scratch. This is **prompt caching**, and it has two practical effects:

1. **Lower cost** -- cached input tokens are significantly cheaper (typically 90% less)
2. **Lower latency** -- the cached prefix is processed faster

In Claude Code, caching happens automatically. The system prompt, your CLAUDE.md files, and tool definitions form a stable prefix that stays the same across turns, so they get cached after the first turn. This is why a well-organized CLAUDE.md is essentially free after the first request in a conversation -- you pay full price once, then cache prices for the rest of the session.

You don't need to do anything to enable prompt caching. Just know that the beginning of the prompt is what gets cached, so stable content (system prompt, CLAUDE.md) belongs at the top and volatile content (conversation turns) belongs at the bottom -- which is exactly how Claude Code already structures things.

## Hallucinations

### What Are Hallucinations?

A hallucination occurs when Claude generates information that sounds plausible but is factually incorrect. In the context of coding, this can manifest as:

- **Invented APIs**: Suggesting methods or functions that don't exist in a library
- **Wrong signatures**: Using incorrect parameter names, types, or return values
- **Fabricated files**: Referring to files or paths that don't exist in the project
- **Incorrect version info**: Suggesting syntax from a different version of a framework
- **Confident but wrong logic**: Producing code that looks correct but has subtle bugs

### Why Hallucinations Happen

Language models generate text by predicting the most likely next token based on patterns in training data. They don't "know" facts -- they have statistical associations. When the model encounters a situation where:

- The training data was sparse or contradictory
- The question requires precise recall of specific details
- Multiple similar-but-different APIs exist (e.g., different ORMs, different versions)

...it may generate a plausible-sounding but incorrect response.

### How Claude Code Mitigates Hallucinations

Claude Code has structural advantages over plain chat:

1. **Tool grounding**: Claude can Read files, run commands, and verify its assumptions rather than relying on memory alone
2. **Error feedback**: When code doesn't compile or tests fail, Claude sees the errors and can self-correct
3. **File system access**: Claude can check what files, functions, and APIs actually exist
4. **Web search**: Claude can look up documentation for unfamiliar libraries

### How to Reduce Hallucinations

**For humans:**

1. **Ask Claude to verify**: "Check the actual API before using it" or "read the docs first"
2. **Provide context**: Share relevant documentation, types, or examples
3. **Review generated code**: Especially for unfamiliar libraries or APIs
4. **Run tests**: Let Claude verify its own work by running the test suite
5. **Be skeptical of confidence**: Claude may sound certain even when wrong

**For Claude Code:**

1. **Read before writing**: Always read the file/function before editing
2. **Check imports and types**: Verify that referenced modules and types exist
3. **Run verification commands**: After writing code, run tests or type checks
4. **Use WebSearch for unfamiliar libraries**: Look up current API documentation
5. **State uncertainty**: When unsure about an API, say so rather than guessing

## Knowledge Cutoff

Claude's training data has a cutoff date. After that date, the model has no built-in awareness of new library releases, API changes, framework updates, or world events. In practice this means:

- Claude may suggest deprecated APIs or miss newly added features
- Version-specific syntax (e.g., a React hook added in v19) may be unknown
- Recently created packages or tools won't exist in the model's memory

Claude Code mitigates this structurally. By reading your actual project files (`package.json`, lock files, source code), Claude grounds itself in what your project actually uses rather than relying on training data. When that isn't enough, `WebSearch` and `WebFetch` can pull current documentation. The best practice is to tell Claude to check docs when working with rapidly evolving libraries.

## Temperature and Determinism

### What is Temperature?

Temperature controls the randomness of the model's output. Claude Code uses a **low temperature** for code generation, which means:

- Outputs are more deterministic and consistent
- The model favors high-probability tokens (more conventional code)
- Less creative variation between runs

You don't control temperature directly in Claude Code, but understanding it helps explain why:

- The same prompt may produce slightly different results on re-run
- Claude tends to write conventional, idiomatic code
- Explicitly asking for creative alternatives can help when you want unconventional solutions

## Models and Capabilities

### Model Differences That Matter in Practice

| Aspect | Opus 4.6 | Sonnet 4.6 | Haiku 4.5 |
| --- | --- | --- | --- |
| **Complex reasoning** | Strongest | Strong | Adequate |
| **Large codebase navigation** | Best | Good | Good for targeted searches |
| **Subtle bug detection** | Best | Good | May miss nuance |
| **Speed** | Slowest | Fast | Fastest |
| **Cost per token** | Highest | Medium | Lowest |
| **Best for** | Architecture, complex refactors | General development | Quick lookups, simple edits |

### When to Switch Models

- **Start with Sonnet** for most tasks -- it's the best balance
- **Switch to Opus** when you need deeper reasoning (complex bugs, architecture decisions, large refactors spanning many files)
- **Use Haiku for subagents** doing exploration or simple tasks (set via `model: haiku` in agent definitions)

## Extended Thinking

Claude can be configured to use "extended thinking" -- an internal reasoning step before responding. This:

- Improves quality on complex problems
- Consumes additional tokens (visible in verbose mode with `Ctrl+O`)
- Can be toggled with `Alt+T`

Use extended thinking for complex debugging, architectural decisions, or multi-step reasoning. Disable it for simple tasks to save tokens.

### Effort Levels

Effort levels control how much reasoning Claude applies before responding. There are three levels:

| Level | Symbol | When to use |
| --- | --- | --- |
| **Low** | `○` | Quick lookups, simple edits |
| **Medium** | `◐` | General development (default for Opus 4.6 on Max/Team) |
| **High** | `●` | Complex debugging, architecture, multi-step reasoning |

Change the effort level during a session with `/effort` or set it per-turn by including the keyword **`ultrathink`** in your prompt (triggers high effort for that turn only). Use `/effort auto` to reset to the default.

## Tool Use

Claude doesn't just generate text -- it can take actions. When Claude decides it needs to read a file, run a command, or search the codebase, it follows a structured loop:

1. **Decide**: Based on the current prompt, Claude determines that a tool would help (e.g., "I need to read the file before editing it")
2. **Call**: Claude emits a structured tool request specifying the tool name and parameters (e.g., `Read` with `file_path: "src/auth.ts"`)
3. **Execute**: Claude Code executes the tool and returns the result to Claude as a new message
4. **Continue**: Claude incorporates the result into its reasoning and either responds or makes another tool call

This loop can repeat multiple times in a single turn -- Claude might search for a file, read it, edit it, then run tests, all before giving you a final response. Each tool call and its result consume context tokens, which is why efficient tool use matters (see [Chapter 3](03-tools-reference.md) for the full tool reference).

The key insight: Claude doesn't have a hidden ability to see your filesystem or run commands. Every action goes through an explicit tool call that you can see and approve. This is why Claude Code asks for permission before running commands or writing files.

## System Prompt

The system prompt is a set of instructions injected at the start of every conversation. In Claude Code, the system prompt includes:

- Claude Code's core operating instructions
- Your CLAUDE.md file(s) contents
- Auto memory (MEMORY.md)
- Available tool definitions
- MCP server tool definitions
- Loaded skill descriptions
- Environment information (OS, shell, working directory)

Understanding that all of this occupies context space helps you make informed decisions about what to include in your CLAUDE.md and which MCP servers to enable.

---

Next: [Tools Reference](03-tools-reference.md) -- The complete guide to every tool Claude Code uses.

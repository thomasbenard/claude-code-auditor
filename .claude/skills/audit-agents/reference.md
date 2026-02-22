# Audit Reference: Agent Efficiency Patterns

Use these examples when making recommendations.

## Model Selection Guide

| Agent type | Recommended `model` | Why |
|---|---|---|
| Test runner | `haiku` | Runs commands, reads output, formats report |
| Linter / formatter | `haiku` | Mechanical execution and reporting |
| Code search / explorer | `haiku` | Equivalent to built-in Explore agent |
| Code reviewer | `sonnet` | Needs reasoning but not frontier-level |
| Migration helper | `sonnet` | Schema understanding, moderate complexity |
| Refactoring agent | Omit (inherit) | Deep reasoning about architecture |
| Implementation agent | Omit (inherit) | Complex multi-step code generation |

### Example: Downgrading model

Before (wasteful):
```yaml
---
name: test-runner
description: Runs tests and reports results
tools: Bash, Read, Grep, Glob
---
```

After (efficient):
```yaml
---
name: test-runner
description: Runs tests and reports results with failure analysis
tools: Bash, Read, Grep, Glob
model: haiku
maxTurns: 15
background: true
---
```

Savings: ~90% cost reduction (Haiku vs Opus) plus background execution frees the main conversation.

## Tool Restriction Guide

| Agent purpose | Recommended `tools` |
|---|---|
| Read-only analysis / review | `Read, Glob, Grep` |
| Command execution + reporting | `Bash, Read, Glob, Grep` |
| Code generation / editing | `Read, Write, Edit, Glob, Grep` |
| Full implementation | `Read, Write, Edit, Bash, Glob, Grep` |

Avoid granting all tools when the agent only needs a subset. Each tool description in the system prompt costs tokens on every turn.

## maxTurns Guide

| Agent complexity | Recommended `maxTurns` |
|---|---|
| Single command + report | 5-10 |
| Search and summarize | 10-15 |
| Multi-step analysis | 15-25 |
| Implementation with testing | 25-40 |
| Complex multi-file work | 40-50 |

Setting `maxTurns` prevents runaway agents from consuming unlimited tokens. The default of 50 is rarely needed.

## Background and Isolation

### When to use `background: true`

- Test suites (output is long, results consumed later)
- Build processes
- Long-running analysis that doesn't need immediate interaction

### When to use `isolation: worktree`

- Agents that modify files which could conflict with the user's current work
- Experimental changes that might need to be discarded
- Parallel implementation agents working on different features

## Auto-Delegation Descriptions

### Too broad (wastes tokens on false positives)

```yaml
description: Helps with testing
```

### Precise (triggers only when appropriate)

```yaml
description: Runs the project's test suite and analyzes failures with suggested fixes
```

## Built-in Agent Overlap

Before creating a custom agent, check if a built-in type already covers the need:

| Built-in | Capabilities | Don't duplicate with custom agent |
|---|---|---|
| Explore | Fast codebase search (Glob, Grep, Read) with Haiku | Custom "search" or "find" agents |
| Plan | Read-only research with inherited model | Custom "analyze" or "investigate" agents |
| Bash | Command execution in isolation | Custom "run-command" agents |
| general-purpose | All tools, full capability | Custom agents that just wrap general-purpose with no specialization |

Custom agents add value when they encode **domain-specific knowledge** (project conventions, workflow steps, validation rules) that built-in agents don't have.

## Output Format

### Summary Table

| # | Agent | Token Efficiency | Quality | Issues Found |
|---|-------|-----------------|---------|--------------|
| 1 | `agent-name` | PASS/IMPROVE/PROBLEM | PASS/IMPROVE/PROBLEM | Brief note |
| 2 | ... | ... | ... | ... |

### Token Savings Opportunities

List every concrete change that would reduce token usage, ordered by estimated impact (highest first). For each:

1. **What to change** (specific file, specific frontmatter key or instruction line)
2. **Estimated savings** (e.g., "~500 tokens/turn by restricting tools", "~90% cost by setting model: haiku")
3. **How to implement** (exact change to make)

### Quality Issues

List any correctness, clarity, or structural problems. For each:

1. **What's wrong**
2. **Why it matters**
3. **How to fix it**

### Recommendations

Top 3 highest-impact improvements across all agents.

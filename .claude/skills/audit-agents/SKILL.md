---
name: audit-agents
description: Audits Claude Code custom agents in a project for quality, efficiency, and token savings
argument-hint: "<path to project root>"
disable-model-invocation: true
context: fork
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

Audit the Claude Code custom agents at the project root: $ARGUMENTS

Read-only audit -- do NOT modify any files. For best-practice reference, see: [reference.md](reference.md)

---

## Step 1: Discover All Agents

Search for agents in:

1. `.claude/agents/*/agent.md` or `.claude/agents/*/AGENT.md`
2. `~/.claude/agents/*/` (user-level -- just note if any found)

If no agents exist, report that as the primary finding. Assess whether the project's complexity warrants custom agents based on its tech stack and structure (detect from package.json, Cargo.toml, pyproject.toml, go.mod, etc.). Then skip to the Output section.

---

## Step 2: Audit Each Agent

For every agent found, report each check as:
- **PASS**: follows best practice
- **IMPROVE**: works but could be better (explain how)
- **PROBLEM**: incorrect or wasteful (explain the fix)

### 2A. Frontmatter Correctness

- [ ] Has `name` (required, lowercase with hyphens)
- [ ] Has `description` (required -- this controls auto-delegation)
- [ ] No unknown or misspelled frontmatter keys
- [ ] Valid values for all fields (e.g., `model` is one of haiku/sonnet/opus)

### 2B. Token Efficiency

**Model selection**:
- [ ] Mechanical agents (test runners, linters, formatters, search) should use `model: haiku`
- [ ] Moderate-reasoning agents (code review, analysis, report generation) should use `model: sonnet`
- [ ] Only agents requiring deep reasoning (architecture, complex refactoring) should inherit Opus

**Tool restriction**:
- [ ] `tools` should list only what the agent needs. Every unused tool adds its description to the system prompt
- [ ] Read-only agents should not have Write/Edit/Bash
- [ ] `disallowedTools` can be used as a deny-list alternative -- check it's not redundant with `tools`

**maxTurns**:
- [ ] Should be set to a reasonable bound. Default is 50 which is generous
- [ ] Simple agents (run command + report) should use 10-20
- [ ] Complex agents (multi-file implementation) can justify 30-50
- [ ] Unbounded agents risk runaway token usage

**Prompt conciseness**:
- [ ] Instructions should be direct, not padded with filler or restating what Claude knows
- [ ] Estimate token count of the agent body -- flag anything over ~500 tokens for review
- [ ] Check for redundant instructions

**Auto-delegation control**:
- [ ] `description` should be specific about when to delegate to this agent
- [ ] Overly broad descriptions (e.g., "helps with code") cause false-positive delegation, wasting tokens loading the agent unnecessarily

### 2C. Quality and Correctness

**Instruction clarity**:
- [ ] Instructions are unambiguous and actionable
- [ ] Steps are in logical order
- [ ] The agent's purpose is clear from instructions alone (agents don't inherit parent context)

**Scope and responsibility**:
- [ ] Agent does one thing well (not a mega-agent)
- [ ] If complex, consider splitting into focused agents
- [ ] Agent's responsibility doesn't overlap heavily with a built-in agent type (Explore, Plan, Bash, general-purpose)

**Configuration coherence**:
- [ ] `tools` match the agent's purpose (e.g., a reviewer doesn't need Write)
- [ ] `model` matches the task complexity
- [ ] `background: true` is set for long-running agents (test suites, builds) that don't need interactive results
- [ ] `isolation: worktree` is set for agents that modify files and could conflict with main work
- [ ] `skills` and `mcpServers` are specified if the agent needs them
- [ ] `permissionMode` is set appropriately if the agent runs sensitive commands

### 2D. Structural Hygiene

- [ ] Agent lives in `.claude/agents/<name>/agent.md` (or `AGENT.md`)
- [ ] Directory name matches the `name` frontmatter field
- [ ] No orphaned files in the agent directory that nothing references
- [ ] Supporting files (if any) are referenced from the agent instructions

---

## Step 3: Cross-Agent Analysis

Look at the agent collection as a whole:

- **Gaps**: Would the project benefit from agents it doesn't have? Common useful agents: test-runner, code-reviewer, migration-helper, search/explore specialist
- **Overlap**: Do any agents overlap with each other or with built-in agent types?
- **Consistency**: Do agents follow a consistent style and naming convention?
- **Built-in coverage**: Are any custom agents redundant with built-in types (Explore, Plan, Bash)?

---

## Output Format

Format your output per the template in [reference.md](reference.md).

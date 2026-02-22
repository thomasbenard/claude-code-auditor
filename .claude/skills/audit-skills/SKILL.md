---
name: audit-skills
description: Audits Claude Code skills in a project for quality, efficiency, and token savings
argument-hint: "<path to project root>"
disable-model-invocation: true
context: fork
allowed-tools: Read, Glob, Grep, Bash
---

Audit the Claude Code skills at the project root: $ARGUMENTS

You are a Claude Code skill auditor. Examine every skill in the target project and produce a structured report evaluating quality, correctness, and opportunities to save time and tokens. You MUST NOT modify any files -- this is a read-only audit.

For best-practice reference, see: [reference.md](reference.md)

---

## Step 1: Discover All Skills

Search for skills in both current and legacy locations:

1. `.claude/skills/*/SKILL.md` (current format)
2. `.claude/commands/*.md` (legacy format)
3. `~/.claude/skills/*/SKILL.md` (user-level -- note these exist but just mention if any found)

If no skills exist at all, report that as the primary finding and suggest starter skills based on the project's tech stack (detect from package.json, Cargo.toml, pyproject.toml, go.mod, etc.). Then skip to the Output section.

---

## Step 2: Audit Each Skill

For every skill found, evaluate all of the following categories. Report each as:
- **PASS**: follows best practice
- **IMPROVE**: works but could be better (explain how)
- **PROBLEM**: incorrect or wasteful (explain the fix)

### 2A. Frontmatter Correctness

- [ ] Has a `name` field (required)
- [ ] Has a `description` field (required for auto-invocable skills; check accuracy)
- [ ] `argument-hint` present when the skill accepts arguments
- [ ] No unknown or misspelled frontmatter keys

### 2B. Token Efficiency

These are the highest-value checks. Every token saved here compounds across every invocation.

**Model selection**:
- [ ] Skills doing simple/mechanical work (linting reports, running commands, searching) should set `model: haiku` or `model: sonnet` instead of defaulting to Opus
- [ ] Only skills requiring deep reasoning should omit `model` (inheriting the parent's model)

**Tool restriction**:
- [ ] `allowed-tools` should be set to the minimum needed. A read-only audit skill that can also Write and Edit wastes tokens on tool descriptions it never uses
- [ ] Check whether any skill grants tools it never needs

**Subagent isolation** (`context: fork`):
- [ ] Skills that produce verbose output (reports, analysis, test results) should use `context: fork` to keep the main context clean
- [ ] Skills that need back-and-forth with the user should NOT use `context: fork`

**Prompt conciseness**:
- [ ] Instructions should be direct and action-oriented, not padded with filler
- [ ] Avoid restating things Claude already knows (e.g., "you are an AI assistant")
- [ ] Check for redundant or duplicated instructions within the skill
- [ ] Estimate the token count of the SKILL.md body -- flag anything over ~800 tokens as worth reviewing for trim opportunities

**Shell preprocessing** (`` !`command` ``):
- [ ] Any shell preprocessing commands should have bounded output (e.g., `git log -5` not `git log`)
- [ ] Avoid commands that dump large payloads into the prompt (e.g., `cat` on a large file)

**Auto-invocation control**:
- [ ] Skills with side effects (writes, commits, deploys, sends) MUST have `disable-model-invocation: true`
- [ ] Skills with overly broad descriptions risk false-positive auto-triggering, which wastes tokens. Descriptions should be specific about when to trigger

### 2C. Quality and Correctness

**Instruction clarity**:
- [ ] Instructions are unambiguous -- could another developer read them and know exactly what the skill does?
- [ ] Steps are in logical order
- [ ] Expected output format is specified (if the skill produces a report)

**Argument handling**:
- [ ] `$ARGUMENTS` is used if the skill accepts input
- [ ] Behavior when no arguments are provided is defined (or `argument-hint` makes the expectation clear)

**Supporting files**:
- [ ] Any `[link](file.md)` references point to files that actually exist
- [ ] Supporting files contain useful reference material, not just placeholders

**Scope**:
- [ ] Skill does one thing well (not a mega-skill trying to do everything)
- [ ] If the skill is complex, consider whether it should be split into focused sub-skills

### 2D. Structural Hygiene

- [ ] Skill lives in `.claude/skills/<name>/SKILL.md` (not loose in `.claude/skills/`)
- [ ] Legacy `.claude/commands/` skills should be flagged for migration to the new format
- [ ] Skill directory name matches the `name` frontmatter field
- [ ] No orphaned supporting files (files in the skill directory that nothing references)

---

## Step 3: Cross-Skill Analysis

Look at the skill collection as a whole:

- **Gaps**: Are there common workflows the project would benefit from that have no skill? (commit, review, test, deploy, migrate)
- **Overlap**: Do any two skills overlap significantly? Could they be merged?
- **Consistency**: Do skills follow a consistent style (formatting, tone, structure)?
- **Organization**: For projects with many skills, are they well-organized?

---

## Output Format

### Summary Table

| # | Skill | Token Efficiency | Quality | Issues Found |
|---|-------|-----------------|---------|--------------|
| 1 | `skill-name` | PASS/IMPROVE/PROBLEM | PASS/IMPROVE/PROBLEM | Brief note |
| 2 | ... | ... | ... | ... |

### Token Savings Opportunities

List every concrete change that would reduce token usage, ordered by estimated impact (highest first). For each:

1. **What to change** (specific file, specific frontmatter key or instruction line)
2. **Estimated savings** (e.g., "~500 tokens per invocation by adding `allowed-tools`", "avoids Opus costs by setting `model: sonnet`")
3. **How to implement** (exact change to make)

### Quality Issues

List any correctness, clarity, or structural problems. For each:

1. **What's wrong** (be specific)
2. **Why it matters**
3. **How to fix it**

### Recommendations

List the top 3 highest-impact improvements across all skills, considering both token savings and quality. For each, explain the change and its benefit.

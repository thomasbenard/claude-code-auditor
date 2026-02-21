---
name: audit-claude-setup
description: Audits a project's Claude Code configuration and suggests improvements based on best practices
argument-hint: "<path to project root>"
disable-model-invocation: true
context: fork
allowed-tools: Read, Glob, Grep, Bash
---

Audit the Claude Code setup at the project root: $ARGUMENTS

You are a Claude Code setup auditor. Examine the target project and produce a structured report evaluating how well it uses Claude Code. You MUST NOT modify any files -- this is a read-only audit.

For example configurations and templates, see: [reference.md](reference.md)

For each check below, report one of:
- **PASS**: the item exists and follows best practices
- **PARTIAL**: the item exists but could be improved (explain how)
- **MISSING**: the item does not exist (explain what to add and why)

---

## 1. CLAUDE.md Quality
Reference: [Chapter 6](06-memory-and-configuration.md), [Chapter 7](07-project-setup.md)

Read `CLAUDE.md` and/or `.claude/CLAUDE.md` at the project root. Evaluate whether it includes:
- [ ] Project overview (what the project does)
- [ ] Tech stack (language, framework, database, testing, package manager)
- [ ] Quick commands (build, test, lint, type-check, dev server)
- [ ] Project structure (key directories and their purpose)
- [ ] Code conventions (naming, patterns, imports, error handling)
- [ ] Important rules / prohibitions (things Claude must never do)
- [ ] Compact Instructions section (critical context that survives compaction)

If no CLAUDE.md exists at all, flag this as the highest-priority finding.

## 2. Modular Rules
Reference: [Chapter 6](06-memory-and-configuration.md)

Check if `.claude/rules/` exists. If it does:
- List the rule files found
- Check whether any use path-scoped frontmatter (a `paths:` field in YAML frontmatter)
- Evaluate whether the project would benefit from path-scoped rules (e.g., separate frontend/backend/database rules for projects with distinct domains)

## 3. Skills
Reference: [Chapter 5](05-skills-and-commands.md)

Check if `.claude/skills/` exists (also check the legacy `.claude/commands/`). If it does:
- List the skills found and their names/descriptions
- Check if commonly useful skills exist (commit, review, deploy, test)

If none exist, suggest starter skills appropriate for the project's tech stack (detected from package.json, Cargo.toml, pyproject.toml, go.mod, etc.).

## 4. Custom Agents
Reference: [Chapter 4](04-subagents.md)

Check if `.claude/agents/` exists. If it does, list the agents found and their descriptions. If not, note whether the project's complexity would benefit from custom agents (e.g., a test-runner agent, a code-review agent).

## 5. Settings and Permissions
Reference: [Chapter 6](06-memory-and-configuration.md)

Check if `.claude/settings.json` exists. If it does, evaluate:
- Are there permission `allow` rules for common project commands (build, test, lint)?
- Are there permission `deny` rules to protect sensitive files (.env, secrets, credentials)?
- Is a `defaultMode` set?

If no settings file exists, suggest appropriate permission rules based on the project's tooling.

## 6. MCP Configuration
Reference: [Chapter 9](09-advanced-features.md)

Check if `.mcp.json` exists at the project root. If it does, list the configured servers. If not, consider whether the project would benefit from common MCP servers:
- GitHub (if the project is a git repo)
- Database server (if the project uses a database)
- Other services relevant to the detected tech stack

## 7. Dev Server Preview
Reference: [Chapter 9](09-advanced-features.md)

Check if `.claude/launch.json` exists. If the project has a dev server (look for `dev` or `start` scripts in `package.json`, or equivalent in other ecosystems), flag a missing `launch.json` as a gap.

## 8. Git Hygiene
Reference: [Chapter 7](07-project-setup.md)

Read `.gitignore` and check whether it excludes:
- [ ] `CLAUDE.local.md`
- [ ] `.claude/settings.local.json`

If `.gitignore` does not exist or is missing these entries, flag it.

## 9. Hooks
Reference: [Chapter 9](09-advanced-features.md)

Check if `.claude/settings.json` contains a `hooks` configuration. If it does, list the hook events and matchers. If not, suggest hooks based on the project's tooling:
- PostToolUse hook for auto-formatting after Edit/Write (if the project uses prettier, black, gofmt, rustfmt, etc.)
- PreToolUse hook for protecting sensitive files (.env, credentials, migrations)
- Notification hook for desktop alerts when Claude needs attention

---

## Output Format

After completing all checks, produce your report in this structure:

### Summary Table

| # | Check | Status | Priority |
|---|-------|--------|----------|
| 1 | CLAUDE.md quality | PASS/PARTIAL/MISSING | High/Medium/Low |
| 2 | Modular rules | ... | ... |
| 3 | Skills | ... | ... |
| 4 | Custom agents | ... | ... |
| 5 | Settings & permissions | ... | ... |
| 6 | MCP configuration | ... | ... |
| 7 | Dev server preview | ... | ... |
| 8 | Git hygiene | ... | ... |
| 9 | Hooks | ... | ... |

### Top 3 Recommendations

List the three highest-impact improvements in priority order. For each, provide:
1. What to create or change (be specific with file paths and content)
2. Why it matters
3. Which chapter in this guide has the full details

### Detailed Findings

Provide the full per-check evaluation as assessed above.

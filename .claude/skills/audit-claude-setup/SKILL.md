---
name: audit-claude-setup
description: Audits a project's Claude Code configuration and suggests improvements based on best practices
argument-hint: "<path to project root>"
disable-model-invocation: true
context: fork
allowed-tools: Read, Glob, Grep, Bash
model: sonnet
---

Audit the Claude Code setup at the project root: $ARGUMENTS

Read-only audit -- do NOT modify any files. For example configurations, see: [reference.md](reference.md)

For each check, report **PASS**, **PARTIAL** (exists but improvable), or **MISSING** (doesn't exist).

---

## 1. CLAUDE.md Quality (Ch 7-8)

Read `CLAUDE.md` and/or `.claude/CLAUDE.md`. Check for:
- [ ] Project overview
- [ ] Tech stack
- [ ] Quick commands (build, test, lint, type-check)
- [ ] Project structure
- [ ] Code conventions
- [ ] Important rules / prohibitions
- [ ] Compact Instructions section

No CLAUDE.md at all = highest-priority finding.

## 2. Modular Rules (Ch 7)

Check `.claude/rules/` -- list files, check for path-scoped frontmatter (`paths:` field), evaluate whether path-scoped rules would benefit the project.

## 3. Skills (Ch 5)

Check `.claude/skills/` and legacy `.claude/commands/`. List skills found, check for common ones (commit, review, deploy, test). If none exist, suggest starters based on detected tech stack.

## 4. Custom Agents (Ch 4)

Check `.claude/agents/` -- list agents or note if the project's complexity warrants them.

## 5. Settings and Permissions (Ch 7)

Check `.claude/settings.json` for permission `allow` rules (build, test, lint), `deny` rules (.env, secrets), and `defaultMode`. If missing, suggest rules based on project tooling.

## 6. MCP Configuration (Ch 6)

Check `.mcp.json` -- list servers or note if the project would benefit from MCP servers based on its tech stack.

## 7. Dev Server Preview (Ch 10)

Check `.claude/launch.json`. Flag as gap if the project has a dev server but no launch config.

## 8. Git Hygiene (Ch 8)

Check `.gitignore` for `CLAUDE.local.md` and `.claude/settings.local.json`.

## 9. Hooks (Ch 10)

Check `.claude/settings.json` for `hooks`. If missing, suggest auto-format (PostToolUse), file protection (PreToolUse), and notification hooks based on project tooling.

---

Format your output per the template in [reference.md](reference.md).

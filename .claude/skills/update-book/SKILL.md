---
name: update-book
description: Updates the Claude Code reference guide with new, changed, or obsolete information
argument-hint: "<topic, feature, or 'full-review'>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, Bash
model: sonnet
---

Update the Claude Code reference guide based on: $ARGUMENTS

For book structure and conventions, see: [reference.md](reference.md)

---

## Step 1: Scope the Update

Determine what needs updating based on the argument:

- **Specific topic** (e.g., "hooks", "skills", "MCP"): Focus on chapters covering that topic
- **Specific feature** (e.g., "launch.json", "worktrees"): Find all mentions across chapters
- **`full-review`**: Scan every chapter for outdated content (this is thorough but slow)

Read `index.md` to identify which chapters are relevant. Then read those chapters fully.

## Step 2: Research Current State

Use WebSearch and WebFetch to check official sources for the latest information:

1. Search for recent Claude Code documentation, changelogs, and release notes
2. Fetch the official docs at `https://docs.anthropic.com/en/docs/claude-code` for current behavior
3. Compare what the book says against what the official sources say

For each discrepancy, note:
- **What the book says** (file, section, line)
- **What the current behavior is** (with source)
- **Type**: `outdated` (was true, no longer), `missing` (new feature not covered), `inaccurate` (was never quite right)

## Step 3: Plan Changes

Before editing, present a summary of all planned changes grouped by chapter:

```
## Planned Changes

### <chapter-file.md>
- [outdated] Section "X": change Y to Z (source: ...)
- [missing] Add new section on feature W after section "X"

### <other-chapter.md>
- ...
```

Wait for user approval before proceeding. If running in a non-interactive context, proceed with changes.

## Step 4: Apply Updates

For each planned change:

1. **Update existing content** -- Edit in place, preserving the chapter's style and structure
2. **Remove obsolete content** -- Delete cleanly, updating any surrounding transitions
3. **Add new content** -- Place in the most logical location within the chapter, matching the existing heading hierarchy and depth of coverage
4. **Update cross-references** -- If a section is renamed, moved, or removed, update all links across all chapters and `index.md`

## Step 5: Verify Consistency

After all edits:

1. Check that all inter-chapter links still resolve (search for `](` patterns and verify targets exist)
2. Verify the `index.md` chapter list and quick reference table are still accurate
3. Confirm no orphaned references to removed sections
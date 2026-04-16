---
name: update-book
description: Updates the Claude Code reference guide with new, changed, or obsolete information
argument-hint: "<topic, feature, or 'full-review'>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, Bash
---

Update Claude Code reference guide based on: $ARGUMENTS

Book structure and conventions: [reference.md](reference.md)

---

## Step 1: Scope Update

Argument types:
- **Specific topic** (e.g., "hooks", "skills", "MCP"): target chapters covering that topic
- **Specific feature** (e.g., "launch.json", "worktrees"): find all mentions across chapters
- **`full-review`**: scan every chapter for outdated content — thorough but slow

### Token-efficient reading strategy

**Do NOT read entire chapters.** Guide ~200KB / ~5000 lines. Reading all wastes tokens. Use targeted reads:

1. **Find candidate chapters** — consult [reference.md](reference.md) § "Topic-to-Chapter Map". For `full-review`, all chapters are candidates.

2. **Extract section map** — for each candidate, Grep headings to get TOC with line numbers:
   ```
   Grep pattern="^##" path="<chapter>.md" output_mode="content"
   ```

3. **Find relevant sections** — Grep topic keywords across candidates:
   ```
   Grep pattern="<keyword>" path="<chapter>.md" output_mode="content" -n=true -C=2
   ```

4. **Read only those sections** — use heading line numbers to find section bounds, read just relevant ranges:
   ```
   Read file_path="<chapter>.md" offset=<section_start> limit=<section_length>
   ```

5. **For `full-review`** — chapter by chapter. Read only section map (headings), compare against Step 2 research. Read sections only if potentially outdated or covering changed features.

## Step 2: Research Current State

Check official sources for latest info:

1. Search recent Claude Code docs, changelogs, release notes
2. Fetch official docs at `https://docs.anthropic.com/en/docs/claude-code`
3. Compare book content against official sources

See [reference.md](reference.md) § "Official Sources to Check" for canonical URLs.

If sources ambiguous or conflicting, flag item as uncertain in change plan and let user decide.

For each discrepancy, note:
- **Book says** (file, section, line)
- **Current behavior** (with source)
- **Type**: `outdated` (was true, no longer), `missing` (new feature uncovered), `inaccurate` (never quite right)

## Step 2b: Scan Stale Content

After researching, grep for claims gone stale:

```
Grep pattern="(v[0-9]+\.[0-9]|202[0-9]-|deprecated|removed|no longer|not yet|coming soon|currently not)" output_mode="content" -n=true
```

Also grep names that change often:
- Model names and IDs (e.g., `claude-3`, `claude-sonnet-4`)
- Version numbers and release references
- Feature flags and experimental features (`CLAUDE_CODE_EXPERIMENTAL`)
- CLI flag names and syntax

Cross-check each match against Step 2 research. Read surrounding section (offset/limit) only if match looks outdated. Flag confirmed stale as `[outdated]` in change plan.

## Step 3: Plan Changes

Before editing, present summary of all planned changes grouped by chapter:

```
## Planned Changes

### <chapter-file.md>
- [outdated] Section "X": change Y to Z (source: ...)
- [missing] Add new section on feature W after section "X"

### <other-chapter.md>
- ...
```

Wait for user approval. If non-interactive context, proceed.

## Step 4: Apply Updates

For each planned change:

1. **Update existing content** — edit in place, preserve chapter style and structure
2. **Remove obsolete content** — delete cleanly, update surrounding transitions
3. **Add new content** — place in most logical location, match existing heading hierarchy
4. **Update cross-references** — if section renamed, moved, or removed, update all links across chapters and `index.md`

### Keep content concise

Actively reduce token count when editing:

- Prefer tables and code examples over prose — more per token
- Remove filler phrases, redundant explanations, obvious statements
- Don't expand one-line mention into paragraph unless topic warrants it
- When adding content, check if existing content on same topic can be trimmed or consolidated
- Net-zero or net-negative line count is ideal

## Step 5: Log Changes

After updates, append summary entry to `13-changelog.md`. Insert directly above `---` / `Back to [Index]` footer:

```markdown
## YYYY-MM-DD

- **<chapter-file.md>**: Brief summary of what changed (e.g., "Updated hooks section to reflect new `pre-tool` event")
- **<other-chapter.md>**: Brief summary
```

One sentence per bullet — high level, not every line edited. Group all changes from single `/update-book` run under one date heading. If entry for today exists, append bullets instead of creating duplicate heading.

## Step 6: Verify Consistency

After all edits:

1. Check all inter-chapter links still resolve (search `](` patterns, verify targets exist)
2. Verify `index.md` chapter list and quick reference table still accurate
3. Confirm no orphaned references to removed sections

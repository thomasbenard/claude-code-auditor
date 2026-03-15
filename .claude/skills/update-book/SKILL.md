---
name: update-book
description: Updates the Claude Code reference guide with new, changed, or obsolete information
argument-hint: "<topic, feature, or 'full-review'>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, WebSearch, WebFetch, Bash
---

Update the Claude Code reference guide based on: $ARGUMENTS

For book structure and conventions, see: [reference.md](reference.md)

---

## Step 1: Scope the Update

Determine what needs updating based on the argument:

- **Specific topic** (e.g., "hooks", "skills", "MCP"): Focus on chapters covering that topic
- **Specific feature** (e.g., "launch.json", "worktrees"): Find all mentions across chapters
- **`full-review`**: Scan every chapter for outdated content (this is thorough but slow)

### Token-efficient reading strategy

**Do NOT read entire chapter files.** The guide is ~200KB / ~5000 lines. Reading it all wastes tens of thousands of tokens. Instead, use targeted reads:

1. **Identify candidate chapters** — Consult [reference.md](reference.md) § "Topic-to-Chapter Map" to find primary and cross-referenced chapters for the topic. For `full-review`, all chapters are candidates.

2. **Extract section map** — For each candidate chapter, Grep for heading patterns to get a table of contents with line numbers:
   ```
   Grep pattern="^##" path="<chapter>.md" output_mode="content"
   ```

3. **Find relevant sections** — Grep for topic keywords across candidate chapters to find which sections mention the topic:
   ```
   Grep pattern="<keyword>" path="<chapter>.md" output_mode="content" -n=true -C=2
   ```

4. **Read only those sections** — Use the heading line numbers from step 2 to determine section boundaries, then read just the relevant ranges:
   ```
   Read file_path="<chapter>.md" offset=<section_start> limit=<section_length>
   ```

5. **For `full-review`** — Work chapter by chapter. For each chapter, read only the section map (headings), then compare headings against your research findings from Step 2. Only read sections that look potentially outdated or that cover features known to have changed.

## Step 2: Research Current State

Use WebSearch and WebFetch to check official sources for the latest information:

1. Search for recent Claude Code documentation, changelogs, and release notes
2. Fetch the official docs at `https://docs.anthropic.com/en/docs/claude-code` for current behavior
3. Compare what the book says against what the official sources say

See [reference.md](reference.md) § "Official Sources to Check" for canonical URLs.

If official sources are ambiguous or conflicting, flag the item as uncertain in the change plan and let the user decide.

For each discrepancy, note:
- **What the book says** (file, section, line)
- **What the current behavior is** (with source)
- **Type**: `outdated` (was true, no longer), `missing` (new feature not covered), `inaccurate` (was never quite right)

## Step 2b: Scan for Stale Content

After researching current state, scan the book for claims that may have gone stale. Run targeted Greps across all chapter files:

```
Grep pattern="(v[0-9]+\.[0-9]|202[0-9]-|deprecated|removed|no longer|not yet|coming soon|currently not)" output_mode="content" -n=true
```

Also grep for specific names that change often:
- Model names and IDs (e.g., `claude-3`, `claude-sonnet-4`)
- Version numbers and release references
- Feature flags and experimental features (`CLAUDE_CODE_EXPERIMENTAL`)
- CLI flag names and syntax

For each match, cross-check against your Step 2 research findings. Only read the surrounding section (via offset/limit) if the match looks outdated. Flag confirmed stale content as `[outdated]` in the change plan.

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

### Keep content concise

When editing, actively look for opportunities to **reduce** token count:

- Prefer tables and code examples over prose — they convey more per token
- Remove filler phrases, redundant explanations, and obvious statements
- Don't expand a one-line mention into a paragraph unless the topic truly warrants it
- If adding new content, check whether existing content on the same topic can be trimmed or consolidated
- A net-zero or net-negative line count change is ideal

## Step 5: Log Changes

After applying updates, append a summary entry to `13-changelog.md`. Insert it directly above the `---` / `Back to [Index]` footer, using this format:

```markdown
## YYYY-MM-DD

- **<chapter-file.md>**: Brief summary of what changed (e.g., "Updated hooks section to reflect new `pre-tool` event")
- **<other-chapter.md>**: Brief summary
```

Each bullet should be one sentence describing the change at a high level — not every line edited, just enough for a reader to understand what was updated and where. Group all changes from a single `/update-book` run under one date heading. If there's already an entry for today's date, append bullets to the existing section rather than creating a duplicate heading.

## Step 6: Verify Consistency

After all edits:

1. Check that all inter-chapter links still resolve (search for `](` patterns and verify targets exist)
2. Verify the `index.md` chapter list and quick reference table are still accurate
3. Confirm no orphaned references to removed sections
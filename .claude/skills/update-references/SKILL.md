---
name: update-references
description: >
  Discovers and adds new Claude Code resources (blogs, YouTube channels, podcasts, Twitter/X accounts,
  communities, tools, conference talks, courses) to chapter 12 (12-references.md). Use this skill
  whenever the user wants to refresh, expand, or curate the references chapter — even if they just say
  "find new resources", "update references", "add blogs/videos", or "what's new in the Claude Code ecosystem".
argument-hint: "<category to focus on, or 'all' for a full sweep>"
disable-model-invocation: true
allowed-tools: Read, Edit, Glob, Grep, WebSearch, WebFetch, Bash
model: sonnet
---

Find and add new Claude Code resources to the references chapter based on: $ARGUMENTS

---

## Step 1: Load Current State

Read `12-references.md` fully. Build a mental inventory of every resource already listed — URLs, channel names, blog titles, podcast episodes. You need this to avoid proposing duplicates.

Also read [reference.md](reference.md) for book conventions.

## Step 2: Determine Scope

Interpret the argument to decide which categories to search:

| Argument | Scope |
|----------|-------|
| `all` or `full sweep` | Every category below |
| A specific category (e.g., `blogs`, `youtube`, `podcasts`) | Just that category |
| A specific topic (e.g., `MCP tutorials`, `hooks deep-dives`) | Cross-category search for that topic |
| No argument | Default to `all` |

## Step 3: Search for New Resources

Search the web methodically, category by category. For each category, run 2-3 targeted queries. Focus on content published in the last 6-12 months that isn't already in the chapter.

### Categories and search strategies

**YouTube Channels** — Search for channels that regularly publish Claude Code content (not one-off videos). Look for creators with a distinct angle or audience.

**Blogs & Newsletters** — Search for standalone articles and recurring blogs. Prioritize pieces that offer unique workflows, deep technical insight, or comprehensive guides rather than surface-level overviews.

**Podcasts** — Search for new podcast episodes featuring Claude Code creators, Anthropic engineers, or experienced users sharing workflow insights.

**Courses** — Search for new structured learning paths (free or paid) on platforms like DeepLearning.AI, Udemy, Skilljar, YouTube playlists.

**Twitter/X Accounts** — Search for developers, Anthropic employees, and community figures who regularly share Claude Code tips, threads, and workflows. Only include accounts that are genuinely active and focused on Claude Code, not accounts that mentioned it once.

**Communities** — Search for active Reddit communities (r/ClaudeAI, r/AnthropicAI), Discord servers, GitHub Discussions, and forums where Claude Code users gather.

**Conference Talks & Presentations** — Search for recorded talks or slide decks from tech conferences featuring Claude Code.

**Tools & Extensions** — Search for VS Code extensions, CLI tools, MCP servers, and other developer tools built specifically for or around Claude Code.

**Books & Ebooks** — Search for published or in-progress books covering Claude Code or AI-assisted development with Claude.

**Community Lists** — Check for new "awesome-claude-code" style repos or curated directories that have emerged.

## Step 4: Curate and Deduplicate

For each potential new entry:

1. **Verify it exists** — WebFetch the URL to confirm it's live and the content matches what the search described
2. **Check for duplicates** — Compare against the inventory from Step 1 (match on URL, author name, and channel/blog name)
3. **Assess quality** — Is this a substantial, useful resource? Skip thin content, clickbait, or auto-generated SEO articles
4. **Classify** — Assign it to the right section in the chapter

## Step 5: Present Proposed Additions

Before editing, present a grouped summary of all proposed additions:

```
## Proposed Additions to Chapter 12

### YouTube Channels (2 new)
- **ChannelName** — Description of focus and audience. [URL]
- ...

### Blogs & Newsletters (1 new)
- **Author — "Title"** — Why it's worth including. [URL]

### Twitter/X Accounts (new section, 3 entries)
- **@handle** — Description. [URL]
- ...

### No new entries found
- Podcasts (existing coverage is current)
- Courses (no significant new offerings found)
```

For each entry, explain briefly why it's worth including. If a category yielded nothing new, say so.

Wait for user approval before editing. If in non-interactive context, proceed with changes.

## Step 6: Apply Changes

Edit `12-references.md` following these formatting rules:

**Existing sections** — Match the exact format already used in that section:
- Tables for: Official Resources, Courses, Podcasts, Community and Curated Lists
- `###` sub-headings with description + bullet points for: YouTube Channels, Blogs and Newsletters
- Bullet lists for: Ranking Guides, Staying Current

**New sections** (e.g., Twitter/X, Communities, Tools) — Add them using the format that best fits the content density:
- Use a table if entries are uniform and compact (name + description)
- Use `###` sub-headings if entries need longer descriptions
- Place new sections logically: Twitter/X after Blogs, Communities after Community Lists, Tools & Extensions before Staying Current

**Writing style**:
- Descriptions should be concise but specific about what makes the resource valuable
- Include the creator's relevant background when it adds credibility (e.g., "Product Lead at Roblox", "Claude Developer Ambassador")
- For YouTube channels and blogs, include a "Best for" bullet identifying the target audience
- Link text should be the resource name, not a raw URL

## Step 7: Verify

After editing:
1. Confirm all new markdown links are syntactically correct
2. Check the section ordering still flows logically
3. Verify the file still ends with `Back to [Index](index.md)`
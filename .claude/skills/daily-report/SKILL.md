---
name: daily-report
description: >
  Generates a daily markdown report of trending Claude Code articles, blog posts, videos, Reddit
  discussions, tweets, tool releases, and announcements from the previous day. Use this skill whenever
  the user wants a daily digest, news roundup, "what's new with Claude Code", trending topics,
  or asks about recent Claude Code content — even if they just say "daily report", "catch me up",
  "what happened yesterday", or "Claude Code news".
argument-hint: "<optional: specific topic focus like 'MCP' or 'hooks', or leave blank for general report>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, WebSearch, WebFetch, Bash(git add:*), Bash(git commit:*), Bash(git push), Bash(git status), Bash(date *), Bash(find .git *)
model: sonnet
---

Generate a daily report of trending Claude Code content from the previous day.

If the user provided a topic focus: $ARGUMENTS

---

## Step 1: Determine Dates

Use the current date from your system context:
- **Today** — used for the output filename (`daily-report/YYYY-MM-DD.md`)
- **Yesterday** — the date to search for (content published on this day)

**CRITICAL:** Run `date +%Y-%m-%d` via Bash to get today's date. Do NOT rely on filenames of existing reports to infer what day it is. The report filename must always use **today's** date.

If the user specified a topic focus in the arguments, narrow your searches to that topic while still checking all source categories.

## Step 2: Search Strategy

Run multiple parallel web searches to cast a wide net. The goal is to find anything noteworthy about Claude Code from the last 24-48 hours — official announcements carry the most weight, followed by community deep-dives, then general coverage.

### Search queries to run

Run at least 6-8 of these searches (adapt based on topic focus):

**Official & news:**
- `"claude code" anthropic announcement` (filtered to recent)
- `"claude code" release update new feature`
- `anthropic "claude code" blog`

**Community:**
- `"claude code" site:reddit.com` (recent)
- `"claude code" site:news.ycombinator.com`
- `"claude code" site:dev.to OR site:medium.com`

**Tutorials & deep-dives:**
- `"claude code" tutorial guide workflow`
- `"claude code" tips tricks best practices`

**Tools & ecosystem:**
- `"claude code" MCP server plugin extension new`
- `"claude code" open source tool github`

**Social:**
- `"claude code" site:x.com OR site:twitter.com`

If a topic focus was specified (e.g., "MCP", "hooks", "skills"), add the topic to each query.

### Known high-value sources

After the broad searches, specifically check these sources for new content. Use WebFetch on any that look promising from search results:

| Category | Sources |
|----------|---------|
| Official | Anthropic Blog, Claude Code GitHub releases, @AnthropicAI / @ClaudeCode on X |
| Blogs | ClaudeLog, Builder.io, blog.sshh.io (Shrivu Shankar), boristane.com, creatoreconomy.so |
| YouTube | IndyDevDan, AICodeKing, Chris Raroque, Nataly Merezhuk, Nick Saraev, Peter Yang |
| Reddit | r/ClaudeCode, r/ClaudeAI |
| Other | Hacker News, Dev.to, Medium, The Verge, TechCrunch |

## Step 3: Curate Findings

For each piece of content found:

1. **Verify recency** — Was it published yesterday or within the last 48 hours? Skip older content unless it suddenly went viral yesterday.
2. **Verify relevance** — Is it specifically about Claude Code (the CLI tool), not just Claude the model or Claude.ai?
3. **Categorize** — Assign to one of: Official Announcements, Articles & Blog Posts, Videos, Community Discussions, Tools & Releases, Notable Tweets
4. **Summarize** — Write a 1-2 sentence summary of what's notable

If a topic focus was specified, still include all findings but lead with the focused topic.

## Step 4: Generate the Report

Create the `daily-report/` directory if it doesn't exist.

**CRITICAL — never modify previous reports:**
1. The output file MUST be `daily-report/{TODAY}.md` where `{TODAY}` is the date from Step 1.
2. If a file with today's date already exists, you may overwrite it (it's a re-run of today's report).
3. **NEVER edit, update, or append to reports from previous days.** Past reports are immutable records. If you find content that was missed in a previous day's report, include it in today's report instead — not by patching the old one.

Write the report to `daily-report/YYYY-MM-DD.md` using this structure:

```markdown
---
title: "Month Day, Year"
parent: "Daily Reports"
nav_order: N
---

# Claude Code Daily Report — Month Day, Year

> Trending articles, discussions, and resources about Claude Code from the previous day.

## Highlights

<!-- 2-3 sentence executive summary of the most notable items from the day -->

## Official Announcements

**[Title](URL)** — Summary of the announcement and why it matters.

## Articles & Blog Posts

**[Title](URL)** by *Author* — Summary of the article's key insights.

## Videos

**[Title](URL)** by *Creator* (duration) — What the video covers and who it's for.

## Community Discussions

**[Title](URL)** (r/ClaudeCode, 42 upvotes) — Summary of the discussion and key takeaways.

## Tools & Releases

**[Name](URL)** — What the tool does and why it's interesting.

## Notable Tweets

**[@handle](URL)**: "Key quote or paraphrase of the tweet."

---

*Generated by the daily-report skill on YYYY-MM-DD*
```

### Front matter rules

- The `title` is the human-readable date (e.g., "March 10, 2026")
- The `parent` must always be `"Daily Reports"` to nest under the submenu
- Set `nav_order` by counting existing reports in `daily-report/` (excluding `index.md`) and using the next integer, so newer reports appear last

### Formatting rules

- **Omit empty sections** — If no content was found for a category, leave the section out entirely. A clean report with 2 sections is better than one with 4 empty sections.
- **Quiet days are fine** — If very little was found, write a brief Highlights section noting it was a quiet day and include whatever was found. Not every day produces major news.
- **Keep it scannable** — The reader should be able to skim the full report in under 2 minutes. Lead with the most important items in each section.
- **Always include URLs** — Every item needs a clickable link so the reader can go deeper.
- **No speculation** — Only include content you actually found and verified. Don't pad the report with guesses about what might have been published.

## Step 5: Clean Up Stale Git Locks

Before committing, check for and remove any stale `.lock` files in `.git/`:

```bash
find .git -name "*.lock" -type f -delete 2>/dev/null; true
```

Git lock files from previous runs can linger and block commits. The `; true` ensures the step never fails — if there are no lock files or deletion fails, execution continues regardless. If a lock file resists deletion, wait 3 seconds and retry once:

```bash
sleep 3 && find .git -name "*.lock" -type f -delete 2>/dev/null; true
```

## Step 6: Commit and Push

This skill runs autonomously via Windows Task Scheduler (`claude -p`), so every step must complete without user interaction.

After writing the report file:

1. Stage the new report file: `git add daily-report/YYYY-MM-DD.md`
2. Commit with the message format: `Add daily report for YYYY-MM-DD`
3. Push to the remote: `git push`

If `git push` fails (e.g., network issue, auth error), do NOT retry in a loop. Note the failure in Step 7 output so it shows up in the Task Scheduler logs.

## Step 7: Report Back

Print a summary to stdout (this becomes the Task Scheduler log output):
- The path to the generated report
- How many items were found across categories
- The 1-2 most notable findings (or note that it was a quiet day)
- The commit hash
- Whether the push succeeded or failed

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a documentation-only project: an 11-chapter reference guide about Claude Code, organized as markdown files with an `index.md` table of contents. There is no build system, no tests, and no code -- only prose in markdown.

## Structure

- `index.md` -- Table of contents linking all chapters, quick reference table
- `01-introduction.md` through `11-troubleshooting.md` -- Chapters in reading order
- `.claude/skills/audit-claude-setup/` -- Skill that audits a project's Claude Code setup against this guide's best practices
- `.claude/skills/audit-skills/` -- Skill that audits a project's Claude Code skills for quality and token efficiency

Chapters are grouped into four sections:
1. Fundamentals (01-02): concepts and background
2. Working with Tools (03-06): tools, subagents, skills, MCP
3. Configuration and Memory (07-08): settings, CLAUDE.md, project setup
4. Mastering Claude Code (09-11): prompting, advanced features, troubleshooting

## Conventions

- Chapters use `##` for major sections and `###` for subsections
- Each chapter ends with a `Next: [Chapter Name](filename.md)` link (except chapter 11 which links back to index)
- Cross-references between chapters use relative markdown links: `[Chapter 2](02-core-ai-concepts.md)`
- Tables are used extensively for reference material (tool comparisons, settings, shortcuts)
- Code blocks use language-specific fencing (```json, ```bash, ```yaml, ```markdown)
- Chapters are self-contained but may reference other chapters for deeper coverage of a topic

## When Editing

- Keep all inter-chapter links consistent -- if renaming a file, update all references across every chapter and `index.md`
- The index.md quick reference table and chapter list must stay in sync with actual files
- Content should be accurate to current Claude Code behavior; when unsure, verify against official documentation
- The guide serves two audiences (humans learning Claude Code, and Claude Code itself optimizing its behavior) -- keep both perspectives in mind

---
title: Home
layout: home
nav_order: 0
---

# Claude Code Reference Guide

*This guide was written entirely by Claude Code itself.*

A comprehensive reference for using Claude Code effectively. This guide serves two audiences:

- **Humans** learning to use Claude Code for software engineering tasks
- **Claude Code itself** checking how to operate more efficiently on a given project

---

## Chapters

### Fundamentals

1. **[Introduction to Claude Code](01-introduction.md)**
   What Claude Code is, how it works, available models, and the interaction loop.

2. **[Core AI Concepts](02-core-ai-concepts.md)**
   Tokens, context windows, context utilization, hallucinations, temperature, and how these concepts affect your daily work with Claude Code.

### Working with Tools

3. **[Tools Reference](03-tools-reference.md)**
   Complete reference for every built-in tool: Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, Task tools, AskUserQuestion, and more. When to use each and best practices.

4. **[Subagents and Task Delegation](04-subagents.md)**
   The Agent tool (formerly Task), available agent types (Explore, Plan, Bash, general-purpose), creating custom agents, parallelization strategies, agent teams for multi-session collaboration, and when to delegate vs. work inline.

5. **[Skills and Slash Commands](05-skills-and-commands.md)**
   What skills are, how to create and invoke them, built-in slash commands, string substitutions, advanced skill patterns, plugins (installing, creating, marketplaces, organization management), and the Agent Skills open standard.
   - [5a. Slash Commands](05a-slash-commands.md) -- Slash commands, bash mode, bundled skills
   - [5b. Skills](05b-skills.md) -- Creating, invoking, debugging, and best practices for skills
   - [5c. Plugins](05c-plugins.md) -- Plugins and the Agent Skills Open Standard

6. **[MCP (Model Context Protocol)](06-mcp.md)**
   How MCP works, adding and configuring servers, authentication, popular servers, building custom servers, and best practices.

### Configuration and Memory

7. **[Memory and Configuration](07-memory-and-configuration.md)**
   CLAUDE.md files, auto memory, settings hierarchy, environment variables, permission modes, and keybindings.

8. **[Project Setup](08-project-setup.md)**
   Setting up a project for Claude Code: CLAUDE.md authoring, modular rules, hooks, and team conventions.

### Mastering Claude Code

9. **[Effective Prompting and Workflow](09-effective-prompting.md)**
   How to write effective prompts, iterative workflows, using plan mode, managing large tasks, and getting the best results.

10. **[Advanced Features](10-advanced-features.md)**
    Hooks, worktrees, remote control, scheduled tasks, IDE integrations, headless mode, CI/CD usage, and extending Claude Code.
    - [10a. Hooks](10a-hooks.md) -- Hook configuration, events, matchers, and examples
    - [10b. Agents and Worktrees](10b-agents-worktrees.md) -- Custom agents, agent teams, worktrees
    - [10c. Automation](10c-automation.md) -- Remote control, scheduled tasks, headless mode, SDK
    - [10d. Integrations](10d-integrations.md) -- IDE, browser automation, voice mode, extended thinking

11. **[Troubleshooting and Optimization](11-troubleshooting.md)**
    Context management, reducing token waste, debugging common issues, performance tips, and understanding costs.

### References

12. **[References and Resources](12-references.md)**
    Curated blogs, YouTube channels, podcasts, courses, and community resources for learning Claude Code.

### Appendix

13. **[Changelog](13-changelog.md)**
    A log of updates made to this guide, with dates and summaries of what changed.

### Daily Reports

- **[Daily Reports](daily-report/index.md)**
  Trending articles, discussions, and resources about Claude Code, compiled daily.

---

## How to Use This Guide

**For humans**: Read chapters 1-2 first for foundational knowledge, then chapter 3 for the tools you'll interact with daily. Jump to specific chapters as needed.

**For Claude Code**: Reference chapter 3 for tool selection rules, chapter 4 for delegation decisions, and chapter 11 for optimization strategies. Chapter 8 contains the patterns for reading project configuration. Chapter 6 covers MCP server integration.

---

## Quick Reference

| I want to...                          | See chapter                                      |
| ------------------------------------- | ------------------------------------------------ |
| Understand what tokens are            | [Core AI Concepts](02-core-ai-concepts.md)       |
| Know which tool to use                | [Tools Reference](03-tools-reference.md)         |
| Delegate work to subagents            | [Subagents](04-subagents.md)                     |
| Orchestrate a team of agents          | [Subagents](04-subagents.md)                     |
| Create custom skills                  | [Skills](05b-skills.md)                           |
| Install or create plugins             | [Plugins](05c-plugins.md)                         |
| Set up MCP servers                    | [MCP](06-mcp.md)                                 |
| Configure my project                  | [Project Setup](08-project-setup.md)             |
| Write better prompts                  | [Effective Prompting](09-effective-prompting.md)  |
| Test frontend with Playwright CLI      | [Integrations](10d-integrations.md)              |
| Set up hooks                          | [Hooks](10a-hooks.md)                            |
| Set up worktrees                      | [Agents and Worktrees](10b-agents-worktrees.md)  |
| Continue a session from another device | [Automation](10c-automation.md)                 |
| Schedule recurring prompts             | [Automation](10c-automation.md)                 |
| Fix context or performance issues     | [Troubleshooting](11-troubleshooting.md)         |
| Find blogs, videos, and courses       | [References](12-references.md)                   |
| Audit a project's Claude Code setup   | `/audit-claude-setup` skill in `.claude/skills/` |

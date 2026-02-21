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
   Complete reference for every built-in tool: Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, TodoWrite, AskUserQuestion, and more. When to use each and best practices.

4. **[Subagents and Task Delegation](04-subagents.md)**
   The Task tool, available agent types (Explore, Plan, Bash, general-purpose), creating custom agents, parallelization strategies, and when to delegate vs. work inline.

5. **[Skills and Slash Commands](05-skills-and-commands.md)**
   What skills are, how to create and invoke them, built-in slash commands, string substitutions, and advanced skill patterns.

### Configuration and Memory

6. **[Memory and Configuration](06-memory-and-configuration.md)**
   CLAUDE.md files, auto memory, settings hierarchy, environment variables, permission modes, and keybindings.

7. **[Project Setup](07-project-setup.md)**
   Setting up a project for Claude Code: CLAUDE.md authoring, modular rules, MCP servers, hooks, and team conventions.

### Mastering Claude Code

8. **[Effective Prompting and Workflow](08-effective-prompting.md)**
   How to write effective prompts, iterative workflows, using plan mode, managing large tasks, and getting the best results.

9. **[Advanced Features](09-advanced-features.md)**
   Hooks, worktrees, MCP integrations, IDE integrations, headless mode, CI/CD usage, and extending Claude Code.

10. **[Troubleshooting and Optimization](10-troubleshooting.md)**
    Context management, reducing token waste, debugging common issues, performance tips, and understanding costs.

---

## How to Use This Guide

**For humans**: Read chapters 1-2 first for foundational knowledge, then chapter 3 for the tools you'll interact with daily. Jump to specific chapters as needed.

**For Claude Code**: Reference chapter 3 for tool selection rules, chapter 4 for delegation decisions, and chapter 10 for optimization strategies. Chapter 7 contains the patterns for reading project configuration.

---

## Quick Reference

| I want to...                          | See chapter                                      |
| ------------------------------------- | ------------------------------------------------ |
| Understand what tokens are            | [Core AI Concepts](02-core-ai-concepts.md)       |
| Know which tool to use                | [Tools Reference](03-tools-reference.md)         |
| Delegate work to subagents            | [Subagents](04-subagents.md)                     |
| Create custom skills                  | [Skills and Commands](05-skills-and-commands.md)  |
| Configure my project                  | [Project Setup](07-project-setup.md)             |
| Write better prompts                  | [Effective Prompting](08-effective-prompting.md)  |
| Set up hooks or MCP                   | [Advanced Features](09-advanced-features.md)     |
| Fix context or performance issues     | [Troubleshooting](10-troubleshooting.md)         |
| Audit a project's Claude Code setup   | `/audit-claude-setup` skill in `.claude/skills/` |

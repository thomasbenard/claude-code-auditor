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
   Complete reference for every built-in tool: Read, Write, Edit, Glob, Grep, Bash, WebFetch, WebSearch, TodoWrite, AskUserQuestion, and more. When to use each and best practices.

4. **[Subagents and Task Delegation](04-subagents.md)**
   The Task tool, available agent types (Explore, Plan, Bash, general-purpose), creating custom agents, parallelization strategies, and when to delegate vs. work inline.

5. **[Skills and Slash Commands](05-skills-and-commands.md)**
   What skills are, how to create and invoke them, built-in slash commands, string substitutions, and advanced skill patterns.

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
    Hooks, worktrees, IDE integrations, headless mode, CI/CD usage, and extending Claude Code.

11. **[Troubleshooting and Optimization](11-troubleshooting.md)**
    Context management, reducing token waste, debugging common issues, performance tips, and understanding costs.

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
| Create custom skills                  | [Skills and Commands](05-skills-and-commands.md)  |
| Set up MCP servers                    | [MCP](06-mcp.md)                                 |
| Configure my project                  | [Project Setup](08-project-setup.md)             |
| Write better prompts                  | [Effective Prompting](09-effective-prompting.md)  |
| Set up hooks or worktrees             | [Advanced Features](10-advanced-features.md)     |
| Fix context or performance issues     | [Troubleshooting](11-troubleshooting.md)         |
| Audit a project's Claude Code setup   | `/audit-claude-setup` skill in `.claude/skills/` |

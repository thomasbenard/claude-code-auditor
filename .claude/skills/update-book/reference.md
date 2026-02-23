# Update Reference: Book Structure and Conventions

Use this reference when updating the guide to maintain consistency.

## Book Structure

| Chapter | File | Topics |
|---|---|---|
| 1 | `01-introduction.md` | What Claude Code is, models, interaction loop |
| 2 | `02-core-ai-concepts.md` | Tokens, context windows, hallucinations, temperature |
| 3 | `03-tools-reference.md` | All built-in tools, when to use each |
| 4 | `04-subagents.md` | Task tool, agent types, custom agents, parallelization |
| 5 | `05-skills-and-commands.md` | Skills, slash commands, SKILL.md format, patterns |
| 6 | `06-mcp.md` | MCP servers, configuration, auth, building servers |
| 7 | `07-memory-and-configuration.md` | CLAUDE.md, auto memory, settings, env vars, permissions |
| 8 | `08-project-setup.md` | Project setup, modular rules, hooks, team conventions |
| 9 | `09-effective-prompting.md` | Prompt writing, plan mode, workflows, large tasks |
| 10 | `10-advanced-features.md` | Hooks, worktrees, IDE, headless mode, CI/CD |
| 11 | `11-troubleshooting.md` | Context management, token waste, debugging, costs |

## Topic-to-Chapter Map

Use this to find where a topic is primarily covered and where it may be cross-referenced:

| Topic | Primary chapter | Cross-references |
|---|---|---|
| Tools | 03 | 04 (subagent tools), 11 (tool optimization) |
| Subagents / Task tool | 04 | 03 (Task tool entry), 11 (delegation for context) |
| Skills | 05 | 07 (settings), 08 (project setup) |
| MCP | 06 | 03 (MCP tools), 07 (settings) |
| CLAUDE.md | 07 | 08 (authoring guide), 09 (prompting) |
| Settings | 07 | 08 (project setup), 10 (hooks config) |
| Hooks | 10 | 08 (project setup), 07 (settings) |
| Worktrees | 10 | 04 (agent isolation) |
| Context management | 11 | 02 (context windows), 09 (prompt efficiency) |

## Writing Conventions

- **Headings**: `##` for major sections, `###` for subsections
- **Chapter links**: `[Chapter Name](filename.md)` with relative paths
- **Navigation**: Each chapter ends with `Next: [Chapter Name](filename.md)` (chapter 11 links to index)
- **Code blocks**: Use language-specific fencing (```json, ```bash, ```yaml, ```markdown)
- **Tables**: Used extensively for reference material (tool comparisons, settings, shortcuts)
- **Tone**: Practical and direct; explain the "what" and "why", avoid filler
- **Audience**: Both humans learning Claude Code and Claude Code optimizing its own behavior

## Change Types

### Updating Existing Content

Edit in place. Preserve surrounding context and transitions. Keep the same level of detail as surrounding content -- don't expand a one-line mention into three paragraphs, and don't compress a detailed section into a brief note.

### Removing Obsolete Content

- Delete the content cleanly
- Update any surrounding text that referenced or transitioned to the removed content
- Search all chapters for cross-references to the removed section
- If a table row is removed, check if the table still makes sense without it

### Adding New Content

- Place in the most logical chapter based on the topic-to-chapter map above
- Match the heading level and depth of coverage of surrounding sections
- Add cross-references from related chapters if the topic is mentioned elsewhere
- Update `index.md` chapter descriptions if the addition significantly changes a chapter's scope

### Official Sources to Check

- Anthropic docs: `https://docs.anthropic.com/en/docs/claude-code`
- Claude Code GitHub: `https://github.com/anthropics/claude-code`
- Claude Code changelog: search for recent release notes and announcements
# Advanced Features: Integrations

## IDE Integrations

### VS Code

The Claude Code VS Code extension provides a graphical interface:

**Key features:**
- Chat panel in the sidebar or as a tab
- Inline diff review for proposed changes
- @-mention files with line ranges (`@src/auth.ts#40-60`)
- Multiple conversations in tabs
- Plan mode with full markdown plan view and comment support
- Spark icon in the activity bar listing all Claude Code sessions
- Session management: rename and remove sessions from the sessions list
- Native MCP server management dialog via `/mcp`
- Compaction displayed as a collapsible "Compacted chat" card

**Shortcuts:**
| Shortcut | Action |
| --- | --- |
| `Ctrl+Shift+Esc` | Open in new tab |
| `Ctrl+N` | New conversation |
| `Alt+K` | Insert @-mention |
| `Ctrl+Esc` | Toggle focus |

### JetBrains IDEs

Available for IntelliJ, PyCharm, WebStorm, GoLand, RubyMine, and more via the JetBrains marketplace.

### Desktop App

Claude Code Desktop provides a native application interface for macOS and Windows.

### Chrome Extension

The Claude in Chrome extension lets Claude Code debug live web applications directly in your browser. Claude can inspect pages, read console messages, monitor network requests, fill forms, and take screenshots -- useful for frontend debugging and visual verification without leaving the browser.

### Slack Integration

Mention `@Claude` in Slack with a bug report or task description to receive a pull request back. Claude Code reads the Slack message, works on the codebase, and opens a PR -- useful for routing bug reports from non-developers or team chat directly into code changes.

## Browser Automation

Claude Code can interact with browsers in two ways: through **Playwright CLI** (recommended) and through MCP browser servers. For frontend testing and visual verification, Playwright CLI is the preferred approach -- it is dramatically more token-efficient and requires no server setup.

### Playwright CLI

[Playwright CLI](https://github.com/microsoft/playwright-cli) (`@playwright/cli`) is a command-line tool built specifically for AI coding agents. Instead of running a persistent MCP server, Claude uses simple shell commands via Bash to control a browser. Screenshots and snapshots are saved to disk rather than streamed into the conversation context, which saves significant tokens.

#### Installation

```bash
# Install globally
npm install -g @playwright/cli@latest

# Or install as a Claude Code skill (auto-discovered)
playwright-cli install --skills
```

The skill-based installation scaffolds a `.claude/skills/playwright-cli/` directory in your project, which Claude Code auto-discovers. You can also install it via the Agent Skills standard:

```bash
npx skills add https://github.com/microsoft/playwright-cli --skill playwright-cli
```

#### Core Commands

| Command | Purpose |
| --- | --- |
| `playwright-cli open [url]` | Launch browser (headless by default, `--headed` for visible) |
| `playwright-cli snapshot` | Capture a compact YAML accessibility snapshot with element references |
| `playwright-cli screenshot` | Save screenshot to disk (`--filename` to specify path) |
| `playwright-cli click <ref>` | Click an element by reference ID from snapshot |
| `playwright-cli fill <ref> <text>` | Fill a form field by reference |
| `playwright-cli pdf` | Generate PDF to disk |

#### Example Workflow

A typical frontend verification loop looks like this:

```bash
# 1. Open the local dev server
playwright-cli open http://localhost:3000/login

# 2. Take a snapshot to see the page structure
playwright-cli snapshot
# Output: YAML with element references like e1, e5, e21

# 3. Fill in the login form
playwright-cli fill e5 "user@example.com"
playwright-cli fill e8 "password123"
playwright-cli click e12

# 4. Screenshot the result
playwright-cli screenshot --filename login-result.png
```

Claude reads the snapshot file to understand page structure, and only reads the screenshot when visual verification is actually needed -- keeping token usage minimal.

#### Why Playwright CLI Replaces MCP for Frontend Testing

| Aspect | Playwright CLI | Browser MCP (Puppeteer/Playwright) |
| --- | --- | --- |
| **Token cost** | ~27k tokens per typical task | ~114k tokens per typical task |
| **Upfront overhead** | ~68 tokens (skill description) | ~3,600 tokens (tool schemas loaded at session start) |
| **Data flow** | Saves to disk; agent reads selectively | Streams into context (screenshots, accessibility trees) |
| **Setup** | `npm install -g @playwright/cli` | `claude mcp add ...`, server lifecycle management |
| **Composability** | Chain with `&&`, pipes, shell scripts | Isolated MCP tool calls |
| **Server management** | None -- stateless commands | Must start, maintain, and debug server process |

**The core insight**: MCP browser servers load tool schemas into every API call and stream full accessibility trees and screenshots directly into the conversation. Playwright CLI saves everything to disk and lets Claude decide what to read, cutting token consumption by 4-10x.

**Use MCP browser automation only when**:
- The agent lacks shell/filesystem access (sandboxed environments)
- You need continuous browser state across many interactions without explicit session management
- You are using the Claude in Chrome extension for live browser interaction

### Quick Screenshots with `npx playwright`

If you don't need full browser automation, the standard `playwright` npm package includes lightweight CLI commands for one-off tasks:

```bash
# Screenshot a URL (no install needed beyond playwright)
npx playwright screenshot https://localhost:3000 home.png
npx playwright screenshot --full-page --device="iPhone 13" https://localhost:3000 mobile.png

# Generate a PDF
npx playwright pdf https://localhost:3000/report report.pdf
```

These are useful for quick visual checks without installing `@playwright/cli`.

### Preview System

For local development, Claude Code can preview your app:

1. Configure dev server in `.claude/launch.json`
2. Claude starts the server with `preview_start`
3. Takes screenshots and snapshots to verify changes
4. Inspects DOM elements for styling verification

## Voice Mode

Voice mode lets you speak to Claude Code using push-to-talk instead of typing. Toggle it with `/voice`.

### Supported Languages

Voice mode supports speech-to-text in 20 languages: English, Spanish, French, German, Italian, Portuguese, Japanese, Korean, Chinese, Hindi, Russian, Polish, Turkish, Dutch, Ukrainian, Greek, Czech, Danish, Swedish, and Norwegian.

### Using Voice Mode

- Press and hold the push-to-talk key (rebindable via `voice:pushToTalk` in keybindings) to speak
- Release to send the transcription as your prompt
- Voice mode automatically retries transient connection failures during rapid push-to-talk re-presses
- Accuracy is optimized for developer terminology

Voice mode is useful when you want to describe a complex task faster than typing, dictate code review feedback, or work hands-free.

## Extended Thinking

Extended thinking gives Claude an internal "scratchpad" for complex reasoning:

- Toggle with `Alt+T`
- Consumes additional tokens (viewable with `Ctrl+O` for verbose mode)
- Improves quality on complex debugging, architecture, and multi-step reasoning
- Not needed for simple tasks

Use extended thinking when:
- Debugging subtle issues with multiple possible causes
- Making architectural decisions
- Working through complex logic or algorithms
- Planning multi-step refactors

Skip it when:
- Making simple edits
- Running commands
- Quick file lookups

---

Next: [Troubleshooting and Optimization](11-troubleshooting.md) -- Solving common problems and maximizing efficiency.

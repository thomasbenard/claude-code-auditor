---
title: "6. MCP (Model Context Protocol)"
nav_order: 6
---

# Chapter 6: MCP (Model Context Protocol)

MCP is the way Claude Code connects to the outside world beyond its built-in tools. It is an open protocol that lets you plug in databases, APIs, browsers, and any custom tooling -- giving Claude capabilities that no single product could ship out of the box.

## What is MCP?

The Model Context Protocol (MCP) is an open standard that defines how AI applications communicate with external services. Think of it like USB for AI tools: just as USB provides a standard way to connect any peripheral to any computer, MCP provides a standard way to connect any tool or data source to any AI application.

Before MCP, integrating Claude with external services required custom code for each integration. MCP standardizes this so that:

- **Tool authors** write one MCP server and it works with any MCP-compatible AI tool
- **Users** add servers with a single command -- no custom glue code
- **Organizations** can publish MCP servers that entire teams share

MCP is not specific to Claude Code. It is an open standard (developed by Anthropic and adopted by the broader ecosystem) used across many AI applications. But Claude Code has first-class MCP support built directly into its architecture.

## MCP Architecture

### Client-Server Model

MCP follows a client-server architecture. Claude Code is the **client** that connects to one or more **MCP servers**:

```
┌─────────────────────────────────────────────────────┐
│                   Claude Code (Client)              │
│                                                     │
│  Built-in tools   MCP client   MCP client   ...    │
│  (Read, Edit,     ┌───────┐    ┌───────┐           │
│   Bash, Grep)     │       │    │       │           │
└───────────────────┤       ├────┤       ├───────────┘
                    └───┬───┘    └───┬───┘
                        │            │
                    ┌───┴───┐    ┌───┴───┐
                    │  MCP  │    │  MCP  │
                    │Server │    │Server │
                    │(GitHub│    │(Postgres│
                    │  API) │    │  DB)  │
                    └───────┘    └───────┘
```

Each MCP server exposes one or more of three capability types:

| Capability | What it provides | How Claude uses it |
| --- | --- | --- |
| **Tools** | Functions Claude can call | Like built-in tools, but backed by external services |
| **Resources** | Data Claude can reference | Loaded via @-mentions in IDEs or read explicitly |
| **Prompts** | Pre-built prompt templates | Become available as slash commands |

Tools are by far the most common capability. Most MCP servers provide tools exclusively.

### How a Tool Call Flows

When Claude decides to use an MCP tool, the flow is:

1. Claude sees the tool in its available tool definitions (loaded at session start)
2. Claude generates a tool call with the appropriate parameters
3. Claude Code checks permission rules (allow/deny lists)
4. If permitted, Claude Code sends the request to the MCP server
5. The MCP server executes the action (API call, database query, etc.)
6. The server returns the result to Claude Code
7. Claude Code passes the result back to Claude
8. Claude incorporates the result and continues reasoning

This is transparent to you -- MCP tools look and behave like built-in tools from the user's perspective.

### Transport Types

MCP servers connect to Claude Code through one of these transport mechanisms:

| Transport | How it works | Best for | Example |
| --- | --- | --- | --- |
| **HTTP** (streamable) | Claude connects to a remote HTTP endpoint | Cloud services, hosted servers | GitHub MCP, Sentry |
| **Stdio** | Claude spawns a local process and communicates via stdin/stdout | Local tools, databases, file processors | PostgreSQL, filesystem |
| **SSE** (deprecated) | Server-sent events over HTTP | Legacy servers only | Older implementations |

**HTTP** is preferred for remote services -- it supports authentication, is firewall-friendly, and the server runs independently. **Stdio** is best for local tools where the server runs on your machine and needs access to local resources.

## Adding and Managing Servers

### CLI Commands

Manage MCP servers from the command line:

| Command | Purpose |
| --- | --- |
| `claude mcp add <name> -- <command> [args...]` | Add a stdio server |
| `claude mcp add --transport http <name> <url>` | Add an HTTP server |
| `claude mcp add --transport http --header "Authorization: Bearer $TOKEN" <name> <url>` | Add with auth headers |
| `claude mcp add --env KEY=value <name> -- <command>` | Add with environment variables |
| `claude mcp add -s project <name> -- <command>` | Add at project scope |
| `claude mcp add -s user <name> -- <command>` | Add at user scope |
| `claude mcp list` | List all configured servers |
| `claude mcp get <name>` | Show server details |
| `claude mcp remove <name>` | Remove a server |

### Adding an HTTP Server

```bash
# GitHub MCP (OAuth-based, authenticate via /mcp in-session)
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Sentry with API key
claude mcp add --transport http \
  --header "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  sentry https://sentry.io/api/mcp/
```

### Adding a Stdio Server

```bash
# PostgreSQL
claude mcp add --env DATABASE_URL=postgres://localhost/mydb \
  postgres -- npx -y @modelcontextprotocol/server-postgres

# Filesystem (read-only access to specific directories)
claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /path/to/dir

# Puppeteer (browser automation)
claude mcp add puppeteer -- npx -y @modelcontextprotocol/server-puppeteer
```

### In-Session Management

Use `/mcp` during a session to:

- View connected servers and their status
- See which tools each server provides
- Authenticate OAuth-based servers
- Check token cost of loaded server definitions
- Restart failed server connections

## Configuration

### Configuration Scopes

MCP servers can be configured at three scopes:

| Scope | File | Shared with team | Purpose |
| --- | --- | --- | --- |
| **Project** | `.mcp.json` | Yes (commit to git) | Servers the whole team needs |
| **User** | `~/.claude.json` | No | Personal servers across all projects |
| **Managed** | System directory | Organization-wide | Enforced by IT/admins |

Project scope is the most common. Add `.mcp.json` to your repository so everyone on the team gets the same servers.

### .mcp.json Format

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./docs"]
    }
  }
}
```

### Environment Variables and Secrets

Use `${VAR_NAME}` syntax in `.mcp.json` to reference environment variables without hardcoding secrets:

```json
{
  "mcpServers": {
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

The actual value comes from the environment, which each developer sets locally. A common pattern:

1. Commit `.mcp.json` with `${VAR}` references
2. Each developer sets the real values in `.claude/settings.local.json`:
   ```json
   {
     "env": {
       "DATABASE_URL": "postgres://localhost/mydb"
     }
   }
   ```
3. `.claude/settings.local.json` is gitignored, keeping secrets out of version control

You can also pass environment variables directly via the CLI:

```bash
claude mcp add --env DATABASE_URL=postgres://localhost/mydb \
  postgres -- npx -y @modelcontextprotocol/server-postgres
```

## How MCP Tools Work in Practice

### Naming Convention

MCP tools follow the naming pattern `mcp__<server>__<tool>`:

```
mcp__github__create_issue
mcp__github__search_repositories
mcp__postgres__query
mcp__filesystem__read_file
mcp__puppeteer__navigate
mcp__puppeteer__screenshot
```

The double-underscore separators distinguish MCP tools from built-in tools and prevent naming collisions between servers.

### Usage Examples

Once configured, Claude uses MCP tools automatically when relevant:

```
User: Create a GitHub issue for the login bug we found

Claude: [Calls mcp__github__create_issue]
        Created issue #42: "Login fails with + character in email"
```

```
User: What's the schema of the users table?

Claude: [Calls mcp__postgres__query with "SELECT column_name, data_type
        FROM information_schema.columns WHERE table_name = 'users'"]
        The users table has: id (uuid), email (text), name (text), ...
```

```
User: Take a screenshot of the login page

Claude: [Calls mcp__puppeteer__navigate to http://localhost:3000/login]
        [Calls mcp__puppeteer__screenshot]
        Here's the current login page: [screenshot]
```

### Permission Rules

MCP tools follow the same permission system as built-in tools. Configure allow/deny rules in `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__github__*",
      "mcp__postgres__query"
    ],
    "deny": [
      "mcp__postgres__execute"
    ]
  }
}
```

Wildcards work at any level:
- `mcp__github__*` -- allow all tools from the GitHub server
- `mcp__*__query` -- allow query tools from any server
- `mcp__dangerous__*` -- deny all tools from a specific server

Evaluation order is the same as for built-in tools: deny rules are checked first, then allow rules.

## Resources and Prompts

While tools are the primary MCP capability, servers can also provide resources and prompts.

### Resources

Resources are data that Claude can reference. In IDE integrations, they appear as @-mentionable items:

```
@github:issue/42    → loads the full issue details into context
@postgres:schema    → loads the database schema
```

Resources are read-only and loaded on demand, making them useful for reference data that Claude might need.

### Prompts

MCP prompts are pre-built prompt templates that become available as commands. They are less commonly used than tools but can be useful for standardized workflows provided by a server.

## Authentication

### OAuth Flow

Many HTTP-based MCP servers use OAuth for authentication (e.g., GitHub, Slack, Jira):

1. Run `/mcp` in a session
2. Select the server that needs authentication
3. Claude Code opens a browser window for the OAuth flow
4. Authorize the application
5. Credentials are stored securely and reused across sessions

### API Keys via Environment Variables

For servers that use API keys rather than OAuth:

```bash
# Pass at add time
claude mcp add --transport http \
  --header "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  sentry https://sentry.io/api/mcp/

# Or use env vars in .mcp.json
{
  "mcpServers": {
    "sentry": {
      "type": "http",
      "url": "https://sentry.io/api/mcp/",
      "headers": {
        "Authorization": "Bearer ${SENTRY_AUTH_TOKEN}"
      }
    }
  }
}
```

### Credential Storage

- OAuth tokens are stored in Claude Code's secure credential store
- API keys should live in environment variables, not hardcoded in config
- Use `.claude/settings.local.json` (gitignored) for developer-specific secrets

## Popular MCP Servers

Here are commonly used MCP servers and their typical setup:

| Server | Transport | What it provides | Install command |
| --- | --- | --- | --- |
| **GitHub** | HTTP | Issues, PRs, repos, code search | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| **PostgreSQL** | Stdio | Database queries | `claude mcp add postgres -- npx -y @modelcontextprotocol/server-postgres` |
| **Filesystem** | Stdio | Read/write files outside the project | `claude mcp add filesystem -- npx -y @modelcontextprotocol/server-filesystem /path` |
| **Sentry** | HTTP | Error tracking, issue monitoring | `claude mcp add --transport http sentry https://sentry.io/api/mcp/` |
| **Puppeteer** | Stdio | Browser automation, screenshots | `claude mcp add puppeteer -- npx -y @modelcontextprotocol/server-puppeteer` |
| **Memory** | Stdio | Persistent key-value knowledge base | `claude mcp add memory -- npx -y @modelcontextprotocol/server-memory` |
| **Slack** | HTTP | Channel messages, user lookup | `claude mcp add --transport http slack <slack-mcp-url>` |

### Common Use-Case Patterns

**Database-driven development**: Add the PostgreSQL MCP so Claude can inspect schemas, run queries, and verify data changes directly.

**Full-stack with previews**: Combine Puppeteer MCP with a dev server in `launch.json` so Claude can make changes and visually verify them.

**Issue tracking workflow**: Add GitHub MCP so Claude can read issue details, create branches, and open PRs -- all from natural language instructions.

## Building Your Own MCP Server

If you need Claude to interact with a proprietary API or internal tool, you can build a custom MCP server.

### SDK Options

MCP server SDKs are available in multiple languages:

| Language | Package |
| --- | --- |
| TypeScript | `@modelcontextprotocol/sdk` |
| Python | `mcp` |
| Kotlin | `io.modelcontextprotocol:kotlin-sdk` |
| C# | `ModelContextProtocol` |

### Minimal TypeScript Example

```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const server = new McpServer({
  name: "my-tool",
  version: "1.0.0",
});

server.tool(
  "lookup_user",
  "Look up a user by email",
  { email: z.string().email() },
  async ({ email }) => {
    const user = await db.users.findByEmail(email);
    return {
      content: [{
        type: "text",
        text: JSON.stringify(user, null, 2),
      }],
    };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
```

Register it with Claude Code:

```bash
claude mcp add my-tool -- node /path/to/my-tool/dist/index.js
```

For a full guide to building MCP servers, see the official documentation at [modelcontextprotocol.io](https://modelcontextprotocol.io).

## Context Cost and Performance

### Token Cost

Every MCP server adds its tool definitions to the system prompt. This consumes context tokens before you even send your first message:

| Server tool count | Approximate token cost |
| --- | --- |
| 1-5 tools | 500-1,500 tokens |
| 5-15 tools | 1,500-4,000 tokens |
| 15-30 tools | 4,000-8,000 tokens |
| 30+ tools | 8,000+ tokens |

With multiple servers, this adds up. Three servers with 15 tools each could consume 10,000+ tokens of your 200,000 token context -- 5% gone before any work begins.

### Checking Your MCP Token Cost

Run `/mcp` in a session to see the token cost of each connected server.

Run `/context` to see how MCP definitions fit into your overall context usage.

### Startup Latency

- **HTTP servers**: Near-instant connection (server is already running)
- **Stdio servers**: Must spawn a process at session start. If the server uses `npx`, this includes downloading the package on first run (can take 5-30 seconds)

### Optimization Strategies

1. **Only enable what you need**: Remove servers you're not actively using with `claude mcp remove <name>`
2. **Prefer HTTP over stdio for cloud services**: Faster startup, no local process overhead
3. **Cache npx packages**: Run the npx command once manually so the package is cached for subsequent sessions
4. **Use project scope for team servers**: Put shared servers in `.mcp.json` so they're consistent but only load in relevant projects
5. **Monitor with `/mcp`**: Check periodically to see if servers you've added are still relevant

## Pitfalls and Anti-Patterns

### Common Pitfalls

**1. Too many servers loaded at once**

Each server consumes context tokens for its tool definitions. Loading 5+ servers can consume 10-20% of your context before any work begins.

*Fix*: Only enable servers for the current task. Use `claude mcp remove` to clean up unused ones.

**2. Hardcoded secrets in `.mcp.json`**

Committing API keys or database passwords directly in `.mcp.json` exposes them in version control.

*Fix*: Use `${VAR_NAME}` references and set actual values in `.claude/settings.local.json` (gitignored) or shell environment.

**3. OAuth authentication expiry**

OAuth tokens can expire. When they do, MCP tools silently fail or return authentication errors.

*Fix*: Run `/mcp` to check server status. Re-authenticate when needed.

**4. npx startup latency**

Stdio servers using `npx` download the package on first run, causing delays of 5-30 seconds.

*Fix*: Run the npx command once manually to cache the package, or install the package globally.

**5. Stale server connections**

Long-running sessions can experience server disconnections, especially for stdio servers.

*Fix*: If MCP tools start failing, use `/mcp` to check status and restart connections.

**6. Tool name conflicts**

If two MCP servers expose tools with the same name, only one will be usable. The namespacing (`mcp__server__tool`) prevents this at the protocol level, but server names must be unique.

*Fix*: Choose distinct server names when adding. Check `claude mcp list` for conflicts.

**7. Excessive tool counts from a single server**

Some MCP servers expose 30+ tools. This bloats the system prompt and can confuse tool selection.

*Fix*: Check if the server supports tool filtering. If not, consider whether a lighter-weight alternative exists.

### Anti-Patterns

**Using MCP when a built-in tool suffices**: Claude Code's built-in file tools (Read, Edit, Grep, Glob) are faster and cheaper than an MCP filesystem server. Only use MCP filesystem for accessing directories outside the project.

**Installing MCP servers globally when they're project-specific**: A database MCP server makes sense for a project with PostgreSQL, but not for all your projects. Use project-scoped `.mcp.json` instead of user-scoped config.

**Ignoring MCP token costs**: Adding servers "just in case" wastes context. Check `/mcp` and `/context` regularly.

## Debugging MCP Issues

When MCP tools aren't working as expected, follow these diagnostic steps:

### Step 1: Check Server Status

Run `/mcp` in your session. This shows:
- Which servers are connected
- Which tools each server provides
- Connection status and any errors

### Step 2: Verify Configuration

```bash
# List all configured servers
claude mcp list

# Check specific server details
claude mcp get <server-name>
```

### Step 3: Test the Server Independently

For stdio servers, try running the command directly:

```bash
# Test that the server process starts
npx -y @modelcontextprotocol/server-postgres

# Check if the right version is installed
npx -y @modelcontextprotocol/server-postgres --version
```

### Step 4: Check Environment Variables

Ensure referenced `${VAR}` values are actually set:

```bash
# Check if the var exists
echo $DATABASE_URL

# Check if it's in settings.local.json
cat .claude/settings.local.json
```

### Step 5: Check Permissions

MCP tools follow the same permission rules as built-in tools. If a tool is blocked:

```bash
# Check permission rules
claude config get permissions
```

Look for deny rules matching `mcp__<server>__*` patterns.

### Step 6: Check Logs

For persistent issues, Claude Code's debug mode provides more detail:

```
/debug
```

### Common Error Scenarios

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Server shows as "disconnected" | Process crashed or timed out | Restart via `/mcp`, check logs |
| "Tool not found" error | Server not loaded, or misspelled name | Run `claude mcp list`, verify name |
| "Permission denied" on tool call | Deny rule blocking the tool | Check `.claude/settings.json` deny list |
| Authentication error from server | Expired OAuth token or missing API key | Re-authenticate via `/mcp` |
| Server takes long to start | npx downloading package | Pre-cache with manual npx run |
| Tool returns empty/unexpected data | Wrong env vars or server misconfigured | Verify env vars, test server independently |
| "Connection refused" for HTTP server | Server is down or URL is wrong | Check URL, verify server is running |

## Best Practices

1. **Start with one or two servers**: Add MCP servers as you need them, not preemptively. Each one costs context tokens.

2. **Use project scope for team servers**: Put shared server configs in `.mcp.json` so the whole team benefits and configuration stays consistent.

3. **Never hardcode secrets**: Always use `${VAR_NAME}` references in `.mcp.json`. Set real values in `.claude/settings.local.json` (gitignored) or environment variables.

4. **Set permission rules for MCP tools**: Use allow/deny rules in `.claude/settings.json` to control what MCP tools can do, especially for tools with write access (database execute, file write, etc.).

5. **Monitor context cost**: Run `/mcp` and `/context` periodically. Remove servers that aren't pulling their weight.

6. **Pre-cache npx packages**: Run stdio server commands once manually so subsequent sessions start faster.

7. **Prefer HTTP for cloud services**: HTTP servers start instantly and don't require local process management. Use them for GitHub, Sentry, Slack, and similar hosted APIs.

8. **Use stdio for local tools**: Database access, file operations outside the project, and local automation are best served by stdio servers running on your machine.

9. **Keep server names short and descriptive**: Names become part of tool identifiers (`mcp__name__tool`). Short names are easier to read in logs and permission rules.

10. **Document MCP setup in CLAUDE.md**: If your project uses MCP servers, mention them in CLAUDE.md so Claude (and new team members) know what external integrations are available.

---

Next: [Memory and Configuration](07-memory-and-configuration.md) -- How Claude Code remembers and how to configure it.

---
title: "8. Effective Prompting and Workflow"
nav_order: 8
---

# Chapter 8: Effective Prompting and Workflow

How you communicate with Claude Code significantly affects the quality and efficiency of the results. This chapter covers prompting strategies, workflow patterns, and practical tips for getting the most out of every interaction.

## Prompting Fundamentals

### Be Specific

The most common mistake is being too vague. Claude Code performs best with concrete, specific instructions.

**Vague** (works but less reliable):
```
Fix the auth bug
```

**Specific** (much better):
```
The login endpoint at src/api/auth.ts returns 500 when the email
contains a + character. Fix the email validation to handle this case.
```

**Why specificity matters**: Claude has to make fewer assumptions, which means fewer wrong turns, fewer wasted tokens, and faster results.

### Provide Context

Claude Code can read your files, but telling it where to look saves time:

```
The UserService class in src/services/user.ts has a findByEmail method
that doesn't handle the case where the email is null. Add a null check
that returns null early instead of throwing.
```

### State Your Intent, Not Just the Action

Tell Claude **why** you want something, not just **what**:

```
# Just the what:
Add a try-catch around the database call in createUser

# What + why (better):
The createUser function in src/repos/user.ts crashes the server when
the database is unreachable. Wrap the database call in a try-catch that
logs the error and returns a proper error response instead of crashing.
```

Knowing the intent helps Claude make better decisions about implementation details.

### Use File References

Reference specific files to guide Claude:

```
Look at @src/auth/middleware.ts and @src/auth/types.ts.
The AuthContext type is missing the refreshToken field.
Add it and update the middleware to populate it.
```

In IDEs, `@` references with line ranges work too: `@src/auth.ts#40-60`

## Prompt Patterns

### The "Like X" Pattern

Reference existing code as a template:

```
Create a new API endpoint for /api/v1/products following the same
pattern as the existing /api/v1/users endpoint in src/api/users.ts.
Include the same validation, error handling, and response format.
```

### The "Investigate Then Fix" Pattern

For bugs where you don't know the root cause:

```
The checkout page shows "undefined" instead of the product price
when the currency is EUR. Investigate why this happens, then fix it.
Check the price formatting logic and the API response shape.
```

### The "Constraint" Pattern

Set boundaries to prevent over-engineering:

```
Add input validation to the registration form. Keep it simple:
- Required fields: name, email, password
- Email must be valid format
- Password minimum 8 characters
Don't add any other validation. Don't refactor existing code.
```

### The "Verify" Pattern

Ask Claude to verify its own work:

```
Fix the date parsing bug in src/utils/date.ts, then run the tests
to confirm the fix works. If tests fail, iterate until they pass.
```

### The "Scope Limit" Pattern

Prevent Claude from making unrelated changes:

```
Update the Button component to accept a "loading" prop.
Only modify src/components/Button.tsx and its test file.
Don't change any other files or add new dependencies.
```

## Workflow Patterns

### The Exploration Workflow

When working with an unfamiliar codebase:

1. **Start broad**: "Give me an overview of this project's architecture"
2. **Narrow down**: "Explain how the authentication flow works"
3. **Get specific**: "Show me the token validation logic"
4. **Then act**: "Now fix the token expiry bug"

### The Plan-Then-Execute Workflow

For complex changes:

1. **Enter plan mode**: Press `Shift+Tab` to enter plan mode, or ask Claude to plan first
2. **Review the plan**: Claude explores and proposes an approach
3. **Refine**: Ask questions or request changes to the plan
4. **Execute**: Approve and let Claude implement

This is especially valuable for:
- Multi-file refactors
- Architectural changes
- Unfamiliar code that needs investigation first

### The Iterative Workflow

Build up changes incrementally:

```
Step 1: "Create the database schema for the products table"
Step 2: "Now create the repository class for products"
Step 3: "Add the API endpoint that uses the repository"
Step 4: "Write tests for the endpoint"
Step 5: "Run all tests and fix any issues"
```

Each step builds on the previous one, and you can course-correct between steps.

### The Review Workflow

Use Claude Code to review changes before committing:

```
Review the changes I've made in this branch. Run git diff against main
and analyze each change for correctness, security issues, and style
consistency with the rest of the codebase.
```

## Managing Large Tasks

### Breaking Down Work

Large tasks should be broken into manageable pieces:

```
I need to add a notification system. Let's break this into phases:

Phase 1: Create the notification data model and database schema
Phase 2: Build the notification service with send/read/dismiss
Phase 3: Add API endpoints for notifications
Phase 4: Add real-time delivery via WebSocket
Phase 5: Write tests for all components

Let's start with Phase 1.
```

### Using Subagents for Parallel Research

When starting a large task, research in parallel:

```
Before we implement, I need to understand:
1. How the current event system works (check src/events/)
2. What WebSocket infrastructure exists (check src/ws/)
3. What notification patterns other parts of the app use

Research all three in parallel using subagents.
```

### Context Management for Long Tasks

During long implementation sessions:

1. **Compact between phases**: `/compact focus on Phase 2: notification service`
2. **Use subagents for verification**: Delegate test runs to subagents
3. **Summarize progress**: "Summarize what we've done so far before we continue"
4. **Start new sessions for new phases**: If context gets too full, start a new session with a clear brief

## Common Mistakes to Avoid

### Over-Specifying Implementation Details

**Too detailed** (constrains Claude unnecessarily):
```
Create a function called validateEmail that takes a string parameter
named email and uses a regex /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
to validate it, returning a boolean.
```

**Better** (gives Claude room to use good judgment):
```
Add email validation to the registration flow. Use whatever
approach is consistent with how other validations work in this project.
```

### Asking Claude to "Improve" Without Direction

**Vague**:
```
Improve this code
```

**Directed**:
```
This function has three issues: it doesn't handle errors, it has
a potential null reference on line 42, and the variable names are
unclear. Fix these three things.
```

### Ignoring Claude's Findings

When Claude reports something unexpected (a different file structure, a failing test, a missing dependency), engage with it rather than repeating your original instruction. Claude may have found something you didn't know about.

### Not Running Tests

Always include test verification in your workflow:

```
After making the changes, run the test suite. If anything fails,
fix it before we move on.
```

## Tips for Different Task Types

### Bug Fixes

```
Bug: [describe the symptom]
Expected: [what should happen]
Actual: [what happens instead]
Reproduction: [steps or specific input]
Suspected area: [file or module, if known]

Investigate, fix, and verify with tests.
```

### New Features

```
Feature: [what it does]
Requirements:
- [requirement 1]
- [requirement 2]
Constraints:
- [what it should NOT do]
- [files it should NOT modify]

Follow existing patterns in the codebase.
```

### Refactoring

```
Refactor: [what needs to change]
Goal: [why we're refactoring]
Scope: [which files/modules]
Constraint: behavior must not change (existing tests must pass)
```

### Code Review

```
Review the changes in [branch/files]. Check for:
- Correctness and edge cases
- Security issues
- Performance concerns
- Consistency with project conventions
Provide specific feedback with file:line references.
```

## Working with Plan Mode

Plan mode (`Shift+Tab` to toggle) is underutilized but powerful:

### When to Use Plan Mode

- You're unsure about the right approach
- The change touches many files
- You want to understand the blast radius before committing
- You're exploring an unfamiliar codebase

### How Plan Mode Works

1. Claude can only read files and search -- no modifications
2. Claude creates a detailed plan with specific files and changes
3. You review and can ask for adjustments
4. On approval, Claude switches to implementation

### Example Plan Mode Interaction

```
User: I need to add rate limiting to all API endpoints.
      [In plan mode]

Claude: [Reads existing middleware, API routes, dependencies]
        Plan:
        1. Install express-rate-limit package
        2. Create src/middleware/rate-limit.ts with configurable limits
        3. Add rate limit middleware to src/api/router.ts
        4. Add per-route overrides for sensitive endpoints (login, register)
        5. Add tests for rate limiting behavior
        6. Update .env.example with RATE_LIMIT_WINDOW and RATE_LIMIT_MAX

User: Looks good, but use Redis for the rate limit store since
      we already have Redis for sessions.

Claude: [Updates plan to use Redis store]
        [Implements after approval]
```

## Interaction Tips

### Use the Todo List

For multi-step tasks, Claude maintains a visible todo list. You can reference it:

```
What's left on the todo list? Skip the documentation task
and move to the testing task.
```

### Redirect When Needed

If Claude goes in the wrong direction, redirect explicitly:

```
Stop. That approach won't work because [reason].
Instead, try [alternative approach].
```

### Acknowledge Good Work

When Claude does something well, saying so helps calibrate future responses:

```
That implementation looks great. Now apply the same pattern
to the remaining three endpoints.
```

---

Next: [Advanced Features](09-advanced-features.md) -- Hooks, worktrees, MCP, headless mode, and more.

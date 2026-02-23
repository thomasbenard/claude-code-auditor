---
name: commit
description: Stages and commits changes with an auto-generated commit message
argument-hint: "<optional message or guidance>"
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep
model: sonnet
---

Create a git commit for the current changes.

If the user provided guidance: $ARGUMENTS

---

## Step 1: Assess the Working Tree

Run these in parallel:

1. `git status` — see untracked and modified files
2. `git diff` — see unstaged changes
3. `git diff --staged` — see already-staged changes
4. `git log --oneline -5` — see recent commit style

If there are no changes to commit, inform the user and stop.

## Step 2: Stage Files

- Stage all modified and new files that are part of the logical change
- Do NOT stage files that likely contain secrets (`.env`, credentials, tokens)
- If unrelated changes are mixed together, ask the user which to include

## Step 3: Write the Commit Message

Analyze the staged diff to write a commit message:

- **First line**: imperative mood, under 72 characters, focuses on the "why" not the "what" (e.g., "Add X" not "Added X", "Fix Y" not "Fixing Y")
- **Match the repository's existing style** based on the recent log
- If the user provided specific guidance in `$ARGUMENTS`, incorporate it
- End with the co-author trailer

## Step 4: Commit

Create the commit using a HEREDOC for the message:

```bash
git commit -m "$(cat <<'EOF'
<message>

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

Run `git status` after to confirm success. Report the commit hash and summary to the user.
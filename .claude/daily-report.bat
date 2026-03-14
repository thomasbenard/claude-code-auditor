@echo off
cd /d C:\Users\Thomas\workspace\claude-code-book
claude -p "run /daily-report" --model sonnet --allowedTools "Read,Write,Edit,Glob,WebSearch,WebFetch,Bash(git add:*),Bash(git commit:*),Bash(git push),Bash(git status),Bash(date *),Bash(find .git *)"

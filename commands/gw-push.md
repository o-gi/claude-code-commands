Commit all changes and push to remote.

## Quick Usage

When you type `/user:gh-push`, this command will:

1. Stage all changes
```bash
git add -A
```

2. Create commit with auto-generated message (includes issue reference if found)
```bash
# Extract issue number from current branch name if exists
ISSUE_NUM=$(git branch --show-current | grep -oE '[0-9]+' | head -1)
if [ -n "$ISSUE_NUM" ]; then
    git commit -m "generated message based on changes

This implements issue #$ISSUE_NUM"
else
    git commit -m "generated message based on changes"
fi
```

3. Push to current branch
```bash
git push -u origin $(git branch --show-current)
```

4. Create or update PR if needed

## With Arguments

- `$ARGUMENTS` - Use as commit message
- Example: `/user:gh-push fix login bug` → commits with "fix login bug"

## Important

This is a shortcut for quick commits. For more control, use:
- `/user:gw:push` - Full featured push with PR options
- `gt:push` - Traditional trigger approach
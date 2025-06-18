Commit all changes and push to remote.

## Quick Usage

When you type `/user:gh-push`, this command will:

1. Stage all changes
```bash
git add -A
```

2. Create commit with auto-generated message
```bash
git commit -m "generated message based on changes"
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
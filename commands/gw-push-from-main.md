Create a new branch from main and push with PR creation.

## Usage

```
/user:gw-push-from-main [branch-name-or-description]
```

## Examples

```bash
# Auto-generate branch name from changes
/user:gw-push-from-main

# Use specified branch name
/user:gw-push-from-main feat-user-auth

# Use description (will be converted to branch name)
/user:gw-push-from-main "add user authentication"
```

## Workflow

1. **Check current branch**
   - Must be on main/master branch
   - Error if already on feature branch

2. **Analyze changes**
   ```bash
   git status --porcelain
   git diff --staged --name-only
   ```

3. **Generate or use branch name**
   - If no argument: Generate from changes
   - If argument provided: Use as branch name or convert description
   - Format: `feat-`, `fix-`, `refactor-` prefix based on changes

4. **Create and switch to new branch**
   ```bash
   git checkout -b <branch-name>
   ```

5. **Stage and commit changes**
   ```bash
   git add -A
   # Extract issue number from branch name if exists
   ISSUE_NUM=$(echo "<branch-name>" | grep -oE '[0-9]+' | head -1)
   if [ -n "$ISSUE_NUM" ]; then
       git commit -m "feat: <description based on changes>

This implements issue #$ISSUE_NUM"
   else
       git commit -m "feat: <description based on changes>"
   fi
   ```

6. **Push to remote**
   ```bash
   git push -u origin <branch-name>
   ```

7. **Create PR**
   ```bash
   gh pr create --title "<title>" --body "<body with details>"
   ```

## Branch Name Generation Rules

1. **From file changes**:
   - New files → `feat-`
   - Bug fixes → `fix-`
   - Refactoring → `refactor-`
   - Documentation → `docs-`

2. **From description**:
   - "add X" → `feat-X`
   - "fix X" → `fix-X`
   - "update X" → `feat-update-X`
   - Convert spaces to hyphens
   - Remove special characters

3. **Fallback**:
   - Use timestamp: `feat-2024-01-15-1234`

## Safety Checks

- ✅ Only works from main/master branch
- ✅ Checks for uncommitted changes
- ✅ Validates branch name format
- ✅ Confirms before creating PR
- ✅ Shows what will be done before execution

## Error Handling

- Not on main branch → Error with instructions
- No changes to commit → Error
- Branch already exists → Suggest alternative
- Network issues → Retry or manual steps

## Implementation Steps

1. Get current branch and verify it's main/master
2. Check for changes using git status
3. Generate or validate branch name
4. Create new branch
5. Add all changes and commit
6. Push to remote
7. Create PR using gh CLI

## Notes

- Always creates PR against main/master
- Uses conventional commit format
- Preserves all local changes
- Safe operation (no force push)
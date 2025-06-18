# gw-pr-sync - Sync PR with latest main branch

Sync a pull request with the latest changes from the main branch.

## Usage
```
/user:gw-pr-sync [PR-number]
```

## Workflow

1. **Get PR Information**
   ```bash
   PR_NUM=$1
   PR_INFO=$(gh pr view $PR_NUM --json headRefName,state)
   BRANCH_NAME=$(echo "$PR_INFO" | jq -r '.headRefName')
   PR_STATE=$(echo "$PR_INFO" | jq -r '.state')
   ```

2. **Check PR State**
   ```bash
   if [ "$PR_STATE" != "OPEN" ]; then
     echo "❌ PR #$PR_NUM is not open (state: $PR_STATE)"
     exit 1
   fi
   ```

3. **Navigate to Worktree or Create One**
   ```bash
   WORKTREE_PATH="./worktrees/$BRANCH_NAME"
   
   if [ -d "$WORKTREE_PATH" ]; then
     cd "$WORKTREE_PATH"
     echo "📂 Using existing worktree: $WORKTREE_PATH"
   else
     echo "🌲 Creating new worktree at: $WORKTREE_PATH"
     git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
     cd "$WORKTREE_PATH"
   fi
   ```

4. **Fetch Latest Changes**
   ```bash
   echo "🔄 Fetching latest changes..."
   git fetch origin main
   git fetch origin "$BRANCH_NAME"
   ```

5. **Show Current Status**
   ```bash
   echo "📊 Current branch status:"
   COMMITS_BEHIND=$(git rev-list --count HEAD..origin/main)
   COMMITS_AHEAD=$(git rev-list --count origin/main..HEAD)
   echo "  Behind main: $COMMITS_BEHIND commits"
   echo "  Ahead of main: $COMMITS_AHEAD commits"
   ```

6. **Perform Rebase**
   ```bash
   echo "🔄 Rebasing onto origin/main..."
   git rebase origin/main
   ```

7. **Handle Conflicts (if any)**
   ```bash
   if [ $? -ne 0 ]; then
     echo "⚠️  Rebase conflicts detected!"
     echo "Please resolve conflicts and then run:"
     echo "  git rebase --continue"
     echo "  git push --force-with-lease origin $BRANCH_NAME"
     exit 1
   fi
   ```

8. **Force Push with Lease**
   ```bash
   echo "📤 Pushing rebased branch..."
   git push --force-with-lease origin "$BRANCH_NAME"
   ```

9. **Update PR Comment**
   ```bash
   gh pr comment $PR_NUM --body "🔄 Synced with latest main branch"
   ```

10. **Show Final Status**
    ```bash
    echo "✅ PR #$PR_NUM successfully synced with main"
    gh pr view $PR_NUM --web
    ```

## Error Handling

- Check if PR exists and is open
- Handle worktree creation failures
- Handle rebase conflicts gracefully
- Use --force-with-lease for safer force pushes

## Notes

- This command uses rebase to keep a clean history
- If you prefer merge instead of rebase, replace step 6 with:
  ```bash
  git merge origin/main -m "Merge latest main into $BRANCH_NAME"
  ```
- Always uses --force-with-lease for safety
- Automatically opens PR in browser after success
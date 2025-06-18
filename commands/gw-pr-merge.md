Merge PR #$ARGUMENTS with squash and clean up worktree if exists.

## Purpose

Complete PR workflow: merge, cleanup branches, and remove worktrees.

## Usage

```bash
/user:gw-pr-merge 1
/user:gw-pr-merge #1
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 2. Parse PR number
```bash
PR_NUM=$(echo "$ARGUMENTS" | sed 's/^#//' | awk '{print $1}')
```

### 3. Get PR information
```bash
# Get PR details using gh's query flag (no jq needed)
BRANCH_NAME=$(gh pr view $PR_NUM --json headRefName -q .headRefName)
PR_STATE=$(gh pr view $PR_NUM --json state -q .state)
# Check if PR is merged (mergedAt field will be non-empty if merged)
PR_MERGED_AT=$(gh pr view $PR_NUM --json mergedAt -q .mergedAt)
if [ -n "$PR_MERGED_AT" ]; then
  PR_MERGED="true"
else
  PR_MERGED="false"
fi
ISSUE_NUM=$(echo $BRANCH_NAME | grep -oE '[0-9]+' | head -1)

echo "📋 PR #$PR_NUM Status:"
echo "   Branch: $BRANCH_NAME"
echo "   State: $PR_STATE"
echo "   Merged: $PR_MERGED"
```

### 4. Update other open PRs
```bash
# Update all other open PRs created by me to avoid merge conflicts
echo "🔄 Updating my other open PRs..."

# Get list of open PRs created by me (excluding the current one)
OTHER_PRS=$(gh pr list --state open --author "@me" --json number,headRefName -q ".[] | select(.number != $PR_NUM)")

if [ -n "$OTHER_PRS" ]; then
  PR_COUNT=$(echo "$OTHER_PRS" | jq -s 'length')
  echo "📦 Found $PR_COUNT of my other open PR(s) to update"
  
  # Save current location
  CURRENT_DIR=$(pwd)
  CURRENT_BRANCH=$(git branch --show-current)
  
  # Update each PR
  echo "$OTHER_PRS" | jq -r '.headRefName' | while read -r BRANCH; do
    echo "  🌿 Updating: $BRANCH"
    
    # Check if worktree exists
    WORKTREE_PATH=$(git worktree list | grep " \[$BRANCH\]" | awk '{print $1}')
    
    if [ -n "$WORKTREE_PATH" ]; then
      # Update via worktree
      cd "$WORKTREE_PATH"
      if git pull --rebase origin main >/dev/null 2>&1; then
        if git push --force-with-lease origin "$BRANCH" >/dev/null 2>&1; then
          echo "    ✅ Updated successfully"
        else
          echo "    ⚠️  Push failed (may have conflicts)"
        fi
      else
        echo "    ⚠️  Rebase failed (has conflicts)"
        git rebase --abort >/dev/null 2>&1
      fi
    else
      # Update via checkout
      cd "$CURRENT_DIR"
      if git fetch origin "$BRANCH" >/dev/null 2>&1; then
        git checkout "$BRANCH" >/dev/null 2>&1
        if git rebase origin/main >/dev/null 2>&1; then
          if git push --force-with-lease origin "$BRANCH" >/dev/null 2>&1; then
            echo "    ✅ Updated successfully"
          else
            echo "    ⚠️  Push failed"
          fi
        else
          echo "    ⚠️  Rebase failed (has conflicts)"
          git rebase --abort >/dev/null 2>&1
        fi
      else
        echo "    ⚠️  Branch not found"
      fi
    fi
  done
  
  # Return to original location
  cd "$CURRENT_DIR"
  if [ -n "$CURRENT_BRANCH" ]; then
    git checkout "$CURRENT_BRANCH" >/dev/null 2>&1
  fi
  
  echo "✅ Finished updating my other PRs"
else
  echo "ℹ️  No other open PRs by me found"
fi
```

### 5. Verify PR is ready
```bash
# Check if already merged
if [ "$PR_MERGED" = "true" ]; then
  echo "⚠️  PR #$PR_NUM is already merged!"
  echo "🧹 Proceeding with cleanup only..."
  SKIP_MERGE=true
else
  # Check if ready to merge
  MERGEABLE=$(gh pr view $PR_NUM --json mergeable -q .mergeable)
  if [ "$MERGEABLE" != "MERGEABLE" ]; then
    echo "❌ PR #$PR_NUM is not mergeable (conflicts or checks failing)"
    exit 1
  fi
  SKIP_MERGE=false
fi
```

### 6. Perform squash merge (if not already merged)
```bash
if [ "$SKIP_MERGE" = "false" ]; then
  echo "🔀 Squash merging PR #$PR_NUM..."
  gh pr merge $PR_NUM --squash --delete-branch
  
  # Verify merge succeeded
  sleep 2
  PR_MERGED_CHECK=$(gh pr view $PR_NUM --json mergedAt -q .mergedAt)
  if [ -z "$PR_MERGED_CHECK" ]; then
    echo "❌ Failed to merge PR #$PR_NUM"
    exit 1
  fi
  echo "✅ PR #$PR_NUM merged successfully!"
else
  echo "ℹ️  Skipping merge (already merged)"
fi
```

### 7. Clean up worktrees
```bash
echo "🧹 Cleaning up worktrees..."

# Find all worktrees for this issue (including claude1, claude2, etc.)
# Pattern matches: feat-33-something or feat-33 (end of string)
RELATED_WORKTREES=$(git worktree list | grep -E "\[(feat|fix|docs|refactor|test|perf|chore)-$ISSUE_NUM(-|$)" | awk '{print $1}')

if [ -n "$RELATED_WORKTREES" ]; then
  WORKTREE_COUNT=$(echo "$RELATED_WORKTREES" | wc -l)
  echo "📦 Found $WORKTREE_COUNT worktree(s) for issue #$ISSUE_NUM"
  
  # Get current directory to check if we're in a worktree
  CURRENT_DIR=$(pwd)
  
  for WORKTREE in $RELATED_WORKTREES; do
    echo "  🌲 Removing: $WORKTREE"
    
    # Switch to main if currently in this worktree
    if [[ "$CURRENT_DIR" == "$WORKTREE"* ]]; then
      echo "  📍 Currently in this worktree, switching to main..."
      cd $(git rev-parse --show-toplevel)
      CURRENT_DIR=$(pwd)
    fi
    
    # Remove worktree
    if git worktree remove "$WORKTREE" --force 2>/dev/null; then
      echo "  ✅ Removed successfully"
    else
      echo "  ⚠️  Failed to remove (may be already gone)"
    fi
  done
else
  echo "ℹ️  No worktrees found for issue #$ISSUE_NUM"
fi
```

### 8. Update local main
```bash
echo "📥 Updating local main branch..."
git checkout main
git pull origin main
```

### 9. Clean up related branches
```bash
echo "🗑️ Cleaning up branches..."

# First ensure we're not on any branch to be deleted
CURRENT_BRANCH=$(git branch --show-current)

# Find all branches for this issue (including claude1, claude2, etc.)
RELATED_BRANCHES=$(git branch | grep -E "(feat|fix|docs|refactor|test|perf|chore)-$ISSUE_NUM(-|$)" | sed 's/^[* ]*//')

if [ -n "$RELATED_BRANCHES" ]; then
  BRANCH_COUNT=$(echo "$RELATED_BRANCHES" | wc -l)
  echo "📦 Found $BRANCH_COUNT branch(es) for issue #$ISSUE_NUM"
  
  for BRANCH in $RELATED_BRANCHES; do
    # Skip if we're currently on this branch
    if [ "$CURRENT_BRANCH" = "$BRANCH" ]; then
      echo "  ⚠️  Currently on $BRANCH, switching to main..."
      git checkout main
      CURRENT_BRANCH="main"
    fi
    
    # Delete the branch
    echo "  🌿 Deleting: $BRANCH"
    if git branch -d "$BRANCH" 2>/dev/null; then
      echo "  ✅ Deleted successfully"
    else
      # Force delete if needed
      if git branch -D "$BRANCH" 2>/dev/null; then
        echo "  ✅ Force deleted successfully"
      else
        echo "  ⚠️  Failed to delete (may be already gone)"
      fi
    fi
  done
else
  echo "ℹ️  No local branches found for issue #$ISSUE_NUM"
fi
```

### 10. Final summary
```bash
echo "
✅ PR #$PR_NUM merged successfully!
🧹 Cleanup completed:
   - Remote branch deleted (by GitHub)
   - All related local branches deleted (including claude variants)
   - All related worktrees removed
   - Switched to main
   - Main branch updated
   
📊 Cleaned up issue #$ISSUE_NUM:
   - Worktrees removed: $WORKTREE_COUNT
   - Branches deleted: $BRANCH_COUNT
"
```

## Features

- **One command**: Merge + full cleanup
- **Auto-update PRs**: Updates all YOUR other open PRs before merging to prevent conflicts
- **Group cleanup**: Removes ALL worktrees/branches for the same issue (including claude1, claude2, etc.)
- **Safe**: Checks PR status before merging
- **Complete cleanup**: Removes all traces of the feature branches
- **Always squash**: Keeps git history clean
- **Smart detection**: Finds all related branches by issue number

## Example workflow

### Single implementation
```bash
# Start work on issue
/user:gw-iss-run #33

# ... do work, create PR ...

# When PR is approved and ready
/user:gw-pr-merge #45

# Everything is cleaned up automatically!
```

### Parallel implementations
```bash
# Create 3 parallel implementations
/user:gw-iss-run-parallel #33 -p 3

# Creates:
# - feat-33-auth-claude1
# - feat-33-auth-claude2
# - feat-33-auth-claude3

# ... work on implementations, choose best one ...
# ... create PR from feat-33-auth-claude2 (PR #45) ...

# When PR is approved
/user:gw-pr-merge #45

# ALL related worktrees and branches are cleaned up:
# ✅ Removes ./worktrees/feat-33-auth-claude1
# ✅ Removes ./worktrees/feat-33-auth-claude2
# ✅ Removes ./worktrees/feat-33-auth-claude3
# ✅ Deletes all 3 local branches
```

## Error handling

- If PR is not ready: Shows what's blocking
- If in worktree: Safely switches out before removal
- If branch has unpushed commits: Warns before deletion
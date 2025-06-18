Check progress of parallel implementations for an issue.

ISSUE_NUMBER: Issue number (e.g., 123 or #123)

## Purpose

Display the status of all worktrees/branches working on a specific issue, including commit counts, last activity, and current branch status. Works with branches created by any gw command, not just parallel implementations.

## Usage

```bash
/user:gw-iss-status 33      # Show status for issue #33
/user:gw-iss-status #33     # Same with # prefix
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Parse issue number
```bash
ISSUE_NUM=$(echo "$ARGUMENTS" | sed 's/^#//' | awk '{print $1}')
```

### 2. Find all related branches
```bash
echo "🔍 Checking branches for issue #$ISSUE_NUM..."

# Find all branches related to this issue
BRANCHES=$(git branch -a | grep -E "(feat|fix|docs|refactor|test|perf|chore)-$ISSUE_NUM-" | sed 's/^[* ]*//' | sed 's/remotes\/origin\///' | sort -u)

if [ -z "$BRANCHES" ]; then
  echo "❌ No branches found for issue #$ISSUE_NUM"
  exit 1
fi

# Count branches
BRANCH_COUNT=$(echo "$BRANCHES" | wc -l)
echo "📊 Found $BRANCH_COUNT branch(es)"
echo ""
```

### 3. Check each branch status
```bash
# Current branch for comparison
CURRENT_BRANCH=$(git branch --show-current)

for BRANCH in $BRANCHES; do
  # Skip remote tracking branches if local exists
  if [[ "$BRANCH" == "remotes/origin/"* ]]; then
    LOCAL_BRANCH=${BRANCH#remotes/origin/}
    if echo "$BRANCHES" | grep -q "^$LOCAL_BRANCH$"; then
      continue
    fi
    BRANCH=$LOCAL_BRANCH
  fi
  
  # Extract variant number if present
  if [[ "$BRANCH" =~ -claude([0-9]+)$ ]]; then
    VARIANT="claude${BASH_REMATCH[1]}"
  elif [[ "$BRANCH" =~ -v([0-9]+)$ ]]; then
    # Legacy support for old v1, v2 format
    VARIANT="v${BASH_REMATCH[1]}"
  else
    VARIANT="main"
  fi
  
  # Branch indicator
  if [ "$BRANCH" == "$CURRENT_BRANCH" ]; then
    INDICATOR="→"
  else
    INDICATOR=" "
  fi
  
  echo "$INDICATOR 🌿 $BRANCH ($VARIANT)"
  
  # Check if worktree exists
  WORKTREE_PATH=$(git worktree list | grep " \[$BRANCH\]" | awk '{print $1}')
  if [ -n "$WORKTREE_PATH" ]; then
    echo "    📁 Worktree: $WORKTREE_PATH"
  else
    echo "    📁 Worktree: none"
  fi
  
  # Get last commit
  LAST_COMMIT=$(git log -1 --pretty=format:"%h %s" $BRANCH 2>/dev/null || echo "No commits yet")
  LAST_COMMIT_TIME=$(git log -1 --pretty=format:"%ar" $BRANCH 2>/dev/null || echo "")
  echo "    📝 Last: $LAST_COMMIT"
  if [ -n "$LAST_COMMIT_TIME" ]; then
    echo "    ⏰ When: $LAST_COMMIT_TIME"
  fi
  
  # Count commits ahead of main
  COMMITS_AHEAD=$(git rev-list --count origin/main..$BRANCH 2>/dev/null || echo "0")
  if [ "$COMMITS_AHEAD" == "0" ]; then
    echo "    📊 Progress: No new commits"
  else
    echo "    📊 Progress: $COMMITS_AHEAD commits ahead"
  fi
  
  # Check if pushed to remote
  if git ls-remote --exit-code --heads origin $BRANCH >/dev/null 2>&1; then
    # Get push status
    BEHIND=$(git rev-list --count $BRANCH..origin/$BRANCH 2>/dev/null || echo "0")
    AHEAD=$(git rev-list --count origin/$BRANCH..$BRANCH 2>/dev/null || echo "0")
    
    if [ "$BEHIND" == "0" ] && [ "$AHEAD" == "0" ]; then
      echo "    🔄 Remote: ✅ Up to date"
    elif [ "$AHEAD" != "0" ]; then
      echo "    🔄 Remote: ⚠️  $AHEAD commits not pushed"
    else
      echo "    🔄 Remote: ⚠️  $BEHIND commits behind"
    fi
  else
    echo "    🔄 Remote: ❌ Not pushed"
  fi
  
  # Check for PR
  PR_NUMBER=$(gh pr list --head $BRANCH --json number -q '.[0].number' 2>/dev/null)
  if [ -n "$PR_NUMBER" ]; then
    PR_STATE=$(gh pr view $PR_NUMBER --json state -q '.state' 2>/dev/null)
    echo "    🔗 PR: #$PR_NUMBER ($PR_STATE)"
  else
    echo "    🔗 PR: None"
  fi
  
  # Check for uncommitted changes if worktree exists
  if [ -n "$WORKTREE_PATH" ] && [ -d "$WORKTREE_PATH" ]; then
    CHANGES=$(cd "$WORKTREE_PATH" && git status --porcelain 2>/dev/null | wc -l)
    if [ "$CHANGES" -gt 0 ]; then
      echo "    ⚠️  Changes: $CHANGES uncommitted files"
    else
      echo "    ✅ Changes: Clean"
    fi
  fi
  
  echo ""
done
```

### 4. Show summary
```bash
echo "📊 Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count statuses
UNPUSHED_COUNT=0
PR_COUNT=0
WORKTREE_COUNT=0

for BRANCH in $BRANCHES; do
  # Skip remote tracking branches if local exists
  if [[ "$BRANCH" == "remotes/origin/"* ]]; then
    LOCAL_BRANCH=${BRANCH#remotes/origin/}
    if echo "$BRANCHES" | grep -q "^$LOCAL_BRANCH$"; then
      continue
    fi
    BRANCH=$LOCAL_BRANCH
  fi
  
  # Count unpushed
  if ! git ls-remote --exit-code --heads origin $BRANCH >/dev/null 2>&1; then
    ((UNPUSHED_COUNT++))
  fi
  
  # Count PRs
  if gh pr list --head $BRANCH --json number -q '.[0].number' >/dev/null 2>&1; then
    ((PR_COUNT++))
  fi
  
  # Count worktrees
  if git worktree list | grep -q " \[$BRANCH\]"; then
    ((WORKTREE_COUNT++))
  fi
done

echo "• Total branches: $BRANCH_COUNT"
echo "• Active worktrees: $WORKTREE_COUNT"
echo "• Unpushed branches: $UNPUSHED_COUNT"
echo "• Pull requests: $PR_COUNT"

# Find branch with most commits
MAX_COMMITS=0
LEADING_BRANCH=""

for BRANCH in $BRANCHES; do
  # Skip remote tracking branches
  if [[ "$BRANCH" == "remotes/origin/"* ]]; then
    continue
  fi
  
  COMMITS=$(git rev-list --count origin/main..$BRANCH 2>/dev/null || echo "0")
  if [ "$COMMITS" -gt "$MAX_COMMITS" ]; then
    MAX_COMMITS=$COMMITS
    LEADING_BRANCH=$BRANCH
  fi
done

if [ -n "$LEADING_BRANCH" ] && [ "$MAX_COMMITS" -gt 0 ]; then
  echo ""
  echo "🏆 Most progress: $LEADING_BRANCH ($MAX_COMMITS commits)"
fi
echo ""

# Recommendations
if [ "$UNPUSHED_COUNT" -gt 0 ]; then
  echo "💡 Recommendations:"
  echo "• Push completed implementations: /user:gw-push"
  echo "• Or clean up abandoned branches: git branch -d <branch-name>"
fi

if [ "$BRANCH_COUNT" -gt 3 ]; then
  echo "• Consider cleaning up old implementation variants"
  echo "• Remove unused worktrees: git worktree remove <path>"
fi
```

### 5. Show next steps
```bash
echo ""
echo "🚀 Next Steps:"
echo "   1. Continue work: cd <worktree-path> && claude"
echo "   2. Compare code: /user:gw-editor -a"
echo "   3. Push chosen implementation: cd <worktree> && /user:gw-push"
echo "   4. Clean up: git worktree remove <worktree-path>"
```

## Example Output

```
◆ [main] claude-5678 @ main

🔍 Checking branches for issue #33...
📊 Found 3 branch(es)

  🌿 feat-33-auth-system-claude1 (claude1)
    📁 Worktree: ./worktrees/feat-33-auth-system-claude1
    📝 Last: a1b2c3d Add JWT authentication
    ⏰ When: 2 hours ago
    📊 Progress: 5 commits ahead
    🔄 Remote: ✅ Up to date
    🔗 PR: #45 (OPEN)
    ✅ Changes: Clean

→ 🌿 feat-33-auth-system-claude2 (claude2)
    📁 Worktree: ./worktrees/feat-33-auth-system-claude2
    📝 Last: d4e5f6g Implement OAuth2 flow
    ⏰ When: 30 minutes ago
    📊 Progress: 3 commits ahead
    🔄 Remote: ❌ Not pushed
    🔗 PR: None
    ⚠️  Changes: 2 uncommitted files

  🌿 feat-33-auth-system-claude3 (claude3)
    📁 Worktree: ./worktrees/feat-33-auth-system-claude3
    📝 Last: 7h8i9j0 Initial branch
    ⏰ When: 3 hours ago
    📊 Progress: No new commits
    🔄 Remote: ❌ Not pushed
    🔗 PR: None

📊 Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• Total branches: 3
• Active worktrees: 3
• Unpushed branches: 2
• Pull requests: 1

🏆 Most progress: feat-33-auth-system-claude1 (5 commits)

💡 Recommendations:
• Push completed implementations: /user:gw-push
• Or clean up abandoned branches: git branch -d <branch-name>

🚀 Next Steps:
   1. Continue work: cd <worktree-path> && claude
   2. Compare code: /user:gw-editor -a
   3. Push chosen implementation: cd <worktree> && /user:gw-push
   4. Clean up: git worktree remove <worktree-path>
```

## Features

- **Branch discovery**: Finds all branches related to the issue
- **Worktree mapping**: Shows which branches have active worktrees
- **Progress tracking**: Shows commits ahead of main
- **Remote status**: Indicates if branches are pushed
- **PR tracking**: Shows associated pull requests
- **Current branch indicator**: Arrow shows which branch you're on
- **Variant detection**: Identifies -claude1, -claude2 suffixes for parallel implementations (legacy -v1, -v2 also supported)

## Use Cases

### Monitor parallel implementations
```bash
# After running gw-iss-run-parallel
/user:gw-iss-status 33

# See which variants have made progress
# Identify which ones are ready to push
```

### Check before cleanup
```bash
# Before removing worktrees
/user:gw-iss-status 33

# Ensure important work is pushed
# Identify abandoned branches
```

### Review implementation progress
```bash
# During development
/user:gw-iss-status 33

# See last commit messages
# Check which variants are active
```

## Notes

- Works with both local and remote branches
- Shows all branches created by any gw command
- Helps identify stale or abandoned implementations
- Useful for deciding which variant to promote to PR
- Current branch marked with arrow (→) for easy identification
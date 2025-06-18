Sync TodoWrite completion status to GitHub issue checkboxes automatically.

## Purpose

When Claude completes tasks in TodoWrite, automatically update the corresponding GitHub issue checkboxes to maintain sync between local work and GitHub tracking.

## Usage

```bash
# Auto-detect issue from current branch and sync
/user:gw-iss-sync

# Specify issue number explicitly
/user:gw-iss-sync 70

# Sync with custom mapping
/user:gw-iss-sync 70 "TypeScript errors" "apps/web でtsc"
```

## Workflow

### 1. Display session info

```bash
source ~/.claude/commands/_session-display.sh
```

### 2. Get issue number

```bash
# From argument or current branch
if [ -n "$1" ] && [[ "$1" =~ ^[0-9]+$ ]]; then
  ISSUE_NUM="$1"
else
  ISSUE_NUM=$(git branch --show-current | grep -oE '[0-9]+' | head -1)
fi

if [ -z "$ISSUE_NUM" ]; then
  echo "❌ No issue number found. Provide issue number or work in issue branch"
  exit 1
fi

echo "🔄 Syncing TodoWrite → GitHub Issue #$ISSUE_NUM"
```

### 3. Get current TodoWrite status

```bash
# Claude should read current TodoWrite and identify completed tasks
echo "📋 Reading TodoWrite status..."

# Map common task patterns between TodoWrite and Issue
# TodoWrite format → GitHub issue format mapping
TASK_MAPPINGS=(
  "TypeScriptエラーを修正:tsc実行・エラー修正"
  "ESLintエラーを修正:eslint実行・エラー修正"
  "現状分析:Analyze current"
  "実装:Implement"
  "テスト:test"
  "PR作成:Create pull request"
)
```

### 4. Smart checkbox update

```bash
# Get current issue body
ISSUE_BODY=$(gh issue view $ISSUE_NUM --json body -q .body)

# For each completed TodoWrite task:
# 1. Find matching checkbox in issue
# 2. Update it to [x]
# 3. Handle variations in task names

# Example: If TodoWrite has "✅ apps/web の TypeScript エラーを修正"
# Match with issue: "- [ ] apps/web でtsc実行・エラー修正"

echo "✅ Updating checkboxes..."

# Update issue with all changes at once
gh issue edit $ISSUE_NUM --body "$UPDATED_BODY"

# Add sync record comment
SYNC_COMMENT="🔄 **TodoWrite Sync** $(date '+%Y-%m-%d %H:%M')

Synced completed tasks:
- ✅ Task 1
- ✅ Task 2
...

Session: \`claude -r $SESSION_ID\`"

gh issue comment $ISSUE_NUM --body "$SYNC_COMMENT"
```

### 5. Commit sync point

```bash
# Optional: Create a sync commit
git add -A
git commit -m "chore: sync TodoWrite status with issue #$ISSUE_NUM

Synced $(echo "$COMPLETED_COUNT") completed tasks

Session: claude -r $SESSION_ID"
```

## Integration with gw-iss commands

This command should be called:
1. After completing major tasks in TodoWrite
2. Before creating PR
3. Periodically during long implementations

Add to gw-iss-run/implement workflows:
```bash
# After implementation work
echo "🔄 Syncing progress with GitHub issue..."
/user:gw-iss-sync
```

## Examples

### Basic sync
```bash
/user:gw-iss-sync
# Automatically detects issue #70 from branch name
# Updates all matching checkboxes
```

### Manual sync with mapping
```bash
/user:gw-iss-sync 70
# Explicitly sync issue #70
```

## Notes

- Handles Japanese/English task name variations
- Creates audit trail with comments
- Session ID included for traceability
- Works with gw-iss-run-parallel workflows
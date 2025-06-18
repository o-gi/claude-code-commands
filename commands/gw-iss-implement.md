Start implementation work on GitHub issue #$ARGUMENTS (local commits only, no push/PR).

**CRITICAL**: This command implements the same bi-directional sync as gw-iss-run but stops at local commits:
1. Import ALL checkboxes from issue (including already completed ones marked with [x])
2. Create TodoWrite tasks with matching states (completed for [x], pending for [ ])
3. When marking tasks complete in TodoWrite, update GitHub issue checkboxes automatically
4. Create commits but DO NOT push or create PR

## Purpose

Begin working on an issue by creating a branch, importing tasks, and implementing locally.
Perfect for when you want to review changes before pushing.

## Usage

```bash
/user:gw-iss-implement 123        # Default: uses worktree
/user:gw-iss-implement #123       # Default: uses worktree
/user:gw-iss-implement 123 -n     # Use traditional branch switch
/user:gw-iss-implement #123 --no-worktree   # Use traditional branch switch
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Parse issue number
```bash
# Remove # if present and extract issue number
ISSUE_NUM=$(echo "$ARGUMENTS" | sed 's/^#//' | awk '{print $1}')
FLAGS=$(echo "$ARGUMENTS" | awk '{$1=""; print $0}')
```

### 2. Fetch issue details
```bash
gh issue view $ISSUE_NUM
```

### 3. Check existing branch and worktree setup
```bash
# Extract flags
USE_WORKTREE=true  # Default to true
COMPLEXITY="normal"

# Parse all flags from the FLAGS variable
for flag in $FLAGS; do
  case $flag in
    -n|--no-worktree)
      USE_WORKTREE=false
      ;;
    --complex)
      COMPLEXITY="complex"
      ;;
  esac
done

# Get repository name
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Generate branch name from issue title
ISSUE_TITLE=$(gh issue view $ISSUE_NUM --json title -q .title)
echo "🤔 Analyzing issue title to generate branch name..."

# IMPORTANT: Claude must generate an appropriate branch name based on the issue title
# Issue title: "$ISSUE_TITLE"
# 
# Branch naming rules for Claude:
# - Choose appropriate prefix: feat-, fix-, docs-, refactor-, test-, perf-, chore-
# - Keep it concise (2-4 words after prefix)
# - Use lowercase and hyphens (NO SLASHES)
# - Be specific but not too long
# - Include issue number when using feat/fix/chore prefixes
# 
# Examples:
# - "rootのREADME更新" → "docs-update-readme"
# - "ログインエラー修正" → "fix-$ISSUE_NUM-login-error"
# - "ユーザー検索機能追加" → "feat-$ISSUE_NUM-add-user-search"
# - "パフォーマンス改善" → "perf-optimize-query-performance"
# - "型定義の修正" → "fix-$ISSUE_NUM-type-definitions"
#
# Claude should understand the intent from the issue title and create a meaningful branch name

# Fallback (Claude will override this during execution)
BRANCH_NAME="feat-$ISSUE_NUM-update"

# Worktree path is same as branch name (no conversion needed!)
WORKTREE_PATH="./worktrees/$BRANCH_NAME"

if [ "$USE_WORKTREE" = true ]; then
  # Check if worktree already exists
  if git worktree list | grep -q "$WORKTREE_PATH"; then
    echo "🔄 Resuming work in existing worktree: $WORKTREE_PATH"
    cd "$WORKTREE_PATH"
  else
    # Check if branch exists
    if git branch -a | grep -q "$BRANCH_NAME"; then
      echo "🌲 Creating worktree for existing branch: $BRANCH_NAME"
      git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
    else
      echo "🌲 Creating new worktree and branch: $BRANCH_NAME"
      git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH"
    fi
    cd "$WORKTREE_PATH"
    echo "📢 Switched to worktree: $WORKTREE_PATH"
    
    # Install dependencies in the new worktree
    echo "📦 Installing dependencies..."
    pnpm install
    echo "✅ Dependencies installed"
    
    # Sync .env files from main repository
    echo "🔄 Syncing .env files..."
    /user:gw-env-sync
    echo "✅ Environment files synced"
    
    echo "💡 Tip: Open a new terminal tab or VS Code window for this worktree"
  fi
else
  # Traditional branch checkout
  EXISTING_BRANCH=$(git branch -a | grep -E "(feat|fix|chore)-$ISSUE_NUM-" | head -1)
  if [ -n "$EXISTING_BRANCH" ]; then
    echo "🔄 Resuming work on existing branch: $EXISTING_BRANCH"
    git checkout $EXISTING_BRANCH
  else
    echo "🌱 Creating new branch: $BRANCH_NAME"
    git checkout -b "$BRANCH_NAME"
  fi
fi
```

### 4. Smart import checkboxes to TodoWrite

**IMPORTANT**: Claude must implement the following logic when processing this command:

1. **Fetch issue body and parse ALL checkboxes**:
   ```bash
   # Get issue body
   ISSUE_BODY=$(gh issue view $ISSUE_NUM --json body -q .body)
   ```

2. **Parse checkboxes with their states**:
   - Extract all `- [ ]` (unchecked) items
   - Extract all `- [x]` (completed) items
   - Preserve the exact task text for matching

3. **Import to TodoWrite with proper states**:
   - For `- [x]` items → Create with status: `completed`
   - For `- [ ]` items → Create with status: `pending`
   - Use meaningful IDs (e.g., `issue-1-task-1`)

4. **Handle existing TodoWrite tasks**:
   - Check if TodoWrite already has tasks for this issue
   - If yes, only import new checkboxes not in TodoWrite
   - Update existing task states to match GitHub

5. **Example implementation Claude should follow**:
   ```python
   # Claude should:
   # 1. Read current TodoWrite tasks
   # 2. Parse GitHub issue checkboxes
   # 3. For each checkbox in issue:
   #    - If task exists in TodoWrite: update status to match
   #    - If task is new: add to TodoWrite with correct status
   # 4. Preserve task order from issue
   ```

**Note**: This is NOT bash code - Claude must implement this logic using TodoWrite/TodoRead tools when executing this command.

### 5. Start implementation with smart commits
- Begin with first task
- Update GitHub issue as tasks complete
- **Commit at meaningful points**
- **DO NOT push or create PR**

### 6. Claude implements the solution

**NOW CLAUDE MUST START IMPLEMENTATION:**

```bash
echo "🚀 Starting implementation..."

# Claude should now:
# 1. Read TodoWrite to see all imported tasks
# 2. Start with the first pending task
# 3. Mark it as 'in_progress'
# 4. Implement the feature/fix
# 5. Test the implementation
# 6. Mark as 'completed' when done
# 7. Commit with appropriate message
# 8. Move to next task
# 9. Repeat until all tasks are complete

# IMPORTANT: This is where Claude actively starts coding!
# Claude has full autonomy to:
# - Read and analyze code
# - Create/edit files
# - Run tests
# - Fix errors
# - Make commits
# - Update task status
# - Sync with GitHub issue

echo "💻 Claude is now implementing the solution..."

# KEY DIFFERENCE from gw-iss-run:
# - Creates commits locally but does NOT push
# - Does NOT create PR automatically
# - User reviews locally before pushing
```

**COMPLEXITY HANDLING**:
- If `COMPLEXITY="complex"`:
  - Perform deeper code analysis
  - Break tasks into smaller subtasks
  - Write more comprehensive tests
  - Add extensive error handling
  - Consider performance implications
  - Document complex logic thoroughly
- If `COMPLEXITY="normal"`:
  - Standard implementation approach
  - Good test coverage
  - Standard error handling

## Commit Strategy

### When to commit automatically:

1. **After completing a task**
   ```bash
   # When marking a TodoWrite task as completed
   git add -A
   git commit -m "feat: [Task name from TodoWrite]"
   
   # Example: "feat: Move credentials to env variables"
   ```

2. **After passing tests**
   ```bash
   # If tests pass after fixing
   git add -A
   git commit -m "test: Add/fix tests for [feature]"
   ```

3. **After fixing lint/type errors**
   ```bash
   # If lint/tsc was failing and now passes
   git add -A
   git commit -m "fix: Resolve type/lint issues in [module]"
   ```

4. **Before phase completion**
   ```bash
   # Before running phase checks
   git add -A
   git commit -m "chore: Complete Phase X tasks"
   ```

### Commit message patterns:
- `feat:` - New feature implementation
- `fix:` - Bug fixes
- `refactor:` - Code improvements
- `test:` - Test additions/fixes
- `docs:` - Documentation updates
- `chore:` - Maintenance tasks

### Smart detection:
```bash
# Check if there are uncommitted changes
if [[ -n $(git status -s) ]]; then
  echo "📝 Uncommitted changes detected"
  
  # Analyze what changed
  if git diff --name-only | grep -q "test"; then
    COMMIT_TYPE="test"
  elif git diff --name-only | grep -q "config\|env"; then
    COMMIT_TYPE="chore"
  else
    COMMIT_TYPE="feat"
  fi
  
  echo "💾 Creating commit: $COMMIT_TYPE: $CURRENT_TASK"
  git add -A
  git commit -m "$COMMIT_TYPE: $CURRENT_TASK"
fi
```

## GitHub Issue Checkbox Sync

### Auto-sync features

**IMPORTANT**: Claude must implement bi-directional sync between TodoWrite and GitHub issues.

1. **Task completion sync with auto-commit**
   
   When marking a task as `completed` in TodoWrite, Claude MUST IMMEDIATELY:
   
   a) **Update GitHub issue checkbox IN THE SAME TOOL CALL**:
   ```bash
   # CRITICAL: Claude must run this bash command in the SAME message as TodoWrite update
   # Get current issue body
   ISSUE_BODY=$(gh issue view $ISSUE_NUM --json body -q .body)
   
   # Replace the specific checkbox (exact string match)
   UPDATED_BODY=$(echo "$ISSUE_BODY" | sed "s/- \[ \] $TASK_TEXT/- [x] $TASK_TEXT/")
   
   # Update the issue
   gh issue edit $ISSUE_NUM --body "$UPDATED_BODY"
   ```
   
   **IMPLEMENTATION**: When Claude updates TodoWrite, it MUST include Bash tool call in the same message:
   - TodoWrite tool: Mark task as completed
   - Bash tool: Update GitHub issue checkbox
   Both in ONE message!
   
   b) **Create commit for the completed work**:
   ```bash
   git add -A
   git commit -m "feat: $TASK_TEXT"
   ```
   
   c) **DO NOT push** - Keep commits local only

2. **Phase completion checks**
   When all tasks in a phase are completed:
   ```bash
   # Detect monorepo structure
   if [ -f "pnpm-workspace.yaml" ] || [ -f "lerna.json" ] || [ -f "nx.json" ]; then
     echo "📦 Monorepo detected"
     
     # Find which workspace/app was modified
     MODIFIED_DIRS=$(git diff --name-only | grep -E "^(apps|packages)/[^/]+/" | cut -d'/' -f1,2 | sort -u)
     
     for DIR in $MODIFIED_DIRS; do
       echo "🔍 Checking $DIR..."
       
       # TypeScript check (if tsconfig exists)
       if [ -f "$DIR/tsconfig.json" ]; then
         echo "Running TypeScript check in $DIR"
         cd $DIR && npx tsc --noEmit
         cd - > /dev/null
       fi
       
       # ESLint check (if package.json has lint script)
       if [ -f "$DIR/package.json" ] && grep -q '"lint"' "$DIR/package.json"; then
         echo "Running lint in $DIR"
         pnpm --filter "./$DIR" lint
       fi
       
       # Test (if package.json has test script)
       if [ -f "$DIR/package.json" ] && grep -q '"test"' "$DIR/package.json"; then
         echo "Running tests in $DIR"
         pnpm --filter "./$DIR" test
       fi
     done
   else
     # Single project - run globally
     echo "📋 Single project detected"
     npx tsc --noEmit
     pnpm run lint
     pnpm test
   fi
   
   # If all pass, add completion comment
   gh issue comment $ISSUE_NUM --body "✅ Phase X completed
   ✓ Type check passed
   ✓ Lint check passed
   ✓ Tests passed"
   ```

### Sync Example

**GitHub Issue #1 contains**:
```markdown
- [x] Create issue on GitHub
- [x] Setup git worktree and branch  
- [ ] Analyze existing code structure
- [ ] Implement core functionality
- [ ] Add tests
```

**TodoWrite should import as**:
```javascript
[
  { content: "Create issue on GitHub", status: "completed", id: "issue-1-1" },
  { content: "Setup git worktree and branch", status: "completed", id: "issue-1-2" },
  { content: "Analyze existing code structure", status: "pending", id: "issue-1-3" },
  { content: "Implement core functionality", status: "pending", id: "issue-1-4" },
  { content: "Add tests", status: "pending", id: "issue-1-5" }
]
```

**When task 3 is marked complete in TodoWrite**:
1. GitHub issue checkbox updated: `- [x] Analyze existing code structure`
2. Commit created: `git commit -m "feat: Analyze existing code structure"`
3. NO push - changes remain local
4. TodoWrite shows 3/5 tasks complete, matching GitHub's checkboxes

## Options

- `-n` or `--no-worktree`: Use traditional branch switching instead of worktree
  - Switches branches in current directory
  - No separate directory created
  - Cannot work on multiple issues in parallel
  - Saves disk space

- `--complex`: Indicates this is a complex task requiring deeper analysis
  - More thorough code analysis
  - Breaks implementation into smaller steps
  - More comprehensive testing
  - Better error handling
  - Performance considerations

## Monorepo Support

### Auto-detection
The command automatically detects monorepo by checking for:
- `pnpm-workspace.yaml`
- `lerna.json`
- `nx.json`
- `turbo.json`

### Workspace-specific checks
For monorepos, only runs checks in modified workspaces:
```bash
# Example: If you modified apps/web/
pnpm --filter ./apps/web lint
pnpm --filter ./apps/web test
cd apps/web && npx tsc --noEmit
```

## Worktree Management

### Benefits of using worktree (default):
1. **Parallel Development**: Work on multiple issues simultaneously
2. **Clean Separation**: Each issue has its own directory
3. **No Context Switching**: No need to stash/commit when switching tasks
4. **Multiple Claude Sessions**: Run different Claude instances per worktree

### Worktree workflow (default):
```bash
# Terminal 1: Work on authentication issue
/user:gw-iss-implement #1
# Claude Code can now work in ./worktrees/feat-1-auth

# Terminal 2: Work on UI issue (parallel)
/user:gw-iss-implement #2
# Claude Code can now work in ./worktrees/feat-2-ui

# When done, push and create PR manually:
git push -u origin feat-1-auth
/user:gw-pr-create
```

## What Happens at Completion

### When all tasks are completed

Unlike `gw-iss-run`, this command does NOT automatically push or create PR.

```bash
# MANDATORY: Sync final progress to GitHub issue
echo "🔄 Syncing final progress to GitHub issue..."
/user:gw-iss-sync
echo "✅ Issue checkboxes updated"

echo "🎉 All tasks completed!"
echo "📝 Local commits created successfully"
echo ""
echo "Next steps:"
echo "1. Review changes locally"
echo "2. When ready to push: git push -u origin $BRANCH_NAME"
echo "3. Create PR: /user:gw-pr-create"
```

### Summary display
```bash
# Show what was done
echo "Summary:"
echo "- Branch: $BRANCH_NAME"
echo "- Commits: $(git rev-list --count origin/$(git branch --show-current)..HEAD 2>/dev/null || echo "X")"
echo "- Changed files: $(git diff --name-only origin/$(git branch --show-current)..HEAD 2>/dev/null | wc -l || echo "X")"
echo "- All tasks synced with GitHub issue #$ISSUE_NUM"
```

## Differences from gw-iss-run

| Feature | gw-iss-implement | gw-iss-run |
|---------|------------------|------------|
| Create branch/worktree | ✅ | ✅ |
| Import issue tasks | ✅ | ✅ |
| Implement solution | ✅ | ✅ |
| Create commits | ✅ | ✅ |
| Sync GitHub checkboxes | ✅ | ✅ |
| Push to remote | ❌ | ✅ |
| Create PR | ❌ | ✅ |

## Error handling

If type check, lint, or tests fail:
- Mark the task as pending again
- Show which workspace failed
- Show error details
- Continue after fixes
- Remind user to fix before pushing
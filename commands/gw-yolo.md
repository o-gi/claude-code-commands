One-shot command: Claude Code plans, creates issue, implements solution, and creates PR through consultation.

## ⚠️ MANDATORY WORKFLOW ORDER ⚠️
**NEVER SKIP OR REORDER THESE STEPS:**
1. Create GitHub issue FIRST
2. Extract issue number from URL
3. Create worktree with issue-based branch name
4. ONLY THEN start implementation with TodoWrite

**IF YOU START WITH TODOWRITE, YOU ARE DOING IT WRONG!**

## Purpose

Give Claude Code a task description, and it will:

**Default (Consultation Mode)**:
1. **ANALYZE & PLAN** - Present comprehensive implementation plan
2. **GET APPROVAL** - User reviews and can modify the plan
3. **CREATE GITHUB ISSUE** (MUST BE FIRST - NO TODOWRITE YET!)
4. **EXTRACT ISSUE NUMBER** (from the created issue URL)
5. **CREATE WORKTREE** (using issue number in branch name)
6. **START TODOWRITE** (ONLY AFTER steps 1-3 are complete)
7. Actually implement the solution
8. Run tests and checks
9. Create PR when ready

**With -f/--force (Immediate Mode)**:
Skip steps 1-2 and proceed directly to issue creation and implementation.

⚠️ DO NOT USE TODOWRITE UNTIL AFTER ISSUE AND WORKTREE ARE CREATED!

All in one command - thoughtful YOLO with quality by default.

## Usage

```bash
# Default: consultation mode with ultrathink analysis (plan before executing)
/user:gw-yolo "Add user authentication with JWT"

# Force immediate execution (skip consultation)
/user:gw-yolo "Add user authentication" -f
/user:gw-yolo "Add user authentication" --force

# Specify thinking level (default: ultrathink)
/user:gw-yolo "fix typo" -l think                          # Basic analysis (~5 min)
/user:gw-yolo "add feature" -l "think hard"                # Moderate analysis (~10 min)  
/user:gw-yolo "refactor API" -l "think harder"             # Deep analysis (~15 min)
/user:gw-yolo "redesign architecture" -l ultrathink        # Deepest analysis (20+ min)

# Exclude original request from issue
/user:gw-yolo "Add sensitive feature" -np
/user:gw-yolo -np "Add sensitive feature" -l "think hard"

# Create draft PR
/user:gw-yolo "experimental feature" --draft

# Combine flags
/user:gw-yolo "fix typo" -f -l think                       # Force + quick analysis
/user:gw-yolo "complex feature" -l ultrathink -np          # Deep analysis + no prompt

# Note: git worktree is ALWAYS used (no -w flag needed)
```

## Workflow

### ⚠️ CRITICAL: WORKFLOW ORDER IS MANDATORY ⚠️

**Default Flow (Consultation Mode)**:
```
USER: /user:gw-yolo "Fix TypeScript errors"
         ↓
[1] ANALYZE & PRESENT PLAN
         ↓
[2] USER APPROVES/MODIFIES
         ↓
[3] CREATE GITHUB ISSUE (#123)
         ↓
[4] EXTRACT ISSUE NUMBER (123)
         ↓
[5] CREATE WORKTREE (./worktrees/fix-123-typescript)
         ↓
[6] CD INTO WORKTREE
         ↓
[7] NOW START TODOWRITE with:
    - Analyze current errors
    - Fix TypeScript errors
    - Fix ESLint errors
    - Run tests
    - Create PR (LAST!)
```

**Force Flow (-f flag)**:
```
USER: /user:gw-yolo "Fix TypeScript errors" -f
         ↓
[Skip to step 3 above]
```

**DO NOT START WITH TODOWRITE!**

### 0. Display session info

```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. FIRST STEP: Create GitHub issue (MANDATORY)

```bash
# Parse arguments flexibly
TASK_DESC=""
INCLUDE_PROMPT=true
THINKING_LEVEL="ultrathink"  # Default to deepest analysis
DRAFT_PR="false"
FORCE_EXECUTE=false  # Default to consultation mode

# Parse all arguments
i=1
for arg in "$@"; do
  case $arg in
    -np|--no-prompt)
      INCLUDE_PROMPT=false
      ;;
    -f|--force)
      FORCE_EXECUTE=true
      ;;
    -l|--level)
      # Get next argument as thinking level
      shift
      THINKING_LEVEL="${1:-ultrathink}"
      # Validate thinking level
      case "$THINKING_LEVEL" in
        "think"|"think hard"|"think harder"|"ultrathink")
          ;;
        *)
          echo "❌ Invalid thinking level: $THINKING_LEVEL"
          echo "Valid levels: think, 'think hard', 'think harder', ultrathink"
          exit 1
          ;;
      esac
      ;;
    --draft)
      DRAFT_PR="true"
      ;;
    *)
      # Collect non-flag arguments as task description
      if [ -z "$TASK_DESC" ]; then
        TASK_DESC="$arg"
      else
        TASK_DESC="$TASK_DESC $arg"
      fi
      ;;
  esac
done

echo "🤖 Claude Code starting: $TASK_DESC"
echo "🧠 Using thinking level: $THINKING_LEVEL"

# Consultation Mode (Default)
if [ "$FORCE_EXECUTE" = false ]; then
  echo "📋 Analyzing your request with '$THINKING_LEVEL' computational budget..."
  echo ""
  
  # Claude analyzes the task and proposes:
  # 1. Complete implementation plan
  # 2. GitHub issue structure
  # 3. Task breakdown
  # 4. Technical approach
  # 5. Potential challenges
  # 6. Time estimate
  
  echo "## 🎯 Implementation Plan"
  echo ""
  echo "**Task**: $TASK_DESC"
  echo "**Estimated Time**: [based on thinking level and complexity]"
  echo ""
  echo "### 📝 Proposed GitHub Issue"
  echo "**Title**: [Generated title]"
  echo "**Type**: Feature/Bug/Chore"
  echo ""
  echo "### 📋 Task Breakdown"
  echo "- [ ] Create GitHub issue and get issue number"
  echo "- [ ] Set up git worktree and branch"
  echo "- [ ] [Specific implementation tasks...]"
  echo "- [ ] Add tests"
  echo "- [ ] Update documentation"
  echo "- [ ] Create pull request"
  echo ""
  echo "### 🏗️ Technical Approach"
  echo "[Detailed technical approach based on analysis]"
  echo ""
  echo "### ⚠️ Potential Challenges"
  echo "[Identified risks and mitigation strategies]"
  echo ""
  echo "### 🔄 Implementation Flow"
  echo "1. Issue Creation → 2. Worktree Setup → 3. Implementation → 4. Testing → 5. PR"
  echo ""
  echo "---"
  echo ""
  echo "What would you like to do?"
  echo "1. Proceed with this plan"
  echo "2. Modify the plan"
  echo "3. Add more details"
  echo "4. Cancel"
  echo ""
  read -p "Choice (1-4): " CHOICE
  
  case $CHOICE in
    1)
      echo "✅ Proceeding with implementation..."
      ;;
    2)
      echo "What would you like to modify?"
      # Allow iterative refinement
      # Claude will update the plan based on feedback
      ;;
    3)
      echo "What additional details would you like to add?"
      # Claude incorporates additional context
      ;;
    4)
      echo "❌ YOLO cancelled"
      exit 0
      ;;
  esac
  
  # Loop until user is satisfied
  # Claude can have multiple rounds of refinement
fi

echo "📝 Step 1: Creating GitHub issue FIRST (required for branch naming)..."

# THIS MUST BE THE FIRST ACTION - NO ANALYSIS BEFORE ISSUE CREATION
# Generate comprehensive issue body with specified thinking level
if [ "$INCLUDE_PROMPT" = true ]; then
  ISSUE_BODY="Session: \`claude -r $SESSION_ID\`

## Overview
$TASK_DESC

## Technical Approach
[Claude analyzes and describes approach]

## Implementation Tasks
- [ ] Create GitHub issue and get issue number
- [ ] Set up git worktree and branch
- [ ] Analyze existing code structure
- [ ] Implement core functionality
- [ ] Add comprehensive tests
- [ ] Update documentation
- [ ] Ensure type safety
- [ ] Run linting and formatting
- [ ] Create pull request

## Acceptance Criteria
- All tests pass
- TypeScript check passes
- ESLint passes
- Feature works as described

---
<details>
<summary>📝 Original Request</summary>

\`\`\`
$TASK_DESC
\`\`\`

Created via: \`/user:gw-yolo\`  
Date: $(date +%Y-%m-%d)
</details>"
else
  # Without original request
  ISSUE_BODY="Session: \`claude -r $SESSION_ID\`

## Overview
$TASK_DESC

## Technical Approach
[Claude analyzes and describes approach]

## Implementation Tasks
- [ ] Create GitHub issue and get issue number
- [ ] Set up git worktree and branch
- [ ] Analyze existing code structure
- [ ] Implement core functionality
- [ ] Add comprehensive tests
- [ ] Update documentation
- [ ] Ensure type safety
- [ ] Run linting and formatting
- [ ] Create pull request

## Acceptance Criteria
- All tests pass
- TypeScript check passes
- ESLint passes
- Feature works as described"
fi

# Create issue - THIS IS ALWAYS FIRST
ISSUE_URL=$(gh issue create --title "$TASK_DESC" --body "$ISSUE_BODY")
ISSUE_NUM=$(echo $ISSUE_URL | grep -oE '[0-9]+$')
echo "✅ Created issue #$ISSUE_NUM"
echo "🔗 $ISSUE_URL"
```

### 1.5. Import GitHub issue checkboxes to TodoWrite

```bash
echo "📋 Importing issue tasks to TodoWrite for synchronization..."

# CRITICAL: Import ALL checkboxes from the created GitHub issue to TodoWrite
# This ensures perfect synchronization throughout the workflow
#
# Claude MUST implement the following logic:
#
# 1. Fetch issue body:
#    ISSUE_BODY=$(gh issue view $ISSUE_NUM --json body -q .body)
#
# 2. Parse ALL checkboxes (both [ ] and [x]):
#    - Extract all checkbox lines with their states
#    - Preserve exact task text for proper matching
#
# 3. Import to TodoWrite with proper states:
#    - First task "Create GitHub issue..." → status: 'completed' (already done)
#    - Second task "Set up git worktree..." → status: 'pending' (will be done next)
#    - All other tasks → status: 'pending'
#    - Use IDs like: issue-$ISSUE_NUM-task-1, issue-$ISSUE_NUM-task-2, etc.
#
# 4. This ensures TodoWrite matches GitHub issue from the start
#
# Example: If issue has these checkboxes:
# - [ ] Create GitHub issue and get issue number
# - [ ] Set up git worktree and branch
# - [ ] Analyze existing code structure
# - [ ] Implement core functionality
#
# TodoWrite should have ALL of them, with the first marked as completed

echo "✅ TodoWrite synchronized with GitHub issue #$ISSUE_NUM"
```

### 2. Create branch and setup (ALWAYS uses worktree)

```bash
# Options already parsed in step 1

# Create branch name
# IMPORTANT: Claude must generate an appropriate branch name based on the task description
echo "🤔 Analyzing task to generate branch name..."

# Claude will analyze the task and generate an appropriate branch name
# Based on: "$TASK_DESC"
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
# - "検索機能追加" → "feat-$ISSUE_NUM-add-search"
# - "テスト追加" → "test-add-user-api-tests"
# - "リファクタリング" → "refactor-clean-auth-logic"
#
# Claude should understand the intent and create a meaningful branch name

# For now, using a simple fallback (Claude will override this during execution)
BRANCH_NAME="feat-$ISSUE_NUM-update"

# ALWAYS use worktree for gw-yolo
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
# Worktree path is same as branch name (no conversion needed!)
WORKTREE_PATH="./worktrees/$BRANCH_NAME"

echo "🌲 Creating worktree for isolated development..."
git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH"
cd "$WORKTREE_PATH"
echo "📁 Working in: $WORKTREE_PATH"

# Install dependencies in the new worktree
echo "📦 Installing dependencies..."
pnpm install
echo "✅ Dependencies installed"

# Sync .env files from main repository
echo "🔄 Syncing .env files..."
/user:gw-env-sync
echo "✅ Environment files synced"

echo "💡 This keeps your main workspace clean while Claude Code works!"
```

### 3. Claude Code implements solution

```bash
echo "📋 Updating TodoWrite task status..."

# ⚠️ CRITICAL: TodoWrite should already have ALL tasks imported from GitHub issue
# By this point:
# - GitHub issue is CREATED ✅
# - Worktree is CREATED ✅
# - TodoWrite has ALL tasks from the issue
#
# Claude MUST now:
# 1. Update the "Set up git worktree and branch" task to 'completed'
# 2. Begin working on the next pending task
# 3. Use incremental sync to keep GitHub issue updated
#
# IMPORTANT: After completing each major task:
# - Mark it as completed in TodoWrite
# - Run: /user:gw-iss-sync to update GitHub issue checkboxes
# This ensures continuous synchronization
# SYNC WORKFLOW:
# - TodoWrite already contains ALL tasks from GitHub issue
# - First task (Create issue) is already marked 'completed' ✅
# - Second task (Set up worktree) should now be marked 'completed' ✅
# - Work through remaining tasks, marking each as 'in_progress' then 'completed'
# - Run /user:gw-iss-sync after major milestones to update GitHub checkboxes

echo "🧠 Analyzing codebase..."
echo "💻 Implementing solution..."

# AUTOMATIC SYNC WITH TODOWRITE:
# Claude MUST sync GitHub issue checkboxes IMMEDIATELY when updating TodoWrite
#
# CRITICAL: When marking a task as completed in TodoWrite, Claude MUST:
# 1. Use TodoWrite tool to mark task as completed
# 2. IN THE SAME MESSAGE, use Bash tool to update GitHub checkbox:
#    ```bash
#    TASK_TEXT="exact task text from TodoWrite"
#    ISSUE_BODY=$(gh issue view $ISSUE_NUM --json body -q .body)
#    UPDATED_BODY=$(echo "$ISSUE_BODY" | sed "s/- \[ \] $TASK_TEXT/- [x] $TASK_TEXT/")
#    gh issue edit $ISSUE_NUM --body "$UPDATED_BODY"
#    ```
# 3. Both tools MUST be called in ONE message for atomic updates
#
# This ensures GitHub issue is ALWAYS in sync with TodoWrite

# THINKING LEVEL HANDLING:
# Based on $THINKING_LEVEL, Claude adjusts analysis depth:
#
# - think: Basic implementation, quick analysis (~5 min)
#   - Simple task breakdown
#   - Basic tests
#   - Single commit for small changes
#
# - think hard: Moderate analysis (~10 min)
#   - Detailed implementation plan
#   - Good test coverage
#   - Logical commit boundaries
#
# - think harder: Deep analysis (~15 min)
#   - Consider edge cases
#   - Comprehensive tests
#   - Performance considerations
#   - Multiple atomic commits
#
# - ultrathink: Deepest analysis (20+ min) - DEFAULT
#   - Architecture considerations
#   - Security implications
#   - Scalability analysis
#   - Extensive test coverage
#   - Detailed documentation
#   - Granular commits with clear purpose

# This is where Claude Code:
# 1. Uses Read/Grep/Glob to understand the codebase
# 2. Uses TodoWrite to track progress (with correct order)
# 3. Uses Edit/Write to implement the solution
# 4. Runs tests incrementally
# 5. Fixes any issues that arise

# Claude will actually implement based on the task description
# This is not simulated - real implementation happens here
```

### 4. Incremental commits

```bash
# Claude commits at logical points:
# - After each major component
# - After adding tests
# - After documentation updates

echo "💾 Committing progress..."
# Claude should commit with issue reference:
# git add -A && git commit -m "feat: implement [component]

This implements issue #$ISSUE_NUM"
```

### 5. Final checks and PR creation

```bash
echo "🔍 Running final checks..."

# Run checks individually and stop on first failure
echo "1/3: TypeScript check..."
if ! npx tsc --noEmit; then
  echo "❌ TypeScript check failed!"
  echo "🔧 Fixing type errors..."
  # Claude should fix type errors here
  exit 1
fi

echo "2/3: ESLint check..."
if ! pnpm -w run lint:fresh; then
  echo "❌ Lint check failed!"
  echo "🔧 Fixing lint errors..."
  # Claude should fix lint errors here
  exit 1
fi

echo "3/3: Running tests..."
if ! pnpm test; then
  echo "❌ Tests failed!"
  echo "🔧 Fixing test failures..."
  # Claude should fix test failures here
  exit 1
fi

# All checks passed
if true; then
  echo "✅ All checks passed"
  
  # MANDATORY: Sync TodoWrite progress to GitHub issue
  echo "🔄 Syncing progress to GitHub issue..."
  /user:gw-iss-sync
  echo "✅ Issue checkboxes updated"

  git push -u origin "$BRANCH_NAME"

  # Create comprehensive PR
  PR_BODY="## Summary
Implements #$ISSUE_NUM: $TASK_DESC

## Changes Made
[Claude lists actual changes made]

## Technical Details
[Claude explains implementation approach]

## Testing
[Claude describes tests added]

## Screenshots/Examples
[If applicable]

Fixes #$ISSUE_NUM"

  # Create PR (draft if requested)
  if [ "$DRAFT_PR" = "true" ]; then
    PR_URL=$(gh pr create --title "$TASK_DESC" --body "$PR_BODY" --draft)
    echo "✅ Created DRAFT PR"
  else
    PR_URL=$(gh pr create --title "$TASK_DESC" --body "$PR_BODY")
    echo "✅ Created PR"
  fi
  echo "🔗 $PR_URL"
fi

# This should never be reached if checks fail
echo "🚫 Should not create PR with failing tests!"
```

### 6. Summary

```bash
echo "
🎉 Task completed by Claude Code!
📋 Issue: #$ISSUE_NUM - $ISSUE_URL
🌿 Branch: $BRANCH_NAME
🌲 Worktree: $WORKTREE_PATH
🔗 PR: #$(echo $PR_URL | grep -oE '[0-9]+$') - $PR_URL
⏱️  Time: [elapsed time]

Claude Code implemented:
- [Summary of what was built]
- [Key files modified]
- [Tests added]"
```

## Examples

### Consultation Mode (Default)

```bash
/user:gw-yolo "Add loading spinner to login form"

🤖 Claude Code starting: Add loading spinner to login form
🧠 Using thinking level: ultrathink
📋 Analyzing your request with 'ultrathink' computational budget...

## 🎯 Implementation Plan

**Task**: Add loading spinner to login form
**Estimated Time**: 30-45 minutes

### 📝 Proposed GitHub Issue
**Title**: Add loading spinner to login form during authentication
**Type**: Feature

### 📋 Task Breakdown
- [ ] Create GitHub issue and get issue number
- [ ] Set up git worktree and branch
- [ ] Locate and analyze LoginForm component
- [ ] Add loading state to form
- [ ] Import/create spinner component
- [ ] Add loading logic during authentication
- [ ] Style spinner appropriately
- [ ] Add tests for loading states
- [ ] Update documentation
- [ ] Create pull request

### 🏗️ Technical Approach
- Use existing UI library's spinner component
- Add isLoading state to LoginForm
- Show spinner during authentication API calls
- Disable form inputs while loading
- Handle error states appropriately

### ⚠️ Potential Challenges
- Ensuring spinner is accessible
- Preventing multiple simultaneous submissions
- Maintaining form state during loading

---

What would you like to do?
1. Proceed with this plan
2. Modify the plan
3. Add more details
4. Cancel

Choice (1-4): 1
✅ Proceeding with implementation...
📝 Step 1: Creating GitHub issue FIRST (required for branch naming)...
✅ Created issue #1
🔗 https://github.com/org/repo/issues/1
🌿 Branch: feat-1-add-loading-spinner
🧠 Analyzing codebase...
💻 Implementing solution...
[... implementation continues ...]
```

### Force Mode (Skip Consultation)

```bash
/user:gw-yolo "Add loading spinner to login form" -f

🤖 Claude Code starting: Add loading spinner to login form
🧠 Using thinking level: ultrathink
📝 Step 1: Creating GitHub issue FIRST (required for branch naming)...
✅ Created issue #1
🔗 https://github.com/org/repo/issues/1
🌿 Branch: feat-1-add-loading-spinner
🧠 Analyzing codebase...
💻 Implementing solution...
  → Found login form at: components/auth/LoginForm.tsx
  → Adding spinner component...
  → Importing from existing UI library...
  → Adding loading state management...
💾 Committing progress...
🔍 Running final checks...
✅ All checks passed
✅ Created PR: https://github.com/org/repo/pull/2

🎉 Task completed by Claude Code!
```

### Complex task with thinking levels

```bash
/user:gw-yolo "Implement real-time notifications with WebSocket" -l ultrathink

🤖 Claude Code starting: Implement real-time notifications with WebSocket
🧠 Using thinking level: ultrathink
📝 Creating detailed issue...
✅ Created issue #2
🔗 https://github.com/org/repo/issues/2
🌲 Working in: ./worktrees/issue-2
🧠 Analyzing codebase with deep architectural analysis...
  → Studying existing API structure...
  → Checking for WebSocket libraries...
💻 Implementing solution...
  → Setting up WebSocket server...
  → Creating notification types...
  → Implementing client-side handlers...
  → Adding reconnection logic...
  → Creating notification UI components...
  → Adding tests for each component...
💾 Committing progress...
  → commit 1: feat: add WebSocket server setup
  → commit 2: feat: implement notification types and handlers
  → commit 3: feat: add client-side WebSocket connection
  → commit 4: test: add comprehensive WebSocket tests
🔍 Running final checks...
✅ All checks passed
✅ Created PR: https://github.com/org/repo/pull/3
```

## Options

- `-f` or `--force`: Skip consultation and execute immediately (old behavior)
  - Useful when you're certain about the task
  - Saves time for simple, well-understood tasks
  - Maintains the original YOLO spirit

- `-l` or `--level`: Control thinking depth (default: ultrathink)
  - `think`: Basic analysis (~5 min) - simple tasks
  - `think hard`: Moderate analysis (~10 min) - standard features
  - `think harder`: Deep analysis (~15 min) - complex features
  - `ultrathink`: Deepest analysis (20+ min) - architectural changes

- `--draft`: Create PR as draft (useful for very large features)

- `-np` or `--no-prompt`: Exclude original request from issue body

**Note**: Git worktree is ALWAYS used - no flag needed. This ensures:

- Main workspace stays clean
- Parallel development is possible
- No interference with other work
- Easy cleanup after completion

## Important Notes

1. **Claude Code does the actual implementation** - not just scaffolding
2. **Smart commits** - Claude commits at logical points
3. **Test-driven** - Claude writes tests alongside implementation
4. **Self-correcting** - If tests fail, Claude fixes them
5. **Context-aware** - Claude studies your codebase patterns

## When to use gw-yolo

- **New features**: "Add user profile page"
- **Bug fixes**: "Fix memory leak in data processing"
- **Refactoring**: "Refactor API client to use async/await"
- **Integrations**: "Add Stripe payment integration"
- **Any task you'd normally implement yourself**

## Limitations

- Very large architectural changes may need human oversight
- Claude follows existing patterns in your codebase
- Complex business logic may need clarification via gw-iss-edit

This is thoughtful "vibe coding" - describe what you want, Claude Code plans it, you approve, then it builds!

## Important: Always Uses Worktree

`gw-yolo` ALWAYS creates a git worktree because:

1. **Isolation**: Claude Code works in a separate directory
2. **Parallel work**: You can continue other work in main directory
3. **Clean separation**: No mixing of different features
4. **Multiple Claude sessions**: Can run multiple gw-yolo commands simultaneously

**Note**: Worktree cleanup is handled by the user after PR merge

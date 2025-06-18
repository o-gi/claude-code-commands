Check CI failures and fix issues for PR #$ARGUMENTS.

## Purpose

View PR status, CI failures, and help fix issues in an existing PR.
Automatically creates and moves to a worktree for isolated PR fixes.

## Usage

```bash
/user:gw-pr-fix 1      # Default: creates worktree for PR fixes
/user:gw-pr-fix #1     # Same with # prefix
/user:gw-pr-fix 1 -n   # Use traditional branch checkout
/user:gw-pr-fix #1 --no-worktree   # Use traditional branch checkout
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 2. Parse PR number and flags
```bash
PR_NUM=$(echo "$ARGUMENTS" | sed 's/^#//' | awk '{print $1}')
FLAGS=$(echo "$ARGUMENTS" | awk '{$1=""; print $0}')

# Extract flags
USE_WORKTREE=true  # Default to true

# Parse all flags from the FLAGS variable
for flag in $FLAGS; do
  case $flag in
    -n|--no-worktree)
      USE_WORKTREE=false
      ;;
  esac
done
```

### 3. Fetch PR details and status
```bash
# Get PR info
PR_INFO=$(gh pr view $PR_NUM --json headRefName,state,statusCheckRollup,mergeable)
BRANCH=$(echo $PR_INFO | jq -r .headRefName)
PR_STATE=$(echo $PR_INFO | jq -r .state)

# Show PR status
echo "📋 PR #$PR_NUM Status"
echo "🌿 Branch: $BRANCH"
echo "📊 State: $PR_STATE"
```

### 4. Check CI status
```bash
# Get check runs
echo -e "\n🔍 CI Status:"
gh pr checks $PR_NUM

# Get detailed failure info
FAILED_CHECKS=$(gh pr checks $PR_NUM --json name,status,conclusion | jq -r '.[] | select(.conclusion=="failure") | .name')

if [ -n "$FAILED_CHECKS" ]; then
  echo -e "\n❌ Failed checks:"
  echo "$FAILED_CHECKS"
fi
```

### 5. Show failure details
```bash
# For each failed check, try to get logs
for CHECK in $FAILED_CHECKS; do
  echo -e "\n📝 Details for: $CHECK"
  
  # Get workflow run logs (if GitHub Actions)
  WORKFLOW_RUN=$(gh run list --branch $BRANCH --limit 1 --json databaseId,status,conclusion | jq -r '.[0]')
  
  if [ "$WORKFLOW_RUN" != "null" ]; then
    RUN_ID=$(echo $WORKFLOW_RUN | jq -r .databaseId)
    
    # Show failed jobs
    echo "Failed jobs in workflow:"
    gh run view $RUN_ID --json jobs | jq -r '.jobs[] | select(.conclusion=="failure") | "- \(.name): \(.conclusion)"'
    
    # Try to get error logs
    echo -e "\n🔴 Error output:"
    gh run view $RUN_ID --log-failed | grep -A 5 -B 5 "Error" | head -50
  fi
done
```

### 6. Common fixes based on failure type

```bash
# Analyze failure patterns
if echo "$FAILED_CHECKS" | grep -q "test"; then
  echo -e "\n🧪 Test failures detected"
  echo "Suggested actions:"
  echo "1. Run tests locally: pnpm test"
  echo "2. Check test logs above for specific failures"
  echo "3. Update test snapshots if needed"
fi

if echo "$FAILED_CHECKS" | grep -q "lint"; then
  echo -e "\n🔧 Lint failures detected"
  echo "Suggested actions:"
  echo "1. Run: pnpm -w run lint:fresh"
  echo "2. Auto-fix issues: pnpm lint:fix"
fi

if echo "$FAILED_CHECKS" | grep -q "typecheck\|tsc"; then
  echo -e "\n📐 TypeScript failures detected"
  echo "Suggested actions:"
  echo "1. Run: npx tsc --noEmit"
  echo "2. Check type errors in the logs above"
fi

if echo "$FAILED_CHECKS" | grep -q "build"; then
  echo -e "\n🏗️ Build failures detected"
  echo "Suggested actions:"
  echo "1. Run: pnpm build"
  echo "2. Check for missing dependencies"
fi
```

### 7. Checkout PR branch for fixes (with worktree support)
```bash
echo -e "\n🔧 Ready to fix?"

# Check if already in the PR's worktree
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "$BRANCH" ]; then
  echo "✅ Already on PR branch: $BRANCH"
  echo "🚀 Ready to fix issues!"
else
  if [ "$USE_WORKTREE" = true ]; then
    # Create worktree for PR
    REPO_NAME=$(basename $(git rev-parse --show-toplevel))
    # Worktree path is same as branch name (no conversion needed!)
    WORKTREE_PATH="./worktrees/$BRANCH"
    
    # Check if worktree already exists
    if git worktree list | grep -q "$WORKTREE_PATH"; then
      echo "🔄 Worktree already exists: $WORKTREE_PATH"
      cd "$WORKTREE_PATH"
      echo "📁 Moved to existing worktree"
      echo "🌿 Now on branch: $(git branch --show-current)"
    else
      echo "🌲 Creating worktree: $WORKTREE_PATH"
      git worktree add "$WORKTREE_PATH" "$BRANCH"
      echo "✅ Worktree created!"
      
      # Automatically change to worktree
      cd "$WORKTREE_PATH"
      echo "📁 Moved to: $WORKTREE_PATH"
      echo "🌿 Now on branch: $(git branch --show-current)"
      
      # Install dependencies in the new worktree
      echo "📦 Installing dependencies..."
      pnpm install
      echo "✅ Dependencies installed"
      
      # Link .env file if it exists in parent directory
      if [ -f "../../.env" ]; then
        ln -s ../../.env .env
        echo "✅ Linked .env file"
      fi
      
      echo "🚀 Ready to fix CI issues!"
    fi
  else
    # Regular checkout
    gh pr checkout $PR_NUM
    echo "✅ Switched to branch: $BRANCH"
    echo "🚀 Ready to fix issues!"
  fi
fi
```

### 8. Fix issues locally until all checks pass
```bash
echo -e "\n🔧 Starting fixes based on CI failures..."

# Detect monorepo and affected packages
if [ -f "pnpm-workspace.yaml" ] || [ -f "lerna.json" ] || [ -f "turbo.json" ]; then
  echo "📦 Monorepo detected - finding affected packages..."
  
  # Get modified files to determine which packages to test
  MODIFIED_FILES=$(git diff --name-only origin/main...HEAD)
  AFFECTED_DIRS=$(echo "$MODIFIED_FILES" | grep -E "^(apps|packages)/[^/]+/" | cut -d'/' -f1,2 | sort -u)
  
  if [ -n "$AFFECTED_DIRS" ]; then
    echo "🎯 Affected packages:"
    echo "$AFFECTED_DIRS"
  fi
fi

# Run local checks iteratively until all pass
MAX_ATTEMPTS=5
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
  echo -e "\n🔄 Attempt $ATTEMPT/$MAX_ATTEMPTS to fix and verify..."
  
  # Claude should fix issues here based on CI failures
  # Using Read, Edit, Write tools
  
  echo -e "\n🧪 Running local checks..."
  ALL_PASSED=true
  
  # 1. TypeScript check
  echo "1/3: TypeScript check..."
  if [ -n "$AFFECTED_DIRS" ]; then
    # Monorepo: check only affected packages
    for DIR in $AFFECTED_DIRS; do
      echo "  Checking $DIR..."
      if ! (cd $DIR && npx tsc --noEmit 2>&1); then
        echo "  ❌ TypeScript failed in $DIR"
        ALL_PASSED=false
      fi
    done
  else
    # Single repo
    if ! npx tsc --noEmit; then
      echo "  ❌ TypeScript check failed"
      ALL_PASSED=false
    fi
  fi
  
  # 2. ESLint check
  echo "2/3: ESLint check..."
  if ! pnpm -w run lint:fresh; then
    echo "  ❌ Lint check failed"
    ALL_PASSED=false
  fi
  
  # 3. Test check
  echo "3/3: Running tests..."
  if [ -n "$AFFECTED_DIRS" ]; then
    # Monorepo: test only affected packages
    for DIR in $AFFECTED_DIRS; do
      echo "  Testing $DIR..."
      if ! pnpm --filter "./$DIR" test; then
        echo "  ❌ Tests failed in $DIR"
        ALL_PASSED=false
      fi
    done
  else
    # Single repo
    if ! pnpm test; then
      echo "  ❌ Tests failed"
      ALL_PASSED=false
    fi
  fi
  
  if [ "$ALL_PASSED" = true ]; then
    echo -e "\n✅ All local checks passed!"
    break
  else
    echo -e "\n⚠️  Some checks failed. Fixing issues..."
    # Claude will analyze and fix the failures
    ATTEMPT=$((ATTEMPT + 1))
  fi
done

if [ "$ALL_PASSED" = true ]; then
  echo -e "\n🎉 Ready to push fixes!"
  
  # Commit all fixes
  git add -A
  git commit -m "fix: resolve CI failures

- Fixed TypeScript errors
- Fixed ESLint warnings
- Fixed failing tests"
  
  # Push to remote
  echo "🚀 Pushing fixes..."
  git push
  
  echo -e "\n✅ Fixes pushed! Monitor CI:"
  echo "gh pr checks $PR_NUM --watch"
else
  echo -e "\n❌ Could not fix all issues after $MAX_ATTEMPTS attempts"
  echo "Manual intervention may be required."
  exit 1
fi
```

## Features

- **CI status overview**: Shows all check statuses
- **Detailed failure logs**: Extracts error messages
- **Smart suggestions**: Provides fix commands based on failure type
- **Worktree support**: Option to create isolated worktree for PR fixes
- **Quick checkout**: Option to checkout PR branch (regular or worktree)
- **Workflow integration**: Works with GitHub Actions

## Example output

```
◆ [main] claude-1234 @ main/apps/web

📋 PR #1 Status
🌿 Branch: fix/1-fix-typescript-eslint-and-test
📊 State: OPEN

🔍 CI Status:
❌ test-web        failing
✅ lint            passing
✅ typecheck       passing

📝 Details for: test-web
Failed jobs in workflow:
- test: failure

🔴 Error output:
FAIL src/app/users/page.test.tsx
  ● Test suite failed to run
    Cannot find module '@/lib/auth'

🧪 Test failures detected
Suggested actions:
1. Run tests locally: pnpm test
2. Check test logs above for specific failures

Use worktree for parallel work? (y/n) y
🌲 Creating worktree: ./worktrees/pr-1
✅ Worktree created!
📁 Moved to: ./worktrees/pr-1
🌿 Now on branch: fix/1-fix-typescript-eslint-and-test
🚀 Ready to fix CI issues!
```

## Advanced usage

### Watch CI status
```bash
# Keep watching until all checks pass
gh pr checks $PR_NUM --watch
```

### Re-run failed checks
```bash
# Re-run all checks
gh workflow run ci.yml --ref $BRANCH

# Or click "Re-run failed jobs" in GitHub UI
```
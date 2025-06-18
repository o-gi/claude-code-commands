Create a pull request with smart defaults based on current branch and commits.

## Purpose

Create a GitHub pull request with intelligent title and description generation.

## Usage

```bash
# Auto-generate PR from branch and commits
/user:gw-pr-create

# With custom title
/user:gw-pr-create "Custom PR title"

# With draft flag
/user:gw-pr-create -d
/user:gw-pr-create --draft
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Gather context
```bash
# Get current branch
BRANCH=$(git branch --show-current)

# Extract issue number if present
ISSUE_NUM=$(echo $BRANCH | grep -oE '[0-9]+' | head -1)

# Get recent commits
COMMITS=$(git log origin/main..HEAD --oneline)

# Count changes
CHANGED_FILES=$(git diff origin/main --name-only | wc -l)
```

### 2. Generate PR title

If no title provided:
```bash
# If issue number exists
if [ -n "$ISSUE_NUM" ]; then
  ISSUE_TITLE=$(gh issue view $ISSUE_NUM --json title -q .title)
  PR_TITLE="$ISSUE_TITLE"
else
  # Use branch name or first commit
  PR_TITLE=$(git log -1 --pretty=%s)
fi
```

### 3. Select base branch

```bash
# Get default branch
DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)

# Get recently active branches (excluding current)
CURRENT_BRANCH=$(git branch --show-current)
RECENT_BRANCHES=$(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/remotes/origin/ | 
                  grep -v "^origin/HEAD" | 
                  sed 's|^origin/||' | 
                  grep -v "^$CURRENT_BRANCH$" | 
                  head -10)

# Build branch menu
echo "🌿 Select base branch for PR:"
echo "1) $DEFAULT_BRANCH (default)"

# Add common branches if they exist
BRANCH_NUM=2
for COMMON_BRANCH in develop staging production; do
  if git show-ref --verify --quiet refs/remotes/origin/$COMMON_BRANCH; then
    echo "$BRANCH_NUM) $COMMON_BRANCH"
    eval "BRANCH_$BRANCH_NUM=$COMMON_BRANCH"
    ((BRANCH_NUM++))
  fi
done

# Add recent branches
echo ""
echo "🔄 Recently active branches:"
for BRANCH in $RECENT_BRANCHES; do
  if [ $BRANCH_NUM -le 9 ]; then
    echo "$BRANCH_NUM) $BRANCH"
    eval "BRANCH_$BRANCH_NUM=$BRANCH"
    ((BRANCH_NUM++))
  fi
done

echo ""
echo "0) Enter custom branch"
echo ""
read -p "Choose base branch [1]: " BRANCH_CHOICE

# Handle selection
if [ -z "$BRANCH_CHOICE" ] || [ "$BRANCH_CHOICE" = "1" ]; then
  BASE_BRANCH=$DEFAULT_BRANCH
elif [ "$BRANCH_CHOICE" = "0" ]; then
  read -p "Enter custom branch name: " BASE_BRANCH
else
  # Dynamic branch selection
  SELECTED_VAR="BRANCH_$BRANCH_CHOICE"
  BASE_BRANCH=${!SELECTED_VAR}
  if [ -z "$BASE_BRANCH" ]; then
    echo "❌ Invalid selection"
    exit 1
  fi
fi

echo "✅ Base branch: $BASE_BRANCH"

# Verify base branch exists
if ! git show-ref --verify --quiet refs/remotes/origin/$BASE_BRANCH; then
  echo "❌ Branch '$BASE_BRANCH' not found on remote"
  exit 1
fi

# Show diff summary
echo ""
echo "📋 Comparing $CURRENT_BRANCH...$BASE_BRANCH:"
# Fetch latest base branch
git fetch origin $BASE_BRANCH --quiet

# Show commit count
COMMIT_COUNT=$(git rev-list --count origin/$BASE_BRANCH..HEAD)
echo "🔢 Commits: $COMMIT_COUNT"

# Show file changes
FILE_CHANGES=$(git diff --stat origin/$BASE_BRANCH...HEAD | tail -1)
echo "📄 $FILE_CHANGES"

# Show commits
echo ""
echo "📦 Recent commits:"
git log origin/$BASE_BRANCH..HEAD --oneline --max-count=5

# Confirm to proceed
echo ""
read -p "🚀 Create PR from $CURRENT_BRANCH to $BASE_BRANCH? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "🚫 PR creation cancelled"
  exit 0
fi
```

### 4. Generate PR body

```markdown
## Summary
[Auto-generated from commits and changes]

## Changes
- Modified X files
- Key changes: [extracted from commits]

## Related Issue
Fixes #$ISSUE_NUM

## Checklist
- [ ] Tests pass
- [ ] TypeScript check passes
- [ ] ESLint passes
- [ ] Documentation updated (if needed)
```

### 5. Smart PR creation

```bash
# Check if PR already exists
EXISTING_PR=$(gh pr list --head $BRANCH --json number -q '.[0].number')

if [ -n "$EXISTING_PR" ]; then
  echo "❌ PR already exists: #$EXISTING_PR"
  echo "Use 'gh pr view $EXISTING_PR' to view"
  exit 1
fi

# Create PR with selected base
if [ "$DRAFT" = true ]; then
  gh pr create --draft --base "$BASE_BRANCH" --title "$PR_TITLE" --body "$PR_BODY"
else
  gh pr create --base "$BASE_BRANCH" --title "$PR_TITLE" --body "$PR_BODY"
fi
```

### 6. Post-creation actions

```bash
# Get created PR number
PR_NUM=$(gh pr list --head $BRANCH --json number -q '.[0].number')

# Add labels if issue had labels
if [ -n "$ISSUE_NUM" ]; then
  LABELS=$(gh issue view $ISSUE_NUM --json labels -q '.labels[].name' | tr '\n' ',')
  if [ -n "$LABELS" ]; then
    gh pr edit $PR_NUM --add-label "$LABELS"
  fi
fi

# Show PR URL
echo "✅ PR created: $(gh pr view $PR_NUM --json url -q .url)"
```

## Features

- **Smart title generation**: From issue or commits
- **Auto-link issues**: Detects issue number from branch
- **Label sync**: Copies labels from related issue
- **Draft support**: Create as draft PR
- **Duplicate prevention**: Won't create if PR exists
- **Rich description**: Includes summary and checklist

## Examples

### Basic usage
```bash
# On branch: fix/1-login-error
/user:gw-pr-create
# Creates: "Fix login error"
```

### With custom title
```bash
/user:gw-pr-create "Refactor authentication system"
# Creates PR with custom title but still links issue
```

### Draft PR
```bash
/user:gw-pr-create -d
# Creates draft PR for work in progress
```
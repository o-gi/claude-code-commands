Open worktree in editor for code review.

## Purpose

Open a git worktree in Cursor/VSCode for local code review. Accepts PR number, issue number, or branch name to locate the appropriate worktree.

## Usage

```bash
# Open by PR number
/user:gw-editor 1
/user:gw-editor pr:1
/user:gw-editor #1

# Open by issue number
/user:gw-editor i2
/user:gw-editor issue:2

# Open by branch name
/user:gw-editor feat-2-improve-images

# Interactive selection
/user:gw-editor

# Open all worktrees
/user:gw-editor --all
/user:gw-editor -a
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Parse arguments
```bash
INPUT="$1"

# Check for --all flag first
OPEN_ALL=false
if [ "$INPUT" = "--all" ] || [ "$INPUT" = "-a" ]; then
  OPEN_ALL=true
  TYPE="all"
else
  # Determine input type
  TYPE=""
  IDENTIFIER=""
  
  if [ -z "$INPUT" ]; then
    # No input - interactive mode
    TYPE="interactive"
  elif [[ "$INPUT" =~ ^#?([0-9]+)$ ]]; then
  # Just a number - assume PR
  TYPE="pr"
  IDENTIFIER="${BASH_REMATCH[1]}"
elif [[ "$INPUT" =~ ^pr:([0-9]+)$ ]] || [[ "$INPUT" =~ ^p([0-9]+)$ ]]; then
  # Explicit PR
  TYPE="pr"
  IDENTIFIER="${BASH_REMATCH[1]}"
elif [[ "$INPUT" =~ ^issue:([0-9]+)$ ]] || [[ "$INPUT" =~ ^i([0-9]+)$ ]]; then
  # Explicit issue
  TYPE="issue"
  IDENTIFIER="${BASH_REMATCH[1]}"
else
    # Assume branch name
    TYPE="branch"
    IDENTIFIER="$INPUT"
  fi
fi

echo "🔍 Input type: $TYPE"
```

### 2. Detect editor
```bash
# Check which editor is available
EDITOR_CMD=""
EDITOR_NAME=""

if command -v cursor &> /dev/null; then
  EDITOR_CMD="cursor"
  EDITOR_NAME="Cursor"
elif command -v code &> /dev/null; then
  EDITOR_CMD="code"
  EDITOR_NAME="VS Code"
else
  echo "❌ Neither Cursor nor VS Code found in PATH"
  echo "💡 Please install Cursor from: https://cursor.sh"
  echo "   Or VS Code from: https://code.visualstudio.com"
  exit 1
fi

echo "📝 Using editor: $EDITOR_NAME"
```

### 3. Handle --all flag
```bash
if [ "$OPEN_ALL" = true ]; then
  echo "🌲 Opening all worktrees in $EDITOR_NAME..."
  
  # Get all worktrees except main
  WORKTREES=$(git worktree list --porcelain | awk '
    /^worktree / { 
      path = substr($0, 10)
      if (path != ".") print path
    }
  ')
  
  if [ -z "$WORKTREES" ]; then
    echo "📭 No worktrees found"
    exit 0
  fi
  
  # Open each worktree
  COUNT=0
  for WORKTREE in $WORKTREES; do
    WORKTREE_NAME=$(basename "$WORKTREE")
    echo "   ✅ Opening $WORKTREE_NAME"
    $EDITOR_CMD -n "$WORKTREE"
    COUNT=$((COUNT + 1))
    sleep 0.5  # Small delay between windows
  done
  
  echo ""
  echo "✨ Opened $COUNT worktree(s) in $EDITOR_NAME"
  exit 0
fi
```

### 4. Resolve to branch name
```bash
BRANCH_NAME=""

case $TYPE in
  pr)
    echo "🔍 Looking up PR #$IDENTIFIER..."
    
    # Get PR info
    PR_INFO=$(gh pr view $IDENTIFIER --json headRefName,state,title 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo "❌ PR #$IDENTIFIER not found"
      exit 1
    fi
    
    BRANCH_NAME=$(echo "$PR_INFO" | jq -r .headRefName)
    PR_STATE=$(echo "$PR_INFO" | jq -r .state)
    PR_TITLE=$(echo "$PR_INFO" | jq -r .title)
    
    echo "📋 PR: $PR_TITLE"
    echo "🌿 Branch: $BRANCH_NAME"
    echo "📊 State: $PR_STATE"
    ;;
    
  issue)
    echo "🔍 Looking up issue #$IDENTIFIER..."
    
    # Get issue info
    ISSUE_INFO=$(gh issue view $IDENTIFIER --json title,state 2>/dev/null)
    if [ $? -ne 0 ]; then
      echo "❌ Issue #$IDENTIFIER not found"
      exit 1
    fi
    
    ISSUE_TITLE=$(echo "$ISSUE_INFO" | jq -r .title)
    ISSUE_STATE=$(echo "$ISSUE_INFO" | jq -r .state)
    
    echo "📋 Issue: $ISSUE_TITLE"
    echo "📊 State: $ISSUE_STATE"
    
    # Find branches related to this issue
    echo "🔍 Searching for related branches..."
    
    # Look for branches containing the issue number
    BRANCHES=$(git branch -a | grep -E "(feat|fix|docs|refactor|test|perf|chore)-$IDENTIFIER-" | sed 's/^[* ]*//' | sed 's/remotes\/origin\///')
    
    if [ -z "$BRANCHES" ]; then
      echo "❌ No branches found for issue #$IDENTIFIER"
      exit 1
    fi
    
    # If multiple branches, let user choose
    BRANCH_COUNT=$(echo "$BRANCHES" | wc -l)
    if [ $BRANCH_COUNT -gt 1 ]; then
      echo "🌿 Found multiple branches:"
      echo "$BRANCHES" | nl -nrz -w2
      echo ""
      read -p "Select branch number: " SELECTION
      BRANCH_NAME=$(echo "$BRANCHES" | sed -n "${SELECTION}p")
    else
      BRANCH_NAME="$BRANCHES"
    fi
    
    echo "🌿 Selected branch: $BRANCH_NAME"
    ;;
    
  branch)
    BRANCH_NAME="$IDENTIFIER"
    echo "🌿 Branch: $BRANCH_NAME"
    ;;
    
  interactive)
    # Interactive mode - show all worktrees
    echo "🌲 Available worktrees:"
    echo ""
    
    # Get worktree list
    WORKTREES=$(git worktree list --porcelain | awk '
      /^worktree / { 
        path = substr($0, 10)
        getline
        if ($1 == "HEAD") commit = $2
        getline
        if ($1 == "branch") branch = substr($0, 8)
        else branch = "detached"
        
        # Skip the main worktree
        if (path != ".") {
          print branch "|" path
        }
      }
    ' | sort)
    
    if [ -z "$WORKTREES" ]; then
      echo "📭 No worktrees found"
      exit 1
    fi
    
    # Display worktrees
    echo "$WORKTREES" | awk -F'|' '{printf "%-3d. %-40s %s\n", NR, $1, $2}'
    echo ""
    
    read -p "Select worktree number (or q to quit): " SELECTION
    
    if [ "$SELECTION" = "q" ]; then
      echo "👋 Bye!"
      exit 0
    fi
    
    # Get selected branch
    BRANCH_NAME=$(echo "$WORKTREES" | sed -n "${SELECTION}p" | cut -d'|' -f1)
    
    if [ -z "$BRANCH_NAME" ]; then
      echo "❌ Invalid selection"
      exit 1
    fi
    
    echo "🌿 Selected branch: $BRANCH_NAME"
    ;;
esac
```

### 5. Find worktree path
```bash
# Find worktree for this branch
WORKTREE_PATH="./worktrees/$BRANCH_NAME"

# Check if worktree exists
if [ ! -d "$WORKTREE_PATH" ]; then
  echo "❌ Worktree not found: $WORKTREE_PATH"
  echo ""
  echo "💡 Looking for alternative worktrees..."
  
  # Check if there are variant worktrees (v1, v2, etc.)
  VARIANTS=$(ls -d "./worktrees/$BRANCH_NAME"* 2>/dev/null)
  
  if [ -n "$VARIANTS" ]; then
    echo "🌲 Found variant worktrees:"
    echo "$VARIANTS" | nl -nrz -w2
    echo ""
    read -p "Select variant number: " VARIANT_SELECTION
    WORKTREE_PATH=$(echo "$VARIANTS" | sed -n "${VARIANT_SELECTION}p")
    
    if [ ! -d "$WORKTREE_PATH" ]; then
      echo "❌ Invalid selection"
      exit 1
    fi
  else
    echo "❌ No worktrees found for branch: $BRANCH_NAME"
    echo ""
    echo "💡 Available worktrees:"
    ls -1 ./worktrees/ 2>/dev/null | sed 's/^/   /'
    exit 1
  fi
fi

echo "📁 Worktree path: $WORKTREE_PATH"
```

### 6. Open in editor
```bash
echo ""
echo "🚀 Opening in $EDITOR_NAME..."
$EDITOR_CMD -n "$WORKTREE_PATH"

echo "✅ Opened: $WORKTREE_PATH"
echo ""
echo "💡 Tips for code review:"
echo "   - Use GitLens/Git Graph to see commit history"
echo "   - Check test files for implementation details"
echo "   - Review CI/CD configuration changes"
echo "   - Use terminal in $EDITOR_NAME to run tests locally"
```

## Features

- **Multiple input formats**: PR number, issue number, or branch name
- **Smart resolution**: Automatically finds the correct worktree
- **Interactive mode**: Browse and select from available worktrees
- **Variant support**: Handles parallel implementations (v1, v2, etc.)
- **Editor detection**: Works with Cursor or VS Code
- **Open all**: Use `-a` to open all worktrees at once

## Examples

### Open PR for review
```bash
/user:gw-editor 1

🔍 Input type: pr
📝 Using editor: Cursor
🔍 Looking up PR #1...
📋 PR: Add user authentication
🌿 Branch: feat-1-add-auth
📊 State: OPEN
📁 Worktree path: ./worktrees/feat-1-add-auth

🚀 Opening in Cursor...
✅ Opened: ./worktrees/feat-1-add-auth
```

### Open issue implementation
```bash
/user:gw-editor i2

🔍 Input type: issue
📝 Using editor: Cursor
🔍 Looking up issue #2...
📋 Issue: Improve image display
📊 State: OPEN
🔍 Searching for related branches...
🌿 Found multiple branches:
01 feat-2-improve-images
02 feat-2-improve-images-v1
03 feat-2-improve-images-v2

Select branch number: 2
🌿 Selected branch: feat-2-improve-images-v1
📁 Worktree path: ./worktrees/feat-2-improve-images-v1

🚀 Opening in Cursor...
```

### Interactive selection
```bash
/user:gw-editor

🔍 Input type: interactive
📝 Using editor: Cursor
🌲 Available worktrees:

1.  feat-2-improve-images                ./worktrees/feat-2-improve-images
2.  fix-3-login-error                    ./worktrees/fix-3-login-error
3.  docs-4-update-readme                 ./worktrees/docs-4-update-readme

Select worktree number (or q to quit): 2
🌿 Selected branch: fix-59-login-error
📁 Worktree path: ./worktrees/fix-59-login-error

🚀 Opening in Cursor...
```

### Open all worktrees
```bash
/user:gw-editor -a

🔍 Input type: all
📝 Using editor: Cursor
🌲 Opening all worktrees in Cursor...
   ✅ Opening feat-2-improve-images
   ✅ Opening fix-3-login-error
   ✅ Opening docs-4-update-readme

✨ Opened 3 worktree(s) in Cursor
```

## Use Cases

1. **PR Code Review**: Review completed PRs locally with full IDE features
2. **Issue Verification**: Check implementation for specific issues
3. **Quick Access**: Jump to any worktree by branch name
4. **Comparison**: Open multiple implementations for side-by-side review

## Notes

- Requires `gh` CLI for PR/issue lookup
- Works best with consistent branch naming (feat-XX-description)
- Supports parallel implementations (v1, v2, etc.)
- Opens in new window (-n flag) to avoid mixing projects
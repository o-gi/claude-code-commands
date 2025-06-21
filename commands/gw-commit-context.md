Load commit context for Claude to understand implementation details and rationale.

## Purpose

Analyze a git commit and its related GitHub issue (if referenced) to understand:
- What was changed and why
- The implementation approach taken
- The original requirements (from linked issue)
- The technical decisions made

This helps Claude understand past implementations for better context when working on related features or fixes.

## Usage

```bash
# Basic usage - load commit context silently
/user:gw-commit-context abc123
/user:gw-commit-context acbbcfdd6adf501f52a1fddac47cebffc621a164

# Show what was understood
/user:gw-commit-context abc123 -v
/user:gw-commit-context abc123 --verbose

# Adjust thinking depth (default: ultrathink)
/user:gw-commit-context abc123 -l think        # Quick understanding
/user:gw-commit-context abc123 -l "think hard" # Moderate analysis
/user:gw-commit-context abc123 -l ultrathink   # Deep analysis (default)

# Skip diff for large commits
/user:gw-commit-context abc123 --no-diff

# Combine options
/user:gw-commit-context abc123 -v -l "think hard" --no-diff
```

## Workflow

### 0. Display session info

```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Parse arguments

```bash
# Initialize variables
COMMIT_SHA=""
VERBOSE=false
THINKING_LEVEL="ultrathink"
INCLUDE_DIFF=true

# Parse arguments
for arg in "$@"; do
  case $arg in
    -v|--verbose)
      VERBOSE=true
      ;;
    -l|--level)
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
    --no-diff)
      INCLUDE_DIFF=false
      ;;
    *)
      # First non-flag argument is the commit SHA
      if [ -z "$COMMIT_SHA" ]; then
        COMMIT_SHA="$arg"
      fi
      ;;
  esac
done

# Validate commit SHA provided
if [ -z "$COMMIT_SHA" ]; then
  echo "❌ Error: No commit SHA provided"
  echo "Usage: /user:gw-commit-context <commit-sha> [options]"
  exit 1
fi
```

### 2. Fetch commit information

```bash
# Get commit details
echo "📖 Loading commit: $COMMIT_SHA"

# Basic commit info (always included)
COMMIT_INFO=$(git show --no-patch --format=fuller $COMMIT_SHA 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "❌ Error: Invalid commit SHA: $COMMIT_SHA"
  exit 1
fi

# Show commit metadata
echo "$COMMIT_INFO"
echo ""

# Show changed files
echo "📝 Changed files:"
git show --name-status --format="" $COMMIT_SHA
echo ""

# Show diff if requested
if [ "$INCLUDE_DIFF" = true ]; then
  echo "🔍 Full diff:"
  git show $COMMIT_SHA
else
  echo "ℹ️ Diff skipped (use without --no-diff to include)"
fi
```

### 3. Extract and fetch related issue

```bash
# Extract issue number from commit message
COMMIT_MSG=$(git show -s --format=%B $COMMIT_SHA)
ISSUE_NUM=$(echo "$COMMIT_MSG" | grep -oE 'This implements issue #[0-9]+' | grep -oE '[0-9]+' | head -1)

# If issue found, fetch it
if [ -n "$ISSUE_NUM" ]; then
  echo ""
  echo "🔗 Found related issue: #$ISSUE_NUM"
  echo "📋 Loading issue context..."
  
  # Fetch issue details
  gh issue view $ISSUE_NUM 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "⚠️ Warning: Could not fetch issue #$ISSUE_NUM (may be closed or inaccessible)"
  fi
else
  echo "ℹ️ No related issue found in commit message"
fi
```

### 4. Analyze with specified thinking level

```bash
# Claude analyzes based on thinking level
echo ""
echo "🧠 Analyzing with '$THINKING_LEVEL' computational budget..."

# Based on THINKING_LEVEL, Claude will:
# - think: Quick understanding of changes
# - think hard: Moderate analysis of implementation
# - think harder: Deep dive into technical decisions
# - ultrathink: Complete understanding of rationale and implications
```

### 5. Display understanding (if verbose)

```bash
if [ "$VERBOSE" = true ]; then
  echo ""
  echo "## 🎯 Understanding Summary"
  echo ""
  echo "### What was changed"
  echo "[Summary of changes]"
  echo ""
  echo "### Why it was changed"
  echo "[Rationale from commit message and issue]"
  echo ""
  echo "### Technical approach"
  echo "[Implementation details and decisions]"
  echo ""
  echo "### Key insights"
  echo "[Important patterns or learnings]"
fi
```

## What Claude understands

After running this command, Claude will have deep context about:
1. **The change itself**: Files modified, code changes
2. **The rationale**: Why this change was needed (from issue)
3. **The approach**: How it was implemented
4. **The context**: Related to which feature/fix
5. **The patterns**: Coding style and conventions used

## What this command does NOT do

- Does NOT modify any files
- Does NOT create branches or worktrees
- Does NOT create TodoWrite tasks
- Does NOT make any commits

## Example scenarios

### Understanding a bug fix
```bash
/user:gw-commit-context abc123 -v
# Claude learns how a specific bug was fixed and why that approach was chosen
```

### Analyzing a feature implementation
```bash
/user:gw-commit-context feat-commit-sha
# Claude silently loads context about how a feature was built
```

### Quick review of recent changes
```bash
/user:gw-commit-context HEAD -l think --no-diff
# Fast understanding of the most recent commit
```

### Deep analysis for refactoring
```bash
/user:gw-commit-context old-implementation -v -l ultrathink
# Comprehensive understanding before refactoring
```
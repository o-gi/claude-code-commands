Smart commit with auto-generated or custom messages.

## Usage

```bash
# Auto-generate message from changes (default)
/user:gw-commit

# Specify exact message
/user:gw-commit -m "fix: resolve login timeout issue"

# Generate from prompt/hint
/user:gw-commit -p "updated authentication flow for OAuth"

# Interactive mode (Claude suggests, you can edit)
/user:gw-commit -i
```

## Options

- `-m, --message`: Specify exact commit message
- `-p, --prompt`: Provide hint for AI-generated message
- `-i, --interactive`: Interactive mode with AI suggestions
- `-n, --no-verify`: Skip pre-commit hooks

## Features

1. **Auto-detection**:
   - Extracts issue number from branch name
   - Determines commit type from changes
   - Adds session ID for traceability

2. **Smart type detection**:
   - `feat:` for new features
   - `fix:` for bug fixes
   - `test:` for test changes
   - `docs:` for documentation
   - `chore:` for maintenance
   - `refactor:` for code improvements
   - `style:` for formatting changes
   - `perf:` for performance improvements

3. **Issue reference**:
   - Automatically adds "This implements issue #N"
   - Extracts from branch name pattern

4. **Session tracking**:
   - Adds "Session: claude -r [sessionId]"
   - For audit trail

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Parse arguments
```bash
# Default values
MESSAGE=""
PROMPT=""
INTERACTIVE=false
NO_VERIFY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -m|--message)
      MESSAGE="$2"
      shift 2
      ;;
    -p|--prompt)
      PROMPT="$2"
      shift 2
      ;;
    -i|--interactive)
      INTERACTIVE=true
      shift
      ;;
    -n|--no-verify)
      NO_VERIFY=true
      shift
      ;;
    *)
      echo "❌ Unknown option: $1"
      echo "Usage: gw-commit [-m message] [-p prompt] [-i] [-n]"
      exit 1
      ;;
  esac
done
```

### 2. Extract context
```bash
# Get issue number from branch
ISSUE_NUM=$(git branch --show-current | grep -oE '[0-9]+' | head -1)

# Get current session ID (if available)
SESSION_ID="${CLAUDE_SESSION_ID:-}"
```

### 3. Generate or use message

#### Option A: Direct message (-m)
```bash
if [ -n "$MESSAGE" ]; then
  COMMIT_MSG="$MESSAGE"
  echo "📝 Using provided message: $COMMIT_MSG"
fi
```

#### Option B: Prompt-based (-p)
```bash
if [ -n "$PROMPT" ]; then
  echo "🤖 Generating message from prompt: $PROMPT"
  
  # Claude analyzes diff and prompt
  git diff --staged > /tmp/staged-diff.txt
  
  # Claude generates message based on:
  # 1. The staged changes
  # 2. The user's prompt
  # 3. Conventional commit format
  
  # Example output:
  # "feat: implement OAuth2 authentication flow
  #
  # - Add OAuth2 provider configuration
  # - Implement token refresh logic
  # - Update login component with OAuth options"
fi
```

#### Option C: Auto-generate (default)
```bash
if [ -z "$MESSAGE" ] && [ -z "$PROMPT" ] && [ "$INTERACTIVE" = false ]; then
  echo "🔍 Analyzing changes..."
  
  # Get staged changes
  STAGED_FILES=$(git diff --staged --name-only)
  
  if [ -z "$STAGED_FILES" ]; then
    echo "❌ No staged changes to commit"
    echo "💡 Use 'git add' to stage changes first"
    exit 1
  fi
  
  # Analyze changes for commit type
  if git diff --staged --name-only | grep -q "test"; then
    COMMIT_TYPE="test"
  elif git diff --staged --name-only | grep -q "docs\|README\|CHANGELOG"; then
    COMMIT_TYPE="docs"
  elif git diff --staged --name-only | grep -q "package.*json\|requirements\|Gemfile\|go.mod"; then
    COMMIT_TYPE="chore"
  elif git diff --staged | grep -q "fix\|bug\|error\|issue"; then
    COMMIT_TYPE="fix"
  else
    COMMIT_TYPE="feat"
  fi
  
  # Claude analyzes the actual changes
  echo "📊 Detected type: $COMMIT_TYPE"
  
  # Get main changed files
  MAIN_FILES=$(git diff --staged --name-only | head -3 | xargs basename | sed 's/\.[^.]*$//' | paste -sd ", ")
  
  # Generate descriptive message
  COMMIT_MSG="$COMMIT_TYPE: update $MAIN_FILES"
  
  # Claude would generate more specific message like:
  # "feat: add user authentication module"
  # "fix: resolve memory leak in data processor"
  # "test: add unit tests for payment service"
fi
```

#### Option D: Interactive (-i)
```bash
if [ "$INTERACTIVE" = true ]; then
  echo "🤖 Generating commit message suggestion..."
  
  # Claude analyzes and suggests
  SUGGESTED_MSG="feat: implement user profile management"
  
  echo "📝 Suggested message:"
  echo "   $SUGGESTED_MSG"
  echo ""
  read -p "✏️  Edit message (press Enter to accept): " USER_MSG
  
  if [ -n "$USER_MSG" ]; then
    COMMIT_MSG="$USER_MSG"
  else
    COMMIT_MSG="$SUGGESTED_MSG"
  fi
fi
```

### 4. Add metadata
```bash
# Add issue reference if available
if [ -n "$ISSUE_NUM" ]; then
  COMMIT_MSG="$COMMIT_MSG

This implements issue #$ISSUE_NUM"
fi

# Add session ID if available
if [ -n "$SESSION_ID" ]; then
  COMMIT_MSG="$COMMIT_MSG
Session: claude -r $SESSION_ID"
fi
```

### 5. Create commit
```bash
echo "💾 Creating commit..."

# Commit with or without verification
if [ "$NO_VERIFY" = true ]; then
  git commit -m "$COMMIT_MSG" --no-verify
else
  git commit -m "$COMMIT_MSG"
fi

if [ $? -eq 0 ]; then
  echo "✅ Committed successfully!"
  echo ""
  echo "📋 Commit message:"
  echo "$COMMIT_MSG" | sed 's/^/   /'
else
  echo "❌ Commit failed"
  exit 1
fi
```

## Examples

### Auto-generated
```bash
$ /user:gw-commit
🔍 Analyzing changes...
📊 Detected type: feat
💾 Creating commit...
✅ Committed successfully!

📋 Commit message:
   feat: add user authentication service
   
   This implements issue #42
   Session: claude -r ABC123
```

### With message
```bash
$ /user:gw-commit -m "fix: resolve race condition in payment processor"
📝 Using provided message: fix: resolve race condition in payment processor
💾 Creating commit...
✅ Committed successfully!
```

### With prompt
```bash
$ /user:gw-commit -p "updated the login page styling"
🤖 Generating message from prompt: updated the login page styling
💾 Creating commit...
✅ Committed successfully!

📋 Commit message:
   style: update login page UI components
   
   - Modernize input field styling
   - Update button hover states
   - Improve mobile responsiveness
   
   This implements issue #17
```

### Interactive
```bash
$ /user:gw-commit -i
🤖 Generating commit message suggestion...
📝 Suggested message:
   feat: implement real-time notifications

✏️  Edit message (press Enter to accept): feat: add WebSocket-based notifications
💾 Creating commit...
✅ Committed successfully!
```

## Integration with other gw commands

Other gw commands can use this for consistent commits:

```bash
# In gw-push.md:
/user:gw-commit -p "auto-generated from push command"
git push

# In gw-iss-implement.md:
/user:gw-commit -p "$TASK_TEXT"
```

## Error handling

- No staged changes → Show helpful message
- Commit fails → Show git error
- Unknown options → Show usage
- Pre-commit hook fails → Show hook output

## Notes

- Always stages changes are committed
- Respects git hooks unless -n is used
- Compatible with monorepos
- Works with all git workflows
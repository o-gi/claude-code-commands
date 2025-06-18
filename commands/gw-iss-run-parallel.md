Create multiple parallel implementations with tmux for trying different approaches.

ISSUE_NUMBER: Issue number (e.g., 123 or #123)
-p, --parallel [2-8]: Number of parallel implementations (default: 3)
-m, --model [opus|sonnet]: Model to use for Claude instances (default: opus)

## Purpose

Create multiple worktrees to implement the same issue with different approaches, allowing comparison and selection of the best solution. Each implementation will be pushed and a PR created.

## Requirements

- tmux installed (`brew install tmux`)
- Claude Code CLI available in PATH

## Usage

```bash
# Default: create 3 parallel implementations with Opus
/user:gw-iss-run-parallel 33

# Specify number of parallel implementations
/user:gw-iss-run-parallel 33 -p 5
/user:gw-iss-run-parallel #33 --parallel 4

# Use Sonnet model for all instances
/user:gw-iss-run-parallel 33 -m sonnet
/user:gw-iss-run-parallel 33 --model sonnet -p 4
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Parse arguments
```bash
# Parse issue number and flags
ISSUE_NUM=$(echo "$ARGUMENTS" | sed 's/^#//' | awk '{print $1}')
FLAGS=$(echo "$ARGUMENTS" | awk '{$1=""; print $0}')

# Default parallel count
PARALLEL_COUNT=3
# Default model
MODEL="opus"

# Parse flags
i=1
for arg in $FLAGS; do
  case $arg in
    -p|--parallel)
      # Get next argument as count
      PARALLEL_COUNT=$(echo "$FLAGS" | awk -v i=$((i+1)) '{print $i}')
      if [ -z "$PARALLEL_COUNT" ]; then
        PARALLEL_COUNT=3
      fi
      ;;
    -m|--model)
      # Get next argument as model
      MODEL=$(echo "$FLAGS" | awk -v i=$((i+1)) '{print $i}')
      if [ -z "$MODEL" ]; then
        MODEL="opus"
      fi
      ;;
  esac
  ((i++))
done

# Validate count
if ! [[ "$PARALLEL_COUNT" =~ ^[0-9]+$ ]] || [ $PARALLEL_COUNT -lt 2 ] || [ $PARALLEL_COUNT -gt 8 ]; then
  echo "❌ Invalid count. Must be between 2 and 8."
  exit 1
fi

# Validate model
if [[ "$MODEL" != "opus" && "$MODEL" != "sonnet" ]]; then
  echo "❌ Invalid model. Must be 'opus' or 'sonnet'."
  exit 1
fi

echo "🚀 Creating $PARALLEL_COUNT parallel implementations for issue #$ISSUE_NUM (model: $MODEL)"
```

### 2. Check tmux availability
```bash
if ! command -v tmux &> /dev/null; then
  echo "❌ tmux is not installed. Please install with: brew install tmux"
  exit 1
fi

if ! command -v claude &> /dev/null; then
  echo "❌ Claude Code CLI not found. Please ensure 'claude' is in your PATH"
  exit 1
fi
```

### 3. Fetch issue details and generate branch name
```bash
# Get issue title for branch naming
ISSUE_TITLE=$(gh issue view $ISSUE_NUM --json title -q .title)
echo "📋 Issue: $ISSUE_TITLE"

# IMPORTANT: Claude must generate appropriate branch name
echo "🤔 Analyzing issue to generate branch name..."

# Branch naming logic (same as gw-iss-run)
# Claude will generate: feat-1-improve-images, fix-1-login-error, etc.
# For now, using fallback
BRANCH_BASE="feat-$ISSUE_NUM-update"
```

### 4. Create worktrees
```bash
echo "🌲 Creating worktrees..."

# Array to store worktree paths
WORKTREE_PATHS=()

for i in $(seq 1 $PARALLEL_COUNT); do
  VARIANT_BRANCH="$BRANCH_BASE-claude$i"
  # Worktree path is same as branch name (no conversion needed!)
  VARIANT_WORKTREE="./worktrees/$VARIANT_BRANCH"
  
  # Check if worktree exists
  if git worktree list | grep -q "$VARIANT_WORKTREE"; then
    echo "  ⚠️  claude$i: Already exists at $VARIANT_WORKTREE"
  else
    # Create new worktree
    git worktree add -b "$VARIANT_BRANCH" "$VARIANT_WORKTREE" > /dev/null 2>&1
    echo "  ✅ claude$i: Created $VARIANT_BRANCH @ $VARIANT_WORKTREE"
    
    # Setup worktree
    (
      cd "$VARIANT_WORKTREE"
      
      # Install dependencies
      echo "  📦 claude$i: Installing dependencies..."
      pnpm install > /dev/null 2>&1
      
      # Link .env files
      if [ -f "../../.env" ]; then
        ln -s ../../.env .env
      fi
      
      # Run gw-env-sync if available
      if [ -f ~/.claude/commands/gw-env-sync.md ]; then
        echo "  🔗 claude$i: Syncing .env files..."
        # This would need to be executed through Claude
      fi
    )
  fi
  
  WORKTREE_PATHS+=("$VARIANT_WORKTREE")
done
```

### 5. Create tmux session
```bash
# Generate unique session name
SESSION_NAME="claude-parallel-$ISSUE_NUM"

# Kill existing session if it exists
tmux kill-session -t "$SESSION_NAME" 2>/dev/null

echo -e "\n🖥️  Creating tmux session: $SESSION_NAME"

# Create new tmux session
tmux new-session -d -s "$SESSION_NAME" -n "issue-$ISSUE_NUM"

# Setup layout based on count
case $PARALLEL_COUNT in
  2)
    # Split horizontally
    tmux split-window -h -t "$SESSION_NAME:0"
    ;;
  3)
    # 3 vertical panes
    tmux split-window -h -t "$SESSION_NAME:0"
    tmux split-window -h -t "$SESSION_NAME:0.1"
    tmux select-layout -t "$SESSION_NAME:0" even-horizontal
    ;;
  4)
    # 2x2 grid
    tmux split-window -h -t "$SESSION_NAME:0"
    tmux split-window -v -t "$SESSION_NAME:0.0"
    tmux split-window -v -t "$SESSION_NAME:0.2"
    tmux select-layout -t "$SESSION_NAME:0" tiled
    ;;
  *)
    # 5+ panes: use tiled layout
    for ((i=2; i<=PARALLEL_COUNT; i++)); do
      tmux split-window -t "$SESSION_NAME:0"
    done
    tmux select-layout -t "$SESSION_NAME:0" tiled
    ;;
esac
```

### 6. Launch Claude in each pane
```bash
echo "🤖 Launching Claude instances..."

for i in $(seq 0 $((PARALLEL_COUNT - 1))); do
  PANE_INDEX=$i
  VARIANT_NUM=$((i + 1))
  WORKTREE_PATH="${WORKTREE_PATHS[$i]}"
  
  # Send commands to each pane
  tmux send-keys -t "$SESSION_NAME:0.$PANE_INDEX" "cd $WORKTREE_PATH" C-m
  sleep 0.5
  
  # Launch Claude with model
  CLAUDE_CMD="claude"
  if [ "$MODEL" = "sonnet" ]; then
    CLAUDE_CMD="claude --model claude-3-5-sonnet-20241022"
  fi
  tmux send-keys -t "$SESSION_NAME:0.$PANE_INDEX" "$CLAUDE_CMD" C-m
  sleep 2
  
  # Create variant-specific prompt
  VARIANT_TEXT="This is implementation variant $VARIANT_NUM of $PARALLEL_COUNT. Try a different approach than other variants."
  
  # Send instruction to Claude
  tmux send-keys -t "$SESSION_NAME:0.$PANE_INDEX" "$VARIANT_TEXT Then run: /user:gw-iss-run $ISSUE_NUM" C-m
  
  echo "  ✅ claude$VARIANT_NUM: Claude ($MODEL) launched in $WORKTREE_PATH"
done
```

### 7. Attach to tmux session
```bash
echo -e "\n✨ All set! Attaching to tmux session...\n"

# Show helpful tmux commands
echo "📚 Tmux shortcuts:"
echo "  - Switch panes: Ctrl-b + arrow keys"
echo "  - Zoom pane: Ctrl-b + z"
echo "  - Detach: Ctrl-b + d"
echo "  - Kill session: tmux kill-session -t $SESSION_NAME"
echo ""
echo "📊 Check progress: /user:gw-iss-status $ISSUE_NUM"
echo ""

# Attach to session
tmux attach-session -t "$SESSION_NAME"
```

## Example Output

```
◆ [main] claude-1234 @ main

🚀 Creating 3 parallel implementations for issue #1 (model: opus)
📋 Issue: Improve product image display
🤔 Analyzing issue to generate branch name...

🌲 Creating worktrees...
  ✅ claude1: Created feat-1-improve-images-claude1 @ ./worktrees/feat-1-improve-images-claude1
  ✅ claude2: Created feat-1-improve-images-claude2 @ ./worktrees/feat-1-improve-images-claude2
  ✅ claude3: Created feat-1-improve-images-claude3 @ ./worktrees/feat-1-improve-images-claude3

🖥️  Creating tmux session: claude-parallel-1
🤖 Launching Claude instances...
  ✅ claude1: Claude (opus) launched in ./worktrees/feat-1-improve-images-claude1
  ✅ claude2: Claude (opus) launched in ./worktrees/feat-1-improve-images-claude2
  ✅ claude3: Claude (opus) launched in ./worktrees/feat-1-improve-images-claude3

✨ All set! Attaching to tmux session...

📚 Tmux shortcuts:
  - Switch panes: Ctrl-b + arrow keys
  - Zoom pane: Ctrl-b + z
  - Detach: Ctrl-b + d
  - Kill session: tmux kill-session -t claude-parallel-1

📊 Check progress: /user:gw-iss-status 1
```

## Features

- **Automatic worktree creation**: Creates N worktrees with -claude1, -claude2, etc.
- **Dependency installation**: Runs pnpm install in each worktree
- **Environment setup**: Links .env files automatically
- **Smart tmux layout**: Adjusts layout based on number of panes
- **Claude automation**: Launches Claude and runs gw-iss-run automatically
- **Model selection**: Choose between Opus (default) or Sonnet for all instances
- **Session management**: Reuses or recreates tmux sessions

## Tmux Layouts

- **2 panes**: Horizontal split (side by side)
- **3 panes**: Even horizontal layout
- **4 panes**: 2x2 grid
- **5+ panes**: Tiled layout (auto-arranged)

## Advanced Usage

### Resume existing session
```bash
# If session exists, it will be killed and recreated
# To manually attach to existing:
tmux attach-session -t claude-parallel-1
```

### Monitor from outside tmux
```bash
# Check status without attaching
/user:gw-iss-status 1

# View specific pane
tmux capture-pane -t claude-parallel-1:0.0 -p
```

### Clean up
```bash
# Kill tmux session
tmux kill-session -t claude-parallel-1

# Remove worktrees
git worktree remove ./worktrees/feat-1-improve-images-claude1
git worktree remove ./worktrees/feat-1-improve-images-claude2
git worktree remove ./worktrees/feat-1-improve-images-claude3
```

## Notes

- Each Claude instance is independent
- They will import the same issue tasks but may implement differently
- Use gw-iss-status to compare progress
- Choose the best implementation for final PR
- Requires tmux and Claude CLI in PATH
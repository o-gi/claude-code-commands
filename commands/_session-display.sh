#!/bin/bash
# Common session display function for all gt commands

show_session_info() {
  # Generate visual identifier (last 4 digits)
  VISUAL_ID="claude-$(echo $$$(date +%s) | tail -c 5)"
  
  # Get actual Claude session ID from environment or use placeholder
  SESSION_ID="${CLAUDE_SESSION_ID:-01JFK6YZ8KQXJ2V3P9M7N5R4TC}"
  
  # Detect model from environment or default
  MODEL="${CLAUDE_MODEL:-Opus}"
  
  # Get current branch
  BRANCH=$(git branch --show-current 2>/dev/null || echo "no-branch")
  
  # Get current directory relative to git root
  GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
  CURRENT_DIR=$(pwd)
  REL_PATH=${CURRENT_DIR#$GIT_ROOT/}
  if [ "$REL_PATH" = "$CURRENT_DIR" ]; then
    REL_PATH="."
  fi
  
  # Check if in worktree
  # Get all worktrees and check if current directory is one of them
  CURRENT_DIR_ABS=$(cd "$(pwd)" && pwd)
  WORKTREE_INFO=$(git worktree list | grep -F "$CURRENT_DIR_ABS" | head -1)
  
  if [ -n "$WORKTREE_INFO" ]; then
    # We are in a worktree
    WORKTREE_PATH=$(echo "$WORKTREE_INFO" | awk '{print $1}')
    WORKTREE_NAME=$(basename "$WORKTREE_PATH")
    
    # Extract issue number if present
    if [[ "$WORKTREE_NAME" =~ -issue-([0-9]+)$ ]]; then
      WORKTREE_DISPLAY="issue-${BASH_REMATCH[1]}"
    elif [[ "$WORKTREE_NAME" =~ -pr-([0-9]+)$ ]]; then
      WORKTREE_DISPLAY="pr-${BASH_REMATCH[1]}"
    else
      WORKTREE_DISPLAY="$WORKTREE_NAME"
    fi
  else
    # Not in a worktree, we're in main repo
    WORKTREE_DISPLAY="main"
  fi
  
  # Display session info with new format
  echo "🌿 Branch: $BRANCH | 🌲 Worktree: $WORKTREE_DISPLAY | 🆔 $SESSION_ID | 📌 $VISUAL_ID | 🤖 $MODEL"
  echo ""
}

# Auto-display when sourced
show_session_info
# Claude Code Git Workflow Commands 🚀

A collection of powerful git workflow commands for Claude Code that enable parallel development, automated PR creation, and seamless GitHub integration.

## 🌟 Overview

This repository contains custom commands that enhance Claude Code's ability to work with Git and GitHub, enabling:

- **Parallel Development**: Work on multiple issues simultaneously using git worktrees
- **Automated Workflows**: From issue creation to PR merge in one command
- **Smart Branching**: Consistent branch naming without slashes for worktree compatibility
- **Session Management**: Track multiple Claude instances in WezTerm panels
- **Environment Sync**: Automatic `.env` file management across worktrees

## 🚀 Quick Start

### Installation

1. Clone this repository to `~/.claude`:
```bash
git clone https://github.com/YOUR_USERNAME/claude-workflow.git ~/.claude
```

2. Ensure Claude Code can access the commands:
```bash
# Commands are automatically available when placed in ~/.claude/commands/
```

3. Set up shell aliases for convenience:
```bash
# Add to ~/.zshrc or ~/.bashrc
alias cl='claude'
alias cld='claude --dangerously-skip-permissions'
```

### Command Usage Note

All commands accept arguments with or without quotes:
```bash
# Both of these work identically:
/user:gw-yolo Add user authentication
/user:gw-yolo "Add user authentication"

# Useful for quick typing:
/user:gw-iss-create Fix login bug          # Plans and creates through consultation (ultrathink)
/user:gw-iss-create -l think Fix typo      # Quick analysis for simple tasks
/user:gw-iss-create -f Fix login bug       # Force immediate creation (old behavior)
/user:gw-yolo Update README                 # Plans, creates issue, implements (consultation)
/user:gw-yolo -f Update README              # Immediate execution (old YOLO behavior)
```

### Standard Workflow (Recommended)

**Note**: Issue/PR numbers can be specified with or without `#` - both `33` and `#33` work identically.

```bash
# Basic flow (auto push & PR):
/user:gw-iss-create        # 1. Plan and create issue through consultation
/user:gw-iss-run #33       # 2. Start implementation → push → PR

# Cautious flow (review before push):
/user:gw-iss-create        # 1. Plan and create issue through consultation
/user:gw-iss-implement #33 # 2. Start implementation (commits only)
/user:gw-push              # 3. Push and create PR when ready

# Parallel flow (try multiple approaches):
/user:gw-iss-create        # 1. Plan and create issue through consultation

# Option A: With auto push/PR
/user:gw-iss-run-parallel #33 -p 3  # 2a. Create 3 parallel implementations (auto push/PR)

# Option B: Local only
/user:gw-iss-implement-parallel #33 -p 3  # 2b. Create 3 parallel implementations (local only)

/user:gw-iss-status #33    # 3. Check progress of all variants
/user:gw-editor -a         # 4. Open all worktrees to compare
# Choose best implementation and create PR from that branch

# Optional steps:
/user:gw-iss-edit #33      # Edit issue if requirements need clarification
/user:gw-iss-context #33   # Load existing issue context
/user:gw-editor #33        # Open in editor for review after completion

# After PR is approved:
/user:gw-pr-merge #34      # Merge PR with squash and cleanup worktree
```

### YOLO Workflow (Thoughtful & Effective 🚀)

```bash
# Default: Plan first, then implement (quotes optional)
/user:gw-yolo Add user authentication feature
# Shows plan → you approve → creates issue #33, implements, creates PR #34

# Skip planning for speed (original YOLO behavior)
/user:gw-yolo Add user authentication feature -f
# Immediately creates issue #33, implements, creates PR #34

# Note: I often use 'cld' alias (--dangerously-skip-permissions) for speed

# After PR is approved:
/user:gw-pr-merge #34      # Merge PR with squash and cleanup worktree
```

## 📚 Core Commands

### Issue Management
- **`gw-iss-create [description]`** - Create GitHub issues through consultation and planning (default)
  - `-l, --level [level]` - Thinking depth: think, "think hard", "think harder", ultrathink (default)
  - `-f, --force` - Skip consultation and create immediately (old behavior)
  - `-np, --no-prompt` - Exclude original request from issue body
- **`gw-iss-context [issue#]`** - Load issue context for Claude to understand requirements
- **`gw-commit-context [commit-sha]`** - Load commit context and related issue to understand implementation
  - `-v, --verbose` - Show understanding summary
  - `-l, --level [level]` - Thinking depth: think, "think hard", "think harder", ultrathink (default)
  - `--no-diff` - Skip diff for large commits
- **`gw-iss-edit [issue#] [content]`** - Edit existing issues (append updates, modify content)
- **`gw-iss-run [issue#]`** - Start working on an issue (implement → push → PR)
  - `-n, --no-worktree` - Use traditional branch switching
  - `-l, --level [level]` - Thinking depth: think, "think hard", "think harder", ultrathink (default)
  - `--draft` - Create PR as draft when completed
- **`gw-iss-implement [issue#]`** - Start working on an issue (implement → commit only, no push/PR)
  - `-n, --no-worktree` - Use traditional branch switching
  - `-l, --level [level]` - Thinking depth: think, "think hard", "think harder", ultrathink (default)
- **`gw-iss-run-parallel [issue#]`** - Create multiple parallel implementations with tmux (with push/PR)
  - `-p, --parallel [2-8]` - Number of parallel implementations (default: 3)
  - `-m, --model [opus|sonnet]` - Model to use for Claude instances (default: opus)
- **`gw-iss-implement-parallel [issue#]`** - Create multiple parallel implementations with tmux (local only, no push/PR)
  - `-p, --parallel [2-8]` - Number of parallel implementations (default: 3)
  - `-m, --model [opus|sonnet]` - Model to use for Claude instances (default: opus)
- **`gw-iss-status [issue#]`** - Check progress of parallel implementations
- **`gw-iss-sync [issue#]`** - Sync TodoWrite tasks with GitHub issue checkboxes
  - Automatically updates GitHub issue checkboxes based on TodoWrite state
  - Optional: Specify issue number, otherwise uses current branch

### Pull Request Management
- **`gw-pr-create`** - Create PRs with structured descriptions
  - `-d, --draft` - Create PR as draft
- **`gw-pr-fix [pr#]`** - Automatically fix CI failures in PRs
  - `-n, --no-worktree` - Use traditional branch checkout
- **`gw-pr-merge [pr#]`** - Merge PRs with squash and cleanup all related worktrees/branches
- **`gw-pr-close [pr#]`** - Close PR without merging and cleanup worktrees/branches
  - `-c, --comment "message"` - Add comment exactly as provided
  - `-p, --prompt "message"` - Generate professional closing message from prompt
- **`gw-pr-sync [pr#]`** - Sync PR with latest main branch changes
  - Rebases PR branch onto latest main
  - Handles conflicts gracefully
  - Updates PR with force-push

### Workflow Automation
- **`gw-yolo [description]`** - Complete flow: plan → create issue → implement → create PR (consultation by default)
  - `-f, --force` - Skip consultation and execute immediately (old behavior)
  - `-l, --level [level]` - Thinking depth: think, "think hard", "think harder", ultrathink (default)
  - `--draft` - Create PR as draft
  - `-np, --no-prompt` - Exclude original request from issue body
- **`gw-push [message]`** - Simple commit and push workflow
- **`gw-push-from-main [branch-name-or-description]`** - Create branch from main and push with PR
  - Automatically creates new branch when on main
  - Generates branch name from changes if not provided
- **`gw-commit`** - Smart commit with auto-generated or custom messages
  - `-m, --message "msg"` - Specify exact commit message
  - `-p, --prompt "hint"` - Generate message from prompt/hint
  - `-i, --interactive` - Interactive mode with AI suggestions
  - `-n, --no-verify` - Skip pre-commit hooks

### Utilities
- **`gw-editor [pr#|issue#|branch]`** - Open worktrees in Cursor/VSCode
  - `-a, --all` - Open all worktrees at once
- **`gw-env-sync [worktree]`** - Sync `.env` files across all worktrees
  - `--status` - List current .env files and their link status

## 💡 Command Options Examples

```bash
# Working without worktrees (traditional branch switching)
/user:gw-iss-run #33 -n
/user:gw-iss-implement #33 --no-worktree

# Specify thinking levels for different task complexities
/user:gw-yolo "Refactor authentication system" -l ultrathink
/user:gw-iss-run #33 -l "think harder" --draft

# Parallel development (with auto push/PR)
/user:gw-iss-run-parallel #33 -p 5  # Create 5 parallel implementations
/user:gw-iss-run-parallel #33 -m sonnet  # Use Sonnet model for all instances
/user:gw-iss-run-parallel #33 -p 4 -m sonnet  # 4 instances with Sonnet

# Parallel development (local only)
/user:gw-iss-implement-parallel #33 -p 5  # Create 5 parallel implementations locally
/user:gw-iss-implement-parallel #33 -m sonnet  # Use Sonnet model

# Draft PRs
/user:gw-pr-create -d
/user:gw-yolo "Add experimental feature" --draft

# Exclude original request from issues (privacy/sensitive info)
/user:gw-iss-create -np "Fix security vulnerability"
/user:gw-yolo -np "Add payment processing" -l "think harder"

# Skip consultation and create issue immediately
/user:gw-iss-create -f "fix typo in README"  # Force immediate creation

# Adjust thinking level for different complexities
/user:gw-iss-create -l think "fix typo"                    # Quick 5-min analysis
/user:gw-iss-create -l "think hard" "add login feature"    # 10-min analysis
/user:gw-iss-create -l "think harder" "refactor API"       # 15-min analysis
/user:gw-iss-create "redesign architecture"                # Default: ultrathink (20+ min)

# YOLO with consultation (default) or force
/user:gw-yolo "add search feature"         # Shows plan first, then implements
/user:gw-yolo "fix typo" -f -l think       # Force immediate + quick analysis

# Close PR with comments
/user:gw-pr-close #45 -c "Closing due to requirement changes"
/user:gw-pr-close #45 -p "not working properly"  # Generates professional message

# Working from main branch
/user:gw-push-from-main  # Auto-generates branch name from changes
/user:gw-push-from-main feat-new-api  # Use specific branch name

# Editor management
/user:gw-editor #33       # Open specific issue worktree
/user:gw-editor --all     # Open all worktrees

# Environment sync
/user:gw-env-sync --status         # Check .env link status
/user:gw-env-sync feat-33-auth    # Sync specific worktree

# Smart commits
/user:gw-commit                    # Auto-generate from changes
/user:gw-commit -m "fix: specific bug"  # Direct message
/user:gw-commit -p "login fix"     # Generate from hint
/user:gw-commit -i                 # Interactive mode

# Understanding past commits
/user:gw-commit-context abc123     # Silently load commit and related issue
/user:gw-commit-context abc123 -v  # Show understanding summary
/user:gw-commit-context HEAD -l think --no-diff  # Quick look at latest commit
```

## 🎯 Key Features

### 1. Git Worktree Integration
All commands create worktrees in `./worktrees/` subdirectory with branch-based naming:
```
./worktrees/feat-33-add-auth/
./worktrees/fix-34-login-bug/
./worktrees/docs-35-update-readme/
```

### 2. Parallel Development
Work on multiple implementations simultaneously:
```bash
# Create 3 parallel implementations (Opus by default)
/user:gw-iss-run-parallel 33 -p 3

# Use Sonnet model for faster responses
/user:gw-iss-run-parallel 33 -p 3 -m sonnet

# Opens tmux with:
# - Terminal 1: ./worktrees/feat-33-auth-claude1/ (with selected model)
# - Terminal 2: ./worktrees/feat-33-auth-claude2/ (with selected model)
# - Terminal 3: ./worktrees/feat-33-auth-claude3/ (with selected model)
```

### 3. Smart Branch Naming
Branches use hyphens instead of slashes for perfect worktree compatibility:
- ✅ `feat-33-add-authentication`
- ✅ `fix-34-resolve-memory-leak`
- ❌ ~~`feat/33-add-authentication`~~ (not used)

### 4. Session Display
Every command shows session context for WezTerm panel management:
```
🌿 Branch: main | 🌲 Worktree: main | 🆔 01JFK6YZ8KQXJ2V3P9M7N5R4TC | 📌 claude-1234 | 🤖 Opus
```

The session display includes:
- 🆔 Actual Claude Code session ID (use with `claude -r` to resume)
- 📌 Visual identifier for distinguishing WezTerm panels
- 🤖 Current model (Opus/Sonnet) in each parallel terminal

### 5. TodoWrite Integration
Automatic task synchronization between Claude's TodoWrite and GitHub issue checkboxes.

### 6. Group Cleanup
`gw-pr-merge` automatically cleans up ALL related worktrees and branches for the same issue:
- Detects all variants (claude1, claude2, etc.) by issue number
- Removes all worktrees in one command
- Deletes all local branches
- Perfect for parallel implementation workflows

### 7. Automatic Environment Sync
All worktree-creating commands now automatically sync `.env` files:
- `gw-yolo`, `gw-iss-run`, `gw-iss-implement`
- No need to manually run `gw-env-sync` after worktree creation
- Ensures immediate development readiness

### 8. Privacy Options
Control what information is included in GitHub issues:
- Use `-np` or `--no-prompt` to exclude original request
- Useful for sensitive information or private details
- Available in `gw-iss-create` and `gw-yolo` commands

## 📖 Example Workflows

### Complete Development Lifecycle
```bash
# 1. Create issue and implement
/user:gw-iss-create        # Plan and create issue #33 (consultation mode)
/user:gw-iss-run #33       # Implement, test, push, create PR #34

# 2. After PR review and approval
/user:gw-pr-merge #34      # Merge with squash & cleanup ALL related worktrees

# The worktree AND any parallel variants are automatically removed!
```

### Standard Feature Development
```bash
# 1. Start with an idea (quotes are optional)
/user:gw-yolo Add search functionality to user dashboard
# or
/user:gw-yolo "Add search functionality to user dashboard"

# Claude will:
# - Create GitHub issue #45
# - Create branch: feat-45-add-search-functionality
# - Create worktree: ./worktrees/feat-45-add-search-functionality/
# - Implement the feature
# - Run tests
# - Create PR when ready

# 2. After approval:
/user:gw-pr-merge #46      # Merge PR and cleanup
```

### Working on Existing Issue
```bash
# For existing issues, you can skip creation:
/user:gw-iss-run #38       # Directly start implementation → push → PR

# Or use implement for local work only:
/user:gw-iss-implement #38 # Work locally without pushing
# Review changes...
/user:gw-push             # Push when ready

# Or load context first if you want Claude to understand the issue:
/user:gw-iss-context #38   # Read and analyze issue
/user:gw-iss-run #38       # Then start implementation
```

### Understanding Past Implementations
```bash
# Analyze how a bug was fixed
/user:gw-commit-context fix-commit-sha -v
# Claude understands the fix approach and rationale

# Research feature implementation before refactoring
/user:gw-commit-context feat-original-sha
# Claude silently loads context about implementation patterns

# Quick review of recent changes
/user:gw-commit-context HEAD -l think --no-diff
# Fast understanding without full diff analysis
```

### Parallel Implementation Comparison
```bash
# 1. Create multiple approaches (requires tmux)
/user:gw-iss-run-parallel #52 -p 3
# This opens tmux with 3 panes, each running Claude in a different worktree

# 2. Check progress
/user:gw-iss-status #52

# 3. Open all in editor to compare
/user:gw-editor -a

# 4. Choose best implementation and create PR from it
# 5. When PR is approved, merge and cleanup ALL variants
/user:gw-pr-merge #46  # Removes all 3 worktrees automatically!
```

### Fixing CI Failures
```bash
# 1. Automated CI fix
/user:gw-pr-fix #67

# Claude will:
# - Analyze CI failures
# - Create worktree from PR branch
# - Fix issues iteratively
# - Push when all checks pass
```

### Working from Main Branch
```bash
# Accidentally started work on main branch?
# Make your changes...

# Then safely create branch and PR:
/user:gw-push-from-main
# or with specific branch name:
/user:gw-push-from-main feat-new-feature

# Claude will:
# - Create new branch from main
# - Move all your changes
# - Create commit and push
# - Create PR automatically
```

### Closing PRs Without Merge
```bash
# Simple close
/user:gw-pr-close #45

# With direct comment
/user:gw-pr-close #45 -c "Requirements changed, closing this approach"

# With generated professional message
/user:gw-pr-close #45 -p "not working as expected"
# Generates: "Technical issues prevent this implementation from meeting requirements.
#            Closing to explore alternative approaches."

# All variants cleanup worktrees/branches automatically
```

## 🛠️ Configuration

### Required Tools
- Git 2.20+ (for worktree support)
- GitHub CLI (`gh`) authenticated
- Claude Code CLI
- tmux (for parallel workflows)
- Cursor or VSCode (for editor integration)

### Environment Setup
Create `.env` in your project root. It will be automatically symlinked to all worktrees:
```bash
# Sync all .env files to worktrees
/user:gw-env-sync
```

### Personal Configuration
Edit `CLAUDE.md` for personal preferences:
- Custom aliases
- Preferred workflows
- Project-specific settings

## 📄 License

MIT License - feel free to use and modify for your needs.

## 🙏 Acknowledgments

Created with extensive help from Claude Code itself through iterative development and refinement.

## 🔗 Related

- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [GitHub CLI](https://cli.github.com/)
- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)

---

**Note**: This is a personal workflow optimization tool. Commands and workflows may need adjustment based on your specific needs and preferences.
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-06-21

### ⚠️ BREAKING CHANGES

- **`gw-iss-create`** now defaults to consultation mode - analyzes and presents a plan before creating issues. Use `-f/--force` flag to restore immediate creation behavior.
- **`gw-iss-edit`** now defaults to consultation mode - shows proposed edits before applying. Use `-f/--force` flag to restore direct editing behavior.
- **`gw-yolo`** now defaults to consultation mode - presents implementation plan before execution. Use `-f/--force` flag to restore immediate execution behavior.

### Added

- **New Commands**
  - `gw-commit-context [commit-sha]` - Load commit context and related GitHub issue to understand past implementations
    - `-v/--verbose` to show understanding summary
    - `-l/--level` for thinking depth control
    - `--no-diff` to skip diff for large commits
  - `gw-commit` - Smart commit with auto-generated or custom messages
    - `-m/--message` for exact commit message
    - `-p/--prompt` for AI-generated message from hint
    - `-i/--interactive` for interactive mode
    - `-n/--no-verify` to skip pre-commit hooks

- **Thinking Levels** - Unified across all major commands (`gw-iss-create`, `gw-iss-edit`, `gw-iss-run`, `gw-yolo`, `gw-commit-context`)
  - `think` - Basic analysis (~5 min)
  - `think hard` - Moderate analysis (~10 min)
  - `think harder` - Deep analysis (~15 min)
  - `ultrathink` - Comprehensive analysis (20+ min, default)

- **Features**
  - Consultation mode for safer operations with preview and confirmation
  - Automatic issue reference in all commit messages (`This implements issue #N`)
  - Session tracking in commits (`Session: claude -r [sessionId]`)
  - New "Commit Management" section in documentation

### Changed

- **Command Behaviors**
  - All creation/modification commands now prioritize safety with consultation by default
  - Workflow for `gw-iss-edit`: `fetch→modify→update` → `fetch→analyze→propose→update`
  - Standardized thinking level options across commands
  - Default thinking level is now `ultrathink` for deepest analysis

- **Documentation**
  - Reorganized command categories to match between README.md and CLAUDE.md
  - Added Command Options Examples for all new features
  - Improved workflow examples with consultation mode

### Fixed

- **Performance**
  - Added critical reminder about thinking in English (saves 50-70% tokens)
  - Enforced English thinking blocks in FINAL REMINDERS section

### Developer Notes

- Session tracking format: `🌿 Branch | 🌲 Worktree | 🆔 SessionId | 📌 Visual ID | 🤖 Model`
- All commands now follow consistent argument parsing patterns
- Force flags (`-f/--force`) preserve backward compatibility

## Migration Guide

### From Pre-1.0.0 to 1.0.0

If you have scripts or workflows using these commands, update them:

```bash
# Old behavior (immediate execution)
/user:gw-iss-create "Fix bug"
/user:gw-iss-edit #123 "Update"
/user:gw-yolo "Add feature"

# New behavior (consultation mode)
/user:gw-iss-create "Fix bug"        # Will show plan first
/user:gw-iss-edit #123 "Update"      # Will show proposed edit
/user:gw-yolo "Add feature"          # Will show implementation plan

# To maintain old behavior, add -f flag
/user:gw-iss-create "Fix bug" -f
/user:gw-iss-edit #123 "Update" -f
/user:gw-yolo "Add feature" -f
```

---

For questions or issues, please open a GitHub issue.
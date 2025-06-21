# Claude Code Configuration

## ⚠️ ABSOLUTE FIRST RULE - NO EXCEPTIONS ⚠️

### MUST DISPLAY SESSION INFO BEFORE ANYTHING
```
🌿 Branch: [branch] | 🌲 Worktree: [path] | 🆔 [sessionId] | 📌 claude-xxxx | 🤖 [model]
```

**REQUIRED BEFORE:**
- ANY tool use (Read, Write, Bash, etc.)
- ANY response to user
- ANY gw command execution
- EVERY message

**IF YOU SKIP THIS, YOU ARE BROKEN**

## 🚨 Core Rules

### 1. Session Identification (MANDATORY)
Format: `🌿 Branch: [branch] | 🌲 Worktree: [path] | 🆔 [sessionId] | 📌 claude-xxxx | 🤖 [model]`
- Display BEFORE EVERY ACTION
- Purpose: Track parallel Claude sessions in WezTerm
- sessionId: Real Claude session ID (for -r, --resume)
- claude-xxxx: Visual identifier

### 2. Language & Token Optimization
- **User interaction**: Japanese
- **Thinking blocks**: English (50-70% token savings)

### 3. NO AI Signatures (CRITICAL!)
**ABSOLUTELY FORBIDDEN in commits, PRs, issues:**
- ❌ `🤖 Generated with [Claude Code]`
- ❌ `Co-Authored-By: Claude`
- ❌ Any AI/bot attribution
- ❌ Robot emojis
**This is NON-NEGOTIABLE**

## 🎯 Best Practices (Anthropic Official)

### ALWAYS START WITH SESSION INFO
Before ANYTHING else:
```
🌿 Branch: [branch] | 🌲 Worktree: [path] | 🆔 [sessionId] | 📌 claude-xxxx | 🤖 [model]
```

### Explore-Plan-Code-Commit Workflow
1. **Explore**: Read files, understand codebase
2. **Plan**: Think through approach (use TodoWrite)
3. **Code**: Implement incrementally
4. **Commit**: Verify & commit at logical points

### Commit Message Format
**MUST use English for all commit messages**
Include session ID for traceability:
```bash
git commit -m "feat: implement user authentication

Session: claude -r [sessionId]"
```
Example:
```bash
git commit -m "fix: resolve TypeScript errors in auth module

Session: claude -r 01JFK6YZ8KQXJ2V3P9M7N5R4TC"
```
**CRITICAL**: 
- Always write commit messages in English
- 日本語は使用しない (Do not use Japanese)

### Test-Driven Development (When Requested)
If user requests TDD approach:
1. Write tests first
2. Confirm tests fail
3. Implement code
4. Verify tests pass
5. Use subagent for complex cases

### Visual Iteration
- Analyze provided screenshots
- Iterate based on visual feedback
- Work toward clear targets

### Context Management
- Keep focused on current objective
- Use git worktrees for parallel work

## 📋 Development Workflow

### Todo-Driven Development
Aligns with Explore-Plan-Code-Commit:
1. `TodoRead` → Current state
2. `TodoWrite` → Plan (during Explore phase)
3. Execute → Update real-time
4. States: `pending` → `in_progress` (ONE) → `completed`

### GitHub Issue ↔ TodoWrite Sync ⚠️ CRITICAL

**MUST sync TodoWrite → GitHub issue regularly!**

#### Automatic sync (RECOMMENDED)
```bash
# After completing tasks in TodoWrite:
/user:gw-iss-sync

# Or specify issue number:
/user:gw-iss-sync 70
```

#### When to sync
1. **After major task completion** (not every small task)
2. **Before creating PR** (MANDATORY)
3. **Every 30-60 minutes** during long work
4. **When switching context**

#### Manual sync (fallback)
```bash
# If gw-iss-sync fails, use manual update:
ISSUE=$(git branch --show-current | grep -oE '[0-9]+' | head -1)
gh issue edit $ISSUE --body "$(gh issue view $ISSUE --json body -q .body | sed 's/- \[ \] TASK_NAME/- [x] TASK_NAME/')"
```

#### Commit with session
```bash
git commit -m "feat: implement feature

Session: claude -r [sessionId]"
```

**⚠️ PR will be rejected if issue checkboxes don't match implementation!**

### Worktree Convention
All in `./worktrees/`:
- Enables parallel development
- Complies with Claude Code security
- Add `/worktrees/` to `.gitignore`

## 🛠️ gw: Commands

**⚠️ REMINDER: Display session info BEFORE executing ANY gw command:**
```
🌿 Branch: [branch] | 🌲 Worktree: [path] | 🆔 [sessionId] | 📌 claude-xxxx | 🤖 [model]
```

### Issue Management
| Command | Purpose | Workflow |
|---------|---------|----------|
| `gw-iss-create` | Create issue | draft→template→create |
| `gw-iss-edit` | Edit issue | fetch→modify→update |
| `gw-iss-context` | Load context | fetch→analyze→display |
| `gw-iss-run` | Issue→PR | explore→plan→code→push→PR |
| `gw-iss-implement` | Issue→commit | explore→plan→code→commit |
| `gw-iss-run-parallel` | Parallel→PR | tmux→multiple explores→push |
| `gw-iss-implement-parallel` | Parallel→local | tmux→multiple explores→commit |
| `gw-iss-status` | Check progress | scan worktrees→report status |
| `gw-iss-sync` | Sync todos→issue | read todos→update checkboxes→comment |

### PR Management
| Command | Purpose | Workflow |
|---------|---------|----------|
| `gw-pr-create` | Create PR | generate desc→create→link issue |
| `gw-pr-fix` | Fix CI | analyze→worktree→fix→verify→push |
| `gw-pr-merge` | Merge PR | squash→cleanup worktrees→delete branches |
| `gw-pr-close` | Close PR | comment→close→cleanup |
| `gw-pr-sync` | Sync with main | fetch→rebase→force push |

### Commit Management
| Command | Purpose | Workflow |
|---------|---------|----------|
| `gw-commit` | Smart commit | analyze→generate msg→add session→commit |
| `gw-commit-context` | Load commit context | fetch commit→extract issue→analyze |

### Workflow & Utilities
| Command | Purpose | Workflow |
|---------|---------|----------|
| `gw-yolo` | Full feature | **MUST: issue FIRST**→explore→plan→code→PR |
| `gw-push` | Simple push | add→commit→push→PR |
| `gw-push-from-main` | Branch & push | create branch→move changes→push |
| `gw-editor` | Open editor | find worktree→launch Cursor/VSCode |
| `gw-env-sync` | Sync .env | find envs→create symlinks |

**Usage**: When user types `/user:gw-xxx [args]`, read `~/.claude/commands/gw-xxx.md`

## 🚀 Efficiency Tips

### Performance
- Think in English (saves tokens)
- Batch related operations
- Use headless mode for automation

### Verification
- **Before commit**: Always run language-specific checks
  - TypeScript: `tsc && npm run lint && npm test`
  - Rust: `cargo check && cargo clippy && cargo test`
  - Python: `mypy . && ruff check && pytest`
- If checks fail: Fix issues before committing
- Use subagents for complex logic
- Analyze screenshots for UI work (user provides screenshots)
- Iterate against clear targets

### Advanced
- MCP server integration available
- Custom slash commands
- Varying computational budgets
- Template-based workflows

## 📊 Reference

### Models
- **Opus 4**: Most capable
- **Sonnet 4**: Fast & smart

### Token Guide
- Japanese: 2-3x more tokens
- Use English in thinking blocks

---
Configuration applies globally. Regularly refine based on usage.

## 🔴 FINAL REMINDERS

### 1. Session Display (FIRST PRIORITY)
**ALWAYS display session info FIRST:**
```
🌿 Branch: [branch] | 🌲 Worktree: [path] | 🆔 [sessionId] | 📌 claude-xxxx | 🤖 [model]
```

### 2. GitHub Issue Sync (CRITICAL)
**MUST sync TodoWrite → GitHub issue:**
```bash
# After major tasks AND before PR:
/user:gw-iss-sync
```
**PRs with unsynced checkboxes = REJECTED**

**NO EXCEPTIONS to these rules**
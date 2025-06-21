Edit GitHub issue through consultation and review.

ISSUE_NUMBER: First argument (e.g., 123 or #123)
CONTENT: Everything after the issue number

## Purpose

Add new findings, errors, or notes to an existing GitHub issue during implementation with intelligent formatting and review.

## Usage

```bash
# Default: consultation mode with ultrathink (review before editing)
/user:gw-iss-edit #123 "Found memory leak in auth module"

# Force immediate edit (skip consultation)
/user:gw-iss-edit #123 "Quick note about API" -f
/user:gw-iss-edit #123 "Quick note about API" --force

# Specify thinking level
/user:gw-iss-edit #123 -l think              # Quick analysis (~5 min)
/user:gw-iss-edit #123 -l "think hard"       # Moderate analysis (~10 min)
/user:gw-iss-edit #123 -l "think harder"     # Deep analysis (~15 min)
/user:gw-iss-edit #123 -l ultrathink         # Full context integration (20+ min)

# Interactive mode (no content provided)
/user:gw-iss-edit #123

# Combine flags
/user:gw-iss-edit #123 "Complex findings" -l "think hard"
/user:gw-iss-edit #123 "Quick fix" -f
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
ISSUE_NUM=""
CONTENT=""
FORCE_EDIT=false
THINKING_LEVEL="ultrathink"  # Default to deepest analysis

# Parse arguments
for arg in "$@"; do
  case $arg in
    -f|--force)
      FORCE_EDIT=true
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
    *)
      # First non-flag is issue number
      if [ -z "$ISSUE_NUM" ]; then
        ISSUE_NUM=$(echo "$arg" | sed 's/^#//')
      else
        # Rest is content
        if [ -z "$CONTENT" ]; then
          CONTENT="$arg"
        else
          CONTENT="$CONTENT $arg"
        fi
      fi
      ;;
  esac
done
```

### 2. Fetch current issue content
```bash
echo "📖 Fetching issue #$ISSUE_NUM..."
ISSUE_DATA=$(gh issue view $ISSUE_NUM --json body,title,state,labels)
CURRENT_BODY=$(echo "$ISSUE_DATA" | jq -r .body)
ISSUE_TITLE=$(echo "$ISSUE_DATA" | jq -r .title)
```

### 3. Determine content to add

If no content provided:
```bash
if [ -z "$CONTENT" ]; then
  echo "What would you like to add to issue #$ISSUE_NUM?"
  read CONTENT
fi
```

### 4. Consultation Mode (Default)

```bash
if [ "$FORCE_EDIT" = false ]; then
  echo "📋 Analyzing issue and your update with '$THINKING_LEVEL' computational budget..."
  echo ""
  
  # Claude analyzes with specified thinking level:
  # - think: Basic formatting and placement (~5 min)
  # - think hard: Context integration, checkbox detection (~10 min)
  # - think harder: Impact analysis, related tasks (~15 min)
  # - ultrathink: Full history review, optimal integration (20+ min)
  
  echo "## 🎯 Current Issue: #$ISSUE_NUM - $ISSUE_TITLE"
  echo ""
  echo "## 📝 Proposed Update"
  echo ""
  echo "### Your Input:"
  echo "$CONTENT"
  echo ""
  echo "### Suggested Format:"
  echo "---"
  echo "## Update: $(date '+%Y-%m-%d %H:%M')"
  echo ""
  echo "[Claude's intelligently formatted version of the content]"
  echo "- [ ] Any new tasks detected"
  echo "- [ ] Additional checklist items"
  echo ""
  echo "Session: \`claude -r [sessionId]\`"
  echo ""
  echo "### Integration Analysis:"
  echo "- Where this fits in the issue structure"
  echo "- Related existing tasks"
  echo "- Suggested additional context"
  echo ""
  echo "---"
  echo ""
  echo "Proceed with this update? (y/n)"
  read CONFIRM
  
  if [ "$CONFIRM" != "y" ]; then
    echo "❌ Update cancelled"
    exit 0
  fi
fi
```

### 5. Format the addition

```bash
# Format based on consultation or direct mode
if [ "$FORCE_EDIT" = true ]; then
  # Simple format for force mode
  FORMATTED_UPDATE="

---
## Update: $(date '+%Y-%m-%d %H:%M')

$CONTENT

Session: \`claude -r [sessionId]\`"
else
  # Use Claude's intelligent formatting from consultation
  FORMATTED_UPDATE="[Claude's approved formatted update]"
fi
```

### 6. Update the issue

```bash
# Append formatted content
NEW_BODY="$CURRENT_BODY$FORMATTED_UPDATE"

# Update issue
echo "✏️ Updating issue #$ISSUE_NUM..."
gh issue edit $ISSUE_NUM --body "$NEW_BODY"

if [ $? -eq 0 ]; then
  echo "✅ Issue #$ISSUE_NUM updated successfully"
else
  echo "❌ Failed to update issue"
  exit 1
fi
```

### 7. Re-read and process

After updating:
1. Re-fetch the updated issue
2. Parse any new checkboxes added
3. Update TodoWrite if new tasks were added
4. Show confirmation of what was added

## Example usage scenarios

### Scenario 1: Default consultation mode
```
/user:gw-iss-edit #1 "Error: API_KEY not needed anymore"

📋 Analyzing issue and your update with 'ultrathink' computational budget...

## 🎯 Current Issue: #1 - Implement user authentication

## 📝 Proposed Update

### Your Input:
Error: API_KEY not needed anymore

### Suggested Format:
---
## Update: 2025-06-21 15:30

### Configuration Change Required

Error discovered: The API_KEY environment variable is no longer needed after switching to OAuth.

**Action items:**
- [ ] Remove API_KEY from .env.example
- [ ] Update environment documentation
- [ ] Remove API_KEY validation from config loader

This simplifies our deployment process.

Session: `claude -r 01JFK6YZ8KQXJ2V3P9M7N5R4TC`

### Integration Analysis:
- This update relates to the "Environment Setup" section
- Affects deployment documentation task
- Should be addressed before PR creation

---

Proceed with this update? (y/n)
```

### Scenario 2: Force mode (skip consultation)
```
/user:gw-iss-edit #1 "Quick note: Tests passing" -f

✏️ Updating issue #1...
✅ Issue #1 updated successfully
```

### Scenario 3: Different thinking levels
```
# Quick formatting
/user:gw-iss-edit #1 "Found typo" -l think

# Deeper integration
/user:gw-iss-edit #1 "Major architectural concern" -l ultrathink
```

### Scenario 4: Interactive mode
```
/user:gw-iss-edit #1

What would you like to add to issue #1?
> The login endpoint needs rate limiting

📋 Analyzing issue and your update with 'ultrathink' computational budget...
[consultation continues...]
```
> Only using 4 commands actually

✅ Issue #1 updated
📋 New tasks added to TodoWrite
```

## Features

- **Preserves existing content**: Only appends, never overwrites
- **Timestamped updates**: Each edit is clearly marked with time
- **Auto-sync**: If new checkboxes are added, they're imported to TodoWrite
- **Context preservation**: Keeps implementation context intact

## Common use cases

1. **Add error logs**: Document errors encountered during implementation
2. **Add findings**: Note discoveries about the codebase
3. **Add new tasks**: Append new checkboxes for additional work
4. **Add notes**: Implementation decisions or blockers

## Format examples

### Adding new tasks
```
- [ ] Remove API_KEY from required env vars
- [ ] Update documentation for env variables
```

### Adding error info
```
Found error in config.js:
- API_KEY is required but not used
- Only 4 operations actually needed: auth/fetch/process/cleanup
```

### Adding implementation notes
```
Decision: Removing unused environment variables
Affected files:
- apps/api/src/config.ts
- .env.example
```
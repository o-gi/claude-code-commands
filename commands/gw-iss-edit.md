Edit GitHub issue by appending new information.

ISSUE_NUMBER: First argument (e.g., 123 or #123)
CONTENT: Everything after the issue number

## Purpose

Add new findings, errors, or notes to an existing GitHub issue during implementation.

## Usage

```bash
/user:gw-iss-edit 123
/user:gw-iss-edit #123
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 2. Parse issue number and content
```bash
# Extract issue number (first argument)
ISSUE_NUM=$(echo "$ARGUMENTS" | sed 's/^#//' | awk '{print $1}')

# Extract content (everything after issue number)
CONTENT=$(echo "$ARGUMENTS" | sed 's/^#\?[0-9]\+ *//')
```

### 3. Fetch current issue content
```bash
gh issue view $ISSUE_NUM --json body,title
```

### 4. Determine content to add

If no content provided after issue number:
- Ask: "What would you like to add to issue #$ISSUE_NUM?"
- Wait for user input

If content provided:
- Use the provided content directly

### 5. Format the addition

Create a formatted section to append:
```markdown
---
## Update: [timestamp]

[User's input here]
```

### 6. Update the issue

```bash
# Get current body
CURRENT_BODY=$(gh issue view $ISSUE_NUM --json body -q .body)

# Append new content
NEW_BODY="$CURRENT_BODY

---
## Update: $(date '+%Y-%m-%d %H:%M')

$USER_INPUT

Session: \`claude -r [sessionId]\`"

# Update issue
gh issue edit $ISSUE_NUM --body "$NEW_BODY"
```

### 7. Re-read and process

After updating:
1. Re-fetch the updated issue
2. Parse any new checkboxes added
3. Update TodoWrite if new tasks were added
4. Show confirmation of what was added

## Example usage scenarios

### Scenario 1: With content provided
```
/user:gw-iss-edit #1 Error: API_KEY not needed
- [ ] Remove API_KEY
- [ ] Update env documentation
```

### Scenario 2: Without content (interactive)
```
/user:gw-iss-edit #1

> What would you like to add to issue #1?
> Error: Missing required environment variable
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
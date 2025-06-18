Create a GitHub issue by understanding your needs.

## Usage

```bash
# Default: include original request in issue
/user:gw-iss-create "fix login error"

# Exclude original request
/user:gw-iss-create -np "fix login error"
/user:gw-iss-create --no-prompt "fix login error"

# Flag position is flexible
/user:gw-iss-create "fix login error" -np
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Parse arguments flexibly
```bash
# Initialize variables
USER_INPUT=""
INCLUDE_PROMPT=true

# Parse all arguments
for arg in "$@"; do
  case $arg in
    -np|--no-prompt)
      INCLUDE_PROMPT=false
      ;;
    *)
      # Collect non-flag arguments as user input
      if [ -z "$USER_INPUT" ]; then
        USER_INPUT="$arg"
      else
        USER_INPUT="$USER_INPUT $arg"
      fi
      ;;
  esac
done

# If no input provided, ask for it
if [ -z "$USER_INPUT" ]; then
  echo "What would you like to address?"
  read USER_INPUT
fi
```

2. **Parse input and create issue immediately**
   - Accept natural language input directly
   - Examples: "Prisma upgrade", "login error", "add dark mode"

3. **Interpret and structure**
   - Generate appropriate issue title
   - Auto-detect issue type (Bug/Feature/Chore)
   - Structure the details

4. **Ask clarifying questions if needed**
   - "What's the current version?"
   - "Can you describe the error?"
   - Only ask when necessary

5. **Preview the issue**
   - Show generated title and body
   - Allow edits if needed

6. **Create on GitHub**
   ```bash
   # Generate issue body based on INCLUDE_PROMPT flag
   if [ "$INCLUDE_PROMPT" = true ]; then
     ISSUE_BODY="Session: \`claude -r [sessionId]\`
   
   ## Overview
   [Claude generates overview]
   
   ## Tasks
   [Claude generates task list]
   
   ---
   <details>
   <summary>📝 Original Request</summary>
   
   \`\`\`
   $USER_INPUT
   \`\`\`
   
   Created via: \`/user:gw-iss-create\`  
   Date: $(date +%Y-%m-%d)
   </details>"
   else
     # Without original request
     ISSUE_BODY="Session: \`claude -r [sessionId]\`
   
   ## Overview
   [Claude generates overview]
   
   ## Tasks
   [Claude generates task list]
   
   ---
   Created via: \`/user:gw-iss-create -np\`  
   Date: $(date +%Y-%m-%d)"
   fi
   
   # Create issue
   gh issue create --title "title" --body "$ISSUE_BODY"
   ```

## Input/Output Examples

### Example 1
Input: "Prisma upgrade"
Output:
- Title: "Upgrade Prisma to latest version"
- Type: Chore
- Body: Dependencies update, migration checks, etc.

### Example 2
Input: "500 error on login"
Output:
- Title: "Fix 500 error occurring during login"
- Type: Bug
- Body: Error details, reproduction steps, impact

### Example 3
Input: "want dark mode"
Output:
- Title: "Add dark mode support"
- Type: Feature
- Body: Implementation scope, UI components, etc.

## Usage Flow

### Direct usage (recommended)
```
/user:gw-iss-create Prisma upgrade
```

### Interactive usage (if no input)
```
/user:gw-iss-create

> What would you like to address?
> Prisma upgrade

> What's the current Prisma version? (Enter to skip)
> 5.19

📋 Creating issue with:

Title: Upgrade Prisma from v5.19 to latest version
Type: Chore
Labels: dependencies, maintenance

Body:
## Overview
Upgrade Prisma to the latest released version.

## Current Status
- Current version: 5.19
- Latest version: [to be checked]

## Tasks
- [ ] Check latest version changelog
- [ ] Review breaking changes
- [ ] Update packages
- [ ] Regenerate Prisma Client
- [ ] Verify migrations
- [ ] Run tests

---
<details>
<summary>📝 Original Request</summary>

```
Prisma upgrade
```

Created via: `/user:gw-iss-create`
Date: $(date +%Y-%m-%d)
</details>

Create this issue? (y/n/edit)
```

## Important Note

**This command ONLY creates GitHub issues.**
- Does NOT start implementation
- Does NOT modify local files
- Only registers the issue on GitHub

**Direct usage is preferred:**
- `/user:gw-iss-create fix login bug` → Creates issue immediately
- `/user:gw-iss-create add dark mode` → Creates issue immediately
- No need to say "create issue" - the command name already implies that!
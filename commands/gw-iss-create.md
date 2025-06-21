Create a GitHub issue through consultation and planning.

## Usage

```bash
# Default: consultation mode (plan before creating)
/user:gw-iss-create "fix login error"

# Force immediate creation (skip consultation)
/user:gw-iss-create "fix login error" -f
/user:gw-iss-create "fix login error" --force

# Exclude original request from issue body
/user:gw-iss-create "fix login error" -np
/user:gw-iss-create "fix login error" --no-prompt

# Combine flags
/user:gw-iss-create "fix login error" -f -np
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
FORCE_CREATE=false

# Parse all arguments
for arg in "$@"; do
  case $arg in
    -np|--no-prompt)
      INCLUDE_PROMPT=false
      ;;
    -f|--force)
      FORCE_CREATE=true
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

### 2. Consultation Mode (Default)

```bash
if [ "$FORCE_CREATE" = false ]; then
  echo "📋 Analyzing your request..."
  echo ""
  
  # Claude analyzes the request and proposes:
  # 1. Issue title
  # 2. Issue type (Bug/Feature/Chore/Refactor)
  # 3. Task breakdown
  # 4. Implementation approach
  # 5. Potential challenges
  
  echo "## Proposed Issue"
  echo ""
  echo "**Title**: [Generated title]"
  echo "**Type**: Feature/Bug/Chore"
  echo "**Labels**: [suggested labels]"
  echo ""
  echo "### Overview"
  echo "[Generated overview based on analysis]"
  echo ""
  echo "### Tasks"
  echo "- [ ] [Task 1]"
  echo "- [ ] [Task 2]"
  echo "- [ ] [Task 3]"
  echo ""
  echo "### Implementation Notes"
  echo "[Any important considerations]"
  echo ""
  echo "---"
  echo ""
  echo "What would you like to do?"
  echo "1. Create issue as-is"
  echo "2. Modify the proposal"
  echo "3. Add more details"
  echo "4. Cancel"
  echo ""
  read -p "Choice (1-4): " CHOICE
  
  case $CHOICE in
    1)
      # Proceed to create
      ;;
    2)
      echo "What would you like to modify?"
      # Allow iterative refinement
      # Claude will update the proposal based on feedback
      ;;
    3)
      echo "What additional details would you like to add?"
      # Claude incorporates additional context
      ;;
    4)
      echo "❌ Issue creation cancelled"
      exit 0
      ;;
  esac
  
  # Loop until user is satisfied
  # Claude can have multiple rounds of refinement
fi
```

### 3. Create Issue

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

## Consultation Mode Examples

### Example 1: Feature Request
```
/user:gw-iss-create "add user authentication"

📋 Analyzing your request...

## Proposed Issue

**Title**: Implement user authentication system
**Type**: Feature
**Labels**: enhancement, backend, frontend

### Overview
Add a complete user authentication system with login, logout, and session management capabilities.

### Tasks
- [ ] Design authentication flow and database schema
- [ ] Implement backend authentication API
- [ ] Create login/register UI components
- [ ] Add session management and JWT tokens
- [ ] Implement password reset functionality
- [ ] Add authentication middleware
- [ ] Write tests for auth endpoints
- [ ] Update documentation

### Implementation Notes
- Consider using bcrypt for password hashing
- JWT tokens with refresh token pattern
- Need to decide on session storage (Redis/Database)

---

What would you like to do?
1. Create issue as-is
2. Modify the proposal
3. Add more details
4. Cancel

Choice (1-4): 3

What additional details would you like to add?
> Also need OAuth integration with Google and GitHub

📋 Updated proposal:

### Tasks
- [ ] Design authentication flow and database schema
- [ ] Implement backend authentication API
- [ ] Create login/register UI components
- [ ] Add session management and JWT tokens
- [ ] Implement password reset functionality
- [ ] Add authentication middleware
- [ ] Integrate OAuth providers (Google, GitHub)
- [ ] Create OAuth callback handlers
- [ ] Write tests for auth endpoints
- [ ] Update documentation

### Implementation Notes
- Consider using bcrypt for password hashing
- JWT tokens with refresh token pattern
- Need to decide on session storage (Redis/Database)
- Use Passport.js or similar for OAuth integration

[Continue until satisfied...]
```

### Example 2: Bug Report
```
/user:gw-iss-create "users can't login after midnight"

📋 Analyzing your request...

## Proposed Issue

**Title**: Fix login failure occurring after midnight
**Type**: Bug
**Labels**: bug, critical, authentication

### Overview
Users are experiencing login failures when attempting to authenticate after midnight. This appears to be a timezone or timestamp validation issue.

### Tasks
- [ ] Reproduce the issue in development environment
- [ ] Check timezone handling in authentication logic
- [ ] Review JWT token expiration logic
- [ ] Verify database timestamp comparisons
- [ ] Add logging to identify exact failure point
- [ ] Implement fix
- [ ] Add tests for edge cases around midnight
- [ ] Test in different timezones

### Implementation Notes
- Priority: Critical - affecting user access
- Likely related to UTC/local time conversion
- Check for any scheduled jobs running at midnight

What would you like to do?
[...]
```

## Force Mode (-f flag)

When using `-f` or `--force`, the command behaves like the original version:
- Immediately creates the issue without consultation
- No interactive planning phase
- Useful when you're certain about the issue details

```bash
/user:gw-iss-create "fix typo in README" -f
# Creates issue immediately without consultation
```

## Benefits of Consultation Mode

1. **Better Issue Quality**
   - Well-structured task lists
   - Clear implementation approach
   - Comprehensive scope definition

2. **Avoid Incomplete Issues**
   - Catch missing requirements early
   - Add important details before creation
   - Reduce need for issue edits later

3. **Learning & Planning**
   - Understand complexity before starting
   - Identify potential challenges
   - Better time estimation

4. **Flexibility**
   - Iterative refinement
   - Add context as needed
   - Cancel if requirements unclear

## Important Notes

- **Default is consultation mode** - plan before creating
- Use `-f` flag for immediate creation when confident
- Can combine with `-np` to exclude original request
- GitHub issue is only created after confirmation
- No local changes are made by this command
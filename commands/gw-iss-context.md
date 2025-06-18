Load GitHub issue context for Claude to understand requirements.

## Purpose

Load and analyze a GitHub issue so Claude Code can understand the context, requirements, and implementation details before starting work. This helps Claude grasp the full scope of the task.

## Usage

```bash
/user:gw-iss-context 1
/user:gw-iss-context #1
```

Both formats are supported - with or without the # symbol.

## Actions

1. **Parse issue number**
```bash
# Remove # if present and extract issue number
ISSUE_NUM=$(echo "$ARGUMENTS" | sed 's/^#//' | awk '{print $1}')
```

2. **Display issue details**
```bash
gh issue view $ISSUE_NUM
```

3. **Show issue metadata**
- Title
- Status
- Labels
- Assignees
- Description
- Comments

## Why use this command

When Claude Code reads an issue through this command, it can:
- Understand the full requirements and acceptance criteria
- Identify technical constraints and dependencies
- Plan the implementation approach based on issue details
- Reference specific requirements during implementation

## What Claude does after reading

1. **Analyzes requirements**: Understands what needs to be built
2. **Identifies key tasks**: Breaks down the issue into actionable items
3. **Plans approach**: Determines the best implementation strategy
4. **Remembers context**: Keeps issue details in mind during work

## What this command does NOT do

- Does NOT create branches
- Does NOT start implementation
- Does NOT modify any files
- Does NOT create TodoWrite tasks

## Next steps after context loading

After Claude understands the issue context:
- Use `/user:gw-iss-run $ISSUE_NUM` to start implementation
- Use `/user:gw-iss-edit $ISSUE_NUM` if clarification is needed
- Claude can now make informed decisions about the implementation
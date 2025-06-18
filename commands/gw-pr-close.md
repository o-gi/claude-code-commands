Close PR without merging and cleanup all related branches/worktrees.

## Usage

```
/user:gw-pr-close <PR-number> [-c "comment"] [-p "prompt"]
```

## Examples

```bash
# Close PR without comment
/user:gw-pr-close 45

# Close with direct comment
/user:gw-pr-close 45 -c "CIが通らないため一旦クローズ"

# Close with Claude-generated message
/user:gw-pr-close 45 -p "動作してないから"
```

## Options

- `-c, --comment`: Add exact comment as provided
- `-p, --prompt`: Generate professional message from prompt using Claude

## Workflow

1. **Parse arguments**
   - Extract PR number
   - Check for -c or -p flags
   - Get comment/prompt text

2. **Handle comment options**
   - If `-c`: Use comment as-is
   - If `-p`: 
     - Generate professional message from prompt
     - Show generated message for confirmation
     - Ask user to confirm before proceeding
   - If neither: No comment

3. **Close PR**
   ```bash
   # Without comment
   gh pr close <PR-number>
   
   # With comment
   gh pr comment <PR-number> -b "<message>"
   gh pr close <PR-number>
   ```

4. **Get issue number from PR**
   ```bash
   ISSUE_NUM=$(gh pr view <PR-number> --json number -q '.number')
   ```

5. **Find all related branches/worktrees**
   - Same logic as gw-pr-merge
   - Find all branches with issue number
   - Find all worktrees (including parallel ones)

6. **Cleanup process**
   - Switch to main if in worktree
   - Remove all worktrees
   - Delete all local branches
   - Update main branch

## Message Generation Examples (-p option)

### Input: "動作してないから"
### Generated:
```
技術的な問題により、現在の実装では期待通りの動作が確認できないため、
一旦このPRをクローズします。別のアプローチを検討後、新しいPRで対応予定です。
```

### Input: "CIエラー"
### Generated:
```
CI環境でのテストエラーが解決できないため、このPRを一旦クローズします。
エラーの原因を調査し、修正後に新たなPRを作成して対応いたします。
```

### Input: "要件変更"
### Generated:
```
要件に変更があったため、現在のPRをクローズします。
新しい要件に基づいた実装を行い、別途PRを作成する予定です。
ご確認いただいた内容については、今後の実装に活かさせていただきます。
```

## Confirmation Flow

When using `-p` option:
```
📝 Generated message:
----------------------------------------
[Generated professional message here]
----------------------------------------

Is this message OK? (y/n): 
```

## Safety Features

- ✅ Confirms before closing PR
- ✅ Shows what will be cleaned up
- ✅ Handles current directory properly
- ✅ Updates other PRs if needed
- ✅ Professional message generation with confirmation

## Implementation Steps

1. Parse command arguments for PR number and options
2. If -p flag, generate and confirm message
3. Add comment to PR if message provided
4. Close the PR
5. Find all related branches/worktrees
6. Perform cleanup (same as merge, but without merging)
7. Show summary of actions taken

## Error Handling

- PR not found → Show error
- Already closed → Skip close, ask if cleanup needed
- Network issues → Retry options
- No related branches → Just close PR

## Notes

- Always updates main after cleanup
- Removes ALL related worktrees (including parallel)
- Professional messages are generated in Japanese
- Comment is added before closing for visibility
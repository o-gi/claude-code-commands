Sync .env files from root to all worktrees.

## Purpose

Synchronize all .env* files from the root directory (and monorepo app directories) to worktrees using symbolic links. This ensures consistent environment variables across all parallel development environments.

## Usage

```bash
# Sync to all worktrees
/user:gw-env-sync

# Sync to specific worktree only
/user:gw-env-sync issue-42

# List current .env files and their link status
/user:gw-env-sync --status
```

## Workflow

### 0. Display session info
```bash
# Display current session context
source ~/.claude/commands/_session-display.sh
```

### 1. Parse arguments
```bash
TARGET_WORKTREE="$1"
STATUS_ONLY=false

if [ "$1" = "--status" ]; then
  STATUS_ONLY=true
fi
```

### 2. Find all .env files
```bash
echo "🔍 Scanning for .env files..."

# Find all .env* files in root
ROOT_ENV_FILES=$(find . -maxdepth 1 -name ".env*" -type f | grep -v ".env.example" | sort)

# For monorepo: find .env files in apps/packages directories
MONOREPO_ENV_FILES=""
if [ -f "pnpm-workspace.yaml" ] || [ -f "lerna.json" ] || [ -f "turbo.json" ]; then
  echo "📦 Monorepo detected - scanning app directories..."
  MONOREPO_ENV_FILES=$(find apps packages -maxdepth 2 -name ".env*" -type f 2>/dev/null | grep -v ".env.example" | sort)
fi

# Combine all env files
ALL_ENV_FILES=$(echo -e "$ROOT_ENV_FILES\n$MONOREPO_ENV_FILES" | grep -v "^$" | sort -u)

if [ -z "$ALL_ENV_FILES" ]; then
  echo "⚠️  No .env files found"
  exit 0
fi

echo "📋 Found .env files:"
echo "$ALL_ENV_FILES" | sed 's/^/  - /'
```

### 3. Show status if requested
```bash
if [ "$STATUS_ONLY" = true ]; then
  echo -e "\n📊 Current .env link status:"
  
  # Check each worktree
  for WORKTREE in ./worktrees/*/; do
    if [ -d "$WORKTREE" ]; then
      WORKTREE_NAME=$(basename "$WORKTREE")
      echo -e "\n🌲 Worktree: $WORKTREE_NAME"
      
      # Check each env file
      for ENV_FILE in $ALL_ENV_FILES; do
        ENV_BASENAME=$(basename "$ENV_FILE")
        ENV_RELPATH=$(realpath --relative-to="$WORKTREE" "$ENV_FILE")
        TARGET_PATH="$WORKTREE/$ENV_BASENAME"
        
        if [ -L "$TARGET_PATH" ]; then
          if [ -e "$TARGET_PATH" ]; then
            echo "  ✅ $ENV_BASENAME → linked (valid)"
          else
            echo "  ❌ $ENV_BASENAME → linked (broken)"
          fi
        elif [ -f "$TARGET_PATH" ]; then
          echo "  ⚠️  $ENV_BASENAME → regular file (not linked)"
        else
          echo "  ❌ $ENV_BASENAME → missing"
        fi
      done
    fi
  done
  exit 0
fi
```

### 4. Find worktrees to sync
```bash
# Get list of worktrees
if [ -n "$TARGET_WORKTREE" ]; then
  # Specific worktree requested
  WORKTREE_PATH="./worktrees/$TARGET_WORKTREE"
  if [ ! -d "$WORKTREE_PATH" ]; then
    echo "❌ Worktree not found: $WORKTREE_PATH"
    exit 1
  fi
  WORKTREES="$WORKTREE_PATH"
else
  # All worktrees
  WORKTREES=$(find ./worktrees -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  if [ -z "$WORKTREES" ]; then
    echo "⚠️  No worktrees found in ./worktrees/"
    exit 0
  fi
fi
```

### 5. Sync .env files to worktrees
```bash
echo -e "\n🔄 Syncing .env files to worktrees..."

for WORKTREE in $WORKTREES; do
  WORKTREE_NAME=$(basename "$WORKTREE")
  echo -e "\n🌲 Processing worktree: $WORKTREE_NAME"
  
  # Process each .env file
  for ENV_FILE in $ALL_ENV_FILES; do
    ENV_BASENAME=$(basename "$ENV_FILE")
    ENV_DIR=$(dirname "$ENV_FILE")
    
    # Calculate relative path from worktree to original env file
    ENV_RELPATH=$(realpath --relative-to="$WORKTREE" "$ENV_FILE")
    
    # Determine target location in worktree
    if [ "$ENV_DIR" = "." ]; then
      # Root .env file - link to worktree root
      TARGET_PATH="$WORKTREE/$ENV_BASENAME"
    else
      # Monorepo app .env file - maintain directory structure
      TARGET_DIR="$WORKTREE/$ENV_DIR"
      TARGET_PATH="$TARGET_DIR/$ENV_BASENAME"
      
      # Create directory if needed
      if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
        echo "  📁 Created directory: $ENV_DIR"
      fi
    fi
    
    # Check if link already exists
    if [ -L "$TARGET_PATH" ]; then
      # Check if link is valid
      if [ -e "$TARGET_PATH" ]; then
        echo "  ✅ $ENV_FILE → already linked"
      else
        # Broken link - recreate
        echo "  🔧 $ENV_FILE → fixing broken link"
        rm "$TARGET_PATH"
        ln -s "$ENV_RELPATH" "$TARGET_PATH"
      fi
    elif [ -f "$TARGET_PATH" ]; then
      # Regular file exists - ask before replacing
      echo "  ⚠️  $ENV_FILE → regular file exists"
      read -p "    Replace with symlink? (y/n) " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$TARGET_PATH"
        ln -s "$ENV_RELPATH" "$TARGET_PATH"
        echo "    ✅ Replaced with symlink"
      else
        echo "    ⏭️  Skipped"
      fi
    else
      # Create new symlink
      ln -s "$ENV_RELPATH" "$TARGET_PATH"
      echo "  ✅ $ENV_FILE → linked"
    fi
  done
done

echo -e "\n✅ Sync complete!"
```

### 6. Show summary
```bash
# Count synced files
TOTAL_WORKTREES=$(echo "$WORKTREES" | wc -l)
TOTAL_ENV_FILES=$(echo "$ALL_ENV_FILES" | wc -l)

echo -e "\n📊 Summary:"
echo "  - Worktrees synced: $TOTAL_WORKTREES"
echo "  - .env files linked: $TOTAL_ENV_FILES"
echo -e "\n💡 Tips:"
echo "  - Run 'gw-env-sync --status' to check link status"
echo "  - Links are relative, so they survive moves"
echo "  - Add new .env files to .gitignore"
```

## Features

### Monorepo support
- Detects monorepo structure (pnpm/lerna/turbo)
- Maintains directory structure for app-specific .env files
- Example: `apps/web/.env` → `worktrees/issue-42/apps/web/.env`

### Smart linking
- Uses relative paths for portability
- Detects and fixes broken links
- Preserves existing regular files (with confirmation)

### Safety features
- Excludes .env.example files
- Confirms before replacing existing files
- Shows clear status for each operation

## Examples

### Basic sync
```bash
/user:gw-env-sync

🔍 Scanning for .env files...
📋 Found .env files:
  - .env
  - .env.local
  - apps/web/.env
  - apps/api/.env

🔄 Syncing .env files to worktrees...

🌲 Processing worktree: issue-1
  ✅ .env → linked
  ✅ .env.local → linked
  📁 Created directory: apps/web
  ✅ apps/web/.env → linked
  📁 Created directory: apps/api
  ✅ apps/api/.env → linked

✅ Sync complete!
```

### Check status
```bash
/user:gw-env-sync --status

📊 Current .env link status:

🌲 Worktree: issue-1
  ✅ .env → linked (valid)
  ✅ .env.local → linked (valid)
  ❌ .env.test → missing
  
🌲 Worktree: pr-2
  ✅ .env → linked (valid)
  ⚠️ .env.local → regular file (not linked)
```

### Sync specific worktree
```bash
/user:gw-env-sync issue-2

🔄 Syncing .env files to worktrees...

🌲 Processing worktree: issue-2
  ✅ .env → linked
  ✅ .env.local → linked
```

## Notes

- Symlinks are relative, making them portable
- Works with nested monorepo structures
- Respects .gitignore (doesn't affect git tracking)
- Safe to run multiple times (idempotent)
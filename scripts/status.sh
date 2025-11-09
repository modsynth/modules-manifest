#!/bin/bash
# Show status of all synced modules

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE_ROOT="$MANIFEST_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Modsynth Module Status               ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Find all git repositories in modules/
if [ ! -d "$WORKSPACE_ROOT/modules" ]; then
    echo -e "${YELLOW}No modules synced yet. Run ./scripts/sync.sh to sync modules.${NC}"
    exit 0
fi

# Count modules
TOTAL=0
CLEAN=0
DIRTY=0

find "$WORKSPACE_ROOT/modules" -type d -name ".git" | while read -r git_dir; do
    module_dir=$(dirname "$git_dir")
    module_name=$(basename "$module_dir")
    relative_path=${module_dir#$WORKSPACE_ROOT/}

    TOTAL=$((TOTAL + 1))

    cd "$module_dir"

    # Get current branch/tag
    current=$(git describe --tags --exact-match 2>/dev/null || git rev-parse --abbrev-ref HEAD)

    # Check if clean
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        status="${GREEN}✓ Clean${NC}"
        CLEAN=$((CLEAN + 1))
    else
        status="${RED}✗ Modified${NC}"
        DIRTY=$((DIRTY + 1))
    fi

    # Get latest commit
    last_commit=$(git log -1 --oneline --no-decorate)

    echo -e "${BLUE}📦 $module_name${NC} ($current)"
    echo -e "   Path: $relative_path"
    echo -e "   Status: $status"
    echo -e "   Last: $last_commit"

    # Show modified files if any
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${YELLOW}   Modified files:${NC}"
        git status -s | sed 's/^/      /'
    fi

    echo ""

    cd "$WORKSPACE_ROOT"
done

echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}Summary${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"

# Count modules manually since subshell variables don't propagate
TOTAL_COUNT=$(find "$WORKSPACE_ROOT/modules" -type d -name ".git" 2>/dev/null | wc -l | tr -d ' ')

if [ "$TOTAL_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}No modules synced yet${NC}"
else
    echo -e "Total modules: ${BLUE}$TOTAL_COUNT${NC}"

    # Count clean and dirty
    CLEAN_COUNT=0
    DIRTY_COUNT=0

    find "$WORKSPACE_ROOT/modules" -type d -name ".git" | while read -r git_dir; do
        module_dir=$(dirname "$git_dir")
        cd "$module_dir"
        if git diff-index --quiet HEAD -- 2>/dev/null; then
            CLEAN_COUNT=$((CLEAN_COUNT + 1))
        else
            DIRTY_COUNT=$((DIRTY_COUNT + 1))
        fi
    done > /dev/null 2>&1

    echo ""
    echo -e "${GREEN}Run './scripts/sync.sh' to update modules${NC}"
    echo -e "${YELLOW}Run './scripts/sync.sh <module-name>' to sync specific module${NC}"
fi

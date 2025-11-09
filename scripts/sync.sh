#!/bin/bash
# Modsynth Module Sync Script
# Syncs modules based on manifest.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST_FILE="$MANIFEST_DIR/manifest.json"
WORKSPACE_ROOT="$MANIFEST_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install it first.${NC}"
    echo "  macOS: brew install jq"
    echo "  Ubuntu: sudo apt-get install jq"
    exit 1
fi

# Check if manifest.json exists
if [ ! -f "$MANIFEST_FILE" ]; then
    echo -e "${RED}Error: manifest.json not found at $MANIFEST_FILE${NC}"
    exit 1
fi

# Function to sync a single module
sync_module() {
    local name=$1
    local repo=$2
    local path=$3
    local version=$4

    echo -e "${BLUE}📦 Syncing: $name ($version)${NC}"

    local full_path="$WORKSPACE_ROOT/$path"

    if [ -d "$full_path" ]; then
        # Module exists, update it
        echo "  → Already exists, updating..."
        cd "$full_path"

        # Fetch all tags
        git fetch --all --tags --quiet 2>&1 | grep -v "warning:" || true

        # Checkout specific version
        if git rev-parse "$version" >/dev/null 2>&1; then
            git checkout "$version" --quiet 2>&1 | grep -v "warning:" || true
            echo -e "  ${GREEN}✓ Updated to $version${NC}"
        else
            echo -e "  ${YELLOW}⚠ Version $version not found, staying on current branch${NC}"
        fi

        cd "$WORKSPACE_ROOT"
    else
        # Module doesn't exist, clone it
        echo "  → Cloning..."
        mkdir -p "$(dirname "$full_path")"

        if git clone --quiet "$repo" "$full_path" 2>&1 | grep -v "warning:"; then
            cd "$full_path"

            # Checkout specific version if it exists
            if git rev-parse "$version" >/dev/null 2>&1; then
                git checkout "$version" --quiet 2>&1 | grep -v "warning:" || true
                echo -e "  ${GREEN}✓ Cloned and checked out $version${NC}"
            else
                echo -e "  ${GREEN}✓ Cloned (version $version not tagged yet)${NC}"
            fi

            cd "$WORKSPACE_ROOT"
        else
            echo -e "  ${RED}✗ Failed to clone${NC}"
        fi
    fi

    echo ""
}

# Function to sync all modules in a category
sync_category() {
    local category=$1
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}Category: $category${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo ""

    jq -r ".modules.$category[]? | \"\(.name)|\(.repo)|\(.path)|\(.version)\"" "$MANIFEST_FILE" | \
    while IFS='|' read -r name repo path version; do
        if [ -n "$name" ]; then
            sync_module "$name" "$repo" "$path" "$version"
        fi
    done
}

# Function to sync by profile
sync_profile() {
    local profile=$1
    echo -e "${GREEN}🎯 Syncing profile: $profile${NC}"
    echo ""

    local includes=$(jq -r ".profiles.$profile.includes[]" "$MANIFEST_FILE")

    if [ "$includes" == "*" ]; then
        # Sync all modules
        sync_all
    else
        # Sync specific modules
        echo "$includes" | while read -r module_pattern; do
            if [[ "$module_pattern" == *"/*" ]]; then
                # Category pattern (e.g., "backend/*")
                local category="${module_pattern%/*}"
                sync_category "$category"
            else
                # Specific module name
                local found=false
                for category in $(jq -r '.modules | keys[]' "$MANIFEST_FILE"); do
                    local module_info=$(jq -r ".modules.$category[] | select(.name==\"$module_pattern\") | \"\(.name)|\(.repo)|\(.path)|\(.version)\"" "$MANIFEST_FILE")
                    if [ -n "$module_info" ]; then
                        IFS='|' read -r name repo path version <<< "$module_info"
                        sync_module "$name" "$repo" "$path" "$version"
                        found=true
                        break
                    fi
                done

                if [ "$found" = false ]; then
                    echo -e "${RED}Module not found: $module_pattern${NC}"
                fi
            fi
        done
    fi
}

# Function to sync all modules
sync_all() {
    for category in $(jq -r '.modules | keys[]' "$MANIFEST_FILE"); do
        sync_category "$category"
    done
}

# Function to show usage
show_usage() {
    echo "Modsynth Module Sync Tool"
    echo ""
    echo "Usage:"
    echo "  $0                          # Sync all modules"
    echo "  $0 --profile <name>         # Sync modules by profile"
    echo "  $0 --category <name>        # Sync modules by category"
    echo "  $0 <module-name> [...]      # Sync specific module(s)"
    echo ""
    echo "Profiles:"
    jq -r '.profiles | to_entries[] | "  \(.key) - \(.value.description)"' "$MANIFEST_FILE"
    echo ""
    echo "Categories:"
    jq -r '.modules | keys[] | "  \(.)"' "$MANIFEST_FILE"
    echo ""
    echo "Examples:"
    echo "  $0                          # Sync everything"
    echo "  $0 --profile minimal        # Sync only core modules"
    echo "  $0 --profile phase-1        # Sync Phase 1 modules"
    echo "  $0 --category backend       # Sync all backend modules"
    echo "  $0 auth-module db-module    # Sync specific modules"
}

# Main script logic
main() {
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Modsynth Module Sync Tool           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""

    if [ $# -eq 0 ]; then
        # No arguments, sync all
        sync_all
    elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        show_usage
    elif [ "$1" == "--profile" ]; then
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Profile name required${NC}"
            show_usage
            exit 1
        fi
        sync_profile "$2"
    elif [ "$1" == "--category" ]; then
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Category name required${NC}"
            show_usage
            exit 1
        fi
        sync_category "$2"
    else
        # Sync specific modules
        for module_name in "$@"; do
            local found=false
            for category in $(jq -r '.modules | keys[]' "$MANIFEST_FILE"); do
                local module_info=$(jq -r ".modules.$category[] | select(.name==\"$module_name\") | \"\(.name)|\(.repo)|\(.path)|\(.version)\"" "$MANIFEST_FILE")
                if [ -n "$module_info" ]; then
                    IFS='|' read -r name repo path version <<< "$module_info"
                    sync_module "$name" "$repo" "$path" "$version"
                    found=true
                    break
                fi
            done

            if [ "$found" = false ]; then
                echo -e "${RED}Module not found: $module_name${NC}"
            fi
        done
    fi

    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ Sync Complete!                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
}

# Run main function
main "$@"

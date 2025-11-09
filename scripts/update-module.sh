#!/bin/bash
# Update module version in manifest.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$(dirname "$SCRIPT_DIR")"
MANIFEST_FILE="$MANIFEST_DIR/manifest.json"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    exit 1
fi

# Show usage
show_usage() {
    echo "Update Module Version Tool"
    echo ""
    echo "Usage:"
    echo "  $0 <module-name> <new-version>"
    echo ""
    echo "Example:"
    echo "  $0 auth-module v1.2.3"
    echo ""
}

# Main function
if [ $# -ne 2 ]; then
    show_usage
    exit 1
fi

MODULE_NAME=$1
NEW_VERSION=$2

echo -e "${YELLOW}Updating $MODULE_NAME to $NEW_VERSION...${NC}"

# Find and update the module in all categories
FOUND=false

for category in $(jq -r '.modules | keys[]' "$MANIFEST_FILE"); do
    # Check if module exists in this category
    if jq -e ".modules.$category[] | select(.name==\"$MODULE_NAME\")" "$MANIFEST_FILE" > /dev/null 2>&1; then
        FOUND=true

        # Update the version
        jq ".modules.$category = [.modules.$category[] | if .name == \"$MODULE_NAME\" then .version = \"$NEW_VERSION\" else . end]" \
            "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp"

        mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"

        echo -e "${GREEN}✓ Updated $MODULE_NAME in category '$category' to $NEW_VERSION${NC}"
        break
    fi
done

if [ "$FOUND" = false ]; then
    echo -e "${RED}✗ Module '$MODULE_NAME' not found in manifest${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Review the changes: git diff manifest.json"
echo "  2. Run sync to update local modules: ./scripts/sync.sh $MODULE_NAME"
echo "  3. Commit and push: git add manifest.json && git commit -m \"chore: update $MODULE_NAME to $NEW_VERSION\""

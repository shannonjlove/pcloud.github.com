#!/bin/bash

# Create Wiki.js Pages via API
# This script creates pages in wiki.js using the GraphQL API
# Requires: curl, wiki.js running, and authentication token

set -e

# Configuration
WIKI_URL="${1:-https://wiki.shannonjlove.cloud}"
AUTH_TOKEN="${2:-}"

if [ -z "$AUTH_TOKEN" ]; then
    echo "Usage: $0 <wiki_url> <auth_token>"
    echo ""
    echo "Example:"
    echo "  $0 https://wiki.shannonjlove.cloud your-auth-token"
    echo ""
    echo "To get auth token:"
    echo "  1. Log in to wiki.js"
    echo "  2. Open browser DevTools (F12)"
    echo "  3. Go to Application → Cookies"
    echo "  4. Find 'jwt' cookie and copy its value"
    echo ""
    exit 1
fi

WIKI_URL=$(echo "$WIKI_URL" | sed 's:/*$::')  # Remove trailing slash

echo "=========================================="
echo "Wiki.js Page Creator"
echo "=========================================="
echo "Wiki URL: $WIKI_URL"
echo ""

# Verify connection
if ! curl -s -I "$WIKI_URL" -H "Authorization: Bearer $AUTH_TOKEN" > /dev/null 2>&1; then
    echo "❌ Error: Cannot connect to wiki.js or token is invalid"
    echo "   URL: $WIKI_URL"
    exit 1
fi

echo "✅ Connected to wiki.js"
echo ""

# Create pages
create_page() {
    local title="$1"
    local path="$2"
    local file="$3"

    echo "Creating page: $title..."

    # Read file content
    if [ ! -f "$file" ]; then
        echo "  ❌ File not found: $file"
        return 1
    fi

    content=$(cat "$file")

    # Escape content for JSON
    content_json=$(echo "$content" | jq -R -s '.')

    # Create page via GraphQL
    response=$(curl -s -X POST "$WIKI_URL/graphql" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"query\": \"mutation { pages { create(input: { title: \\\"$title\\\", path: \\\"$path\\\", locale: \\\"en\\\", editor: \\\"markdown\\\", isPublished: true}) { responseResult { succeeded message } page { id path } } } }\"
        }")

    # Check response
    if echo "$response" | grep -q '"succeeded":true'; then
        page_id=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        echo "  ✅ Created: $title (ID: $page_id)"

        # Update content
        echo "  Updating content..."
        curl -s -X POST "$WIKI_URL/graphql" \
            -H "Authorization: Bearer $AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{
                \"query\": \"mutation { pages { update(id: $page_id, input: { content: $content_json }) { responseResult { succeeded } } } }\"
            }" > /dev/null

        echo "  ✅ Content updated"
    else
        echo "  ⚠️  Failed to create: $title"
        echo "  Response: $response"
    fi

    echo ""
}

# Create pages directory if needed
echo "Creating page structure..."
echo ""

# Pages to create
create_page "Templates Overview" "/services/templates" "README.md"
create_page "Service Handoff Template" "/services/templates/template" "service-handoff-template.md"
create_page "Template Usage Guide" "/services/templates/usage-guide" "TEMPLATE_USAGE_GUIDE.md"
create_page "BookStack Handoff Example" "/services/templates/bookstack-example" "bookstack-example-completed.md"

echo "=========================================="
echo "Done!"
echo "=========================================="
echo ""
echo "View your templates at: $WIKI_URL/services/templates"
echo ""

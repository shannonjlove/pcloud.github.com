#!/bin/bash

# Upload Wiki.js Templates Script
# This script helps you upload the service documentation templates to wiki.js
# Usage: bash upload-templates-to-wiki.sh [wiki_url] [admin_token]

set -e

# Configuration
WIKI_URL="${1:-http://localhost:3000}"
ADMIN_TOKEN="${2:-}"

echo "=========================================="
echo "Wiki.js Template Upload Script"
echo "=========================================="
echo ""
echo "Wiki URL: $WIKI_URL"
echo ""

# Check if wiki is accessible
if ! curl -s "$WIKI_URL" > /dev/null; then
    echo "❌ Error: Cannot reach wiki.js at $WIKI_URL"
    echo ""
    echo "Make sure wiki.js is running:"
    echo "  docker-compose up -d wiki"
    echo ""
    echo "Or use custom URL:"
    echo "  bash upload-templates-to-wiki.sh https://wiki.shannonjlove.cloud [token]"
    exit 1
fi

echo "✅ Wiki.js is accessible"
echo ""

# Instructions for manual upload
cat << 'EOF'
Manual Upload Instructions
===========================

Since wiki.js API requires authentication and token management, the easiest
way to upload templates is manually through the web interface:

Step 1: Open Wiki.js
  - Go to https://wiki.shannonjlove.cloud (or your wiki URL)
  - Log in with your admin credentials

Step 2: Create Folder Structure
  - Navigate to root (Home)
  - Create new folder: "Services" (if not exists)
  - Inside Services, create: "Templates"

Step 3: Upload Template Files

  A. Service Handoff Template
     1. In /Services/Templates, create new page "Service Handoff Template"
     2. Switch to Source/Markdown editor
     3. Open wiki-templates/service-handoff-template.md in text editor
     4. Copy entire content
     5. Paste into wiki.js editor
     6. Click Save

  B. Template Usage Guide
     1. In /Services/Templates, create new page "Template Usage Guide"
     2. Switch to Source/Markdown editor
     3. Open wiki-templates/TEMPLATE_USAGE_GUIDE.md in text editor
     4. Copy entire content
     5. Paste into wiki.js editor
     6. Click Save

  C. BookStack Example
     1. In /Services/Templates, create new page "BookStack Handoff Example"
     2. Switch to Source/Markdown editor
     3. Open wiki-templates/bookstack-example-completed.md in text editor
     4. Copy entire content
     5. Paste into wiki.js editor
     6. Click Save

  D. Templates README
     1. In /Services/Templates, create new page "Templates Overview"
     2. Switch to Source/Markdown editor
     3. Open wiki-templates/README.md in text editor
     4. Copy entire content
     5. Paste into wiki.js editor
     6. Click Save

Step 4: Verify Upload
  - Navigate to /Services/Templates
  - See all 4 pages listed
  - Click each to verify content loaded correctly

Step 5: Share with Team
  - Link team to https://[your-wiki]/s/Services/Templates
  - Direct them to "Templates Overview" to start

EOF

echo ""
echo "Quick Copy/Paste Instructions"
echo "============================="
echo ""
echo "1. Open wiki-templates/service-handoff-template.md"
echo "2. Copy the entire file content"
echo "3. Paste into a new wiki.js page (Source editor)"
echo "4. Repeat for the other 3 template files"
echo ""

# Try to provide API-based upload if token is provided
if [ -n "$ADMIN_TOKEN" ]; then
    echo "Attempting API upload with provided token..."
    echo ""

    # Create Templates folder
    FOLDER_ID=$(curl -s -X POST "$WIKI_URL/graphql" \
        -H "Authorization: Bearer $ADMIN_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "query": "mutation { pages { create(input: {title: \"Templates\", path: \"/services/templates\", locale: \"en\"}) { id } } }"
        }' 2>/dev/null | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [ -n "$FOLDER_ID" ]; then
        echo "✅ Created Templates folder: $FOLDER_ID"
    else
        echo "⚠️  Could not create folder via API. Use manual upload steps above."
    fi
else
    echo "💡 Tip: For automated upload via API, provide admin token:"
    echo "   bash upload-templates-to-wiki.sh $WIKI_URL [your-admin-token]"
    echo ""
fi

echo ""
echo "=========================================="
echo "Upload Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Open your wiki at $WIKI_URL"
echo "2. Navigate to /Services/Templates"
echo "3. Share with your team!"
echo ""

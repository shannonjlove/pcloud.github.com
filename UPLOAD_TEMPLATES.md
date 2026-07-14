# Uploading Templates to Wiki.js

This guide explains how to upload the service documentation templates to your wiki.js instance.

## Quick Start

### Option 1: Manual Upload (Recommended for First Time)

1. **Start wiki.js** (if not running):
   ```bash
   docker-compose up -d wiki
   # Wait for it to start (may take 30-40 seconds)
   ```

2. **Access wiki.js**:
   - Open http://localhost:3000 (or your wiki URL)
   - Complete the setup wizard
   - Log in with admin credentials

3. **Create Folder Structure**:
   - Click "New Page" or "+" button
   - Create folder: **Services**
   - Inside Services, create folder: **Templates**

4. **Upload Each Template**:
   
   For each template file (repeat 4 times):
   
   ```
   1. In /Services/Templates, click "New Page"
   2. Enter page title (see list below)
   3. Set editor type to "Markdown"
   4. Click "Create"
   5. Switch to "Source" view (Markdown editor)
   6. Open wiki-templates/[filename] in text editor
   7. Copy entire file content
   8. Paste into wiki.js editor
   9. Click "Save"
   ```

   **Template Files to Upload**:
   - `wiki-templates/service-handoff-template.md` → Title: "Service Handoff Template"
   - `wiki-templates/TEMPLATE_USAGE_GUIDE.md` → Title: "Template Usage Guide"
   - `wiki-templates/bookstack-example-completed.md` → Title: "BookStack Handoff Example"
   - `wiki-templates/README.md` → Title: "Templates Overview"

### Option 2: Script Upload

#### Using Bash Script (Simple)

```bash
# Make script executable (one time)
chmod +x upload-templates-to-wiki.sh

# Run script with your wiki URL
./upload-templates-to-wiki.sh http://localhost:3000

# Or with your production wiki
./upload-templates-to-wiki.sh https://wiki.shannonjlove.cloud [token]
```

#### Using Python Script (Automated)

Requires: `requests` library (`pip install requests`)

```bash
# Make script executable (one time)
chmod +x upload-templates-to-wiki.py

# Option A: With authentication token
python3 upload-templates-to-wiki.py \
  -u http://localhost:3000 \
  -t your-auth-token

# Option B: With email/password (will prompt for password)
python3 upload-templates-to-wiki.py \
  -u http://localhost:3000 \
  -e admin@example.com

# Option C: With email and password
python3 upload-templates-to-wiki.py \
  -u http://localhost:3000 \
  -e admin@example.com \
  -p your-password

# Option D: Dry run (see what would be uploaded)
python3 upload-templates-to-wiki.py \
  -u http://localhost:3000 \
  -t your-token \
  --dry-run
```

## Getting Your Authentication Token

### Method 1: Via Wiki.js UI
1. Log in to wiki.js admin panel
2. Go to Admin → Profile
3. Copy your API token (if available)

### Method 2: Via Browser DevTools
1. Log in to wiki.js
2. Open Browser DevTools (F12)
3. Go to Application → Cookies
4. Find and copy the `jwt` cookie value

### Method 3: Via GraphQL Query
```bash
# After logging in, you can query for token via GraphQL
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { authentication { activeUser { id name } } }"
  }'
```

## Verification Steps

After uploading, verify everything is in place:

1. **Check Folder Structure**:
   - Navigate to http://localhost:3000/services/templates
   - Should see 4 pages listed

2. **Verify Each Page**:
   - Click each page to open it
   - Check content loaded correctly
   - Verify formatting (tables, code blocks, etc.)

3. **Test Links**:
   - If pages reference each other, test those links
   - Look for any broken references

4. **Share with Team**:
   - Copy URL: `http://localhost:3000/services/templates`
   - Share with team members
   - Point them to "Templates Overview" page first

## Troubleshooting

### Wiki.js Not Running

**Error**: "Cannot reach wiki.js at http://localhost:3000"

**Solution**:
```bash
# Check if container is running
docker-compose ps

# If not, start it
docker-compose up -d wiki

# Check logs
docker-compose logs wiki
```

### Content Not Displaying Correctly

**Issue**: Tables or code blocks not rendering properly

**Solution**:
1. In wiki.js, click "Preview" tab to see how it renders
2. Go back to "Source" tab
3. Fix Markdown formatting (common issues):
   - Extra indentation before code blocks
   - Missing blank lines between sections
   - Table columns not aligned

### Page Won't Save

**Issue**: "Error saving page" message

**Solution**:
1. Check browser console for errors (F12)
2. Try uploading smaller sections first
3. Clear browser cache and try again
4. Try different browser
5. Check wiki.js logs for errors

### Authentication Failed

**Error**: "Authentication failed" with Python script

**Solution**:
```bash
# Verify credentials are correct
# Try manual upload instead
bash upload-templates-to-wiki.sh http://localhost:3000

# Or check if wiki.js needs setup first
# Open http://localhost:3000 in browser and complete setup
```

## After Upload

### Team Communication

```markdown
📚 **Service Documentation Templates Now Available**

We've created a comprehensive set of documentation templates for wiki.js!

Location: https://wiki.shannonjlove.cloud/services/templates

Start here: 📖 Templates Overview

Available:
- Service Handoff Template (use for any service)
- Template Usage Guide (how to fill out templates)
- BookStack Example (real-world completed example)
- Templates Overview (learning path & best practices)

Questions? Start with "Template Usage Guide" page.
```

### Next Steps

1. **Share with Team**: Announce templates are available
2. **Training**: Walk team through "Templates Overview"
3. **Create First Handoff**: Use template for existing service (e.g., BookStack)
4. **Iterate**: Collect feedback and improve templates
5. **Standardize**: Require all new services use this template

## Quick Reference: File Locations

```
Project root/
├── wiki-templates/
│   ├── README.md                          ← Uploaded as "Templates Overview"
│   ├── service-handoff-template.md        ← Uploaded as "Service Handoff Template"
│   ├── TEMPLATE_USAGE_GUIDE.md            ← Uploaded as "Template Usage Guide"
│   └── bookstack-example-completed.md     ← Uploaded as "BookStack Handoff Example"
├── upload-templates-to-wiki.sh            ← Bash upload script
├── upload-templates-to-wiki.py            ← Python upload script
└── UPLOAD_TEMPLATES.md                    ← This file
```

## Support

- **Can't upload manually?** Try Python script: `python3 upload-templates-to-wiki.py -u [URL] -t [token]`
- **Script not working?** Check troubleshooting section above
- **Wiki.js issues?** See https://docs.requarks.io/
- **Template questions?** Open `wiki-templates/README.md` locally

---

**Last Updated**: 2026-07-14  
**Status**: Ready to upload ✅

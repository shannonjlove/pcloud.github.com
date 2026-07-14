# Wiki.js Template Usage Guide

This guide explains how to use the service handoff template and upload documentation to wiki.js.

## Available Templates

### Service Handoff Template
**File**: `service-handoff-template.md`
**Purpose**: Comprehensive service documentation for any production service
**Sections**: 20+ sections covering architecture, operations, security, and handoff
**Use Cases**: 
- Service ownership transfers
- New service deployments
- Documentation standardization
- Team onboarding

## How to Use Templates in Wiki.js

### Method 1: Copy/Paste into Wiki.js Editor

1. Open wiki.js at `https://wiki.shannonjlove.cloud`
2. Create a new page or navigate to the desired location
3. Click **Edit** (if existing page) or **Create Page**
4. Click the **Source** button to switch to Markdown editor
5. Open the template file (`service-handoff-template.md`) in a text editor
6. Copy the entire template content
7. Paste into the wiki.js Markdown editor
8. Update the bracketed sections with service-specific information
9. Click **Save**

### Method 2: Upload Markdown File (If Wiki.js Supports)

1. Prepare your completed template as a `.md` file
2. In wiki.js, look for **Upload** or **Import** option (varies by version)
3. Select your Markdown file
4. Configure page location and properties
5. Complete the import

### Method 3: Create from Page Template (If Available)

1. In wiki.js admin panel, navigate to **Templates** section
2. Create a new page template from `service-handoff-template.md`
3. When creating a new page, select this template
4. Fill in the service-specific details
5. Save

## Filling Out the Template

### Quick Reference: Key Sections

| Section | What to Fill In | Example |
|---------|-----------------|---------|
| Service Name | [SERVICE NAME] | BookStack Documentation Platform |
| Description | Purpose and components | "Deployed as containerized instance..." |
| Endpoints | URLs and access methods | docs.shannonjlove.cloud, Tailscale IP |
| Components | Services and applications | BookStack, MariaDB, Nginx |
| Architecture | How components interact | Network diagrams, data flow |
| Procedures | Startup, shutdown, operations | systemctl commands, Docker exec |
| Contacts | Team information | Names, emails, Slack handles |

### Pro Tips

1. **Use Lists**: Break up long paragraphs into bullet points for readability
2. **Code Blocks**: Use triple backticks for commands and code
3. **Tables**: Use markdown tables for configuration, endpoints, and inventory
4. **Cross-Links**: In wiki.js, link to related pages using `[[Page Name]]`
5. **Images**: Add architecture diagrams if available (upload to wiki.js)
6. **Dates**: Always include "Last Updated" or similar
7. **Checklists**: Use `- [ ]` for actionable items

## Best Practices

### Documentation Quality

✅ **DO**:
- Be specific: Use actual URLs, paths, and commands
- Test commands: Verify all shell commands work before documenting
- Update regularly: Schedule quarterly reviews
- Include examples: Show real output and expected values
- Cross-reference: Link to related documentation
- Use consistent formatting: Follow template structure

❌ **DON'T**:
- Leave bracketed placeholders: Replace all `[EXAMPLE]` items
- Use generic descriptions: "Do the thing" is not helpful
- Hardcode IP addresses: Use hostnames where possible
- Skip security sections: Always document auth and access controls
- Forget contact info: Include who to escalate to

### Security

⚠️ **Important**:
- Don't commit passwords or secrets to version control
- Use wiki.js access controls to restrict sensitive documentation
- Consider creating a separate "Secrets" page accessible only to team leads
- Document secret rotation procedures, not the secrets themselves
- Use references like "stored in ~/.env" instead of showing credentials

## Example: BookStack Service Handoff

The BookStack handoff documents provided (`bookstack_service_handoff_markdown_export.md` and `bookstack_workflow_service_handoff.md`) are examples of completed handoff documentation. 

To convert these to wiki.js pages:

1. **Copy** the content from BookStack handoff files
2. **Create new page** in wiki.js at `/Services/BookStack` or similar
3. **Paste** the content
4. **Format** if needed (tables, links, etc.)
5. **Test** all documented procedures
6. **Save** and share with team

## Structure for Multiple Services

Recommended wiki.js folder structure:

```
Services/
├── BookStack/
│   ├── Overview
│   ├── Handoff (Complete handoff doc)
│   ├── Operations Guide
│   └── Troubleshooting
├── Wiki.js/
│   ├── Overview
│   ├── Handoff
│   ├── Setup Guide
│   └── Troubleshooting
├── [Other Service]/
│   └── [Similar structure]
└── Templates/
    ├── Service Handoff Template
    └── Usage Guide (this file)
```

## Uploading Documents to Wiki.js

### Step-by-Step Upload Process

1. **Prepare Your Markdown**
   - Clean up formatting
   - Verify all links work
   - Test code blocks
   - Replace all bracketed placeholders

2. **Open Wiki.js**
   - Navigate to `https://wiki.shannonjlove.cloud`
   - Log in with your credentials

3. **Create Page Structure**
   - Create a parent page for the service (e.g., "BookStack")
   - Create child pages as needed (e.g., "Operations", "Troubleshooting")

4. **Create New Page**
   - Click **New Page** or **+** button
   - Enter page title (e.g., "BookStack Handoff")
   - Select **Markdown** as editor type
   - Click **Create**

5. **Paste Content**
   - In the editor, click **Source** to show Markdown
   - Paste your prepared content
   - Click **Save** when done

6. **Format and Test**
   - Check that tables render correctly
   - Verify code blocks display properly
   - Test any internal wiki links (`[[Link]]`)
   - Confirm external links work

7. **Set Permissions** (Optional)
   - If page has sensitive info, restrict access
   - Go to page settings/permissions
   - Configure who can view/edit

## Integration with Version Control

### Local Workflow

1. Keep Markdown templates in git repository (this repo)
2. When creating wiki.js page, copy from repo
3. Make edits in wiki.js
4. Periodically export wiki.js page as Markdown
5. Compare with repo version and update if significant changes
6. Commit updates to repository

### Backup Considerations

- Export wiki.js pages periodically as Markdown
- Store exports in this repository under `/wiki-exports/`
- Include in backup strategy

## Troubleshooting Wiki.js Content

### Content Not Displaying

- **Check**: Markdown syntax is correct
- **Fix**: Use "Preview" in wiki.js to check rendering
- **Test**: Copy content to a markdown previewer

### Links Not Working

- **Check**: Wiki.js cross-links use `[[Page Name]]` format
- **Fix**: Verify page title matches exactly (case-sensitive)
- **Test**: Use "Link" button in wiki.js to create links

### Images Not Showing

- **Check**: Images are uploaded to wiki.js, not external
- **Fix**: Upload image in wiki.js and reference locally
- **Alternative**: Use `![alt text](wiki-image-url)` format

### Code Blocks Formatting Wrong

- **Check**: Use triple backticks with language (e.g., ` ```bash `)
- **Fix**: Remove extra indentation before code block
- **Test**: Switch to preview to verify formatting

## Template Maintenance

### Regular Updates

- **Monthly**: Review templates for accuracy
- **Quarterly**: Update based on new best practices
- **As needed**: Add new template types for emerging patterns

### Versioning

Keep track of template versions:

```markdown
# Service Handoff Template
**Version**: 2.0  
**Last Updated**: 2026-07-14  
**Created By**: [Your Name]  
**Changes**: Added security section, expanded troubleshooting
```

## Need Help?

- Check wiki.js documentation: `https://docs.requarks.io/`
- Review existing pages in wiki.js for examples
- Refer to BookStack handoff documents for a completed example
- Ask team members who've used the template

---

**Template Set Version**: 1.0  
**Last Updated**: 2026-07-14  
**Maintained By**: [Your Name/Team]

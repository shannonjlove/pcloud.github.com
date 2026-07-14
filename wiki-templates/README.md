# Wiki.js Templates and Documentation

This directory contains templates and guides for creating comprehensive documentation in wiki.js, with a focus on service handoff and operational documentation.

## 📚 Contents

### Core Files

| File | Purpose |
|------|---------|
| **service-handoff-template.md** | Complete template for service documentation; 20+ sections covering architecture, operations, security, backups, and handoff procedures |
| **TEMPLATE_USAGE_GUIDE.md** | Step-by-step guide for using templates in wiki.js, uploading documents, best practices, and troubleshooting |
| **bookstack-example-completed.md** | Real-world example showing how to complete the service handoff template for BookStack |
| **README.md** | This file |

## 🚀 Quick Start

1. **First Time?** Read: `TEMPLATE_USAGE_GUIDE.md`
2. **Need a Template?** Copy: `service-handoff-template.md`
3. **See Example?** Review: `bookstack-example-completed.md`

## 📋 Template Overview

### Service Handoff Template

Complete, production-ready template for documenting any service. Covers:

**Operational Sections**:
- Service Definition and Purpose
- Architecture and Components
- Access and Authentication
- Startup/Shutdown Procedures
- Health Verification and Troubleshooting
- Configuration Management
- Logs and Debugging

**Maintenance Sections**:
- Backup and Recovery Procedures
- Monitoring and Alerting Schedules
- Security and Hardening
- Team Contacts and Escalation

**Handoff Sections**:
- Documentation References
- Open Items and Next Steps
- Acceptance Checklist

## 🎯 Use Cases

### Service Ownership Transfer
Transfer complete operational knowledge to a new team or individual:
1. Fill out service handoff template with all service details
2. Upload to wiki.js in `/Services/[ServiceName]/Handoff` location
3. Have receiving party review and sign off via acceptance checklist
4. Archive completed handoff in git repository

### New Service Deployment
Document a new service from day one:
1. Create service using template as you build
2. Test all procedures as you document them
3. Upload to wiki.js for team reference
4. Use as reference for future similar deployments

### Knowledge Base Standardization
Ensure consistent documentation across all services:
1. Standardize on this template format
2. Require all new services to use it
3. Gradually migrate existing docs to this format
4. Maintain consistency over time

### Team Onboarding
Help new team members understand all systems:
1. Link to service documentation from main team page
2. Use handoff checklist to verify new person understands service
3. Reference specific procedures from handoff docs
4. Update docs as new team members suggest improvements

## 📖 Recommended Wiki.js Structure

```
/Services/
├── 📄 Services Overview (index page)
├── BookStack/
│   ├── 📄 Handoff (Complete handoff doc)
│   ├── 📄 Quick Reference
│   ├── 📄 Troubleshooting
│   └── 📄 Backup & Recovery
├── Wiki.js/
│   ├── 📄 Handoff
│   ├── 📄 Setup Guide
│   └── 📄 Operations
├── [Other Services]/
│   └── (similar structure)
└── Templates/
    ├── 📄 Service Handoff Template
    ├── 📄 Template Usage Guide
    └── 📄 Examples & Tips
```

## ✅ Best Practices

### When Creating Documentation

✅ **DO**:
- Test every command before documenting it
- Use real URLs, hostnames, and paths
- Include expected outputs and error messages
- Add security considerations for each section
- Cross-reference related documentation
- Use code blocks for complex commands
- Update "Last Updated" date when modifying

❌ **DON'T**:
- Leave placeholder text like `[YOUR_SERVICE]`
- Hardcode IP addresses (use hostnames)
- Skip the security section
- Assume readers know the basics
- Forget to test procedures in production-like environment
- Mix multiple commands without explaining each

### Security and Secrets

⚠️ **Important**:
- **Never** commit passwords or API keys to this repository
- Document where secrets are stored, not the secrets themselves
- Use references like "stored in ~/.env" or "in 1Password"
- Include secret rotation procedures
- Restrict access to sensitive wiki.js pages
- Consider separate "Secrets" page for admin team only

### Keeping Documentation Current

📅 **Maintenance Schedule**:
- **Monthly**: Review templates for accuracy
- **Quarterly**: Full documentation audit
- **As-needed**: Update when procedures change
- **Upon request**: Update when team asks for clarification

## 🔄 Integration with Git

### Workflow

1. **In Git**: Keep templates and examples in this directory
2. **In Wiki.js**: Upload/copy templates to wiki.js
3. **Sync**: Periodically export wiki.js pages as Markdown
4. **Archive**: Keep completed handoffs in `/wiki-exports/` directory

### Storage Locations

- **Templates**: `wiki-templates/` (this directory, in git)
- **Exports**: `wiki-exports/` (completed docs, in git)
- **Live**: wiki.js at `https://wiki.shannonjlove.cloud`

### Backup Strategy

1. Export wiki.js pages periodically as Markdown
2. Commit exports to git repository under `wiki-exports/`
3. Use git history as backup of documentation changes
4. Include in automated backup procedures

## 📚 Documentation Files

### service-handoff-template.md

**What**: Complete service handoff template  
**Size**: ~600 lines  
**Sections**: 20+  
**Time to Complete**: 2-4 hours (varies by service complexity)  

**Typical Flow**:
```
1. Copy template to local file
2. Replace all [PLACEHOLDER] items
3. Add service-specific procedures
4. Test all documented commands
5. Paste into wiki.js
6. Get team review and sign-off
```

### TEMPLATE_USAGE_GUIDE.md

**What**: Step-by-step guide for using templates  
**Audience**: Anyone creating wiki.js documentation  
**Contents**: Upload instructions, best practices, troubleshooting  

**Key Sections**:
- How to use templates in wiki.js
- Filling out the template
- Pro tips for documentation
- Best practices (DO's and DON'Ts)
- Security guidelines
- Integration with version control

### bookstack-example-completed.md

**What**: Real-world completed example  
**Service**: BookStack documentation platform  
**Purpose**: Show how to properly complete the template  

**Demonstrates**:
- Realistic, specific procedures
- Proper formatting and structure
- Real commands that work
- Security considerations
- Troubleshooting real problems
- Proper sign-off and acceptance

## 🔍 How to Use Each File

### I'm creating a new service handoff

1. Start with `service-handoff-template.md`
2. Copy the template to a new markdown file
3. Fill in each section with your service details
4. Reference `bookstack-example-completed.md` for examples
5. Upload to wiki.js using steps in `TEMPLATE_USAGE_GUIDE.md`

### I'm uploading to wiki.js for the first time

1. Read the "How to Use Templates in Wiki.js" section of `TEMPLATE_USAGE_GUIDE.md`
2. Prepare your markdown file
3. Follow the "Step-by-Step Upload Process"
4. Format and test in wiki.js

### I want to see what a completed handoff looks like

1. Open `bookstack-example-completed.md`
2. Review each section for real examples
3. Note formatting, commands, and level of detail
4. Use as reference when completing your own templates

### I need help with a specific section

1. Check `bookstack-example-completed.md` for that section
2. Read the "Pro Tips" in `TEMPLATE_USAGE_GUIDE.md`
3. Review "Common Issues and Solutions" if troubleshooting

## 🛠️ Customization

### Adapting the Template

The template is designed to be customizable:

**Add sections** if needed:
- Multi-tenancy considerations
- Performance tuning
- Cost optimization
- Capacity planning

**Remove sections** that don't apply:
- If service has no database, remove backup section
- If no monitoring system, remove alerts section
- If internal-only, reduce public access section

**Combine sections** for simple services:
- Startup and shutdown in one section
- Configuration and troubleshooting combined

**Expand sections** for complex services:
- Separate troubleshooting by component
- Multiple configuration sections
- Advanced procedures section

## 📞 Support and Questions

### Getting Help

1. **Template Questions**: See `TEMPLATE_USAGE_GUIDE.md`
2. **Wiki.js Help**: See wiki.js documentation: https://docs.requarks.io/
3. **Examples**: Review `bookstack-example-completed.md`
4. **Team**: Ask team members who've used the template

### Contributing Improvements

1. Test new procedures thoroughly
2. Add examples to this README if applicable
3. Update templates based on lessons learned
4. Keep version number and "Last Updated" date current

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-07-14 | Initial template suite release |

**Last Updated**: 2026-07-14  
**Maintained By**: [Your Name/Team]

---

## 🎓 Learning Path

**For Service Owners**:
1. Read this README
2. Review `bookstack-example-completed.md` 
3. Copy `service-handoff-template.md`
4. Fill out each section
5. Refer to `TEMPLATE_USAGE_GUIDE.md` when uploading

**For Team Leads**:
1. Read entire README
2. Establish template usage as standard
3. Point team to templates when onboarding
4. Assign template maintenance responsibility

**For New Team Members**:
1. Find your service in wiki.js under `/Services/[ServiceName]/`
2. Read the "Handoff" page
3. Use acceptance checklist to verify understanding
4. Ask questions about unclear procedures

## 🚀 Next Steps

1. **Review**: Read through all files in this directory
2. **Understand**: Review the BookStack example
3. **Prepare**: Gather information about your service
4. **Complete**: Fill out the template for your service
5. **Upload**: Use guide to upload to wiki.js
6. **Share**: Link team members to the documentation

---

**Questions?** Check `TEMPLATE_USAGE_GUIDE.md` or review `bookstack-example-completed.md` for examples.

**Ready to start?** Copy `service-handoff-template.md` and fill it out for your service!

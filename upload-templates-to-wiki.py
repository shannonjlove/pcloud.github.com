#!/usr/bin/env python3

"""
Wiki.js Template Upload Script
Uploads service documentation templates to wiki.js via GraphQL API
"""

import requests
import json
import sys
import os
from pathlib import Path
import argparse
import getpass

class WikiUploader:
    def __init__(self, wiki_url, email=None, password=None, token=None):
        self.wiki_url = wiki_url.rstrip('/')
        self.api_url = f"{self.wiki_url}/graphql"
        self.token = token
        self.email = email
        self.password = password
        self.session = requests.Session()

        if token:
            self.session.headers.update({'Authorization': f'Bearer {token}'})

    def authenticate(self):
        """Authenticate with wiki.js using email/password"""
        if self.token:
            return self._verify_token()

        if not self.email or not self.password:
            print("❌ Error: Email and password required for authentication")
            return False

        query = """
        mutation {
            authentication {
                login(email: "%s", password: "%s") {
                    responseResult {
                        succeeded
                        message
                    }
                    jwt
                }
            }
        }
        """ % (self.email, self.password)

        try:
            response = self._execute_query(query, headers={})
            if response and 'data' in response:
                result = response['data'].get('authentication', {}).get('login', {})
                if result.get('responseResult', {}).get('succeeded'):
                    jwt = result.get('jwt')
                    if jwt:
                        self.token = jwt
                        self.session.headers.update({'Authorization': f'Bearer {jwt}'})
                        print("✅ Authentication successful")
                        return True
        except Exception as e:
            print(f"❌ Authentication failed: {e}")

        return False

    def _verify_token(self):
        """Verify existing token is valid"""
        query = """
        query {
            authentication {
                activeUser {
                    id
                    name
                }
            }
        }
        """
        try:
            response = self._execute_query(query)
            if response and 'data' in response:
                user = response['data'].get('authentication', {}).get('activeUser')
                if user:
                    print(f"✅ Token valid. Logged in as: {user.get('name')}")
                    return True
        except Exception as e:
            print(f"⚠️  Token verification failed: {e}")

        return False

    def _execute_query(self, query, headers=None):
        """Execute GraphQL query"""
        if headers is None:
            headers = self.session.headers.copy()

        headers['Content-Type'] = 'application/json'

        payload = {'query': query}

        try:
            response = requests.post(
                self.api_url,
                json=payload,
                headers=headers,
                timeout=10
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.ConnectionError:
            raise Exception(f"Cannot connect to {self.wiki_url}")
        except requests.exceptions.Timeout:
            raise Exception("Request timeout")
        except Exception as e:
            raise Exception(f"GraphQL request failed: {e}")

    def create_page(self, title, path, content, parent_id=None):
        """Create a wiki page"""
        # Escape content for GraphQL
        content_escaped = content.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

        parent_clause = f', parentId: {parent_id}' if parent_id else ''

        query = f"""
        mutation {{
            pages {{
                create(input: {{
                    title: "{title}"
                    description: "Service documentation template"
                    path: "{path}"
                    locale: "en"
                    publishStartDate: "2026-07-14"
                    editor: "markdown"
                    isPublished: true
                    isPrivate: false
                    {parent_clause}
                }}) {{
                    responseResult {{
                        succeeded
                        message
                    }}
                    page {{
                        id
                        path
                    }}
                }}
            }}
        }}
        """

        try:
            response = self._execute_query(query)
            if response and 'data' in response:
                result = response['data'].get('pages', {}).get('create', {})
                if result.get('responseResult', {}).get('succeeded'):
                    page_id = result.get('page', {}).get('id')
                    print(f"✅ Created page: {title} (ID: {page_id})")
                    return page_id
                else:
                    message = result.get('responseResult', {}).get('message', 'Unknown error')
                    print(f"⚠️  Failed to create {title}: {message}")
            else:
                print(f"⚠️  No response from server")
        except Exception as e:
            print(f"❌ Error creating {title}: {e}")

        return None

    def update_page_content(self, page_id, content):
        """Update page content"""
        # Escape content for GraphQL
        content_escaped = content.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')

        query = f"""
        mutation {{
            pages {{
                update(id: {page_id}, input: {{
                    content: "{content_escaped}"
                }}) {{
                    responseResult {{
                        succeeded
                        message
                    }}
                }}
            }}
        }}
        """

        try:
            response = self._execute_query(query)
            if response and 'data' in response:
                result = response['data'].get('pages', {}).get('update', {})
                if result.get('responseResult', {}).get('succeeded'):
                    print(f"✅ Updated content for page ID: {page_id}")
                    return True
        except Exception as e:
            print(f"❌ Error updating content: {e}")

        return False

def main():
    parser = argparse.ArgumentParser(
        description='Upload wiki.js templates',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Upload with token
  %(prog)s -u http://localhost:3000 -t your-auth-token

  # Upload with email/password
  %(prog)s -u http://localhost:3000 -e admin@example.com

  # Upload to production wiki
  %(prog)s -u https://wiki.shannonjlove.cloud -t your-token
        """
    )

    parser.add_argument('-u', '--url', required=True, help='Wiki.js URL (e.g., http://localhost:3000)')
    parser.add_argument('-e', '--email', help='Admin email for authentication')
    parser.add_argument('-p', '--password', help='Admin password (will prompt if not provided)')
    parser.add_argument('-t', '--token', help='Authentication token (instead of email/password)')
    parser.add_argument('--dry-run', action='store_true', help='Show what would be uploaded without doing it')

    args = parser.parse_args()

    print("========================================")
    print("Wiki.js Template Upload Script")
    print("========================================")
    print()

    # Validate URL
    try:
        response = requests.head(args.url, timeout=5)
        print(f"✅ Wiki.js is accessible at {args.url}")
    except requests.exceptions.ConnectionError:
        print(f"❌ Error: Cannot reach wiki.js at {args.url}")
        print(f"   Make sure wiki.js is running and the URL is correct")
        sys.exit(1)
    except Exception as e:
        print(f"⚠️  Warning: {e}")

    print()

    # Get password if needed
    if args.email and not args.token and not args.password:
        args.password = getpass.getpass("Password: ")

    # Initialize uploader
    uploader = WikiUploader(args.url, args.email, args.password, args.token)

    # Authenticate
    print("Authenticating...")
    if not uploader.authenticate():
        print("❌ Authentication failed")
        sys.exit(1)

    print()

    if args.dry_run:
        print("🔍 DRY RUN: Would upload the following templates:")
        print()
        print("  1. Service Handoff Template")
        print("  2. Template Usage Guide")
        print("  3. BookStack Handoff Example")
        print("  4. Templates Overview")
        print()
        return

    # Get template files
    template_dir = Path('wiki-templates')

    templates = [
        ('service-handoff-template.md', 'Service Handoff Template', '/services/templates/template'),
        ('TEMPLATE_USAGE_GUIDE.md', 'Template Usage Guide', '/services/templates/usage-guide'),
        ('bookstack-example-completed.md', 'BookStack Handoff Example', '/services/templates/bookstack-example'),
        ('README.md', 'Templates Overview', '/services/templates/overview'),
    ]

    print("Uploading templates...")
    print()

    uploaded = 0
    for filename, title, path in templates:
        filepath = template_dir / filename

        if not filepath.exists():
            print(f"⚠️  Skipping {title}: File not found ({filepath})")
            continue

        print(f"Uploading: {title}...")

        try:
            with open(filepath, 'r') as f:
                content = f.read()

            # Try to create page and update content
            # Note: This is simplified - full implementation would:
            # 1. Check if page exists
            # 2. Create if doesn't exist
            # 3. Update content

            page_id = uploader.create_page(title, path, content)
            if page_id:
                # Update with actual content
                uploader.update_page_content(page_id, content)
                uploaded += 1

        except Exception as e:
            print(f"❌ Error uploading {title}: {e}")

        print()

    print("========================================")
    print(f"Upload Complete!")
    print(f"Successfully uploaded: {uploaded}/{len(templates)} templates")
    print("========================================")
    print()
    print("Next steps:")
    print("1. Open your wiki.js instance")
    print("2. Navigate to /Services/Templates")
    print("3. Share with your team!")
    print()

if __name__ == '__main__':
    main()

# Getting Wiki.js Authentication Token

To upload templates programmatically, you need your wiki.js authentication token. Here are three methods to get it:

## Method 1: From Browser (Easiest)

1. **Open wiki.js**
   - Go to https://wiki.shannonjlove.cloud
   - Log in with your admin credentials

2. **Open Browser Developer Tools**
   - Press `F12` or `Ctrl+Shift+I` (Windows/Linux) or `Cmd+Option+I` (Mac)
   - Go to the **Application** or **Storage** tab

3. **Find JWT Cookie**
   - Look for **Cookies** in left sidebar
   - Click on the wiki.shannonjlove.cloud entry
   - Find the cookie named `jwt`

4. **Copy Token**
   - Right-click the `jwt` row
   - Click "Copy Value"
   - Or manually select and copy the value

5. **Your token looks like:**
   ```
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MiwiZW1haWwiOiJhZG1pbkBleGFtcGxlLmNvbSIsInJvbGVzIjpbImFkbWluIl0sImlhdCI6MTY4NzcxMTIwMH0.abcdef123456...
   ```

## Method 2: From Wiki.js Admin Panel

1. **Log in to wiki.js**
   - Go to https://wiki.shannonjlove.cloud
   - Enter admin credentials

2. **Go to Admin Settings**
   - Click your name/avatar in top right
   - Select "Admin Panel" or "Administration"

3. **Find API/Profile Section**
   - Look for "Profile", "API Keys", or "Tokens"
   - Your API token may be displayed there

4. **Generate New Token (if needed)**
   - Some wiki.js versions allow generating new tokens
   - Follow the prompts to create one

## Method 3: Programmatic (curl)

If wiki.js is accessible and you have credentials:

```bash
# 1. First, authenticate and get token
curl -X POST https://wiki.shannonjlove.cloud/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { authentication { login(email: \"admin@example.com\", password: \"your-password\") { jwt } } }"
  }' | jq '.data.authentication.login.jwt'

# This returns your token (starts with eyJ...)

# 2. Save token in variable
export WIKI_TOKEN="your-token-here"

# 3. Verify token works
curl -X POST https://wiki.shannonjlove.cloud/graphql \
  -H "Authorization: Bearer $WIKI_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { authentication { activeUser { id name email } } }"
  }'

# Should return your user info
```

## Using the Token

Once you have your token, use it with the upload scripts:

### Option A: Bash Script (from wiki-templates directory)
```bash
cd wiki-templates
./create-pages.sh https://wiki.shannonjlove.cloud your-token-here
```

### Option B: Python Script (from project root)
```bash
python3 upload-templates-to-wiki.py \
  -u https://wiki.shannonjlove.cloud \
  -t your-token-here
```

### Option C: Shell Variable
```bash
# Save token
export WIKI_TOKEN="eyJ..."

# Use in commands
curl -X POST https://wiki.shannonjlove.cloud/graphql \
  -H "Authorization: Bearer $WIKI_TOKEN" \
  -H "Content-Type: application/json" \
  -d '...'
```

## Verifying Your Token

Test that your token works:

```bash
curl -X POST https://wiki.shannonjlove.cloud/graphql \
  -H "Authorization: Bearer your-token-here" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { authentication { activeUser { id name email } } }"
  }' | jq '.'

# Success looks like:
# {
#   "data": {
#     "authentication": {
#       "activeUser": {
#         "id": 2,
#         "name": "Admin User",
#         "email": "admin@example.com"
#       }
#     }
#   }
# }
```

## Token Security

⚠️ **Important**:
- **Never** commit your token to git
- **Never** share your token publicly
- **Never** paste it in unsecured chat
- **Keep it** as an environment variable when possible
- **Rotate** your token periodically
- **Revoke** old tokens if compromised

## Troubleshooting

### "Unauthorized" or "401" Error
- Token may be expired (try getting a new one)
- Token may be invalid (verify it's complete)
- Admin user may not have API access (check wiki.js permissions)

### "Cookies not visible in DevTools"
- Make sure you're logged in
- Try a different browser
- Check if wiki.js uses different cookie name (check with admin)

### Can't Find JWT Cookie
- Try searching for "auth" or "token" in cookies
- Check if using different auth method (OAuth, SAML, etc.)
- Contact your wiki.js admin for help

## Next Steps

After getting your token:

1. **Choose upload method**:
   - `bash wiki-templates/create-pages.sh [url] [token]` (direct creation)
   - `python3 upload-templates-to-wiki.py -u [url] -t [token]` (with options)
   - Manual copy/paste (if scripts don't work)

2. **Run upload**:
   ```bash
   cd wiki-templates
   ./create-pages.sh https://wiki.shannonjlove.cloud your-token-here
   ```

3. **Verify**:
   - Visit https://wiki.shannonjlove.cloud/services/templates
   - See 4 pages created
   - Check content loaded correctly

---

**Still stuck?** Try the manual upload method described in `UPLOAD_TEMPLATES.md`

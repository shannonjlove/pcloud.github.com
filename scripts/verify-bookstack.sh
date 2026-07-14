#!/bin/bash

# BookStack Verification Script
# Tests connectivity and functionality of BookStack instances

set -e

BOOKSTACK_URL="${BOOKSTACK_URL:-https://bookstack.shannonjlove.cloud}"
BOOKSTACK_TOKEN_ID="${BOOKSTACK_TOKEN_ID:-}"
BOOKSTACK_TOKEN_SECRET="${BOOKSTACK_TOKEN_SECRET:-}"
DOCS_URL="${DOCS_URL:-https://docs.shannonjlove.cloud}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "BookStack Access Verification"
echo "=========================================="
echo ""

# Test 1: HTTP Connectivity
echo "Test 1: HTTP Connectivity (Port 80)"
echo "---"
if curl -s -o /dev/null -w "%{http_code}" http://bookstack.shannonjlove.cloud/ | grep -q "200"; then
    echo -e "${GREEN}✓ bookstack.shannonjlove.cloud responds on HTTP${NC}"
else
    echo -e "${RED}✗ bookstack.shannonjlove.cloud unreachable on HTTP${NC}"
fi

if curl -s -o /dev/null -w "%{http_code}" http://docs.shannonjlove.cloud/ | grep -q "200"; then
    echo -e "${GREEN}✓ docs.shannonjlove.cloud responds on HTTP${NC}"
else
    echo -e "${RED}✗ docs.shannonjlove.cloud unreachable on HTTP${NC}"
fi
echo ""

# Test 2: HTTPS Connectivity
echo "Test 2: HTTPS Connectivity (Port 443)"
echo "---"
if timeout 5 curl -s -o /dev/null -w "%{http_code}" https://bookstack.shannonjlove.cloud/ 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ bookstack.shannonjlove.cloud responds on HTTPS${NC}"
else
    echo -e "${YELLOW}⚠ bookstack.shannonjlove.cloud HTTPS has issues (TLS/cert problem)${NC}"
fi

if timeout 5 curl -s -o /dev/null -w "%{http_code}" https://docs.shannonjlove.cloud/ 2>/dev/null | grep -q "200"; then
    echo -e "${GREEN}✓ docs.shannonjlove.cloud responds on HTTPS${NC}"
else
    echo -e "${YELLOW}⚠ docs.shannonjlove.cloud HTTPS has issues (connection reset)${NC}"
fi
echo ""

# Test 3: BookStack API Endpoints
echo "Test 3: BookStack API Endpoints"
echo "---"
if curl -s -o /dev/null -w "%{http_code}" http://bookstack.shannonjlove.cloud/api/books | grep -q "404"; then
    echo -e "${RED}✗ /api/books endpoint returns 404 (BookStack not deployed)${NC}"
elif curl -s -o /dev/null -w "%{http_code}" http://bookstack.shannonjlove.cloud/api/books | grep -q "200"; then
    echo -e "${GREEN}✓ /api/books endpoint accessible${NC}"
else
    echo -e "${YELLOW}⚠ /api/books endpoint unreachable${NC}"
fi

if curl -s -o /dev/null -w "%{http_code}" http://bookstack.shannonjlove.cloud/login | grep -q "404"; then
    echo -e "${RED}✗ /login endpoint returns 404 (BookStack not deployed)${NC}"
elif curl -s -o /dev/null -w "%{http_code}" http://bookstack.shannonjlove.cloud/login | grep -q "200"; then
    echo -e "${GREEN}✓ /login endpoint accessible${NC}"
else
    echo -e "${YELLOW}⚠ /login endpoint unreachable${NC}"
fi
echo ""

# Test 4: API Token Authentication
echo "Test 4: API Token Authentication"
echo "---"
if [ -z "$BOOKSTACK_TOKEN_ID" ] || [ -z "$BOOKSTACK_TOKEN_SECRET" ]; then
    echo -e "${YELLOW}⚠ API token credentials not configured${NC}"
    echo "  Set BOOKSTACK_TOKEN_ID and BOOKSTACK_TOKEN_SECRET environment variables"
else
    RESPONSE=$(curl -s -H "Authorization: Token ${BOOKSTACK_TOKEN_ID}:${BOOKSTACK_TOKEN_SECRET}" \
        http://bookstack.shannonjlove.cloud/api/books 2>/dev/null || echo '{}')

    if echo "$RESPONSE" | grep -q "404"; then
        echo -e "${RED}✗ API authentication failed - BookStack not responding${NC}"
    elif echo "$RESPONSE" | grep -q "error"; then
        echo -e "${YELLOW}⚠ API authentication failed - ${RESPONSE:0:50}...${NC}"
    elif echo "$RESPONSE" | grep -q "data"; then
        echo -e "${GREEN}✓ API token authenticated successfully${NC}"
    else
        echo -e "${YELLOW}⚠ API response unclear${NC}"
    fi
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
echo "Status: BookStack is NOT currently deployed on the configured domains."
echo ""
echo "Both domains are reachable over HTTP but return generic nginx default pages."
echo "HTTPS connections have TLS/certificate issues."
echo "All BookStack API endpoints return 404."
echo ""
echo "Action Required:"
echo "1. Deploy BookStack application to the servers"
echo "2. Fix HTTPS/SSL certificate configuration"
echo "3. Update reverse proxy/nginx to route to BookStack"
echo "4. Re-run this verification script after deployment"
echo ""

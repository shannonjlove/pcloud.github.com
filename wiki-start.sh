#!/bin/bash

# Wiki.js Quick Start Script
# This script helps you start wiki.js with proper configuration

set -e

echo "==================================="
echo "Wiki.js Setup and Start Script"
echo "==================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    echo "   Visit: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📋 .env file not found. Creating from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        echo "   Created .env file. Please review and update database password if needed."
        echo "   Edit .env file and run this script again."
        exit 0
    fi
fi

# Ask user which setup they want
echo "Select setup mode:"
echo "1) Simple (wiki.js only, local access on port 3000)"
echo "2) Production (wiki.js + nginx, with SSL support)"
echo ""
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting Wiki.js (Simple mode)..."
        echo ""
        docker-compose up -d wiki
        echo ""
        echo "✅ Wiki.js is starting!"
        echo ""
        echo "📝 Initial setup URL: http://localhost:3000"
        echo ""
        echo "📌 Next steps:"
        echo "   1. Open http://localhost:3000 in your browser"
        echo "   2. Complete the setup wizard"
        echo "   3. Set up your first admin user"
        echo ""
        echo "📋 For production setup with subdomain, run:"
        echo "   bash wiki-start.sh"
        ;;
    2)
        echo ""
        echo "🔒 Production setup requires SSL certificates."
        echo ""
        if [ ! -d ssl ]; then
            echo "⚠️  SSL directory not found. You need to:"
            echo ""
            echo "1. Obtain SSL certificates from Let's Encrypt:"
            echo "   certbot certonly --standalone -d wiki.shannonjlove.cloud"
            echo ""
            echo "2. Copy certificates to ssl/ directory:"
            echo "   mkdir -p ssl"
            echo "   sudo cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/fullchain.pem ssl/cert.pem"
            echo "   sudo cp /etc/letsencrypt/live/wiki.shannonjlove.cloud/privkey.pem ssl/key.pem"
            echo ""
            echo "3. Run this script again"
            exit 1
        fi

        echo "✅ SSL certificates found in ssl/ directory"
        echo ""
        echo "📌 Checking DNS configuration..."
        echo "   Make sure you have an A record in your DNS:"
        echo "   Type: A"
        echo "   Name: wiki"
        echo "   Content: Your server IP"
        echo ""
        read -p "Have you configured the DNS A record? (y/n): " dns_configured

        if ! [[ "$dns_configured" =~ ^[Yy]$ ]]; then
            echo "❌ Please configure DNS first, then run this script again."
            exit 1
        fi

        echo ""
        echo "🚀 Starting Wiki.js with Nginx (Production mode)..."
        echo ""
        docker-compose up -d
        echo ""
        echo "✅ Wiki.js is starting with Nginx!"
        echo ""
        echo "📝 Wiki URL: https://wiki.shannonjlove.cloud"
        echo "📝 Health check: https://wiki.shannonjlove.cloud/healthz"
        echo ""
        echo "⏳ Waiting for services to be ready (may take 30-40 seconds)..."
        sleep 10
        docker-compose logs wiki
        ;;
    *)
        echo "❌ Invalid choice. Please enter 1 or 2."
        exit 1
        ;;
esac

echo ""
echo "✅ Setup complete!"
echo ""
echo "📖 For more information, see WIKI_SETUP.md"
echo ""

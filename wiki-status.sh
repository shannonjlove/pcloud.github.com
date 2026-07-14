#!/bin/bash

# Wiki.js Status Check Script

echo "==================================="
echo "Wiki.js Status Check"
echo "==================================="
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi

echo "📦 Docker Status:"
docker version --format '   Docker: {{.Server.Version}}'
echo ""

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed"
    exit 1
fi

echo "📦 Docker Compose Status:"
docker-compose version --short
echo ""

# Check services
echo "🔧 Services Status:"
docker-compose ps
echo ""

# Check wiki.js health
echo "🏥 Wiki.js Health Check:"
if docker inspect wiki-js &> /dev/null; then
    state=$(docker inspect -f '{{.State.Status}}' wiki-js)
    echo "   Container Status: $state"

    if [ "$state" = "running" ]; then
        echo "   ✅ Wiki.js is running"

        # Try to connect
        if curl -sf http://localhost:3000/healthz &> /dev/null; then
            echo "   ✅ Wiki.js is responding"
        else
            echo "   ⚠️  Wiki.js is running but not responding (may still be starting)"
        fi
    else
        echo "   ⚠️  Wiki.js is not running (status: $state)"
    fi
else
    echo "   ⚠️  Wiki.js container not found"
fi
echo ""

# Check nginx (if running)
if docker inspect wiki-nginx &> /dev/null; then
    echo "🌐 Nginx Status:"
    state=$(docker inspect -f '{{.State.Status}}' wiki-nginx)
    echo "   Container Status: $state"

    if [ "$state" = "running" ]; then
        echo "   ✅ Nginx is running"
    fi
    echo ""
fi

# Check volumes
echo "💾 Volumes:"
docker volume ls | grep wiki
echo ""

# Show access URLs
echo "📝 Access URLs:"
echo "   Local: http://localhost:3000"
echo "   Production: https://wiki.shannonjlove.cloud"
echo ""

# Show logs summary
echo "📋 Recent Logs (last 10 lines):"
echo ""
docker-compose logs --tail 10 wiki 2>/dev/null || echo "   No logs available"
echo ""

echo "✅ Status check complete!"
echo ""
echo "📖 For help, see WIKI_SETUP.md"

#!/bin/bash

# Quick start script for development

echo "🚀 Starting Indoor Games Booking System (Development Mode)"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Start services
echo "📦 Starting Docker containers..."
docker-compose -f docker-compose.dev.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check if services are running
if ! docker-compose -f docker-compose.dev.yml ps | grep -q "Up"; then
    echo "❌ Some services failed to start. Check logs with: docker-compose -f docker-compose.dev.yml logs"
    exit 1
fi

# Run migrations
echo "🗄️  Running database migrations..."
docker-compose -f docker-compose.dev.yml exec -T backend npx prisma migrate deploy || \
docker-compose -f docker-compose.dev.yml exec -T backend npx prisma migrate dev

echo ""
echo "✅ Setup complete!"
echo ""
echo "📡 API: http://localhost:3000/api/v1"
echo "📚 Swagger Docs: http://localhost:3000/api/docs"
echo "❤️  Health Check: http://localhost:3000/api/v1/health"
echo ""
echo "📋 View logs: docker-compose -f docker-compose.dev.yml logs -f backend"
echo "🛑 Stop services: docker-compose -f docker-compose.dev.yml down"


@echo off
REM Quick start script for development (Windows)

echo 🚀 Starting Indoor Games Booking System (Development Mode)
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not running. Please start Docker Desktop.
    exit /b 1
)

REM Start services
echo 📦 Starting Docker containers...
docker-compose -f docker-compose.dev.yml up -d

REM Wait for services to be healthy
echo ⏳ Waiting for services to be ready...
timeout /t 10 /nobreak >nul

REM Run migrations
echo 🗄️  Running database migrations...
docker-compose -f docker-compose.dev.yml exec -T backend npx prisma migrate deploy
if errorlevel 1 (
    docker-compose -f docker-compose.dev.yml exec -T backend npx prisma migrate dev
)

echo.
echo ✅ Setup complete!
echo.
echo 📡 API: http://localhost:3000/api/v1
echo 📚 Swagger Docs: http://localhost:3000/api/docs
echo ❤️  Health Check: http://localhost:3000/api/v1/health
echo.
echo 📋 View logs: docker-compose -f docker-compose.dev.yml logs -f backend
echo 🛑 Stop services: docker-compose -f docker-compose.dev.yml down


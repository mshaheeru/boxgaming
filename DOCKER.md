# Docker Setup Guide

This project uses Docker and Docker Compose to containerize all services.

## Prerequisites

- Docker Desktop (or Docker Engine + Docker Compose)
- Docker version 20.10+
- Docker Compose version 2.0+

## Quick Start

### Development Mode

1. Start all services (PostgreSQL, Redis, Backend):
```bash
docker-compose -f docker-compose.dev.yml up -d
```

2. Run database migrations:
```bash
docker-compose -f docker-compose.dev.yml exec backend npx prisma migrate dev
```

3. View logs:
```bash
docker-compose -f docker-compose.dev.yml logs -f backend
```

4. Stop all services:
```bash
docker-compose -f docker-compose.dev.yml down
```

### Production Mode

1. Build and start all services:
```bash
docker-compose up -d --build
```

2. Run database migrations:
```bash
docker-compose exec backend npx prisma migrate deploy
```

3. View logs:
```bash
docker-compose logs -f backend
```

4. Stop all services:
```bash
docker-compose down
```

## Services

### PostgreSQL Database
- **Container**: `indoor_games_db` (dev: `indoor_games_db_dev`)
- **Port**: 5432
- **Credentials**:
  - User: `indooruser`
  - Password: `indoorpass`
  - Database: `indoor_games`
- **Data Volume**: `postgres_data` (persists data)

### Redis Cache
- **Container**: `indoor_games_redis` (dev: `indoor_games_redis_dev`)
- **Port**: 6379
- **Data Volume**: `redis_data` (persists data)

### Backend API
- **Container**: `indoor_games_backend` (dev: `indoor_games_backend_dev`)
- **Port**: 3000
- **Health Check**: `http://localhost:3000/api/v1/health`

## Environment Variables

### Development
Environment variables are set in `docker-compose.dev.yml`. For local overrides, create `docker-compose.override.yml` (see `docker-compose.override.yml.example`).

### Production
Set environment variables in `docker-compose.yml` or use a `.env` file in the project root.

## Database Migrations

### Development
```bash
# Create new migration
docker-compose -f docker-compose.dev.yml exec backend npx prisma migrate dev

# Reset database (WARNING: deletes all data)
docker-compose -f docker-compose.dev.yml exec backend npx prisma migrate reset
```

### Production
```bash
# Apply migrations
docker-compose exec backend npx prisma migrate deploy
```

## Prisma Studio

Access Prisma Studio to view/edit database:

```bash
# Development
docker-compose -f docker-compose.dev.yml exec backend npx prisma studio

# Production
docker-compose exec backend npx prisma studio
```

Then visit: `http://localhost:5555`

## Useful Commands

### View running containers
```bash
docker-compose ps
```

### View logs for specific service
```bash
docker-compose logs -f backend
docker-compose logs -f postgres
docker-compose logs -f redis
```

### Execute commands in container
```bash
# Development
docker-compose -f docker-compose.dev.yml exec backend sh

# Production
docker-compose exec backend sh
```

### Rebuild specific service
```bash
docker-compose build backend
docker-compose up -d backend
```

### Remove all containers and volumes (WARNING: deletes data)
```bash
docker-compose down -v
```

## Troubleshooting

### Port already in use
If port 5432 or 6379 is already in use, modify the port mappings in `docker-compose.yml`:
```yaml
ports:
  - "5433:5432"  # Use 5433 instead of 5432
```

### Database connection errors
1. Check if PostgreSQL container is running: `docker-compose ps`
2. Check PostgreSQL logs: `docker-compose logs postgres`
3. Verify DATABASE_URL in environment variables

### Redis connection errors
1. Check if Redis container is running: `docker-compose ps`
2. Check Redis logs: `docker-compose logs redis`
3. Verify REDIS_HOST and REDIS_PORT in environment variables

### Backend not starting
1. Check backend logs: `docker-compose logs backend`
2. Verify all environment variables are set correctly
3. Ensure database migrations have run
4. Check health endpoint: `curl http://localhost:3000/api/v1/health`

## Data Persistence

All data is persisted in Docker volumes:
- `postgres_data` - PostgreSQL database files
- `redis_data` - Redis data files

To backup data:
```bash
# Backup PostgreSQL
docker-compose exec postgres pg_dump -U indooruser indoor_games > backup.sql

# Restore PostgreSQL
docker-compose exec -T postgres psql -U indooruser indoor_games < backup.sql
```

## Network

All services communicate via the `indoor_games_network` Docker network. Services can reference each other by service name:
- Backend connects to PostgreSQL using hostname: `postgres`
- Backend connects to Redis using hostname: `redis`


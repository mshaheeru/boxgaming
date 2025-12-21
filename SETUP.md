# Setup Instructions

## Option 1: Docker Setup (Recommended)

### Prerequisites
- Docker Desktop installed
- Docker Compose v2.0+

### Steps

1. **Start all services (PostgreSQL, Redis, Backend)**:
```bash
docker-compose -f docker-compose.dev.yml up -d
```

2. **Wait for services to be healthy** (check with):
```bash
docker-compose -f docker-compose.dev.yml ps
```

3. **Run database migrations**:
```bash
docker-compose -f docker-compose.dev.yml exec backend npx prisma migrate dev
```

4. **View backend logs**:
```bash
docker-compose -f docker-compose.dev.yml logs -f backend
```

5. **Access the API**:
   - API: http://localhost:3000/api/v1
   - Swagger Docs: http://localhost:3000/api/docs
   - Health Check: http://localhost:3000/api/v1/health

### Stop services:
```bash
docker-compose -f docker-compose.dev.yml down
```

## Option 2: Local Development Setup

### Prerequisites
- Node.js 18+
- PostgreSQL 14+ (running locally)
- Redis 6+ (running locally)

### Steps

1. **Install dependencies**:
```bash
cd backend
npm install
```

2. **Create `.env` file** (copy from `.env.example`):
```bash
cp .env.example .env
```

3. **Update `.env` file** with your local database and Redis settings:
```env
DATABASE_URL="postgresql://indooruser:indoorpass@localhost:5432/indoor_games?schema=public"
REDIS_HOST=localhost
REDIS_PORT=6379
```

4. **Start PostgreSQL and Redis** (if not running):
   - PostgreSQL: Ensure it's running on port 5432
   - Redis: Ensure it's running on port 6379

5. **Run database migrations**:
```bash
npx prisma migrate dev
```

6. **Start the development server**:
```bash
npm run start:dev
```

7. **Access the API**:
   - API: http://localhost:3000/api/v1
   - Swagger Docs: http://localhost:3000/api/docs
   - Health Check: http://localhost:3000/api/v1/health

## Database Setup

### Using Docker (Automatic)
The database is automatically created when you start the Docker containers.

### Using Local PostgreSQL

1. **Create database**:
```sql
CREATE DATABASE indoor_games;
CREATE USER indooruser WITH PASSWORD 'indoorpass';
GRANT ALL PRIVILEGES ON DATABASE indoor_games TO indooruser;
```

2. **Run migrations**:
```bash
cd backend
npx prisma migrate dev
```

## Verify Setup

1. **Check health endpoint**:
```bash
curl http://localhost:3000/api/v1/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

2. **Test authentication**:
```bash
# Send OTP
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+923001234567"}'

# Verify OTP (check console for OTP code)
curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+923001234567", "otp": "123456"}'
```

## Troubleshooting

### Port Already in Use
If ports 3000, 5432, or 6379 are already in use:

**Docker**: Modify ports in `docker-compose.dev.yml`:
```yaml
ports:
  - "3001:3000"  # Change host port
```

**Local**: Stop the conflicting service or change ports in `.env`

### Database Connection Error
- Verify PostgreSQL is running
- Check DATABASE_URL in `.env`
- Ensure database exists
- Check user permissions

### Redis Connection Error
- Verify Redis is running
- Check REDIS_HOST and REDIS_PORT in `.env`
- Test connection: `redis-cli ping`

### Migration Errors
- Ensure database is created
- Check DATABASE_URL is correct
- Try resetting: `npx prisma migrate reset` (WARNING: deletes data)

## Next Steps

Once setup is complete:
1. Explore API documentation at http://localhost:3000/api/docs
2. Test endpoints using Swagger UI
3. Start building mobile apps and admin dashboard


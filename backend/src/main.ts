import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import * as compression from 'compression';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Enable compression middleware (gzip/deflate)
  app.use(compression({
    filter: (req, res) => {
      // Compress responses larger than 1KB
      if (req.headers['x-no-compression']) {
        return false;
      }
      return compression.filter(req, res);
    },
    level: 6, // Compression level (1-9, 6 is a good balance)
    threshold: 1024, // Only compress responses larger than 1KB
  }));

  // Request duration logging middleware (enhanced)
  app.use((req, res, next) => {
    const start = Date.now();
    const requestId = Math.random().toString(36).substring(7);
    
    console.log(`[${requestId}] ${req.method} ${req.url} - ${new Date().toISOString()}`);
    
    res.on('finish', () => {
      const duration = Date.now() - start;
      const statusEmoji = res.statusCode >= 400 ? '❌' : res.statusCode >= 300 ? '⚠️' : '✅';
      console.log(
        `[${requestId}] ${statusEmoji} ${req.method} ${req.url} - ${res.statusCode} - ${duration}ms`
      );
    });
    
    next();
  });

  // Global prefix
  const apiPrefix = process.env.API_PREFIX || 'api/v1';
  app.setGlobalPrefix(apiPrefix);

  // CORS configuration
  const corsOrigins = process.env.CORS_ORIGIN?.split(',').map(origin => origin.trim()) || [
      'http://localhost:3000',
      'http://localhost:3001',
      'http://localhost:3002',
  ];
  
  // Allow all origins in development for mobile apps
  const allowAllOrigins = process.env.NODE_ENV !== 'production' && process.env.CORS_ORIGIN === '*';
  
  app.enableCors({
    origin: allowAllOrigins ? true : corsOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    exposedHeaders: ['Content-Type'],
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Swagger documentation
  if (process.env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle('Indoor Games Booking API')
      .setDescription('API for Indoor Games Booking System')
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);
  }

  const port = process.env.PORT || 3001;
  const host = process.env.HOST || '0.0.0.0'; // Bind to all network interfaces
  
  const server = await app.listen(port, host);
  
  // Enable HTTP keep-alive for better connection reuse
  server.keepAliveTimeout = 65000; // 65 seconds (slightly longer than default 60s)
  server.headersTimeout = 66000; // 66 seconds (must be > keepAliveTimeout)
  
  console.log('✅ HTTP Keep-Alive enabled (65s timeout)');
  
  // Get network IP for display (optional, for better logging)
  const networkUrl = process.env.NETWORK_URL || `http://192.168.0.65:${port}`;
  console.log(`Application is running on:`);
  console.log(`  - Local: http://localhost:${port}/${apiPrefix}`);
  console.log(`  - Network: ${networkUrl}/${apiPrefix}`);
  console.log(`  - Swagger: ${networkUrl}/api/docs`);
}

bootstrap();


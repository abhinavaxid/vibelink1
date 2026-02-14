import express, { Express } from 'express';
import helmet from 'helmet';
import cors, { CorsOptions } from 'cors';
import http from 'http';
import { Server as SocketIOServer } from 'socket.io';
import dotenv from 'dotenv';

import { initializeDatabase } from './database/init';
import { disconnect } from './database/connection';
import {
  loggingMiddleware,
  rateLimitMiddleware,
} from './middleware';
import { errorHandler } from './utils/errors';
import { setupSocketHandlers } from './socket';

// Load environment variables
dotenv.config();

const app: Express = express();
const PORT = parseInt(process.env.PORT || '5000', 10);
const NODE_ENV = process.env.NODE_ENV || 'development';

const normalizeOrigin = (origin: string): string => origin.trim().replace(/\/+$/, '');
const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:3000';
const allowAllOrigins = corsOrigin.trim() === '*';
const allowedOrigins = allowAllOrigins
  ? []
  : corsOrigin
      .split(',')
      .map((origin) => normalizeOrigin(origin))
      .filter((origin) => origin.length > 0);

const corsOptions: CorsOptions = allowAllOrigins
  ? {
      origin: '*',
      credentials: false,
    }
  : {
      credentials: true,
      origin: (requestOrigin, callback) => {
        // Allow requests without Origin header (health checks/server-to-server).
        if (!requestOrigin) {
          callback(null, true);
          return;
        }

        const normalizedRequestOrigin = normalizeOrigin(requestOrigin);
        if (allowedOrigins.includes(normalizedRequestOrigin)) {
          callback(null, true);
          return;
        }

        callback(new Error(`CORS blocked for origin: ${requestOrigin}`));
      },
    };

const httpServer = http.createServer(app);
const socketServer = new SocketIOServer(httpServer, {
  cors: {
    origin: allowAllOrigins ? '*' : allowedOrigins,
    methods: ['GET', 'POST'],
    credentials: !allowAllOrigins,
  },
});

/** ===================== MIDDLEWARE ===================== */

app.use(helmet());
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));

app.use(loggingMiddleware);

app.use(
  rateLimitMiddleware(
    parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000', 10),
    parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100', 10)
  )
);

/** ===================== HEALTH CHECK ===================== */

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: NODE_ENV,
  });
});

/** ===================== API ROUTES ===================== */

import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import roomRoutes from './routes/rooms';
import gameRoutes from './routes/games';
import matchRoutes from './routes/matches';

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/rooms', roomRoutes);
app.use('/api/games', gameRoutes);
app.use('/api/matches', matchRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: {
      message: 'Route not found',
      path: req.path,
    },
  });
});

app.use(errorHandler);

/** ===================== SOCKET.IO SETUP ===================== */

setupSocketHandlers(socketServer);

/** ===================== SERVER STARTUP ===================== */

async function startServer(): Promise<void> {
  try {
    console.log('Initializing database...');
    await initializeDatabase();

    httpServer.listen(PORT, '0.0.0.0', () => {
      console.log(`REST API + WebSocket server running on http://0.0.0.0:${PORT}`);
      console.log(`Environment: ${NODE_ENV}`);
      console.log(
        allowAllOrigins
          ? 'CORS: allowing all origins (*)'
          : `CORS: allowing ${allowedOrigins.join(', ')}`
      );
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    await disconnect();
    process.exit(1);
  }
}

/** ===================== GRACEFUL SHUTDOWN ===================== */

async function shutdown(signal: string): Promise<void> {
  console.log(`\nReceived ${signal} signal, shutting down gracefully...`);

  httpServer.close(() => {
    console.log('HTTP server closed');
  });

  try {
    await disconnect();
    console.log('Server shutdown complete');
    process.exit(0);
  } catch (error) {
    console.error('Error during shutdown:', error);
    process.exit(1);
  }
}

process.on('SIGTERM', () => {
  void shutdown('SIGTERM');
});
process.on('SIGINT', () => {
  void shutdown('SIGINT');
});

if (require.main === module) {
  void startServer();
}

export { app, httpServer, socketServer };

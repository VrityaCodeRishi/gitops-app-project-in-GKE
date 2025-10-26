import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pkg from 'pg';
import client from 'prom-client';

dotenv.config();

const { Pool } = pkg;

const port = process.env.PORT || 8080;
const app = express();

const register = new client.Registry();
register.setDefaultLabels({
  service: 'gitops-demo-backend'
});
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.05, 0.1, 0.3, 0.5, 1, 2, 5]
});
const dbQueryDuration = new client.Histogram({
  name: 'db_query_duration_seconds',
  help: 'Duration of database queries in seconds',
  labelNames: ['operation'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2]
});
register.registerMetric(httpRequestDuration);
register.registerMetric(dbQueryDuration);

app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer({ method: req.method, route: req.path });
  res.on('finish', () => {
    end({ status_code: res.statusCode });
  });
  next();
});

const poolConfig = process.env.DATABASE_URL
  ? { connectionString: process.env.DATABASE_URL }
  : {
      host: process.env.PGHOST || 'localhost',
      user: process.env.PGUSER || 'postgres',
      password: process.env.PGPASSWORD || 'postgres',
      database: process.env.PGDATABASE || 'app',
      port: Number(process.env.PGPORT || 5432)
    };

const pool = new Pool(poolConfig);

app.get('/api/health', async (_req, res) => {
  try {
    const dbResp = await pool.query('SELECT NOW() AS now');
    res.json({ status: 'ok', databaseTime: dbResp.rows[0].now });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

app.get('/api/message', async (_req, res) => {
  try {
    const end = dbQueryDuration.startTimer({ operation: 'message' });
    const result = await pool.query(
      `SELECT 'Hello from the backend! The database is at ' || current_database() || ' and time is ' || NOW() AS message`
    );
    end();
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

app.get('/metrics', async (_req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).json(err.message);
  }
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});

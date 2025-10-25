import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import pkg from 'pg';

dotenv.config();

const { Pool } = pkg;

const port = process.env.PORT || 8080;
const app = express();

app.use(cors());
app.use(express.json());

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
    const result = await pool.query(
      `SELECT 'Hello from the backend! The database is at ' || current_database() || ' and time is ' || NOW() AS message`
    );
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

app.listen(port, () => {
  console.log(`Backend listening on port ${port}`);
});

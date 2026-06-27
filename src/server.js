import express from 'express';
import pg from 'pg';

const { Pool } = pg;
const app = express();

app.use(express.json());

// Initialize PostgreSQL Connection Pool using your Render database environment variable
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false } // Required for secure cloud hosting connections
});

// A quick health-check route to ensure the server is responding
app.get('/api/health', async (req, res) => {
  try {
    const dbTest = await pool.query('SELECT NOW()');
    res.json({ 
      status: 'healthy', 
      message: 'Server is running and connected to PostgreSQL!', 
      dbTime: dbTest.rows[0].now 
    });
  } catch (error) {
    console.error('Database connection error:', error);
    res.status(500).json({ status: 'error', message: 'Failed to connect to database.' });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Marketplace server humming on port ${PORT}`));

import express from 'express';
import dotenv from 'dotenv';
import { pool } from './db.js';
import productRoutes from './routes/productRoutes.js';

dotenv.config();

const app = express();

app.use(express.json());

// Mount routes
app.use('/api/products', productRoutes);

// Health check
app.get('/api/health', async (req, res) => {
  try {
    const dbTest = await pool.query('SELECT NOW()');

    res.json({
      status: 'healthy',
      message: 'Server is running and connected to PostgreSQL!',
      dbTime: dbTest.rows[0].now
    });

  } catch (error) {
    console.error('Database connection error:', error.message);

    res.status(500).json({
      status: 'error',
      message: 'Failed to connect to database.'
    });
  }
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`🚀 Marketplace server running on port ${PORT}`);
});

import express from 'express';

const router = express.Router();

router.get('/', async (req, res) => {
  try {
    const pool = req.app.locals.pool;

    const result = await pool.query(
      'SELECT * FROM products ORDER BY title'
    );

    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: 'Failed to load products'
    });
  }
});

export default router;

import express from 'express';
import { createStoreProduct } from '../controllers/productController.js';

const router = express.Router();

// POST /api/products/store - Admin creates a store-owned product
router.post('/store', createStoreProduct);

export default router;

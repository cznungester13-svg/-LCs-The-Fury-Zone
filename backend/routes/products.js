import express from "express";
import { pool } from "../db.js";

const router = express.Router();


// GET ALL PRODUCTS
router.get("/", async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT * FROM products WHERE is_active = TRUE AND is_deleted = FALSE ORDER BY created_at DESC`
        );

        res.json(result.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


// GET SINGLE PRODUCT
router.get("/:id", async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT * FROM products WHERE product_id = $1`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ error: "Product not found" });
        }

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


// CREATE PRODUCT (STORE OR RESELLER)
router.post("/", async (req, res) => {
    try {
        const {
            title,
            description,
            price,
            category_id,
            seller_type,
            seller_id,
            condition
        } = req.body;

        const result = await pool.query(
            `INSERT INTO products
            (title, description, price, category_id, seller_type, seller_id, condition, listing_status)
            VALUES
            ($1,$2,$3,$4,$5,$6,$7,'ACTIVE')
            RETURNING *`,
            [
                title,
                description,
                price,
                category_id,
                seller_type,
                seller_id,
                condition || "NEW"
            ]
        );

        res.json(result.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


// DELETE PRODUCT (soft delete)
router.delete("/:id", async (req, res) => {
    try {
        const { id } = req.params;

        await pool.query(
            `UPDATE products
             SET is_deleted = TRUE, is_active = FALSE
             WHERE product_id = $1`,
            [id]
        );

        res.json({ message: "Product deleted" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

export default router;

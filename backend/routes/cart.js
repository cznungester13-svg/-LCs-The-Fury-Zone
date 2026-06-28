import express from "express";
import { pool } from "../db.js";

const router = express.Router();


// GET CART BY USER
router.get("/:user_id", async (req, res) => {
    try {
        const { user_id } = req.params;

        const cart = await pool.query(
            `SELECT * FROM carts WHERE user_id = $1`,
            [user_id]
        );

        if (cart.rows.length === 0) {
            return res.json({ items: [] });
        }

        const cart_id = cart.rows[0].cart_id;

        const items = await pool.query(
            `SELECT ci.*, p.title, p.price, p.thumbnail_url
             FROM cart_items ci
             JOIN products p ON p.product_id = ci.product_id
             WHERE ci.cart_id = $1`,
            [cart_id]
        );

        res.json(items.rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


// ADD ITEM TO CART
router.post("/add", async (req, res) => {
    try {
        const { user_id, product_id, quantity } = req.body;

        // get or create cart
        let cart = await pool.query(
            `SELECT * FROM carts WHERE user_id = $1`,
            [user_id]
        );

        if (cart.rows.length === 0) {
            cart = await pool.query(
                `INSERT INTO carts (user_id)
                 VALUES ($1)
                 RETURNING *`,
                [user_id]
            );
        }

        const cart_id = cart.rows[0].cart_id;

        const item = await pool.query(
            `INSERT INTO cart_items (cart_id, product_id, quantity)
             VALUES ($1, $2, $3)
             RETURNING *`,
            [cart_id, product_id, quantity || 1]
        );

        res.json(item.rows[0]);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});


// REMOVE ITEM
router.delete("/item/:id", async (req, res) => {
    try {
        const { id } = req.params;

        await pool.query(
            `DELETE FROM cart_items WHERE cart_item_id = $1`,
            [id]
        );

        res.json({ message: "Item removed" });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

export default router;

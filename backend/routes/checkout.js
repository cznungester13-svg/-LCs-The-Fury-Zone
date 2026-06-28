import express from "express";
import { pool } from "../db.js";

const router = express.Router();

router.post("/", async (req, res) => {
    const client = await pool.connect();

    try {
        await client.query("BEGIN");

        const { user_id } = req.body;

        // 1. Get cart
        const cartResult = await client.query(
            `SELECT * FROM carts WHERE user_id = $1`,
            [user_id]
        );

        if (cartResult.rows.length === 0) {
            return res.status(400).json({ error: "Cart is empty" });
        }

        const cart_id = cartResult.rows[0].cart_id;

        // 2. Get cart items
        const itemsResult = await client.query(
            `SELECT ci.*, p.price
             FROM cart_items ci
             JOIN products p ON p.product_id = ci.product_id
             WHERE ci.cart_id = $1`,
            [cart_id]
        );

        if (itemsResult.rows.length === 0) {
            return res.status(400).json({ error: "No items in cart" });
        }

        // 3. Calculate total
        let total = 0;
        itemsResult.rows.forEach(item => {
            total += item.price * item.quantity;
        });

        // 4. Create order
        const orderResult = await client.query(
            `INSERT INTO orders (user_id, total_amount, status)
             VALUES ($1, $2, 'PAID')
             RETURNING *`,
            [user_id, total]
        );

        const order_id = orderResult.rows[0].order_id;

        // 5. Insert order items + update inventory
        for (const item of itemsResult.rows) {
            await client.query(
                `INSERT INTO order_items
                (order_id, product_id, quantity, price)
                VALUES ($1, $2, $3, $4)`,
                [order_id, item.product_id, item.quantity, item.price]
            );

            await client.query(
                `UPDATE products
                 SET quantity = quantity - $1
                 WHERE product_id = $2`,
                [item.quantity, item.product_id]
            );
        }

        // 6. Clear cart
        await client.query(
            `DELETE FROM cart_items WHERE cart_id = $1`,
            [cart_id]

import pkg from "pg";
import dotenv from "dotenv";

dotenv.config();

const { Pool } = pkg;

// Neon PostgreSQL connection pool
export const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});

// Test connection (safe version)
(async () => {
    try {
        const client = await pool.connect();
        console.log("🟢 Connected to Neon Database");
        client.release();
    } catch (err) {
        console.error("🔴 Database connection error:", err.message);
    }
})();

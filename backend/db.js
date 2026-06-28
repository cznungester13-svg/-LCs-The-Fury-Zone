import pkg from "pg";
import dotenv from "dotenv";

dotenv.config();

const { Pool } = pkg;

// Neon PostgreSQL connection
export const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});

// Optional test connection
pool.connect()
    .then(() => console.log("🟢 Connected to Neon Database"))
    .catch((err) => console.error("🔴 Database connection error:", err));

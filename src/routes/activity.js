import express from "express";
import db from "../db.js"; // Ensure this path is correct for your database module

const router = express.Router();

/**
 * ✅ GET /api/activity/logs - Fetches the user activity logs.
 * Joins User_Logs with Users to get the UserEmail (used as UserName).
 */
router.get('/logs', async (req, res) => {
    try {
        const sql = `
            SELECT 
                ul.UsrLogTmstp,
                u.UserEmail AS UserName, 
                ul.UsrLogAction,
                ul.UsrLogDescrpt
            FROM 
                User_Logs ul
            JOIN 
                Users u ON ul.UserID = u.UserID
            ORDER BY 
                ul.UsrLogTmstp DESC
            LIMIT 50;
        `;
        
        // --- REAL DATABASE EXECUTION ---
        // This line is now active and will fetch data from your User_Logs table,
        // joining it with the Users table.
        const [logs] = await db.query(sql); 

        res.json({ success: true, logs: logs });

    } catch (error) {
        console.error("Error fetching activity logs:", error);
        res.status(500).json({ success: false, message: "Failed to retrieve logs from the database." });
    }
});

export default router;
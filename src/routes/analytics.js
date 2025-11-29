// Backend/src/routes/analytics.js
import express from "express";
import db from "../db.js";

const router = express.Router();

/**
 * ======================================================
 * SHOP OWNER ANALYTICS ROUTES
 * ======================================================
 */

/**
 * 1️⃣ DETAILED CUSTOMER SEGMENTS (From Python ML Table)
 * Endpoint: GET /api/analytics/segment-details/:shopId
 */
router.get("/segment-details/:shopId", async (req, res) => {
    const { shopId } = req.params;
    if (!shopId) return res.status(400).json({ error: "Shop ID is required." });

    try {
        // Aggregates the individual rows created by the Python script
        const query = `
            SELECT 
                SegmentName,
                COUNT(CustID) as customerCount,
                ROUND(AVG(TotalSpend), 2) as averageSpend,
                ROUND(AVG(Frequency), 1) as averageFrequency,
                ROUND(AVG(Recency), 0) as averageRecency
            FROM Customer_Segments
            WHERE ShopID = ?
            GROUP BY SegmentName
            ORDER BY customerCount DESC;
        `;
        const [segments] = await db.query(query, [shopId]);
        res.json(segments);
    } catch (error) {
        console.error("Error fetching segment details:", error);
        res.status(500).json({ error: "Failed to fetch segment details." });
    }
});

/**
 * 2️⃣ POPULAR SERVICES (Live Calculation)
 * Endpoint: GET /api/analytics/popular-services/:shopId
 */
router.get("/popular-services/:shopId", async (req, res) => {
    const { shopId } = req.params;
    if (!shopId) return res.status(400).json({ error: "Shop ID is required." });

    try {
        const query = `
            SELECT 
                s.SvcName,
                COUNT(ld.LndryDtlID) as orderCount
            FROM Laundry_Details ld
            JOIN Orders o ON ld.OrderID = o.OrderID
            JOIN Services s ON ld.SvcID = s.SvcID
            WHERE o.ShopID = ?
            GROUP BY s.SvcName
            ORDER BY orderCount DESC
            LIMIT 5;
        `;
        const [services] = await db.query(query, [shopId]);
        res.json(services);
    } catch (error) {
        console.error("Error fetching popular services:", error);
        res.status(500).json({ error: "Failed to fetch popular services." });
    }
});


/**
 * 3️⃣ BUSIEST TIMES (Live Calculation)
 * Endpoint: GET /api/analytics/busiest-times/:shopId
 */
router.get("/busiest-times/:shopId", async (req, res) => {
    const { shopId } = req.params;
    if (!shopId) return res.status(400).json({ error: "Shop ID is required." });

    try {
        const query = `
            SELECT 
                CASE 
                    WHEN HOUR(OrderCreatedAt) BETWEEN 7 AND 11 THEN 'Morning (7am-12pm)'
                    WHEN HOUR(OrderCreatedAt) BETWEEN 12 AND 16 THEN 'Afternoon (12pm-5pm)'
                    ELSE 'Evening (5pm onwards)'
                END AS timeSlot,
                COUNT(*) as orderCount
            FROM Orders
            WHERE ShopID = ?
            GROUP BY timeSlot
            ORDER BY FIELD(timeSlot, 'Morning (7am-12pm)', 'Afternoon (12pm-5pm)', 'Evening (5pm onwards)');
        `;
        const [results] = await db.query(query, [shopId]);
        res.json(results);
    } catch (error) {
        console.error("Error fetching busiest times:", error);
        res.status(500).json({ error: "Failed to fetch busiest times." });
    }
});

/**
 * ======================================================
 * 4️⃣ ADMIN DASHBOARD - SYSTEM-WIDE KPIs (Live Calculation)
 * Endpoint: GET /api/analytics/admin-dashboard-stats
 * ======================================================
 */
router.get("/admin-dashboard-stats", async (req, res) => {
    try {
        // 1. Shop & User Stats
        const [shopStats] = await db.query(`
            SELECT 
                COUNT(DISTINCT OwnerID) as totalOwners,
                COUNT(CASE WHEN ShopStatus = 'Open' THEN 1 END) as activeShops
            FROM Laundry_Shops
        `);

        const [userStats] = await db.query(`SELECT COUNT(*) as totalUsers FROM Users`);

        // 2. Revenue Stats (Service + Delivery)
        const [revenueStats] = await db.query(`
            SELECT 
                (SELECT COALESCE(SUM(PayAmount), 0) FROM Invoices WHERE PaymentStatus = 'Paid') +
                (SELECT COALESCE(SUM(DlvryAmount), 0) FROM Delivery_Payments WHERE DlvryPaymentStatus = 'Paid') 
            AS totalPayments
        `);

        // 3. Monthly Growth Chart (Users Joined)
        const [chartData] = await db.query(`
            SELECT 
                DATE_FORMAT(DateCreated, '%Y-%m') as label, 
                COUNT(*) as value 
            FROM Users
            WHERE DateCreated >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
            GROUP BY label
            ORDER BY label ASC
        `);
        
        res.json({
            totalOwners: shopStats[0].totalOwners || 0,
            activeShops: shopStats[0].activeShops || 0,
            totalUsers: userStats[0].totalUsers || 0, 
            totalPayments: parseFloat(revenueStats[0].totalPayments || 0), 
            chartData: chartData || [] 
        });

    } catch (error) {
        console.error("Error fetching admin dashboard stats:", error);
        res.status(500).json({ error: "Failed to fetch admin stats" });
    }
});

export default router;
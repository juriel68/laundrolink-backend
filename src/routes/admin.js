// Backend/src/routes/admin.js

import express from "express";
import db, { runSystemBackup, BACKUP_DIR } from "../db.js";
import logger, { logUserActivity } from "../utils/logger.js"; 
import fs from 'fs'; 
import path from 'path'; 

const router = express.Router();

// Helper function to dynamically generate SQL date condition
const getDateCondition = (period, alias = 'o') => {
    switch (period) {
        case 'Monthly': return `YEAR(${alias}.OrderCreatedAt) = YEAR(CURDATE()) AND MONTH(${alias}.OrderCreatedAt) = MONTH(CURDATE())`;
        case 'Yearly': return `YEAR(${alias}.OrderCreatedAt) = YEAR(CURDATE())`;
        case 'Weekly': default: return `YEARWEEK(${alias}.OrderCreatedAt, 1) = YEARWEEK(CURDATE(), 1)`;
    }
};

const getShopDateCondition = (period, alias = 'ls') => {
    switch (period) {
        case 'Monthly': return `YEAR(${alias}.DateCreated) = YEAR(CURDATE()) AND MONTH(${alias}.DateCreated) = MONTH(CURDATE())`;
        case 'Yearly': return `YEAR(${alias}.DateCreated) = YEAR(CURDATE())`;
        case 'Weekly': default: return `YEARWEEK(${alias}.DateCreated, 1) = YEARWEEK(CURDATE(), 1)`;
    }
};

// =======================================================
// 1. System Settings Routes (Unchanged)
// =======================================================

router.get('/config/maintenance-status', async (req, res) => {
    try {
        const [[config]] = await db.query("SELECT ConfigValue FROM SystemConfig WHERE ConfigKey = 'MAINTENANCE_MODE'");
        const isEnabled = config && config.ConfigValue === 'true';
        return res.status(200).json({ maintenanceMode: isEnabled });
    } catch (error) {
        logger.error(`Error fetching maintenance status: ${error.message}`);
        return res.status(500).json({ message: 'Failed to fetch system configuration.' });
    }
});

router.post('/config/set-maintenance', async (req, res) => {
    const { enable, userId } = req.body; 
    const value = enable ? 'true' : 'false';

    try {
        await db.query(`
            INSERT INTO SystemConfig (ConfigKey, ConfigValue)
            VALUES ('MAINTENANCE_MODE', ?)
            ON DUPLICATE KEY UPDATE ConfigValue = ?`, [value, value]);

        if (userId) {
            await logUserActivity(userId, 'Admin', 'System Config', `Maintenance mode set to: ${enable}`);
        }

        return res.status(200).json({ message: 'Maintenance mode updated.', maintenanceMode: enable });
    } catch (error) {
        logger.error(`Error setting maintenance status: ${error.message}`);
        return res.status(500).json({ message: 'Failed to update system configuration.' });
    }
});


// =======================================================
// 2. Backup Routes (Unchanged)
// =======================================================

router.post('/backup/run', async (req, res) => {
    const { userId } = req.body; 

    try {
        const backupFilePath = await runSystemBackup();
        const backupFileName = path.basename(backupFilePath);
        logger.info(`Database backup successful: ${backupFileName}`);
        
        if (userId) {
            await logUserActivity(userId, 'Admin', 'Data Security', `Generated system backup: ${backupFileName}`);
        }

        return res.status(200).json({ 
            message: 'Database backup completed successfully.',
            filename: backupFileName,
            downloadUrl: `/api/admin/backup/download?filename=${backupFileName}&userId=${userId || ''}` 
        });
    } catch (error) {
        logger.error(`Error running database backup: ${error.message}`);
        return res.status(500).json({ message: 'Failed to run database backup.', error: error.message });
    }
});

router.get('/backup/download', async (req, res) => {
    const { filename, userId } = req.query; 

    if (!filename) return res.status(400).json({ message: 'Missing filename parameter.' });

    const filePath = path.join(BACKUP_DIR, filename);

    if (!fs.existsSync(filePath) || !filePath.startsWith(BACKUP_DIR)) {
        logger.warn(`Attempted download of non-existent or invalid backup file: ${filename}`);
        return res.status(404).json({ message: 'Backup file not found.' });
    }

    if (userId) {
        try {
            await logUserActivity(userId, 'Admin', 'Data Security', `Downloaded backup file: ${filename}`);
        } catch (logError) { console.error("Failed to log download activity:", logError); }
    }

    res.setHeader('Content-disposition', `attachment; filename=${filename}`);
    res.setHeader('Content-type', 'application/sql'); 
    const fileStream = fs.createReadStream(filePath);
    fileStream.pipe(res);
});

// =======================================================
// 3. Admin Reporting Routes (Metrics - UPDATED REVENUE LOGIC)
// =======================================================

router.post("/report/platform-summary", async (req, res) => {
    const { period = 'Weekly' } = req.body; 

    let groupBy, dateFormat;
    const dateCondition = getDateCondition(period, 'o');
    const shopDateCondition = getShopDateCondition(period, 'ls');
    
    switch (period) {
        case 'Monthly':
            groupBy = `DATE_FORMAT(o.OrderCreatedAt, '%Y-%m')`;
            dateFormat = `'%b'`;
            break;
        case 'Yearly':
            groupBy = `YEAR(o.OrderCreatedAt)`;
            dateFormat = `'%Y'`;
            break;
        case 'Weekly':
        default:
            groupBy = `DAYOFWEEK(o.OrderCreatedAt)`;
            dateFormat = `'%a'`;
    }

    try {
        await db.query("SET SESSION group_concat_max_len = 1000000;");

        // 🟢 UPDATED QUERY: Calculates Total Revenue from BOTH Invoices AND Delivery Payments
        const query = `
            SELECT
                (SELECT COUNT(*) FROM Orders) AS totalOrders,
                
                (SELECT 
                    (SELECT COALESCE(SUM(PayAmount), 0) FROM Invoices i JOIN Orders o ON i.OrderID = o.OrderID WHERE i.PaymentStatus = 'Paid' AND ${dateCondition}) +
                    (SELECT COALESCE(SUM(DlvryAmount), 0) FROM Delivery_Payments dp JOIN Orders o ON dp.OrderID = o.OrderID WHERE dp.DlvryPaymentStatus = 'Paid' AND ${dateCondition})
                ) AS totalRevenue,

                (SELECT COUNT(ls.ShopID) FROM Laundry_Shops ls WHERE ${shopDateCondition}) AS newShops,

                (SELECT CONCAT('[', 
                    GROUP_CONCAT(
                        JSON_OBJECT('label', label, 'value', revenue) 
                        ORDER BY sortKey
                    ), 
                ']')
                FROM (
                    SELECT
                        ${groupBy} AS sortKey,
                        DATE_FORMAT(o.OrderCreatedAt, ${dateFormat}) AS label,
                        -- Summing both revenue streams for the chart
                        (COALESCE(SUM(i.PayAmount), 0) + COALESCE(SUM(dp.DlvryAmount), 0)) AS revenue
                    FROM Orders o
                    LEFT JOIN Invoices i ON o.OrderID = i.OrderID AND i.PaymentStatus = 'Paid'
                    LEFT JOIN Delivery_Payments dp ON o.OrderID = dp.OrderID AND dp.DlvryPaymentStatus = 'Paid'
                    WHERE ${dateCondition} 
                    GROUP BY sortKey, label
                ) AS ChartData
                ) AS chartData;
        `;
        
        const [[results]] = await db.query(query);
        const chartDataArray = results.chartData ? JSON.parse(results.chartData) : [];

        res.json({
            totalOrders: results.totalOrders || 0,
            totalRevenue: results.totalRevenue || 0,
            newShops: results.newShops || 0, 
            chartData: chartDataArray,
        });

    } catch (error) {
        logger.error("Error fetching platform summary:", error);
        res.status(500).json({ error: "Failed to fetch platform summary" });
    }
});

router.post("/report/top-shops", async (req, res) => {
    const { period } = req.body; 
    const dateCondition = getDateCondition(period, 'o');
    
    try {
        // 🟢 UPDATED: Ranks shops by Total Revenue (Service + Delivery)
        const query = `
            SELECT
                ls.ShopName AS name, 
                (COALESCE(SUM(i.PayAmount), 0) + COALESCE(SUM(dp.DlvryAmount), 0)) AS revenue
            FROM Orders o
            JOIN Laundry_Shops ls ON o.ShopID = ls.ShopID 
            LEFT JOIN Invoices i ON o.OrderID = i.OrderID AND i.PaymentStatus = 'Paid'
            LEFT JOIN Delivery_Payments dp ON o.OrderID = dp.OrderID AND dp.DlvryPaymentStatus = 'Paid'
            WHERE ${dateCondition}
            GROUP BY ls.ShopID, ls.ShopName
            ORDER BY revenue DESC
            LIMIT 10;
        `;
        const [rows] = await db.query(query);
        res.json(rows);
    } catch (error) {
        logger.error("Error fetching top shops:", error);
        res.status(500).json({ error: "Failed to fetch top shops" });
    }
});

router.post("/report/order-status-breakdown", async (req, res) => {
    const { period } = req.body; 
    const dateCondition = getDateCondition(period, 'o');
    
    try {
        const query = `
            SELECT 
                t1.OrderStatus AS label, 
                COUNT(o.OrderID) AS count
            FROM Orders o
            JOIN Order_Status t1 ON t1.OrderID = o.OrderID
            JOIN (
                SELECT OrderID, MAX(OrderUpdatedAt) as max_date
                FROM Order_Status
                GROUP BY OrderID
            ) t2 ON t1.OrderID = t2.OrderID AND t1.OrderUpdatedAt = t2.max_date
            
            -- Filter: Order must have at least ONE paid component (Service OR Delivery) to be counted in reports
            LEFT JOIN Invoices i ON o.OrderID = i.OrderID 
            LEFT JOIN Delivery_Payments dp ON o.OrderID = dp.OrderID
            WHERE ${dateCondition}
            AND (i.PaymentStatus = 'Paid' OR dp.DlvryPaymentStatus = 'Paid')
            GROUP BY t1.OrderStatus
            ORDER BY count DESC;
        `;
        const [rows] = await db.query(query);
        res.json(rows);
    } catch (error) {
        logger.error("Error fetching order status breakdown:", error);
        res.status(500).json({ error: "Failed to fetch order status breakdown" });
    }
});


// =======================================================
// 4. Admin Analytics Routes (Insights - from Python Tables)
// =======================================================

router.get("/analytics/growth-trend", async (req, res) => {
    try {
        const query = `
            SELECT 
                MonthYear AS label, 
                MonthlyRevenue AS revenue, 
                NewShops
            FROM Platform_Growth_Metrics 
            ORDER BY MonthYear DESC;
        `;
        const [rows] = await db.query(query);
        res.json(rows);
    } catch (error) {
        logger.error("Error fetching platform growth trend:", error);
        res.status(500).json({ error: "Failed to fetch platform growth trend" });
    }
});

router.get("/analytics/service-gaps", async (req, res) => {
    try {
        const query = `
            SELECT 
                SvcName, 
                PlatformOrderCount, 
                OfferingShopCount, 
                GapScore
            FROM Service_Gap_Analysis 
            ORDER BY GapScore DESC
            LIMIT 10;
        `;
        const [rows] = await db.query(query);
        res.json(rows);
    } catch (error) {
        logger.error("Error fetching service gap analysis:", error);
        res.status(500).json({ error: "Failed to fetch service gap analysis" });
    }
});

export default router;
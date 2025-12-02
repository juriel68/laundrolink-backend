// routes/orders.js
import multer from 'multer';
import { cloudinary } from "../config/externalServices.js";
import express from "express";
import db from "../db.js";
import { logUserActivity } from '../utils/logger.js'; 

const router = express.Router();
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// =================================================================
// Helper Functions
// =================================================================

function generateID(prefix) {
    const randomDigits = Math.floor(1000000 + Math.random() * 9000000);
    return `${prefix}${randomDigits}`;
}

const getDateCondition = (period, alias) => {
    switch (period) {
        case "Today": return `DATE(${alias}.OrderCreatedAt) = CURDATE()`;
        case "Weekly":
        case "Last 7 Days":
        default: return `YEARWEEK(${alias}.OrderCreatedAt, 1) = YEARWEEK(CURDATE(), 1)`;
        case "Monthly":
        case "This Month": return `YEAR(${alias}.OrderCreatedAt) = YEAR(CURDATE()) AND MONTH(${alias}.OrderCreatedAt) = MONTH(CURDATE())`;
        case "Yearly":
        case "This Year": return `YEAR(${alias}.OrderCreatedAt) = YEAR(CURDATE())`;
    }
};

// =================================================================
// API Routes: Order Creation
// =================================================================

router.post("/", async (req, res) => {
    console.log("--- START ORDER CREATION PROCESS ---");
    
    const {
        CustID, ShopID, SvcID, 
        deliveryTypeId, 
        weight, instructions, fabrics, addons, 
        finalDeliveryFee 
    } = req.body;

    if (!CustID || !ShopID || !SvcID || !deliveryTypeId || weight === undefined) {
        return res.status(400).json({ success: false, message: "Missing required fields." });
    }

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Verify this Shop actually supports this Delivery Type
        const [validOption] = await connection.query(
            "SELECT 1 FROM Shop_Delivery_Options WHERE ShopID = ? AND DlvryTypeID = ?",
            [ShopID, deliveryTypeId]
        );

        if (validOption.length === 0) {
            throw new Error("This shop does not support the selected delivery type.");
        }

        // 2. Create Order Record (🟢 UPDATED: Removed StaffID from INSERT)
        const newOrderID = generateID('ODR'); 
        await connection.query(
            "INSERT INTO Orders (OrderID, CustID, ShopID, OrderCreatedAt) VALUES (?, ?, ?, NOW())",
            [newOrderID, CustID, ShopID]
        );

        // 3. Create Laundry Details
        const [lndryResult] = await connection.query(
            "INSERT INTO Laundry_Details (OrderID, SvcID, DlvryTypeID, Kilogram, SpecialInstr) VALUES (?, ?, ?, ?, ?)",
            [newOrderID, SvcID, deliveryTypeId, weight, instructions || null]
        );
        const newLndryDtlID = lndryResult.insertId; 

        // 4. Insert Fabrics
        if (fabrics && fabrics.length > 0) {
            const fabricPlaceholders = fabrics.map(() => `(?, ?)`).join(', ');
            const fabricValues = fabrics.flatMap(fabId => [newLndryDtlID, fabId]); 
            await connection.query(
                `INSERT INTO Order_Fabrics (LndryDtlID, FabID) VALUES ${fabricPlaceholders}`,
                fabricValues
            );
        }

        // 5. Insert Addons
        if (addons && addons.length > 0) {
            const addonPlaceholders = addons.map(() => `(?, ?)`).join(', ');
            const addonValues = addons.flatMap(addonId => [newLndryDtlID, addonId]);
            await connection.query(
                `INSERT INTO Order_AddOns (LndryDtlID, AddOnID) VALUES ${addonPlaceholders}`,
                addonValues
            );
        }

        // 6. SET INITIAL STATUS
        let initialStatus = 'Pending'; 

        // If Drop-off (1) or For Delivery (3), status is 'To Weigh'
        if (deliveryTypeId == 1 || deliveryTypeId == 3) {
             initialStatus = 'To Weigh';
        }
        
        await connection.query(
            `INSERT INTO Order_Status (OrderID, OrderStatus, OrderUpdatedAt) VALUES (?, ?, NOW())`,
            [newOrderID, initialStatus]
        );
    
        // 7. Insert Delivery Payment Record (Conditional)
        if (deliveryTypeId != 1) {
            let dlvryPaymentStatus = 'Pending';
            if (deliveryTypeId == 3) {
                dlvryPaymentStatus = 'Pending Later';
            }

            await connection.query(
                `INSERT INTO Delivery_Payments (OrderID, DlvryAmount, DlvryPaymentStatus, CreatedAt) 
                 VALUES (?, ?, ?, NOW())`,
                [newOrderID, finalDeliveryFee, dlvryPaymentStatus]
            );
        }
        
        await logUserActivity(CustID, 'Customer', 'Create Order', `New order created: ${newOrderID}`);

        await connection.commit();
        res.status(201).json({ success: true, message: "Order created successfully.", orderId: newOrderID });

    } catch (error) {
        await connection.rollback();
        console.error("❌ Create order error:", error);
        res.status(500).json({ success: false, message: error.message || "Failed to create order." });
    } finally {
        connection.release();
    }
});

// =================================================================
// API Routes: Order Fetching (UPDATED JOINS)
// =================================================================

router.get("/customer/:customerId", async (req, res) => {
    const { customerId } = req.params;
    try {
        const query = `
            WITH LatestOrderStatus AS (
                SELECT OrderID, OrderStatus, ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY OrderUpdatedAt DESC) as rn
                FROM Order_Status
            ),
            LatestDeliveryStatus AS (
                SELECT OrderID, DlvryStatus, UpdatedAt, ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY UpdatedAt DESC) as drn
                FROM Delivery_Status
            )
            SELECT 
                o.OrderID AS id,
                o.OrderCreatedAt AS createdAt,
                ls.ShopName AS shopName,
                ls.ShopImage_url AS shopImage,
                s.SvcName AS serviceName,
                los.OrderStatus AS status,
                i.PayAmount AS totalAmount,
                i.PaymentStatus AS invoiceStatus,
                dp.DlvryAmount AS deliveryAmount,
                dp.DlvryPaymentStatus AS deliveryPaymentStatus,
                lds.DlvryStatus AS deliveryStatus,
                 CASE WHEN cr.CustRateID IS NOT NULL THEN 1 ELSE 0 END AS isRated
            FROM Orders o
            JOIN LatestOrderStatus los ON o.OrderID = los.OrderID AND los.rn = 1
            LEFT JOIN LatestDeliveryStatus lds ON o.OrderID = lds.OrderID AND lds.drn = 1
            JOIN Laundry_Details ld ON o.OrderID = ld.OrderID 
            JOIN Services s ON ld.SvcID = s.SvcID 
            JOIN Laundry_Shops ls ON o.ShopID = ls.ShopID
            LEFT JOIN Invoices i ON o.OrderID = i.OrderID
            LEFT JOIN Delivery_Payments dp ON o.OrderID = dp.OrderID
            LEFT JOIN Customer_Ratings cr ON o.OrderID = cr.OrderID
            WHERE o.CustID = ? 
            ORDER BY o.OrderCreatedAt DESC;
        `;
        const [rows] = await db.query(query, [customerId]);

        const formattedRows = rows.map(row => ({
            ...row,
            isRated: row.isRated === 1
        }));

        res.json(formattedRows)
    } catch (error) {
        console.error("[ERROR] Error fetching customer orders:", error);
        res.status(500).json({ error: "Failed to fetch customer orders" });
    }
});

router.post("/rate", async (req, res) => {
    const { orderId, rating, comment } = req.body;

    if (!orderId || !rating) {
        return res.status(400).json({ message: "Order ID and Rating are required." });
    }

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Check if already rated
        const [existing] = await connection.query("SELECT CustRateID FROM Customer_Ratings WHERE OrderID = ?", [orderId]);
        if (existing.length > 0) {
            await connection.rollback();
            return res.status(409).json({ message: "Order already rated." });
        }

        // 2. Insert Customer Rating
        await connection.query(
            "INSERT INTO Customer_Ratings (OrderID, CustRating, CustComment) VALUES (?, ?, ?)",
            [orderId, rating, comment || null]
        );

        // 3. Get ShopID associated with this Order
        const [orderInfo] = await connection.query("SELECT ShopID FROM Orders WHERE OrderID = ?", [orderId]);
        
        if (orderInfo.length > 0) {
            const shopId = orderInfo[0].ShopID;

            // 4. Calculate New Average Rating for the Shop
            const [avgResult] = await connection.query(`
                SELECT AVG(cr.CustRating) as newAverage
                FROM Customer_Ratings cr
                JOIN Orders o ON cr.OrderID = o.OrderID
                WHERE o.ShopID = ?
            `, [shopId]);

            const newAverage = parseFloat(avgResult[0].newAverage || rating).toFixed(1);

            // 5. Update or Insert into Shop_Rates (Current Display Rating)
            const [rateRow] = await connection.query("SELECT ShopRevID FROM Shop_Rates WHERE ShopID = ?", [shopId]);
            
            let shopRevId;

            if (rateRow.length > 0) {
                // Update existing entry
                shopRevId = rateRow[0].ShopRevID;
                await connection.query(
                    "UPDATE Shop_Rates SET ShopRating = ? WHERE ShopRevID = ?", 
                    [newAverage, shopRevId]
                );
            } else {
                // Create new entry if first rating
                const [insertRes] = await connection.query(
                    "INSERT INTO Shop_Rates (ShopID, ShopRating) VALUES (?, ?)", 
                    [shopId, newAverage]
                );
                shopRevId = insertRes.insertId;
            }

            // 6. Insert into Shop_Rate_Stats (Historical Log)
            await connection.query(
                "INSERT INTO Shop_Rate_Stats (ShopRevID, InitialRating, UpdatedAt) VALUES (?, ?, NOW())",
                [shopRevId, newAverage]
            );
        }

        await connection.commit();
        res.json({ success: true, message: "Rating submitted and shop updated." });

    } catch (error) {
        await connection.rollback();
        console.error("Rating Error:", error);
        res.status(500).json({ message: "Failed to submit rating." });
    } finally {
        connection.release();
    }
});

// Raw Statuses Route (Unchanged Logic, just DB access)
router.get("/:orderId/raw-statuses", async (req, res) => {
    const { orderId } = req.params;
    const connection = await db.getConnection();
    try {
        const [orderStatuses] = await connection.query(
            `SELECT OrderStatus as status, OrderUpdatedAt as time FROM Order_Status WHERE OrderID = ? ORDER BY OrderUpdatedAt ASC`,
            [orderId]
        );
        const [deliveryStatuses] = await connection.query(
            `SELECT DlvryStatus as status, UpdatedAt as time FROM Delivery_Status WHERE OrderID = ? ORDER BY UpdatedAt ASC`,
            [orderId]
        );
        const [processStatuses] = await connection.query(
            `SELECT OrderProcStatus as status, OrderProcUpdatedAt as time FROM Order_Processing WHERE OrderID = ? ORDER BY OrderProcUpdatedAt ASC`,
            [orderId]
        );

        const mapStatuses = (rows) => {
            const statusMap = {};
            rows.forEach(row => { statusMap[row.status] = { time: row.time }; });
            return statusMap;
        };

        res.json({
            orderStatus: mapStatuses(orderStatuses),
            deliveryStatus: mapStatuses(deliveryStatuses),
            orderProcessing: mapStatuses(processStatuses)
        });
    } catch (error) {
        console.error("Error fetching raw statuses:", error);
        res.status(500).json({ error: "Failed to fetch raw tracking data" });
    } finally {
        connection.release();
    }
});

router.get("/:orderId/process-history", async (req, res) => {
    const { orderId } = req.params;
    try {
        const [processSteps] = await db.query(
            `SELECT OrderProcStatus AS status, OrderProcUpdatedAt AS time FROM Order_Processing WHERE OrderID = ? ORDER BY OrderProcUpdatedAt ASC`,
            [orderId]
        );
        const [coreStatuses] = await db.query(
            `SELECT OrderStatus AS status, OrderUpdatedAt AS time FROM Order_Status WHERE OrderID = ? ORDER BY OrderUpdatedAt ASC`,
            [orderId]
        );
        
        const combinedMap = new Map();
        coreStatuses.forEach(row => combinedMap.set(row.status, row));
        processSteps.forEach(row => combinedMap.set(row.status, row));
        const combinedTimeline = Array.from(combinedMap.values()).sort((a, b) => new Date(a.time) - new Date(b.time));

        res.json(combinedTimeline);
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch tracking history." });
    }
});

router.get("/shop/:shopId", async (req, res) => {
    const { shopId } = req.params;
    try {
        const [rows] = await db.query(
            `
            WITH LatestOrderStatus AS (
                SELECT OrderID, OrderStatus, OrderUpdatedAt, ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY OrderUpdatedAt DESC) as rn
                FROM Order_Status
            ),
            LatestDeliveryStatus AS (
                SELECT OrderID, DlvryStatus, UpdatedAt, ROW_NUMBER() OVER (PARTITION BY OrderID ORDER BY UpdatedAt DESC) as drn
                FROM Delivery_Status
            )
            SELECT 
                o.OrderID AS orderId,
                o.CustID AS customerId,
                o.ShopID AS shopId,
                ld.SvcID AS serviceId,
                ld.LndryDtlID AS laundryDetailId,
                ld.DlvryTypeID AS deliveryOptionId,
                o.OrderCreatedAt AS createdAt,
                los.OrderStatus AS laundryStatus,
                los.OrderUpdatedAt AS updatedAt,
                c.CustName AS customerName,
                s.SvcName AS serviceName,
                i.PaymentStatus as invoiceStatus,
                i.PayAmount as totalAmount, 
                i.ProofImage AS invoiceProofImage,
                pm_inv.MethodName AS invoicePaymentMethod,
                (SELECT op.OrderProcStatus FROM Order_Processing op WHERE op.OrderID = o.OrderID ORDER BY op.OrderProcUpdatedAt DESC LIMIT 1) AS latestProcessStatus,
                lds.DlvryStatus AS deliveryStatus,            
                dp.DlvryPaymentStatus AS deliveryPaymentStatus,
                dp.DlvryAmount AS deliveryAmount,
                dp.PaymentProofImage AS deliveryPaymentProofImage,
                pm.MethodName AS deliveryPaymentMethod,
                dp.StatusUpdatedAt AS deliveryPaymentDate,
                (SELECT ImageUrl FROM Delivery_Booking_Proofs WHERE OrderID = o.OrderID ORDER BY UploadedAt DESC LIMIT 1) AS deliveryProofImage
            FROM Orders o
            JOIN Laundry_Details ld ON o.OrderID = ld.OrderID
            JOIN Customers c ON o.CustID = c.CustID
            JOIN Services s ON ld.SvcID = s.SvcID
            LEFT JOIN LatestOrderStatus los ON o.OrderID = los.OrderID AND los.rn = 1
            LEFT JOIN LatestDeliveryStatus lds ON o.OrderID = lds.OrderID AND lds.drn = 1
            LEFT JOIN Delivery_Payments dp ON o.OrderID = dp.OrderID
            LEFT JOIN Payment_Methods pm ON dp.MethodID = pm.MethodID
            LEFT JOIN Invoices i ON o.OrderID = i.OrderID
            LEFT JOIN Payment_Methods pm_inv ON i.MethodID = pm_inv.MethodID
            WHERE o.ShopID = ? 
            ORDER BY o.OrderCreatedAt DESC;
            `,
            [shopId]
        );
        res.json(rows);
    } catch (error) {
        console.error("Error fetching shop orders:", error);
        res.status(500).json({ error: "Failed to fetch shop orders" });
    }
});


router.get("/:orderId", async (req, res) => {
    const { orderId } = req.params;
    const connection = await db.getConnection();
    try {
        const orderQuery = `
            SELECT 
                o.OrderID AS orderId,
                o.OrderCreatedAt AS createdAt,
                c.CustName AS customerName,
                c.CustPhone AS customerPhone,
                c.CustAddress AS customerAddress,
                ls.shopID AS shopId,
                ls.ShopName AS shopName,
                ls.ShopAddress AS shopAddress,
                ls.ShopPhone AS shopPhone,
                i.InvoiceID AS invoiceId,
                i.ProofImage AS invoiceProofImage,
                ld.SvcID AS serviceId,
                s.SvcName AS serviceName,
                CAST(ss.SvcPrice AS DECIMAL(10, 2)) AS servicePrice, 
                CAST(ld.Kilogram AS DECIMAL(5, 1)) AS weight, 
                ld.SpecialInstr AS instructions,
                ld.WeightProofImage AS weightProofImage,
                dt.DlvryTypeName AS deliveryType, 
                CAST(dp.DlvryAmount AS DECIMAL(10, 2)) AS deliveryFee, 
                CAST(i.PayAmount AS DECIMAL(10, 2)) AS totalAmount,
                PM.MethodName AS paymentMethodName, 
                (SELECT os.OrderStatus FROM Order_Status os WHERE os.OrderID = o.OrderID ORDER BY os.OrderUpdatedAt DESC LIMIT 1) AS orderStatus,
                i.PaymentStatus as invoiceStatus,
                (SELECT DlvryStatus FROM Delivery_Status WHERE OrderID = o.OrderID ORDER BY UpdatedAt DESC LIMIT 1) AS deliveryStatus,
                dp.DlvryPaymentStatus AS deliveryPaymentStatus,

                -- 🟢 NEW: Check if Shop has Active In-House Service
                CASE WHEN sos.ShopServiceStatus = 'Active' THEN 1 ELSE 0 END AS isShopOwnService,

                -- 🟢 NEW: Fetch Linked Partner App Name (if any)
                (SELECT GROUP_CONCAT(da.DlvryAppName SEPARATOR ' / ') 
                 FROM Shop_Delivery_App sda 
                 JOIN Delivery_App da ON sda.DlvryAppID = da.DlvryAppID 
                 WHERE sda.ShopID = o.ShopID
                ) AS partnerAppName

            FROM Orders o
            JOIN Laundry_Details ld ON o.OrderID = ld.OrderID
            LEFT JOIN Customers c ON o.CustID = c.CustID
            LEFT JOIN Laundry_Shops ls ON o.ShopID = ls.ShopID
            LEFT JOIN Services s ON ld.SvcID = s.SvcID
            LEFT JOIN Shop_Services ss ON o.ShopID = ss.ShopID AND ld.SvcID = ss.SvcID
            LEFT JOIN Delivery_Types dt ON ld.DlvryTypeID = dt.DlvryTypeID 
            LEFT JOIN Invoices i ON o.OrderID = i.OrderID 
            LEFT JOIN Payment_Methods PM ON i.MethodID = PM.MethodID
            LEFT JOIN Delivery_Payments dp ON o.OrderID = dp.OrderID
            
            -- 🟢 NEW JOIN to check logistics settings
            LEFT JOIN Shop_Own_Service sos ON o.ShopID = sos.ShopID

            WHERE o.OrderID = ?;
        `;
        const [[orderDetails]] = await connection.query(orderQuery, [orderId]);

        if (!orderDetails) {
            return res.status(404).json({ error: "Order not found" });
        }
        
        const [fabrics] = await connection.query(
            `SELECT f.FabName AS FabricType FROM Order_Fabrics ofb 
             JOIN Fabrics f ON ofb.FabID = f.FabID
             JOIN Laundry_Details ld ON ofb.LndryDtlID = ld.LndryDtlID
             WHERE ld.OrderID = ?`,
            [orderId]
        );

        const [addons] = await connection.query(
            `SELECT a.AddOnName, CAST(SAO.AddOnPrice AS DECIMAL(10, 2)) AS AddOnPrice 
             FROM Order_AddOns oao 
             JOIN Add_Ons a ON oao.AddOnID = a.AddOnID
             JOIN Laundry_Details ld ON oao.LndryDtlID = ld.LndryDtlID
             JOIN Orders o ON ld.OrderID = o.OrderID
             JOIN Shop_Add_Ons SAO ON o.ShopID = SAO.ShopID AND a.AddOnID = SAO.AddOnID
             WHERE ld.OrderID = ?`,
            [orderId]
        );

        res.json({
            ...orderDetails,
            deliveryProvider: orderDetails.isShopOwnService === 1 ? "In-House Delivery" : (orderDetails.partnerAppName || "Partner Courier"),
            isOwnService: orderDetails.isShopOwnService === 1, 
            fabrics: fabrics.map(f => f.FabricType),
            addons: addons.map(a => ({ name: a.AddOnName, price: a.AddOnPrice }))
        });
    } catch (error) {
        console.error("Error fetching details:", error);
        res.status(500).json({ error: "Failed to fetch order details" });
    } finally {
        connection.release();
    }
});


// =================================================================
// API Routes: Actions (Status, Weight, Payment)
// 🟢🟢🟢 WITH RACE CONDITION HANDLERS 🟢🟢🟢
// =================================================================

router.post("/cancel", async (req, res) => {
    const { orderId, userId, userRole } = req.body;
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        
        // 🟢 TRY/CATCH for Duplicate Status
        try {
            await connection.query(
                "INSERT INTO Order_Status (OrderID, OrderStatus, OrderUpdatedAt) VALUES (?, 'Cancelled', NOW())",
                [orderId]
            );
        } catch (e) {
            if (e.code === 'ER_DUP_ENTRY') {
                await connection.rollback();
                return res.status(200).json({ success: true, message: "Order already cancelled." });
            }
            throw e;
        }

        await connection.query(
            "UPDATE Invoices SET PaymentStatus = 'Cancelled', StatusUpdatedAt = NOW() WHERE OrderID = ?",
            [orderId]
        );

        await connection.query(
            "UPDATE Delivery_Payments SET DlvryPaymentStatus = 'Voided', StatusUpdatedAt = NOW() WHERE OrderID = ?",
            [orderId]
        );
        
        await logUserActivity(userId, userRole, 'Cancel Order', `Order ${orderId} cancelled.`);
        await connection.commit();
        res.status(200).json({ success: true, message: "Order cancelled and voided." });

    } catch (error) {
        await connection.rollback();
        res.status(500).json({ success: false, message: "Failed to cancel order." });
    } finally {
        connection.release();
    }
});

router.post("/status", async (req, res) => {
    const { orderId, newStatus, userId, userRole } = req.body;
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();
        
        // 🟢 CHECK: Are we already at this status? (Redundant but safe)
        const [current] = await connection.query("SELECT OrderStatus FROM Order_Status WHERE OrderID=? ORDER BY OrderUpdatedAt DESC LIMIT 1", [orderId]);
        if (current.length > 0 && current[0].OrderStatus === newStatus) {
             await connection.rollback();
             return res.status(200).json({ success: true, message: "Status already updated" });
        }

        // 🟢 TRY/CATCH: Insert new status
        try {
            await connection.query(
                "INSERT INTO Order_Status (OrderID, OrderStatus, OrderUpdatedAt) VALUES (?, ?, NOW())",
                [orderId, newStatus]
            );
        } catch (e) {
            if (e.code === 'ER_DUP_ENTRY') {
                 // This catches the exact moment of a double-click race condition
                 await connection.rollback();
                 return res.status(200).json({ success: true, message: "Status updated (duplicate ignored)" });
            }
            throw e;
        }
        
        await logUserActivity(userId, userRole, 'Update Order Status', `Order ${orderId} status: ${newStatus}`);
        await connection.commit();
        res.status(200).json({ success: true, message: `Status updated to ${newStatus}` });
    } catch (error) {
        await connection.rollback();
        res.status(500).json({ error: "Failed to update status" });
    } finally {
        connection.release();
    }
});

// Weight Update - Handles Invoice Creation/Update
router.post("/weight/update-proof", upload.single("weightProof"), async (req, res) => {
    const { orderId, weight, userId, userRole } = req.body;
    
    if (!orderId || weight === undefined || !req.file) {
        return res.status(400).json({ message: "Missing Order ID, Weight, or Proof Image" });
    }

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        const b64 = Buffer.from(req.file.buffer).toString("base64");
        const dataURI = "data:" + req.file.mimetype + ";base64," + b64;
        const uploadResult = await cloudinary.uploader.upload(dataURI, { folder: "laundrolink_weight_proofs" });

        await connection.query(
            `UPDATE Laundry_Details SET Kilogram = ?, WeightProofImage = ? WHERE OrderID = ?`,
            [weight, uploadResult.secure_url, orderId]
        );

        // Recalculate Total
        const [calcData] = await connection.query(`
            SELECT 
                ss.SvcPrice, 
                (SELECT DlvryAmount FROM Delivery_Payments WHERE OrderID = ? AND DlvryPaymentStatus IN ('Pending', 'Pending Later')) as DlvryFee,
                (SELECT COALESCE(SUM(sao.AddOnPrice),0) FROM Order_AddOns oao 
                 JOIN Laundry_Details ld ON oao.LndryDtlID = ld.LndryDtlID
                 JOIN Orders o ON ld.OrderID = o.OrderID
                 JOIN Shop_Add_Ons sao ON o.ShopID = sao.ShopID AND oao.AddOnID = sao.AddOnID
                 WHERE ld.OrderID = ?) as AddonTotal
            FROM Orders o
            JOIN Laundry_Details ld ON o.OrderID = ld.OrderID
            JOIN Shop_Services ss ON o.ShopID = ss.ShopID AND ld.SvcID = ss.SvcID
            WHERE o.OrderID = ?
        `, [orderId, orderId, orderId]);

        if (calcData.length > 0) {
            const { SvcPrice, AddonTotal, DlvryFee } = calcData[0];
            const numericWeight = parseFloat(weight);
            const safeDlvryFee = parseFloat(DlvryFee) || 0; 
            const newTotal = (parseFloat(SvcPrice) * numericWeight) + parseFloat(AddonTotal) + safeDlvryFee;
            
            // 🟢 RACE CONDITION HANDLER FOR INVOICE
            // Check if Invoice Exists
            const [existing] = await connection.query("SELECT InvoiceID FROM Invoices WHERE OrderID = ?", [orderId]);
            
            if (existing.length > 0) {
                 await connection.query(
                    "UPDATE Invoices SET PayAmount = ?, PaymentStatus = 'To Pay' WHERE OrderID = ?",
                    [newTotal, orderId]
                );
            } else {
                try {
                    const newInvoiceID = generateID('INV');
                    await connection.query(
                        "INSERT INTO Invoices (InvoiceID, OrderID, PayAmount, PaymentStatus, PmtCreatedAt) VALUES (?, ?, ?, 'To Pay', NOW())",
                        [newInvoiceID, orderId, newTotal]
                    );
                } catch (e) {
                    if (e.code === 'ER_DUP_ENTRY') {
                        // If parallel request created it first, just update
                        await connection.query(
                            "UPDATE Invoices SET PayAmount = ?, PaymentStatus = 'To Pay' WHERE OrderID = ?",
                            [newTotal, orderId]
                        );
                    } else {
                        throw e;
                    }
                }
            }
        }

        const [[orderInfo]] = await connection.query("SELECT CustID FROM Orders WHERE OrderID = ?", [orderId]);
        if (orderInfo) {
            const receiverId = orderInfo.CustID;
            
            const participant1 = userId < receiverId ? userId : receiverId;
            const participant2 = userId < receiverId ? receiverId : userId;
            
            let [[conversation]] = await connection.query(
                "SELECT ConversationID FROM Conversations WHERE Participant1_ID = ? AND Participant2_ID = ?",
                [participant1, participant2]
            );

            let conversationId;
            if (conversation) {
                conversationId = conversation.ConversationID;
            } else {
                const [convResult] = await connection.query(
                    "INSERT INTO Conversations (Participant1_ID, Participant2_ID, UpdatedAt) VALUES (?, ?, NOW())",
                    [participant1, participant2]
                );
                conversationId = convResult.insertId;
            }

            await connection.query(
                `INSERT INTO Messages (ConversationID, SenderID, ReceiverID, MessageText, MessageStatus, CreatedAt) 
                 VALUES (?, ?, ?, 'Weight has been updated, please proceed to payment.', 'Sent', NOW())`,
                [conversationId, userId, receiverId]
            );
        }

        await logUserActivity(userId, userRole, 'Update Weight', `Order ${orderId} weight updated to ${weight}kg.`);
        await connection.commit();
        res.json({ success: true, message: "Weight updated." });

    } catch (error) {
        await connection.rollback();
        console.error("Error updating weight:", error);
        res.status(500).json({ message: "Failed to update weight." });
    } finally {
        connection.release();
    }
});

// 1. SERVICE PAYMENT SUBMISSION (Invoices Table)
router.post("/customer/payment-submission", upload.single("proofImage"), async (req, res) => {
    const { orderId, methodId, amount } = req.body;
    let proofUrl = null;

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // 🟢 CONSTRAINT: Check if already submitted or paid
        const [existing] = await connection.query(
            "SELECT PaymentStatus FROM Invoices WHERE OrderID = ?", 
            [orderId]
        );

        if (existing.length > 0) {
            const status = existing[0].PaymentStatus;
            if (status === 'To Confirm' || status === 'Paid') {
                console.log(`Payment for ${orderId} already submitted/paid. Skipping update.`);
                await connection.rollback();
                return res.json({ success: true, message: "Payment already submitted." });
            }
        }

        // Handle Image Upload (Only if status check passes)
        if (req.file) {
            const b64 = Buffer.from(req.file.buffer).toString("base64");
            const dataURI = "data:" + req.file.mimetype + ";base64," + b64;
            const uploadResult = await cloudinary.uploader.upload(dataURI, { folder: "laundrolink_payment_proofs" });
            proofUrl = uploadResult.secure_url;
        }

        // Update Invoices Table
        await connection.query(
            `UPDATE Invoices 
             SET MethodID = ?, PayAmount = ?, PaymentStatus = 'To Confirm', StatusUpdatedAt = NOW(), ProofImage = ? 
             WHERE OrderID = ?`,
            [methodId, amount, proofUrl, orderId]
        );

        await connection.commit();
        res.json({ success: true, message: "Payment submitted." });

    } catch (error) {
        await connection.rollback();
        console.error("Payment Submission Error:", error);
        res.status(500).json({ error: "Failed to submit payment." });
    } finally {
        connection.release();
    }
});

// 2. DELIVERY PAYMENT SUBMISSION (Delivery_Payments Table)
router.post("/customer/delivery-payment-submission", upload.single("proofImage"), async (req, res) => {
    const { orderId, methodId, amount } = req.body;
    let proofUrl = null;

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // 🟢 CONSTRAINT: Check if already submitted or paid
        const [existing] = await connection.query(
            "SELECT DlvryPaymentStatus FROM Delivery_Payments WHERE OrderID = ?", 
            [orderId]
        );

        if (existing.length > 0) {
            const status = existing[0].DlvryPaymentStatus;
            if (status === 'To Confirm' || status === 'Paid') {
                console.log(`Delivery Payment for ${orderId} already submitted/paid. Skipping update.`);
                await connection.rollback();
                return res.json({ success: true, message: "Delivery payment already submitted." });
            }
        }

        // Handle Image Upload (Only if status check passes)
        if (req.file) {
            const b64 = Buffer.from(req.file.buffer).toString("base64");
            const dataURI = "data:" + req.file.mimetype + ";base64," + b64;
            const uploadResult = await cloudinary.uploader.upload(dataURI, { folder: "laundrolink_payment_proofs" });
            proofUrl = uploadResult.secure_url;
        }

        // Update Delivery_Payments Table
        await connection.query(
            `UPDATE Delivery_Payments 
             SET MethodID = ?, DlvryPaymentStatus = 'To Confirm', StatusUpdatedAt = NOW(), PaymentProofImage = ? 
             WHERE OrderID = ?`,
            [methodId, proofUrl, orderId]
        );

        await connection.commit();
        res.json({ success: true, message: "Delivery payment submitted." });

    } catch (error) {
        await connection.rollback();
        console.error("Delivery Payment Error:", error);
        res.status(500).json({ error: "Failed." });
    } finally {
        connection.release();
    }
});

// Staff Confirmations (Race Condition Handled)
router.post("/staff/confirm-service-payment", async (req, res) => {
    const { orderId, userId, userRole } = req.body;
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // 🟢 Check if already paid to prevent double-processing
        const [invoice] = await connection.query("SELECT PaymentStatus FROM Invoices WHERE OrderID = ?", [orderId]);
        if (invoice.length > 0 && invoice[0].PaymentStatus === 'Paid') {
             await connection.rollback();
             return res.status(200).json({ success: true, message: "Already confirmed." });
        }

        await connection.query(
            "UPDATE Invoices SET PaymentStatus = 'Paid', StatusUpdatedAt = NOW() WHERE OrderID = ?",
            [orderId]
        );

        try {
            await connection.query(
                "INSERT INTO Order_Status (OrderID, OrderStatus, OrderUpdatedAt) VALUES (?, 'Processing', NOW())",
                [orderId]
            );
        } catch (e) {
            if (e.code !== 'ER_DUP_ENTRY') throw e; 
        }

        await logUserActivity(userId, userRole, 'Confirm Payment', `Service payment confirmed ${orderId}`);
        await connection.commit();
        res.json({ success: true, message: "Service payment confirmed." });

    } catch (error) {
        await connection.rollback();
        res.status(500).json({ error: "Failed to confirm payment." });
    } finally {
        connection.release();
    }
});

router.post("/staff/confirm-delivery-payment", async (req, res) => {
    const { orderId, userId, userRole } = req.body;

    if (!orderId) return res.status(400).json({ error: "Missing Order ID" });

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // 1. Mark Delivery Payment as PAID
        await connection.query(
            "UPDATE Delivery_Payments SET DlvryPaymentStatus = 'Paid', StatusUpdatedAt = NOW() WHERE OrderID = ?",
            [orderId]
        );

        // 1. Mark Delivery Status as To Pick-up 
        await connection.query(
            "INSERT INTO Delivery_Status (OrderID, DlvryStatus, UpdatedAt) VALUES (?, 'To Pick-up', NOW())",
            [orderId]
        );

        await logUserActivity(userId, userRole, 'Confirm Delivery Pay', `Delivery payment confirmed for Order ${orderId}`);
        await connection.commit();
        res.json({ success: true, message: "Delivery payment confirmed." });

    } catch (error) {
        await connection.rollback();
        console.error("Staff confirm delivery payment error:", error);
        res.status(500).json({ error: "Failed to confirm delivery payment." });
    } finally {
        connection.release();
    }
});

// 1. Upload Booking Proof (Step 1 of 3rd Party App)
router.post("/delivery/upload-booking", upload.single("proofImage"), async (req, res) => {
    const { orderId, userId, userRole } = req.body;
    
    if (!orderId || !req.file) {
        return res.status(400).json({ message: "Missing Order ID or Proof Image" });
    }

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        // Image Upload
        const b64 = Buffer.from(req.file.buffer).toString("base64");
        const dataURI = "data:" + req.file.mimetype + ";base64," + b64;
        const uploadResult = await cloudinary.uploader.upload(dataURI, { folder: "laundrolink_delivery_proofs" });

        // Default to Pick-up status
        let newStatus = 'Rider Booked To Pick-up';

        // Check current status in DB
        const [rows] = await connection.query(
            "SELECT DlvryStatus FROM Delivery_Status WHERE OrderID = ? ORDER BY UpdatedAt DESC LIMIT 1", 
            [orderId]
        );

        if (rows.length > 0) {
            const currentStatus = rows[0].DlvryStatus;
            
            // If the laundry is already processed and marked 'For Delivery', this booking must be for the return trip
            if (currentStatus === 'For Delivery') {
                newStatus = 'Rider Booked For Delivery';
            }
        }

        console.log(`Setting Delivery Status to: ${newStatus}`);

        // Insert new specific status
        await connection.query(
            "INSERT INTO Delivery_Status (OrderID, DlvryStatus, UpdatedAt) VALUES (?, ?, NOW())",
            [orderId, newStatus]
        );
        
        await connection.query(
            `INSERT INTO Delivery_Booking_Proofs (OrderID, ImageUrl, UploadedAt) VALUES (?, ?, NOW())`,
            [orderId, uploadResult.secure_url]
        );

        await logUserActivity(userId, userRole, 'Delivery Booking', `Proof uploaded for Order ${orderId}. Status: ${newStatus}`);

        await connection.commit();
        res.json({ success: true, status: newStatus });

    } catch (error) {
        await connection.rollback();
        console.error("Error uploading booking proof:", error);
        res.status(500).json({ message: "Failed to upload proof." });
    } finally {
        connection.release();
    }
});


// Delivery Status Updates (Logistics)
router.post("/delivery/update-status", async (req, res) => {
    const { orderId, newDlvryStatus, newOrderStatus, userId, userRole } = req.body;
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        if (newDlvryStatus) {
            try {
                await connection.query(
                    "INSERT INTO Delivery_Status (OrderID, DlvryStatus, UpdatedAt) VALUES (?, ?, NOW())",
                    [orderId, newDlvryStatus]
                );
            } catch(e) { if(e.code !== 'ER_DUP_ENTRY') throw e; }
        }

        if (newOrderStatus) {
            try {
                await connection.query(
                    "INSERT INTO Order_Status (OrderID, OrderStatus, OrderUpdatedAt) VALUES (?, ?, NOW())",
                    [orderId, newOrderStatus]
                );
            } catch(e) { if(e.code !== 'ER_DUP_ENTRY') throw e; }
        }

        await logUserActivity(userId, userRole, 'Update Delivery Status', `${orderId}: ${newDlvryStatus}`);
        await connection.commit();
        res.json({ success: true });
    } catch (error) {
        await connection.rollback();
        res.status(500).json({ message: "Failed to update status." });
    } finally {
        connection.release();
    }
});

router.post("/processing-status", async (req, res) => {
    const { orderId, status, userId, userRole } = req.body;
    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        try {
            await connection.query(
                "INSERT INTO Order_Processing (OrderID, OrderProcStatus, OrderProcUpdatedAt) VALUES (?, ?, NOW())",
                [orderId, status]
            );
        } catch(e) { 
            if(e.code === 'ER_DUP_ENTRY') {
                await connection.rollback();
                return res.status(200).json({ success: true, message: "Status already recorded" });
            }
            throw e; 
        }

        if (status === "Out for Delivery" || status === "Ready for Pickup") {
             const mapStatus = status === "Out for Delivery" ? "For Delivery" : "Ready for Pickup";
             try {
                 await connection.query(
                    "INSERT INTO Order_Status (OrderID, OrderStatus, OrderUpdatedAt) VALUES (?, ?, NOW())",
                    [orderId, mapStatus]
                );
             } catch(e) { if(e.code !== 'ER_DUP_ENTRY') throw e; }
        }

        await logUserActivity(userId, userRole, 'Update Processing', `Order ${orderId}: ${status}`);
        await connection.commit();
        res.status(201).json({ success: true });
    } catch (error) {
        await connection.rollback();
        res.status(500).json({ error: "Failed to add status" });
    } finally {
        connection.release();
    }
});

router.get("/overview/:shopId", async (req, res) => {
    const { shopId } = req.params;
    const { period, sortBy = 'OrderCreatedAt', sortOrder = 'DESC' } = req.query;
    const dateCondition = getDateCondition(period, 'o');

    try {
        const ordersQuery = `
            SELECT 
                o.OrderID, o.CustID, s.SvcName, i.PayAmount, o.OrderCreatedAt,
                (SELECT os.OrderStatus FROM Order_Status os WHERE os.OrderID = o.OrderID ORDER BY os.OrderUpdatedAt DESC LIMIT 1) AS OrderStatus
            FROM Orders o
            JOIN Laundry_Details ld ON o.OrderID = ld.OrderID
            JOIN Services s ON ld.SvcID = s.SvcID
            LEFT JOIN Invoices i ON o.OrderID = i.OrderID
            WHERE o.ShopID = ? AND ${dateCondition}
            ORDER BY ${sortBy} ${sortOrder}
        `;
        const [orders] = await db.query(ordersQuery, [shopId]);

        // (Summary query logic remains the same as your previous code)
        const summaryQuery = `
            SELECT
                SUM(CASE WHEN (SELECT os.OrderStatus FROM Order_Status os WHERE os.OrderID = o.OrderID ORDER BY os.OrderUpdatedAt DESC LIMIT 1) = 'Pending' THEN 1 ELSE 0 END) AS pending,
                SUM(CASE WHEN (SELECT os.OrderStatus FROM Order_Status os WHERE os.OrderID = o.OrderID ORDER BY os.OrderUpdatedAt DESC LIMIT 1) = 'Processing' THEN 1 ELSE 0 END) AS processing,
                SUM(CASE WHEN (SELECT os.OrderStatus FROM Order_Status os WHERE os.OrderID = o.OrderID ORDER BY os.OrderUpdatedAt DESC LIMIT 1) = 'For Delivery' THEN 1 ELSE 0 END) AS forDelivery,
                SUM(CASE WHEN (SELECT os.OrderStatus FROM Order_Status os WHERE os.OrderID = o.OrderID ORDER BY os.OrderUpdatedAt DESC LIMIT 1) = 'Completed' THEN 1 ELSE 0 END) AS completed
            FROM Orders o
            WHERE o.ShopID = ? AND ${dateCondition}
        `;
        const [summaryResults] = await db.query(summaryQuery, [shopId]);

        res.json({ summary: summaryResults[0] || {}, orders });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Failed to fetch overview" });
    }
});


router.post("/dashboard-summary", async (req, res) => {
    const { shopId, period = 'Weekly' } = req.body;
    if (!shopId) return res.status(400).json({ error: "Shop ID required" });

    const orderDateCondition = getDateCondition(period, 'o');
    const chartDateFormat = period === 'Yearly' ? `'%Y'` : (period === 'Monthly' ? `'%b'` : `'%a'`);
    const chartGroupBy = period === 'Yearly' ? `YEAR(o.OrderCreatedAt)` : (period === 'Monthly' ? `DATE_FORMAT(o.OrderCreatedAt, '%Y-%m')` : `DAYOFWEEK(o.OrderCreatedAt)`);

    try {
        await db.query("SET SESSION group_concat_max_len = 1000000;");
        
        const query = `
            SELECT
                -- 1. Counts
                (SELECT COUNT(*) FROM Orders o WHERE o.ShopID = ? AND ${orderDateCondition}) AS totalOrders,
                
                (SELECT COUNT(*) FROM Orders o 
                 JOIN Order_Status os ON o.OrderID = os.OrderID 
                 WHERE o.ShopID = ? AND ${orderDateCondition} 
                 AND os.OrderStatus = 'Completed'
                 AND os.OrderUpdatedAt = (SELECT MAX(OrderUpdatedAt) FROM Order_Status WHERE OrderID = o.OrderID)
                ) AS completedOrders,

                (SELECT COUNT(*) FROM Orders o 
                 JOIN Order_Status os ON o.OrderID = os.OrderID 
                 WHERE o.ShopID = ? AND ${orderDateCondition} 
                 AND os.OrderStatus IN ('Pending', 'Processing', 'For Delivery', 'Ready for Pickup', 'To Weigh')
                 AND os.OrderUpdatedAt = (SELECT MAX(OrderUpdatedAt) FROM Order_Status WHERE OrderID = o.OrderID)
                ) AS pendingOrders,

                -- 2. Revenue
                (SELECT COALESCE(SUM(i.PayAmount), 0) 
                 FROM Orders o 
                 JOIN Invoices i ON o.OrderID = i.OrderID 
                 WHERE o.ShopID = ? AND ${orderDateCondition} AND i.PaymentStatus = 'Paid'
                ) AS totalRevenue,

                -- 3. Chart Data
                (SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('label', label, 'value', revenue) ORDER BY sortKey), ']') 
                 FROM (
                    SELECT ${chartGroupBy} AS sortKey, DATE_FORMAT(o.OrderCreatedAt, ${chartDateFormat}) AS label, SUM(i.PayAmount) AS revenue
                    FROM Orders o JOIN Invoices i ON o.OrderID = i.OrderID
                    WHERE o.ShopID = ? AND ${orderDateCondition} AND i.PaymentStatus = 'Paid'
                    GROUP BY sortKey, label
                 ) AS ChartData
                ) AS chartData,

                -- 4. Recent Orders (JSON Array)
                (SELECT CONCAT('[', GROUP_CONCAT(
                    JSON_OBJECT(
                        'id', o.OrderID, 
                        'customer', c.CustName, 
                        'status', (SELECT os.OrderStatus FROM Order_Status os WHERE os.OrderID = o.OrderID ORDER BY os.OrderUpdatedAt DESC LIMIT 1), 
                        'amount', i.PayAmount,
                        'invoiceStatus', i.PaymentStatus
                    ) ORDER BY o.OrderCreatedAt DESC
                 ), ']')
                 FROM (
                    SELECT o.OrderID, o.OrderCreatedAt, o.CustID 
                    FROM Orders o 
                    WHERE o.ShopID = ? 
                    ORDER BY o.OrderCreatedAt DESC LIMIT 5
                 ) o
                 JOIN Customers c ON o.CustID = c.CustID
                 LEFT JOIN Invoices i ON o.OrderID = i.OrderID
                ) AS recentOrders
        `;

        // We pass ShopID multiple times for each subquery
        const params = [shopId, shopId, shopId, shopId, shopId, shopId];
        const [[results]] = await db.query(query, params);

        res.json({
            totalOrders: results.totalOrders || 0,
            completedOrders: results.completedOrders || 0,
            pendingOrders: results.pendingOrders || 0,
            totalRevenue: results.totalRevenue || 0,
            chartData: results.chartData ? JSON.parse(results.chartData) : [],
            recentOrders: results.recentOrders ? JSON.parse(results.recentOrders) : []
        });

    } catch (error) {
        console.error("Dashboard Summary Error:", error);
        res.status(500).json({ error: "Failed to fetch summary" });
    }
});

router.post("/report/order-types", async (req, res) => {
    const { shopId, period } = req.body; 
    const dateCondition = getDateCondition(period, 'o');
    try {
        // Join Laundry_Details to get SvcID
        const query = `
            SELECT s.SvcName AS label, COUNT(o.OrderID) AS count
            FROM Orders o
            JOIN Laundry_Details ld ON o.OrderID = ld.OrderID
            JOIN Services s ON ld.SvcID = s.SvcID
            WHERE o.ShopID = ? AND ${dateCondition}
            GROUP BY s.SvcName
            ORDER BY count DESC;
        `;
        const [rows] = await db.query(query, [shopId]);
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: "Failed" });
    }
});


router.get("/sales/:shopId", async (req, res) => {
    const { shopId } = req.params;
    const { period = 'Weekly', limit, offset } = req.query;
    
    // Helper for date condition (reused from your file)
    const dateCondition = getDateCondition(period, 'T'); // Use generic alias 'T' for the union
    
    const parsedLimit = parseInt(limit, 10) || 15;
    const parsedOffset = parseInt(offset, 10) || 0;

    try {
        
        const getDynamicDate = (p) => {
            switch (p) {
                case "Today": return `DATE(T.PaidAt) = CURDATE()`;
                case "Weekly": default: return `YEARWEEK(T.PaidAt, 1) = YEARWEEK(CURDATE(), 1)`;
                case "Monthly": return `YEAR(T.PaidAt) = YEAR(CURDATE()) AND MONTH(T.PaidAt) = MONTH(CURDATE())`;
                case "Yearly": return `YEAR(T.PaidAt) = YEAR(CURDATE())`;
            }
        };
        const whereClause = getDynamicDate(period);

        const baseUnion = `
            SELECT o.OrderID, i.PayAmount AS PayAmount, i.StatusUpdatedAt AS PaidAt, 'Service' as Type
            FROM Orders o JOIN Invoices i ON o.OrderID = i.OrderID
            WHERE o.ShopID = ? AND i.PaymentStatus = 'Paid'
            
            UNION ALL
            
            SELECT o.OrderID, dp.DlvryAmount AS PayAmount, dp.StatusUpdatedAt AS PaidAt, 'Delivery' as Type
            FROM Orders o JOIN Delivery_Payments dp ON o.OrderID = dp.OrderID
            WHERE o.ShopID = ? AND dp.DlvryPaymentStatus = 'Paid'
        `;

        // 1. Fetch Paginated Transactions
        const transactionsQuery = `
            SELECT * FROM (${baseUnion}) AS T
            WHERE ${whereClause}
            ORDER BY T.PaidAt DESC
            LIMIT ? OFFSET ?
        `;

        // 2. Fetch Totals (Count & Sum)
        const countQuery = `
            SELECT COUNT(*) AS totalCount, SUM(T.PayAmount) AS totalSales
            FROM (${baseUnion}) AS T
            WHERE ${whereClause}
        `;

        const [transactions] = await db.query(transactionsQuery, [shopId, shopId, parsedLimit, parsedOffset]);
        const [countRows] = await db.query(countQuery, [shopId, shopId]);

        res.json({
            summary: { 
                totalSales: countRows[0].totalSales || 0,
                totalOrders: countRows[0].totalCount || 0 // Sending explicit count for Avg Calc
            },
            transactions: transactions,
            totalCount: countRows[0].totalCount || 0
        });

    } catch (error) {
        console.error("Sales Fetch Error:", error);
        res.status(500).json({ error: "Failed to fetch sales" });
    }
});

router.post("/summary", async (req, res) => {
  const { shopId, dateRange } = req.body;

  if (!shopId || !dateRange) {
    return res.status(400).json({ error: "Shop ID and date range are required" });
  }

  // Local helper for this specific route's date logic
  const getSummaryDateCondition = (alias) => {
    switch (dateRange) {
      case "Today":
        return `DATE(${alias}.OrderCreatedAt) = CURDATE()`;
      case "This Month":
        return `YEAR(${alias}.OrderCreatedAt) = YEAR(CURDATE()) AND MONTH(${alias}.OrderCreatedAt) = MONTH(CURDATE())`;
      case "This Week":
      default:
        return `YEARWEEK(${alias}.OrderCreatedAt, 1) = YEARWEEK(CURDATE(), 1)`;
    }
  };

  try {
    await db.query("SET SESSION group_concat_max_len = 1000000;");

    const query = `
      WITH FilteredOrders AS (
        SELECT 
          o.OrderID,
          o.CustID,
          o.OrderCreatedAt,
          (SELECT os.OrderStatus FROM Order_Status os WHERE os.OrderID = o.OrderID ORDER BY os.OrderUpdatedAt DESC LIMIT 1) as status,
          i.PayAmount,
          i.PaymentStatus as InvoiceStatus
        FROM Orders o
        LEFT JOIN Invoices i ON o.OrderID = i.OrderID
        WHERE o.ShopID = ? AND ${getSummaryDateCondition("o")}
      ),
      ChartData AS (
        SELECT
          DATE_FORMAT(OrderCreatedAt, '%a') AS label,
          SUM(PayAmount) AS revenue
        FROM FilteredOrders
        WHERE InvoiceStatus = 'Paid'
        GROUP BY label
        ORDER BY FIELD(label, 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')
      ),
      RecentOrders AS (
        SELECT
          OrderID AS id,
          (SELECT CustName FROM Customers WHERE CustID = FilteredOrders.CustID) AS customer,
          status,
          PayAmount AS amount,
          InvoiceStatus
        FROM FilteredOrders
        ORDER BY OrderCreatedAt DESC
        LIMIT 10
      )
      SELECT
        (SELECT COUNT(*) FROM FilteredOrders) AS totalOrders,
        (SELECT COUNT(*) FROM FilteredOrders WHERE status = 'Completed') AS completedOrders,
        (SELECT COUNT(*) FROM FilteredOrders WHERE status NOT IN ('Completed', 'Rejected', 'Cancelled')) AS pendingOrders,
        (SELECT SUM(CASE WHEN InvoiceStatus = 'Paid' THEN PayAmount ELSE 0 END) FROM FilteredOrders) AS totalRevenue,
        (SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('label', label, 'revenue', revenue)), ']') FROM ChartData) AS chartData,
        (SELECT CONCAT('[', GROUP_CONCAT(JSON_OBJECT('id', id, 'customer', customer, 'status', status, 'amount', amount, 'invoiceStatus', InvoiceStatus)), ']') FROM RecentOrders) AS recentOrders;
    `;

    const [[results]] = await db.query(query, [shopId]);
    
    results.chartData = results.chartData ? JSON.parse(results.chartData) : [];
    results.recentOrders = results.recentOrders ? JSON.parse(results.recentOrders) : [];

    res.json(results);
  } catch (error) {
    console.error("Error fetching order summary:", error);
    res.status(500).json({ error: "Failed to fetch summary" });
  }
});

export default router;
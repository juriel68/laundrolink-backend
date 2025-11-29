import express from "express";
import db from "../db.js";
// 🔑 REQUIRED IMPORTS for file handling
import multer from 'multer'; 
import { cloudinary } from "../config/externalServices.js"; 

const router = express.Router();

// 🔑 SETUP MULTER: Define storage and the 'upload' middleware instance
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });


// =================================================================
// 1. PUBLIC & APP LISTING ROUTES
// =================================================================

// GET /api/shops/ (Public listing)
router.get("/", async (req, res) => {
    const connection = await db.getConnection();
    try {
        const [shops] = await connection.query(`
            SELECT
                LS.ShopID as id, LS.OwnerID, LS.ShopName as name, LS.ShopAddress as address, 
                LS.ShopDescrp as description, LS.ShopImage_url as image_url, 
                LS.ShopPhone as contact, LS.ShopOpeningHours as hours, 
                LS.ShopStatus as availability,
                SR.ShopRating AS rating,
                NULL AS distance
            FROM Laundry_Shops AS LS
            LEFT JOIN Shop_Rates AS SR ON LS.ShopID = SR.ShopID
            GROUP BY LS.ShopID
            ORDER BY LS.ShopName;
        `);
        res.json({ shops });
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch shop list." });
    } finally {
        connection.release();
    }
});

// GET /api/shops/nearby (Mobile App Listing)
router.get("/nearby", async (req, res) => {
    const connection = await db.getConnection();
    try {
        const { lat, lon } = req.query;
        if (!lat || !lon) {
            return res.status(400).json({ success: false, message: "Latitude and longitude are required." });
        }
        
        const latitude = parseFloat(lat);
        const longitude = parseFloat(lon);
        const maxDistanceKm = 300; // Testing radius

        const query = `
            SELECT 
                LS.ShopID as id, 
                LS.ShopName as name, 
                LS.ShopAddress as address, 
                LS.ShopDescrp as description, 
                LS.ShopImage_url as image_url, 
                LS.ShopPhone as contact, 
                LS.ShopOpeningHours as hours, 
                LS.ShopStatus as availability,
                COALESCE(SR.ShopRating, 0.0) AS rating,
                SD.ShopLatitude, 
                SD.ShopLongitude,
                ( 6371 * acos( cos( radians(?) ) * cos( radians( SD.ShopLatitude ) ) * cos( radians( SD.ShopLongitude ) - radians(?) ) + sin( radians(?) ) * sin( radians( SD.ShopLatitude ) ) ) ) AS distance
            FROM 
                Laundry_Shops AS LS
            INNER JOIN
                Shop_Distance AS SD ON LS.ShopID = SD.ShopID
            LEFT JOIN
                Shop_Rates AS SR ON LS.ShopID = SR.ShopID 
            WHERE
                SD.ShopLatitude IS NOT NULL AND SD.ShopLongitude IS NOT NULL
            GROUP BY
                LS.ShopID
            HAVING distance < ?
            ORDER BY distance
            LIMIT 20;
        `;
        const [shops] = await connection.query(query, [latitude, longitude, latitude, maxDistanceKm]);
        
        res.json({ success: true, shops });
    } catch (error) {
        res.status(500).json({ success: false, message: "Failed to fetch nearby shops." });
    } finally {
        connection.release();
    }
});


// GET /api/shops/:shopId/full-details (Customer App)
router.get("/:shopId/full-details", async (req, res) => {
    const { shopId } = req.params;
    const connection = await db.getConnection();

    try {
        // 1. Fetch Basic Shop Details first to ensure existence
        const [shopRows] = await connection.query(
            `SELECT 
                LS.ShopID as id, LS.ShopName as name, LS.ShopAddress as address, 
                LS.ShopDescrp as description, LS.ShopImage_url as image_url, 
                LS.ShopPhone as contact, LS.ShopOpeningHours as hours, 
                LS.ShopStatus as availability,
                COALESCE(SR.ShopRating, 0.0) AS rating 
            FROM Laundry_Shops AS LS
            LEFT JOIN Shop_Rates AS SR ON LS.ShopID = SR.ShopID
            WHERE LS.ShopID = ?`,
            [shopId]
        );

        if (shopRows.length === 0) {
            return res.status(404).json({ success: false, error: "Shop not found." });
        }
        const shopDetails = shopRows[0];

        // 2. Fetch related data in parallel
        const [
            [services],
            [addOns],
            [deliveryOptions], // <--- FIXING THIS QUERY
            [fabricTypes],
            [paymentMethods],
            [ownDeliverySettings],
            [linkedDeliveryApps]
        ] = await Promise.all([
            connection.query(`SELECT SS.SvcID as id, S.SvcName as name, SS.SvcPrice as price, SS.MinWeight as minWeight FROM Shop_Services SS JOIN Services S ON SS.SvcID = S.SvcID WHERE SS.ShopID = ?`, [shopId]),
            connection.query(`SELECT SAO.AddOnID as id, AO.AddOnName as name, SAO.AddOnPrice as price FROM Shop_Add_Ons SAO JOIN Add_Ons AO ON SAO.AddOnID = AO.AddOnID WHERE SAO.ShopID = ?`, [shopId]),
            
            // 🟢 FIXED: Removed DlvryID, using DlvryTypeID as the ID
            connection.query(`SELECT SDO.DlvryTypeID as id, DT.DlvryTypeName as name FROM Shop_Delivery_Options SDO JOIN Delivery_Types DT ON SDO.DlvryTypeID = DT.DlvryTypeID WHERE SDO.ShopID = ?`, [shopId]),
            
            connection.query(`SELECT SF.FabID as id, F.FabName as name FROM Shop_Fabrics SF JOIN Fabrics F ON SF.FabID = F.FabID WHERE SF.ShopID = ?`, [shopId]),
            connection.query(`SELECT PM.MethodID as id, PM.MethodName as name FROM Payment_Methods PM`, []),
            connection.query(`SELECT ShopBaseFare, ShopBaseKm, ShopDistanceRate, ShopServiceStatus FROM Shop_Own_Service WHERE ShopID = ?`, [shopId]),
            connection.query(`SELECT DA.DlvryAppName FROM Shop_Delivery_App SDA JOIN Delivery_App DA ON SDA.DlvryAppID = DA.DlvryAppID WHERE SDA.ShopID = ?`, [shopId])
        ]);

        res.json({
            success: true,
            shop: shopDetails,
            services: services,
            addOns: addOns,
            deliveryOptions: deliveryOptions,
            fabricTypes: fabricTypes,
            paymentMethods: paymentMethods,
            ownDelivery: ownDeliverySettings[0] || null, 
            deliveryApps: linkedDeliveryApps || []
        });

    } catch (error) {
        console.error("Error fetching full details:", error);
        res.status(500).json({ success: false, error: "Failed to fetch shop details." });
    } finally {
        connection.release();
    }
});


// =================================================================
// 2. OWNER MANAGEMENT ROUTES
// =================================================================

// 🟢 NEW ROUTE: Dedicated Image Upload Endpoint for Owner UI
router.post("/upload-image", upload.single("image"), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, message: "No image file provided." });
    }
    
    try {
        const b64 = Buffer.from(req.file.buffer).toString("base64");
        const dataURI = "data:" + req.file.mimetype + ";base64," + b64;
        
        // Upload to Cloudinary
        const uploadResult = await cloudinary.uploader.upload(dataURI, { 
            folder: "laundrolink_shop_images",
            public_id: `shop_${Date.now()}`
        });

        res.json({ 
            success: true, 
            message: "Image uploaded successfully.",
            url: uploadResult.secure_url 
        });

    } catch (error) {
        console.error("Cloudinary upload error:", error);
        res.status(500).json({ success: false, message: "Failed to upload image to cloud storage." });
    }
});


// GET /api/shops/:shopId/full-details-owner (Owner Dashboard)
router.get("/:shopId/full-details-owner", async (req, res) => {
    const { shopId } = req.params;
    const connection = await db.getConnection();

    try {
        const [
            [[shopDetails]],
            rawRatings, // 🟢 UPDATED: Fetches raw customer ratings
            [[shopDistance]] 
        ] = await Promise.all([
            // 1. Fetch Shop Basic Details
            connection.query(
                `SELECT 
                    LS.ShopID, LS.ShopName, LS.ShopDescrp, LS.ShopAddress, 
                    LS.ShopPhone, LS.ShopOpeningHours, LS.ShopStatus, LS.ShopImage_url
                FROM Laundry_Shops AS LS
                WHERE LS.ShopID = ?`,
                [shopId]
            ),
            
            // 2. 🟢 UPDATED: Fetch Ratings from Customer_Ratings via Orders
            connection.query(
                `SELECT cr.CustRating 
                 FROM Customer_Ratings cr
                 JOIN Orders o ON cr.OrderID = o.OrderID
                 WHERE o.ShopID = ?`, 
                [shopId]
            ),

            // 3. Fetch Location
            connection.query(`SELECT ShopLatitude, ShopLongitude FROM Shop_Distance WHERE ShopID = ?`, [shopId])
        ]);
        
        if (!shopDetails) {
            return res.status(404).json({ error: "Shop not found." });
        }
        
        // 🟢 3. Calculate Stats in JavaScript
        const ratingsArray = rawRatings[0].map(r => parseFloat(r.CustRating));
        const ratingCount = ratingsArray.length;
        
        // Calculate Average
        const sum = ratingsArray.reduce((a, b) => a + b, 0);
        const averageRating = ratingCount > 0 ? (sum / ratingCount).toFixed(1) : 0.0;

        // Calculate Breakdown (1-5 Stars)
        const breakdown = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
        ratingsArray.forEach(rating => {
            const roundedRating = Math.round(rating);
            if (breakdown[roundedRating] !== undefined) breakdown[roundedRating]++;
        });

        res.json({
            success: true,
            details: {
                ...shopDetails,
                // Pass the calculated average here
                averageRating: averageRating, 
                ShopLatitude: shopDistance ? shopDistance.ShopLatitude : null,
                ShopLongitude: shopDistance ? shopDistance.ShopLongitude : null,
            },
            rating: {
                averageRating: averageRating,
                ratingCount: ratingCount,
                breakdown: breakdown 
            }
        });

    } catch (error) {
        console.error("Error fetching shop details:", error);
        res.status(500).json({ success: false, error: "Failed to fetch shop details." });
    } finally {
        connection.release();
    }
});

// POST /api/shops/create (Create New Shop)
router.post("/create", async (req, res) => {
    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
        const { 
            OwnerID, ShopName, ShopDescrp, ShopAddress, ShopPhone, 
            ShopOpeningHours, ShopStatus, ShopImage_url, 
            ShopLatitude, ShopLongitude
        } = req.body;

        if (!OwnerID || !ShopName || !ShopAddress || !ShopLatitude || !ShopLongitude) {
            await connection.rollback();
            return res.status(400).json({ success: false, message: "Missing required shop details." });
        }

        const [shopResult] = await connection.query(
            `INSERT INTO Laundry_Shops 
            (OwnerID, ShopName, ShopDescrp, ShopAddress, ShopPhone, ShopOpeningHours, ShopStatus, ShopImage_url) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)`, 
            [OwnerID, ShopName, ShopDescrp, ShopAddress, ShopPhone, ShopOpeningHours, ShopStatus, ShopImage_url || null]
        );
        const newShopID = shopResult.insertId;
        
        await connection.query(
            `INSERT INTO Shop_Distance (ShopID, ShopLatitude, ShopLongitude) VALUES (?, ?, ?)`, 
            [newShopID, ShopLatitude, ShopLongitude]
        );
        
        await connection.commit();
        
        res.status(201).json({ 
            success: true, 
            message: "Shop created and linked successfully!",
            ShopID: newShopID
        });

    } catch (error) {
        await connection.rollback();
        res.status(500).json({ success: false, error: "Failed to create shop." });
    } finally {
        connection.release();
    }
});

// PUT /api/shops/:shopId (Update Shop Details)
router.put("/:shopId", async (req, res) => {
    const { shopId } = req.params;
    const { 
        ShopName, ShopDescrp, ShopAddress, ShopPhone, ShopOpeningHours, 
        ShopStatus, ShopLatitude, ShopLongitude, ShopImage_url 
    } = req.body;
    
    const connection = await db.getConnection();
    await connection.beginTransaction();

    try {
        await connection.query(
            `UPDATE Laundry_Shops SET 
                ShopName = ?, ShopDescrp = ?, ShopAddress = ?, 
                ShopPhone = ?, ShopOpeningHours = ?, ShopStatus = ?,
                ShopImage_url = ?  
            WHERE ShopID = ?`,
            [ShopName, ShopDescrp, ShopAddress, ShopPhone, ShopOpeningHours, ShopStatus, ShopImage_url, shopId] 
        );
        
        if (ShopLatitude && ShopLongitude) {
            await connection.query(
                `INSERT INTO Shop_Distance (ShopID, ShopLatitude, ShopLongitude) 
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE 
                ShopLatitude = VALUES(ShopLatitude), 
                ShopLongitude = VALUES(ShopLongitude)`,
                [shopId, ShopLatitude, ShopLongitude]
            );
        }

        await connection.commit();
        res.json({ success: true, message: "Shop details updated successfully." });

    } catch (error) {
        await connection.rollback();
        res.status(500).json({ error: "Failed to update shop details." });
    } finally {
        connection.release();
    }
});


// =================================================================
// 3. CONFIGURATION ROUTES (Services, Logistics, etc.)
// =================================================================

// --- SERVICES ---
router.get("/global/services", async (req, res) => {
    try {
        const [services] = await db.query(`SELECT SvcID, SvcName FROM Services`);
        res.json({ success: true, services });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

router.get("/:shopId/services", async (req, res) => {
    try {
        // 🔑 CHANGED: Select MinWeight, removed MinLoad/MaxLoad
        const [services] = await db.query(
            `SELECT SS.SvcID, S.SvcName, SS.SvcPrice, SS.MinWeight
             FROM Shop_Services SS 
             JOIN Services S ON SS.SvcID = S.SvcID 
             WHERE SS.ShopID = ?`,
            [req.params.shopId]
        );
        res.json({ success: true, services });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

router.post("/services", async (req, res) => {
    // 🔑 CHANGED: Destructure MinWeight
    const { ShopID, SvcID, SvcPrice, MinWeight } = req.body;
    try {
        // 🔑 CHANGED: Insert/Update MinWeight
        await db.query(
            `INSERT INTO Shop_Services (ShopID, SvcID, SvcPrice, MinWeight) 
             VALUES (?, ?, ?, ?) 
             ON DUPLICATE KEY UPDATE 
                SvcPrice=VALUES(SvcPrice), 
                MinWeight=VALUES(MinWeight)`,
            [ShopID, SvcID, SvcPrice, MinWeight || 1] // Default to 1kg if empty
        );
        res.status(201).json({ success: true });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

// --- FABRICS ---
router.get("/global/fabrics", async (req, res) => {
    try {
        const [fabrics] = await db.query(`SELECT FabID, FabName FROM Fabrics`);
        res.json({ success: true, fabrics });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

router.get("/:shopId/fabrics", async (req, res) => {
    try {
        const [fabrics] = await db.query(
            `SELECT SF.FabID, F.FabName FROM Shop_Fabrics SF JOIN Fabrics F ON SF.FabID = F.FabID WHERE SF.ShopID = ?`,
            [req.params.shopId]
        );
        res.json({ success: true, fabrics });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

router.post("/fabrics", async (req, res) => {
    try {
        await db.query(`INSERT IGNORE INTO Shop_Fabrics (ShopID, FabID) VALUES (?, ?)`, [req.body.ShopID, req.body.FabID]);
        res.status(201).json({ success: true });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

// --- ADD-ONS ---
router.get("/global/addons", async (req, res) => {
    try {
        const [addons] = await db.query(`SELECT AddOnID, AddOnName FROM Add_Ons`);
        res.json({ success: true, addons });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

router.get("/:shopId/addons", async (req, res) => {
    try {
        const [addons] = await db.query(
            `SELECT SAO.AddOnID, AO.AddOnName, SAO.AddOnPrice FROM Shop_Add_Ons SAO JOIN Add_Ons AO ON SAO.AddOnID = AO.AddOnID WHERE SAO.ShopID = ?`,
            [req.params.shopId]
        );
        res.json({ success: true, addons });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

router.post("/addons", async (req, res) => {
    try {
        await db.query(
            `INSERT INTO Shop_Add_Ons (ShopID, AddOnID, AddOnPrice) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE AddOnPrice=VALUES(AddOnPrice)`,
            [req.body.ShopID, req.body.AddOnID, req.body.AddOnPrice]
        );
        res.status(201).json({ success: true });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

// =================================================================
// 5. DELIVERY MODES 
// =================================================================

// --- GLOBAL DELIVERY TYPES ---
router.get("/global/delivery-types", async (req, res) => {
    try {
        // 🔑 UPDATED: Removed DlvryDescription
        const [deliveryTypes] = await db.query(`SELECT DlvryTypeID, DlvryTypeName FROM Delivery_Types`);
        res.json({ success: true, deliveryTypes });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

// --- SHOP DELIVERY OPTIONS ---
router.get("/:shopId/delivery", async (req, res) => {
    try {
        // 🟢 FIXED: Removed DlvryID
        const [delivery] = await db.query(
            `SELECT SDO.DlvryTypeID, DT.DlvryTypeName
             FROM Shop_Delivery_Options SDO 
             JOIN Delivery_Types DT ON SDO.DlvryTypeID = DT.DlvryTypeID 
             WHERE SDO.ShopID = ?`,
            [req.params.shopId]
        );
        res.json({ success: true, delivery });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

router.post("/delivery", async (req, res) => {
    const { ShopID, DlvryTypeID } = req.body; 
    try {
        // 🟢 FIXED: Use INSERT IGNORE to handle duplicates safely (relies on Composite Key)
        await db.query(
            `INSERT IGNORE INTO Shop_Delivery_Options (ShopID, DlvryTypeID) VALUES (?, ?)`, 
            [ShopID, DlvryTypeID]
        );
        // We don't need to return an ID anymore since the TypeID IS the ID
        res.status(201).json({ success: true });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

// =================================================================
// 4. LOGISTICS ROUTES (For Customer & Owner)
// =================================================================

// --- GLOBAL APPS (For Owner Config) ---
router.get("/global/delivery-apps", async (req, res) => {
    try {
        const [apps] = await db.query("SELECT DlvryAppID, DlvryAppName, AppBaseFare, AppBaseKm, AppDistanceRate FROM Delivery_App");
        res.json({ success: true, apps });
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch delivery apps." });
    }
});

// --- SHOP OWN SERVICE (For Customer Calc & Owner Config) ---
router.get("/:shopId/own-delivery", async (req, res) => {
    try {
        const [rows] = await db.query(
            "SELECT ShopBaseFare, ShopBaseKm, ShopDistanceRate, ShopServiceStatus FROM Shop_Own_Service WHERE ShopID = ?", 
            [req.params.shopId]
        );
        res.json({ success: true, settings: rows[0] || null });
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch own delivery settings." });
    }
});

router.post("/own-delivery", async (req, res) => {
    const { ShopID, ShopBaseFare, ShopBaseKm, ShopDistanceRate, ShopServiceStatus } = req.body;
    const statusToSave = ShopServiceStatus || 'Active'; 

    try {
        await db.query(
            `INSERT INTO Shop_Own_Service (ShopID, ShopBaseFare, ShopBaseKm, ShopDistanceRate, ShopServiceStatus) 
             VALUES (?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE 
                ShopBaseFare=VALUES(ShopBaseFare), 
                ShopBaseKm=VALUES(ShopBaseKm), 
                ShopDistanceRate=VALUES(ShopDistanceRate),
                ShopServiceStatus=VALUES(ShopServiceStatus)`,
            [ShopID, ShopBaseFare, ShopBaseKm, ShopDistanceRate, statusToSave]
        );
        res.status(201).json({ success: true });
    } catch (error) {
        res.status(500).json({ error: "Failed to save own delivery settings." });
    }
});

// --- LINKED DELIVERY APPS (For Customer Calc & Owner Config) ---
router.get("/:shopId/delivery-apps", async (req, res) => {
    try {
        const [apps] = await db.query(
            `SELECT DA.DlvryAppID, DA.DlvryAppName, DA.AppBaseFare, DA.AppBaseKm, DA.AppDistanceRate
             FROM Shop_Delivery_App SDA 
             JOIN Delivery_App DA ON SDA.DlvryAppID = DA.DlvryAppID 
             WHERE SDA.ShopID = ?`,
            [req.params.shopId]
        );
        res.json({ success: true, apps });
    } catch (error) {
        res.status(500).json({ error: "Failed to fetch linked delivery apps." });
    }
});

router.post("/delivery-apps", async (req, res) => {
    const { ShopID, DlvryAppID } = req.body;
    try {
        await db.query(
            `INSERT IGNORE INTO Shop_Delivery_App (ShopID, DlvryAppID) VALUES (?, ?)`, 
            [ShopID, DlvryAppID]
        );
        res.status(201).json({ success: true });
    } catch (error) {
        res.status(500).json({ error: "Failed to link delivery app." });
    }
});

router.post("/delivery-apps/unlink", async (req, res) => {
    const { ShopID, DlvryAppID } = req.body;
    try {
        await db.query("DELETE FROM Shop_Delivery_App WHERE ShopID = ? AND DlvryAppID = ?", [ShopID, DlvryAppID]);
        res.json({ success: true });
    } catch (error) {
        res.status(500).json({ error: "Failed to unlink delivery app." });
    }
});

export default router;
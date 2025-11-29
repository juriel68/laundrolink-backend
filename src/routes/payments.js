// src/routes/payments.js
import express from "express";
import db from "../db.js"; 
import { paypalClient, paypal } from "../config/externalServices.js";
const router = express.Router();
const BASE_URL = process.env.API_BASE_URL || "http://localhost:8080";


/**
 * @route POST /api/payments/paypal/create
 * Creates a PayPal order and returns the approval link.
 */
router.post("/paypal/create", async (req, res) => {
    const { amount, orderId, isDelivery } = req.body;

    // Create Request
    const request = new paypal.orders.OrdersCreateRequest();
    request.prefer("return=representation");
    request.requestBody({
        intent: "CAPTURE",
        purchase_units: [{
            reference_id: orderId, // Link PayPal order to Your Order ID
            description: isDelivery ? `Delivery Fee for Order ${orderId}` : `Laundry Service for Order ${orderId}`,
            amount: {
                currency_code: "PHP",
                value: amount.toString(),
            },
        }],
        application_context: {
            brand_name: "LaundroLink",
            landing_page: "LOGIN",
            user_action: "PAY_NOW",
            // 🟢 Dynamic Redirect URLs
            return_url: `${BASE_URL}/api/payments/paypal/success`,
            cancel_url: `${BASE_URL}/api/payments/paypal/cancel`,
        },
    });

    try {
        const order = await paypalClient.execute(request);
        
        // Find the 'approve' link to send to frontend
        const approveLink = order.result.links.find(link => link.rel === 'approve').href;
        
        res.json({ 
            success: true, 
            approvalUrl: approveLink, 
            orderId: order.result.id 
        });
    } catch (err) {
        console.error("PayPal Create Order Error:", err);
        res.status(500).json({ success: false, message: "Could not create PayPal order" });
    }
});

/**
 * @route GET /api/payments/paypal/success
 * Displayed to user in the In-App Browser after payment.
 */
router.get("/paypal/success", (req, res) => {
    res.send(`
        <html>
        <body style="text-align:center; font-family: sans-serif; padding-top: 50px;">
            <h1 style="color: green;">Payment Successful! ✅</h1>
            <p>We have received your payment.</p>
            <p style="font-weight: bold;">Please click "Done" or "Close" to return to the app.</p>
        </body>
        </html>
    `);
});

/**
 * @route GET /api/payments/paypal/cancel
 */
router.get("/paypal/cancel", (req, res) => {
    res.send(`
        <html>
        <body style="text-align:center; font-family: sans-serif; padding-top: 50px;">
            <h1 style="color: red;">Payment Cancelled ❌</h1>
            <p>You cancelled the transaction.</p>
            <p>Please close this window to try again.</p>
        </body>
        </html>
    `);
});



/**
 * @route GET /api/payments/admin
 * @description Admin endpoint to fetch and filter ALL paid transactions (Service & Delivery).
 * @queryParam {string} [shopId] - Optional ShopID to filter by.
 * @queryParam {string} [startDate] - Optional start date (YYYY-MM-DD).
 * @queryParam {string} [endDate] - Optional end date (YYYY-MM-DD).
 */
router.get("/admin", async (req, res) => {
    const { shopId, startDate, endDate } = req.query;

    // We need two separate parameter arrays because we are running two queries combined by UNION
    const params1 = [];
    const params2 = [];
    
    let shopFilter = '';
    let dateFilter1 = ''; // For Invoices table (alias I)
    let dateFilter2 = ''; // For Delivery_Payments table (alias DP)

    // 1. Build Filters
    if (shopId) {
        shopFilter = 'AND O.ShopID = ?';
        params1.push(shopId);
        params2.push(shopId);
    }

    if (startDate && endDate) {
        dateFilter1 = 'AND I.StatusUpdatedAt BETWEEN ? AND DATE_ADD(?, INTERVAL 1 DAY)';
        dateFilter2 = 'AND DP.StatusUpdatedAt BETWEEN ? AND DATE_ADD(?, INTERVAL 1 DAY)';
        
        params1.push(startDate, endDate);
        params2.push(startDate, endDate);
    } else if (startDate) {
        dateFilter1 = 'AND I.StatusUpdatedAt >= ? AND I.StatusUpdatedAt < DATE_ADD(?, INTERVAL 1 DAY)';
        dateFilter2 = 'AND DP.StatusUpdatedAt >= ? AND DP.StatusUpdatedAt < DATE_ADD(?, INTERVAL 1 DAY)';
        
        params1.push(startDate, startDate);
        params2.push(startDate, startDate);
    }

    try {
        const query = `
            /* --- QUERY 1: Service Payments (Invoices) --- */
            SELECT
                C.CustName AS customerName,
                LS.ShopName AS shopName,
                I.PayAmount AS amount,
                PM.MethodName AS paymentMethod,
                I.StatusUpdatedAt AS dateCompleted, 
                I.PaymentStatus AS status,
                O.OrderID AS orderId,
                'Service' AS paymentType
            FROM Invoices I
            JOIN Orders O ON I.OrderID = O.OrderID
            JOIN Customers C ON O.CustID = C.CustID
            JOIN Laundry_Shops LS ON O.ShopID = LS.ShopID
            LEFT JOIN Payment_Methods PM ON I.MethodID = PM.MethodID
            WHERE I.PaymentStatus = 'Paid'
            ${shopFilter}
            ${dateFilter1}

            UNION ALL

            /* --- QUERY 2: Delivery Payments --- */
            SELECT
                C.CustName AS customerName,
                LS.ShopName AS shopName,
                DP.DlvryAmount AS amount,
                PM.MethodName AS paymentMethod,
                DP.StatusUpdatedAt AS dateCompleted,
                DP.DlvryPaymentStatus AS status,
                O.OrderID AS orderId,
                'Delivery' AS paymentType
            FROM Delivery_Payments DP
            JOIN Orders O ON DP.OrderID = O.OrderID
            JOIN Customers C ON O.CustID = C.CustID
            JOIN Laundry_Shops LS ON O.ShopID = LS.ShopID
            LEFT JOIN Payment_Methods PM ON DP.MethodID = PM.MethodID
            WHERE DP.DlvryPaymentStatus = 'Paid'
            ${shopFilter}
            ${dateFilter2}

            ORDER BY dateCompleted DESC;
        `;

        // Combine parameters for the full query
        const finalParams = [...params1, ...params2];

        const [payments] = await db.query(query, finalParams);
        
        res.status(200).json(payments);
    } catch (error) {
        console.error("Error fetching admin payments:", error);
        res.status(500).json({ error: "Failed to fetch payment data" });
    }
});

/**
 * @route GET /api/payments/shops
 * @description Utility endpoint to fetch the list of shops for the filter dropdown.
 */
router.get("/shops", async (req, res) => {
    try {
        const query = `
            SELECT 
                ShopID, 
                ShopName 
            FROM 
                Laundry_Shops 
            ORDER BY 
                ShopName ASC;
        `;
        const [shops] = await db.query(query);
        res.status(200).json(shops);
    } catch (error) {
        console.error("Error fetching shops for filter:", error);
        res.status(500).json({ error: "Failed to fetch shop list" });
    }
});

export default router;
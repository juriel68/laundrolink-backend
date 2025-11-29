// src/server.js

import express from "express";
import cors from "cors";
import dotenv from "dotenv";

// NEW: Import the assumed utility function to read the maintenance setting
import { getMaintenanceStatus } from "./utils/db-settings.js"; 

// Routes
import userRoutes from "./routes/users.js";
import orderRoutes from "./routes/orders.js";
import messagesRouter from './routes/messages.js';
import analyticsRouter from "./routes/analytics.js";
import shopRouter from "./routes/shops.js";
import authRouter from "./routes/auth.js"; 
import activityRouter from "./routes/activity.js";
import paymentRoutes from "./routes/payments.js";
import adminRoutes from "./routes/admin.js";

dotenv.config();

const app = express();

// --- Robust CORS Configuration ---
const allowedOrigins = [
    'http://localhost',
    // 1. Local Development Environments
    'http://localhost:8081',
    'http://localhost:8082', // React Native Dev Server (common default)
    'http://localhost:8080', // Default port for Web apps (where system_settings.php likely runs)
    'http://localhost:3000', // React/Next.js frontend default
    'http://127.0.0.1:8081',
    'http://127.0.0.1:8080',
    'https://laundrolink-backend.onrender.com',
];

app.use(cors({
    origin: (origin, callback) => {
        // Allow requests with no origin (like mobile apps, curl, or same-origin requests)
        if (!origin) return callback(null, true); 
        
        // If the origin is in our allowed list, permit it
        if (allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            // Log for debugging if a request is blocked
            console.log(`CORS Blocked: ${origin}`);
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true // Crucial for handling cookies/sessions/auth tokens
}));
// --- End CORS Configuration ---

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ----------------------------------------------------------------------
// MAINTENANCE MODE MIDDLEWARE
// MUST be placed after body parsers but before protected routes.
// ----------------------------------------------------------------------
app.use(async (req, res, next) => {
    // 1. Exclude critical routes from maintenance block
    //    - /api/auth: Allows admins/users to log in/out.
    //    - /api/admin: Allows admins to turn off maintenance mode.
    //    - /: Health check.
    if (req.path.startsWith('/api/auth') || req.path.startsWith('/api/admin') || req.path === '/') {
        return next();
    }
    
    try {
        // Fetch the current maintenance status from the database
        const isMaintenance = await getMaintenanceStatus(); 
        
        if (isMaintenance) {
            console.log(`[MAINTENANCE] Blocking request: ${req.method} ${req.path}`);
            
            // Return 503 Service Unavailable for all non-excluded API requests
            return res.status(503).json({ 
                success: false,
                message: "App is currently undergoing scheduled maintenance. Please check back later." 
            });
        }
    } catch (error) {
        // Log critical failure but proceed to prevent a total app halt due to DB issue
        console.error("CRITICAL: Failed to check maintenance status. Proceeding without block.", error);
    }

    // If not in maintenance, or if the request was excluded, proceed to the next handler
    next();
});
// ----------------------------------------------------------------------

// API Routes (These are now protected by the middleware)
app.use("/api/users", userRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/messages", messagesRouter);
app.use("/api/analytics", analyticsRouter);
app.use("/api/shops", shopRouter);
app.use("/api/auth", authRouter); 
app.use("/api/activity", activityRouter);
app.use("/api/payments", paymentRoutes);
app.use("/api/admin", adminRoutes);

// Health check route
app.get("/", (req, res) => {
    res.send("🚀 Main Backend API is running...");
});

// --- Server Startup Logic ---
const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '0.0.0.0'; 

app.listen(PORT, HOST, () => {
    console.log(`🚀 Main Backend running on http://${HOST}:${PORT}`);
    console.log(`Open http://localhost:${PORT} in your browser (if running locally)`);
});
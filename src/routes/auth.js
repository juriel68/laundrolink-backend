import express from "express";
import bcrypt from "bcryptjs";
import db from "../db.js";
import { sgMail } from "../config/externalServices.js";
import { logUserActivity } from '../utils/logger.js'; 

const router = express.Router();

// =================================================================
// Helper Functions
// =================================================================

function generateOTP() { 
    return Math.floor(100000 + Math.random() * 900000).toString(); 
}

async function generateNewCustID(connection) {
    const [rows] = await connection.query(
        `SELECT MAX(CAST(SUBSTRING(CustID, 2) AS UNSIGNED)) AS last_id_number
         FROM Customers
         WHERE CustID LIKE 'C%'`
    );
    let nextIdNumber = (rows.length > 0 && rows[0].last_id_number !== null) ? rows[0].last_id_number + 1 : 1;
    return 'C' + nextIdNumber.toString();
}

async function sendEmail(to, subject, html) {
    const msg = {
        to: to,
        from: 'dimpasmj@gmail.com', 
        subject: subject,
        html: html,
    };
    try {
        await sgMail.send(msg);
        console.log(`✅ Email sent successfully to ${to}`);
    } catch (error) {
        console.error('❌ Error sending email:', error.response ? error.response.body.errors : error);
    }
}

async function fetchCustomerDetails(userId, connection) {
    const [rows] = await connection.query(`
        SELECT 
            u.UserID, 
            u.UserEmail, 
            u.UserRole, 
            u.UserPassword, 
            c.CustName AS name, 
            c.CustPhone AS phone, 
            c.CustAddress AS address, 
            cc.picture
        FROM Users u
        JOIN Customers c ON u.UserID = c.CustID
        LEFT JOIN Cust_Credentials cc ON u.UserID = cc.CustID
        WHERE u.UserID = ? AND u.UserRole = 'Customer'`, 
        [userId]
    );

    if (rows.length > 0) {
        const user = rows[0];
        const hasPassword = !!user.UserPassword; 
        delete user.UserPassword; 
        return { ...user, hasPassword };
    }
    return null;
}

// =================================================================
// API Routes: Authentication
// =================================================================

router.post("/login", async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res.status(400).json({ message: "Email and password are required" });
    }

    try {
        const [users] = await db.query(
            `SELECT UserID, UserEmail, UserPassword, UserRole, IsActive FROM Users WHERE UserEmail = ?`,
            [email]
        );

        if (users.length === 0) {
            await logUserActivity('N/A', 'N/A', 'Login Failed', `Unknown email: ${email}`);
            return res.status(401).json({ message: "Invalid credentials" });
        }

        const user = users[0];

        if (user.IsActive === 0) {
            await logUserActivity(user.UserID, user.UserRole, 'Login Denied', `Account deactivated`);
            return res.status(403).json({ message: "Account is deactivated. Contact support." });
        }

        let passwordMatch = false;
        const isHash = user.UserPassword && (user.UserPassword.startsWith('$2a$') || user.UserPassword.startsWith('$2b$'));
        
        if (isHash) {
            passwordMatch = await bcrypt.compare(password, user.UserPassword);
        } else {
            passwordMatch = (password === user.UserPassword);
        }

        if (!passwordMatch) {
            await logUserActivity(user.UserID, user.UserRole, 'Login Failed', `Invalid password`);
            return res.status(401).json({ message: "Invalid credentials" });
        }

        // --- CUSTOMER FLOW (OTP) ---
        if (user.UserRole === 'Customer') {
            const otp = generateOTP();
            await db.query("DELETE FROM otps WHERE user_id = ?", [user.UserID]);
            await db.query("INSERT INTO otps (user_id, otp_code, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 10 MINUTE))", [user.UserID, otp]);
            
            sendEmail(user.UserEmail, 'LaundroLink Login Code', `<strong>Your login code is: ${otp}</strong>`);

            return res.json({
                success: true,
                message: "Credentials valid, sending OTP.",
                userId: user.UserID,
                requiresOTP: true
            });
        }

        // --- STAFF/ADMIN/OWNER FLOW (Direct Login) ---
        await logUserActivity(user.UserID, user.UserRole, 'Login', `Direct login success`);

        delete user.UserPassword; 

        let userDetails = {
            UserID: user.UserID,
            UserEmail: user.UserEmail,
            UserRole: user.UserRole,
            hasPassword: true 
        };

        if (user.UserRole === 'Shop Owner') {
            const [ownerDetails] = await db.query(
                `SELECT o.OwnerID, o.OwnerName, s.ShopID, s.ShopName
                 FROM Shop_Owners o LEFT JOIN Laundry_Shops s ON o.OwnerID = s.OwnerID
                 WHERE o.OwnerID = ?`, [user.UserID]
            );
            if (ownerDetails.length > 0) userDetails = { ...userDetails, ...ownerDetails[0] };

        } else if (user.UserRole === 'Staff') {
            const [staffDetails] = await db.query(
                `SELECT sh.ShopID, sh.ShopName, s.StaffName, s.StaffRole
                 FROM Staffs s JOIN Laundry_Shops sh ON s.ShopID = sh.ShopID
                 WHERE s.StaffID = ?`, [user.UserID]
            );
            if (staffDetails.length > 0) userDetails = { ...userDetails, ...staffDetails[0] };
        }

        res.json({
            success: true,
            user: userDetails,
            requiresOTP: false
        });

    } catch (error) {
        console.error("❌ Login error:", error);
        res.status(500).json({ error: "Server error" });
    }
});

router.post("/google-login", async (req, res) => {
    let connection;
    try {
        const { google_id, email, name, picture } = req.body;
        console.log(`--- Google Login: ${email} ---`);

        if (!google_id || !email || !name) { 
            return res.status(400).json({ success: false, message: "Missing Google data" }); 
        }
        
        connection = await db.getConnection();
        await connection.beginTransaction();

        const [existingUser] = await connection.query(
            "SELECT UserID, IsActive FROM Users WHERE UserEmail = ?", 
            [email]
        );
        
        let userId = existingUser.length > 0 ? existingUser[0].UserID : null;

        if (userId) {
            if (existingUser[0].IsActive === 0) {
                await connection.rollback();
                await logUserActivity(userId, 'Customer', 'Login Denied', 'Google Login Attempt on Deactivated Account');
                return res.status(403).json({ success: false, message: "Account is deactivated. Contact support." });
            }

            await connection.query(
                `INSERT INTO Cust_Credentials (CustID, google_id, is_verified, picture) VALUES (?, ?, 1, ?)
                 ON DUPLICATE KEY UPDATE google_id = VALUES(google_id), picture = VALUES(picture), is_verified = 1`,
                [userId, google_id, picture]
            );
            
            // Note: We commit here because we want the user update to stick even if OTP fails
            await connection.commit(); 
            await logUserActivity(userId, 'Customer', 'Login', 'Google Login Success');

        } else {
            const newCustID = await generateNewCustID(connection);
        
            await connection.query(
                "INSERT INTO Users (UserID, UserEmail, UserPassword, UserRole) VALUES (?, ?, ?, ?)",
                [newCustID, email, null, 'Customer'] 
            );
            
            await connection.query(
                "INSERT INTO Customers (CustID, CustName) VALUES (?, ?)",
                [newCustID, name]
            );

            await connection.query(
                `INSERT INTO Cust_Credentials (CustID, google_id, is_verified, picture) VALUES (?, ?, 1, ?)`,
                [newCustID, google_id, picture] 
            );

            await connection.commit();
            userId = newCustID;
            await logUserActivity(userId, 'Customer', 'Sign-up', 'User created via Google');
        }

        // 🟢 ENFORCE OTP FOR GOOGLE LOGIN
        const otp = generateOTP();
        await db.query("DELETE FROM otps WHERE user_id = ?", [userId]);
        await db.query("INSERT INTO otps (user_id, otp_code, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 10 MINUTE))", [userId, otp]);
            
        sendEmail(email, 'LaundroLink Login Code', `<strong>Your login code is: ${otp}</strong>`);
        
        console.log(`--- Google Login OTP Sent to: ${email} ---`);

        // Return 'requiresOTP' so frontend knows to redirect to Verify screen
        return res.json({ 
            success: true, 
            message: "Google login valid, sending OTP.",
            userId: userId,
            requiresOTP: true
        });

    } catch (error) {
        if (connection) await connection.rollback();
        console.error("❌ Google login error:", error);
        res.status(500).json({ success: false, message: "Server error" });
    } finally {
        if (connection) connection.release();
    }
});

router.post("/verify-otp", async (req, res) => {
    let connection;
    try {
        const { userId, otp } = req.body;
        if (!userId || !otp) return res.status(400).json({ success: false, message: "Missing User ID or OTP." });

        connection = await db.getConnection();
        await connection.beginTransaction();

        const [otpRows] = await connection.query("SELECT * FROM otps WHERE user_id = ? AND otp_code = ? AND expires_at > NOW()", [userId, otp]);
        
        if (otpRows.length === 0) { 
            await logUserActivity(userId, 'Customer', 'OTP Failure', 'Invalid/Expired OTP');
            await connection.rollback();
            return res.status(400).json({ success: false, message: "Invalid or expired OTP." }); 
        }

        await connection.query("DELETE FROM otps WHERE user_id = ?", [userId]);

        const [users] = await connection.query("SELECT IsActive, UserRole FROM Users WHERE UserID = ?", [userId]);
        if (users.length === 0) {
             await connection.rollback();
             return res.status(404).json({ success: false, message: "User not found." });
        }
        
        if (users[0].IsActive === 0) {
            await connection.rollback();
            return res.status(403).json({ success: false, message: "Account is deactivated." });
        }
        
        const fullUserDetails = await fetchCustomerDetails(userId, connection);

        if (!fullUserDetails) {
             await connection.rollback();
             return res.status(500).json({ success: false, message: "Error retrieving full profile data." });
        }
        
        await connection.commit();
        await logUserActivity(userId, fullUserDetails.UserRole, 'Login', 'OTP Verified Success');
        
        res.json({ success: true, message: "Login successful", user: fullUserDetails });

    } catch (error) {
        if (connection) await connection.rollback();
        console.error("❌ verify-otp error:", error);
        res.status(500).json({ success: false, message: "Failed to verify OTP." });
    } finally {
        if (connection) connection.release();
    }
});

// ... (forgot/reset password routes remain unchanged) ...
router.post("/forgot-password", async (req, res) => {
    try {
        const { identifier } = req.body;
        if (!identifier) return res.status(400).json({ success: false, message: "Email required" }); 
        
        const [users] = await db.query("SELECT UserID, UserEmail, UserRole, IsActive FROM Users WHERE UserEmail = ?", [identifier]);
        
        if (users.length === 0) {
            await logUserActivity('N/A', 'N/A', 'Password Reset Failed', `Unknown email: ${identifier}`);
            return res.json({ success: true, message: "If this email exists, an OTP will be sent." });
        }
        
        const user = users[0];

        if (user.IsActive === 0) {
            return res.status(403).json({ success: false, message: "Account deactivated." });
        }
        
        const otp = generateOTP();
        await db.query("DELETE FROM otps WHERE user_id = ?", [user.UserID]);
        await db.query("INSERT INTO otps (user_id, otp_code, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 10 MINUTE))", [user.UserID, otp]);
        
        await logUserActivity(user.UserID, user.UserRole, 'Password Reset', 'OTP Sent');
        
        sendEmail(user.UserEmail, 'LaundroLink Password Reset', `<strong>Your reset code is: ${otp}</strong>`);
        res.json({ success: true, message: "OTP sent." });

    } catch (error) {
        console.error("Forgot password error:", error);
        res.status(500).json({ success: false, message: "Server error" });
    }
});

router.post("/reset-password", async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;
        if (!email || !otp || !newPassword) return res.status(400).json({ success: false, message: "Missing fields" }); 
        
        const [users] = await db.query("SELECT UserID, UserRole, IsActive FROM Users WHERE UserEmail = ?", [email]); 
        if (users.length === 0) return res.status(400).json({ success: false, message: "User not found" });
        
        const { UserID: userId, UserRole } = users[0];

        if (users[0].IsActive === 0) {
            return res.status(403).json({ success: false, message: "Account deactivated." });
        }
        
        const [otpRows] = await db.query("SELECT * FROM otps WHERE user_id = ? AND otp_code = ? AND expires_at > NOW()", [userId, otp]);
        if (otpRows.length === 0) return res.status(400).json({ success: false, message: "Invalid or expired OTP" });
        
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await db.query("UPDATE Users SET UserPassword = ? WHERE UserID = ?", [hashedPassword, userId]);
        await db.query("DELETE FROM otps WHERE user_id = ?", [userId]);
        
        await logUserActivity(userId, UserRole, 'Password Reset', 'Success');
        res.json({ success: true, message: "Password reset successfully" });

    } catch (error) {
        console.error("Reset password error:", error);
        res.status(500).json({ success: false, message: "Server error" });
    }
});

router.get("/test-users", async (req, res) => {
    try {
        const [users] = await db.query(
            `SELECT UserID, UserEmail, UserRole, IsActive FROM Users`
        );
        return res.json({ success: true, count: users.length, data: users });
    } catch (error) {
        return res.status(500).json({ error: error.message });
    }
});

export default router;
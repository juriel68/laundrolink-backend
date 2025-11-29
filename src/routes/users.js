// users.js
import express from "express";
import bcrypt from "bcryptjs";
import db from "../db.js";
import { cloudinary } from "../config/externalServices.js"; 
import multer from 'multer'; 
import { logUserActivity } from '../utils/logger.js'; 

const router = express.Router();
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// =================================================================
// API Routes: User & Staff Management
// =================================================================

// GET /api/users - Fetch all users (general)
router.get("/", async (req, res) => {
    try {
        const [rows] = await db.query("SELECT UserID, UserEmail, UserRole, DateCreated, IsActive FROM Users");
        res.json(rows);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// PUT /api/users/:id - Update generic user details (Email only for Staff/Customer)
router.put("/:id", async (req, res) => {
    const userId = req.params.id;
    const { UserEmail } = req.body; 
    
    const [userCheck] = await db.query(
        "SELECT UserRole FROM Users WHERE UserID = ?", [userId]
    );

    if (userCheck.length === 0) {
        return res.status(404).json({ success: false, message: "User not found." });
    }
    const UserRole = userCheck[0].UserRole; 

    if (UserRole === 'Admin' || UserRole === 'Shop Owner') {
        return res.status(403).json({ success: false, message: "Use the dedicated owner/admin endpoints for sensitive updates." });
    }

    try {
        const [result] = await db.query(
            "UPDATE Users SET UserEmail = ? WHERE UserID = ? AND UserRole IN ('Customer', 'Staff')",
            [UserEmail, userId]
        );

        if (result.affectedRows === 0) {
            return res.status(403).json({ success: false, message: "User role prevents direct update on this endpoint." });
        }

        await logUserActivity(userId, UserRole, 'User Update', `Updated User ID ${userId} email to ${UserEmail}`);
        res.json({ success: true, message: `${UserRole} email updated successfully.` });

    } catch (error) {
        console.error("Update basic user details error:", error);
        res.status(500).json({ success: false, message: error.message || "Failed to update details." });
    }
});


// PUT /api/users/:id/status - Update user Active/Deactive status
router.put("/:id/status", async (req, res) => {
    const userId = req.params.id;
    const { IsActive, Reason } = req.body; 
    let connection;

    if (IsActive === undefined || (IsActive !== 0 && IsActive !== 1)) {
        return res.status(400).json({ success: false, message: "IsActive status (0 or 1) is required." });
    }

    try {
        connection = await db.getConnection();
        await connection.beginTransaction();

        const [userCheck] = await connection.query("SELECT UserRole FROM Users WHERE UserID = ?", [userId]);

        if (userCheck.length === 0) {
            await connection.rollback();
            return res.status(404).json({ success: false, message: "User not found." });
        }
        const UserRole = userCheck[0].UserRole; 
        const statusAction = IsActive === 1 ? 'Reactivated' : 'Deactivated';

        // 1. Update Users Table
        await connection.query(
            "UPDATE Users SET IsActive = ? WHERE UserID = ?",
            [IsActive, userId]
        );

        // 2. Handle Deactivation Reason
        if (IsActive === 0 && Reason) {
            // Insert or Update Reason
            await connection.query(
                `INSERT INTO Deactivated_Account (UserID, Reason) VALUES (?, ?) 
                 ON DUPLICATE KEY UPDATE Reason = VALUES(Reason)`,
                [userId, Reason]
            );
        } else if (IsActive === 1) {
            // If reactivating, remove from Deactivated_Account (Optional cleanup)
            await connection.query("DELETE FROM Deactivated_Account WHERE UserID = ?", [userId]);
        }

        await connection.commit();
        await logUserActivity(userId, UserRole, `User Status Change`, `${UserRole} ${userId} ${statusAction}`);
        res.json({ success: true, message: `User ${userId} successfully ${statusAction}.` });

    } catch (error) {
        if (connection) await connection.rollback();
        console.error("Update user status transaction error:", error);
        res.status(500).json({ success: false, message: error.message || "Failed to update user status." });
    } finally {
        if (connection) connection.release();
    }
});


// GET /api/users/owners 
router.get("/owners", async (req, res) => {
    try {
        const [rows] = await db.query(`
            SELECT u.UserID, u.UserEmail, u.UserRole, u.DateCreated, u.IsActive, 
                   so.OwnerName, so.OwnerPhone, so.OwnerAddress
            FROM Users u
            JOIN Shop_Owners so ON u.UserID = so.OwnerID
            WHERE u.UserRole = 'Shop Owner'
        `);
        res.json(rows);
    } catch (error) {
        console.error("Fetch shop owners error:", error);
        res.status(500).json({ error: error.message });
    }
});


// PUT /api/users/owner/:id - Update Shop Owner details
router.put("/owner/:id", async (req, res) => {
    const userId = req.params.id;
    const { UserEmail, OwnerName, OwnerPhone, OwnerAddress } = req.body;
    const UserRole = 'Shop Owner';
    let connection;

    try {
        connection = await db.getConnection();
        await connection.beginTransaction();

        // 🔒 Check if new email is taken by SOMEONE ELSE
        if (UserEmail) {
             const [emailCheck] = await connection.query(
                 "SELECT UserID FROM Users WHERE UserEmail = ? AND UserID != ?", 
                 [UserEmail, userId]
             );
             if (emailCheck.length > 0) {
                 await connection.rollback();
                 return res.status(409).json({ success: false, message: "Email address is already in use." });
             }
        }

        // Update Users table
        await connection.query(
            "UPDATE Users SET UserEmail = ? WHERE UserID = ? AND UserRole = 'Shop Owner'",
            [UserEmail, userId]
        );

        // Update Shop_Owners table
        await connection.query(
            "UPDATE Shop_Owners SET OwnerName = ?, OwnerPhone = ?, OwnerAddress = ? WHERE OwnerID = ?",
            [OwnerName, OwnerPhone, OwnerAddress, userId]
        );

        await connection.commit();
        await logUserActivity(userId, UserRole, 'Owner Update', `Shop Owner ${OwnerName} details updated`);

        res.json({ success: true, message: "Shop Owner details updated successfully." });

    } catch (error) {
        if (connection) await connection.rollback();
        console.error("Update Shop Owner details transaction error:", error);
        res.status(500).json({ success: false, message: error.message || "Failed to update details." });
    } finally {
        if (connection) connection.release();
    }
});

// GET /api/users/staff/:shopId (Fetch Staff)
router.get("/staff/:shopId", async (req, res) => {
    const { shopId } = req.params;
    const { sortBy, limit, offset } = req.query; 
    
    let orderByClause = 'ORDER BY s.StaffName ASC'; 
    switch (sortBy) {
        case 'age': orderByClause = 'ORDER BY si.StaffAge ASC'; break;
        case 'newest': orderByClause = 'ORDER BY CAST(SUBSTRING(s.StaffID, 2) AS UNSIGNED) DESC'; break;
        case 'oldest': orderByClause = 'ORDER BY CAST(SUBSTRING(s.StaffID, 2) AS UNSIGNED) ASC'; break;
        case 'name': default: orderByClause = 'ORDER BY s.StaffName ASC';
    }
    
    const parsedLimit = parseInt(limit, 10) || 10;
    const parsedOffset = parseInt(offset, 10) || 0;

    try {
        const [countRows] = await db.query(
            `SELECT COUNT(s.StaffID) AS totalCount FROM Staffs s WHERE s.ShopID = ?`,
            [shopId]
        );
        const totalCount = countRows[0].totalCount;
        
        const staffQuery = `
            SELECT s.StaffID, s.StaffName, s.StaffRole, u.IsActive, si.StaffAge, si.StaffAddress, si.StaffCellNo, si.StaffSalary
            FROM Staffs s
            JOIN Staff_Infos si ON s.StaffID = si.StaffID
            JOIN Users u ON s.StaffID = u.UserID
            WHERE s.ShopID = ?
            ${orderByClause}
            LIMIT ? OFFSET ?`;
            
        const [staff] = await db.query(staffQuery, [shopId, parsedLimit, parsedOffset]);
        res.json({ staff: staff, totalCount: totalCount });

    } catch (error) {
        console.error("Fetch staff error:", error);
        res.status(500).json({ error: "Server error while fetching staff." });
    }
});


// POST /api/users/owner (Create Shop Owner)
router.post("/owner", async (req, res) => {
    const { UserEmail, UserPassword, OwnerName, OwnerPhone, OwnerAddress } = req.body;
    const UserRole = 'Shop Owner';
    let newOwnerID = '';

    if (!UserEmail || !UserPassword || !OwnerName) {
        return res.status(400).json({ message: "Email, password, and name are required." });
    }

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction(); 

        const [existingUsers] = await connection.query(
            `SELECT UserID FROM Users WHERE UserEmail = ?`, [UserEmail]
        );

        if (existingUsers.length > 0) {
            await connection.rollback(); 
            return res.status(409).json({ message: "An account with this email already exists." });
        }
        
        // ID GENERATION: O1, O2...
        const [lastOwner] = await connection.query(
            `SELECT UserID FROM Users WHERE UserID LIKE 'O%' ORDER BY CAST(SUBSTRING(UserID, 2) AS UNSIGNED) DESC LIMIT 1`
        );

        let nextOwnerIdNumber = 1;
        if (lastOwner.length > 0) {
            const lastId = lastOwner[0].UserID; 
            const lastIdNumber = parseInt(lastId.substring(1)); 
            nextOwnerIdNumber = lastIdNumber + 1; 
        }
        newOwnerID = `O${nextOwnerIdNumber}`; 

        const hashedPassword = await bcrypt.hash(UserPassword, 10);
        await connection.query(
            `INSERT INTO Users (UserID, UserEmail, UserPassword, UserRole) VALUES (?, ?, ?, ?)`,
            [newOwnerID, UserEmail, hashedPassword, UserRole] 
        );

        await connection.query(
            `INSERT INTO Shop_Owners (OwnerID, OwnerName, OwnerPhone, OwnerAddress) VALUES (?, ?, ?, ?)`,
            [newOwnerID, OwnerName, OwnerPhone, OwnerAddress]
        );

        await connection.commit(); 
        
        await logUserActivity(newOwnerID, UserRole, 'Shop Owner Creation', `New Shop Owner account created: ${newOwnerID}`);

        res.status(201).json({ success: true, message: 'Shop Owner created successfully!', userId: newOwnerID });

    } catch (error) {
        await connection.rollback(); 
        console.error("Create owner error:", error);
        res.status(500).json({ error: "Server error while creating owner." });
    } finally {
        connection.release(); 
    }
});

// POST /api/users/staff
router.post("/staff", async (req, res) => {
    // 1. Validation: Added StaffRole to extraction
    const { ShopID, StaffName, StaffAge, StaffAddress, StaffCellNo, StaffSalary, StaffRole } = req.body;

    if (!ShopID || !StaffName || !StaffSalary) {
        return res.status(400).json({ error: "Missing required fields (ShopID, Name, or Salary)." });
    }

    const connection = await db.getConnection();
    
    try {
        await connection.beginTransaction();

        // ... [ID GENERATION LOGIC REMAINS THE SAME] ...
        const [lastStaff] = await connection.query(
            `SELECT StaffID FROM Staffs WHERE StaffID LIKE 'S%' ORDER BY CAST(SUBSTRING(StaffID, 2) AS UNSIGNED) DESC LIMIT 1`
        );
        let nextIdNumber = 1;
        if (lastStaff.length > 0) {
            const lastId = lastStaff[0].StaffID;
            nextIdNumber = parseInt(lastId.substring(1)) + 1;
        }
        const newStaffID = `S${nextIdNumber}`; 

        // ... [EMAIL GENERATION LOGIC REMAINS THE SAME] ...
        const cleanName = StaffName.split(' ')[0].toLowerCase().replace(/[^a-z0-9]/g, '');
        const [emailResult] = await connection.query(
            `SELECT UserEmail FROM Users WHERE UserEmail REGEXP ? ORDER BY LENGTH(UserEmail) DESC, UserEmail DESC LIMIT 1`,
            [`^${cleanName}[0-9]+$`]
        );
        let newEmailNumber = 1;
        if (emailResult.length > 0) {
            const match = emailResult[0].UserEmail.match(/\d+$/);
            if (match) newEmailNumber = parseInt(match[0], 10) + 1;
        }
        const newUserEmail = `${cleanName}${newEmailNumber}`; 
        const newUserPassword = newUserEmail; 
        const hashedPassword = await bcrypt.hash(newUserPassword, 10);

        // --- 4. INSERTION (UPDATED) ---

        // Update 1: Insert dynamic role into Users table
        await connection.query(
            `INSERT INTO Users (UserID, UserEmail, UserPassword, UserRole) VALUES (?, ?, ?, 'Staff')`,
            [newStaffID, newUserEmail, hashedPassword] 
        );

        // Update 2: Insert dynamic role into Staffs table
        await connection.query(
            `INSERT INTO Staffs (StaffID, StaffName, StaffRole, ShopID) VALUES (?, ?, ?, ?)`,
            [newStaffID, StaffName, StaffRole, ShopID]
        );

        await connection.query(
            `INSERT INTO Staff_Infos (StaffID, StaffAge, StaffAddress, StaffCellNo, StaffSalary) VALUES (?, ?, ?, ?, ?)`,
            [newStaffID, StaffAge, StaffAddress, StaffCellNo, StaffSalary]
        );

        await connection.commit();
        
        // Log activity with the specific role
        if (typeof logUserActivity === 'function') {
            await logUserActivity(newStaffID, StaffRole, 'Staff Creation', `New ${StaffRole}: ${StaffName}`);
        }

        res.status(201).json({ 
            success: true, 
            message: 'Staff member created successfully!', 
            staffId: newStaffID,
            generatedEmail: newUserEmail,
            role: StaffRole
        });

    } catch (error) {
        await connection.rollback();
        console.error("Create staff error:", error);
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: "Duplicate entry detected." });
        }
        res.status(500).json({ error: "Server error while creating staff member." });
    } finally {
        connection.release();
    }
});

// PUT /api/users/staff/:staffId (Update Staff Member)
router.put("/staff/:staffId", async (req, res) => {
    const { staffId } = req.params;
    const { StaffName, StaffAge, StaffAddress, StaffCellNo, StaffSalary } = req.body;
    const UserRole = 'Staff'; 

    const connection = await db.getConnection();
    try {
        await connection.beginTransaction();

        await connection.query(
            `UPDATE Staffs SET StaffName = ? WHERE StaffID = ?`,
            [StaffName, staffId]
        );

        await connection.query(
            `UPDATE Staff_Infos si SET si.StaffAge = ?, si.StaffAddress = ?, si.StaffCellNo = ?, si.StaffSalary = ? WHERE si.StaffID = ?`,
            [StaffAge, StaffAddress, StaffCellNo, StaffSalary, staffId]
        );

        await connection.commit();
        await logUserActivity(staffId, UserRole, 'Staff Update', `Staff member ${staffId} updated details`);
        res.json({ success: true, message: 'Staff member updated successfully.' });

    } catch (error) {
        await connection.rollback();
        console.error("Update staff error:", error);
        res.status(500).json({ error: "Server error while updating staff member." });
    } finally {
        connection.release();
    }
});

// POST /api/users/upload (Image Upload)
router.post("/upload", upload.single("file"), async (req, res) => {
    try {
        if (!req.file) return res.status(400).json({ success: false, message: "No file uploaded." }); 
        
        const b64 = Buffer.from(req.file.buffer).toString("base64");
        const dataURI = "data:" + req.file.mimetype + ";base64," + b64;
        const result = await cloudinary.uploader.upload(dataURI, { folder: "laundrolink_profiles" });
        
        res.json({ success: true, message: "Image uploaded successfully.", url: result.secure_url });
    } catch (error) {
        console.error("❌ Image upload error:", error);
        res.status(500).json({ success: false, message: "Failed to upload image." });
    }
});

// PUT /api/users/:UserID (Customer Profile Update)
router.put("/profile/:UserID", async (req, res) => {
    const connection = await db.getConnection();
    const { UserID } = req.params;
    
    try {
        await connection.beginTransaction();

        const { name, phone, address, picture } = req.body;
        
        const [userCheck] = await connection.query("SELECT UserRole FROM Users WHERE UserID = ?", [UserID]);
        if (userCheck.length === 0 || userCheck[0].UserRole !== 'Customer') {
             await connection.rollback();
             return res.status(403).json({ success: false, message: "Access denied." });
        }
        const UserRole = userCheck[0].UserRole;

        const customerFieldsToUpdate = [];
        const customerValues = [];

        if (name !== undefined) { customerFieldsToUpdate.push("CustName = ?"); customerValues.push(name); }
        if (phone !== undefined) { customerFieldsToUpdate.push("CustPhone = ?"); customerValues.push(phone); } 
        if (address !== undefined) { customerFieldsToUpdate.push("CustAddress = ?"); customerValues.push(address); } 

        if (customerFieldsToUpdate.length > 0) {
            customerValues.push(UserID);
            const sql = `UPDATE Customers SET ${customerFieldsToUpdate.join(", ")} WHERE CustID = ?`;
            await connection.query(sql, customerValues);
        }

        if (picture !== undefined) {
            await connection.query("UPDATE Cust_Credentials SET picture = ? WHERE CustID = ?", [picture, UserID]);
        }

        await connection.commit();
        await logUserActivity(UserID, UserRole, 'Profile Update', 'Customer updated profile');

        const [updatedUserRows] = await db.query(`
            SELECT u.UserID, u.UserEmail, u.UserRole, c.CustName AS name, c.CustPhone AS phone, c.CustAddress AS address, cc.picture
            FROM Users u JOIN Customers c ON u.UserID = c.CustID LEFT JOIN Cust_Credentials cc ON u.UserID = cc.CustID
            WHERE u.UserID = ?`, [UserID]
        );

        res.json({ success: true, message: "Profile updated.", user: updatedUserRows[0] });
    } catch (error) {
        await connection.rollback();
        console.error("❌ Profile update error:", error);
        res.status(500).json({ success: false, message: "Failed to update profile." });
    } finally {
        connection.release();
    }
});

// POST /api/users/set-password
router.post("/set-password", async (req, res) => {
    try {
        const { userId, newPassword } = req.body;
        if (!userId || !newPassword) return res.status(400).json({ success: false, message: "Missing fields." });
        
        const [userRows] = await db.query("SELECT UserRole FROM Users WHERE UserID = ?", [userId]);
        if (userRows.length === 0) return res.status(404).json({ success: false, message: "User not found." });
        
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await db.query("UPDATE Users SET UserPassword = ? WHERE UserID = ?", [hashedPassword, userId]);
        
        await logUserActivity(userId, userRows[0].UserRole, 'Password Change', 'User set/updated password');
        res.json({ success: true, message: "Password updated successfully." });
    } catch (error) {
        console.error("❌ Set password error:", error);
        res.status(500).json({ success: false, message: "Failed to update password." });
    }
});

export default router;
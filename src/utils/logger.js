// Backend/src/utils/logger.js

import db from '../db.js'; // Your database connection module (db.js is in src/ folder)

// =======================================================
// 1. Basic Console/Server Logging
// =======================================================

/**
 * Basic logger object for standard system messages (errors, warnings, info).
 * This typically logs to the console and/or a server log file.
 */
const systemLogger = {
    info: (message) => {
        console.log(`[INFO] [${new Date().toISOString()}] ${message}`);
    },
    warn: (message) => {
        console.warn(`[WARN] [${new Date().toISOString()}] ${message}`);
    },
    error: (message, error = null) => {
        console.error(`[ERROR] [${new Date().toISOString()}] ${message}`);
        if (error) {
            console.error(error);
        }
    }
};

// =======================================================
// 2. Database User Activity Logging
// =======================================================

/**
 * Logs an activity into the User_Logs table.
 * * NOTE: The 'export' keyword is removed here to prevent the 'Duplicate export' error.
 * The function is exported later in the block export statement.
 * * @param {string} UserID - The ID of the user performing the action.
 * @param {string} UserRole - The role of the user (e.g., 'Admin', 'Customer').
 * @param {string} UsrLogAction - The type of action (e.g., 'Login', 'Update', 'Delete').
 * @param {string} UsrLogDescrpt - A detailed description of the action.
 */
async function logUserActivity(UserID, UserRole, UsrLogAction, UsrLogDescrpt) {
    try {
        const sql = `
            INSERT INTO User_Logs (UserID, UserRole, UsrLogAction, UsrLogDescrpt)
            VALUES (?, ?, ?, ?);
        `;
        // Execute the insertion query, using the exported default pool (db)
        await db.query(sql, [UserID, UserRole, UsrLogAction, UsrLogDescrpt]);
        // systemLogger.info(`Activity logged for UserID ${UserID}: ${UsrLogAction}`);
    } catch (error) {
        systemLogger.error("CRITICAL: Failed to insert user log entry.", error);
    }
}


// Export both the user activity logger (default) and the generic system logger (named)
// This is the ONLY place 'logUserActivity' should be exported.
export { systemLogger as default, logUserActivity };
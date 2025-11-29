// src/utils/db-settings.js

import db from "../db.js"; // Import your existing database connection/pool

/**
 * Fetches the current Maintenance Mode status from the database.
 * @returns {Promise<boolean>} True if maintenance mode is enabled, false otherwise.
 */
export async function getMaintenanceStatus() {
    try {
        // Query the SystemConfig table for the MAINTENANCE_MODE key
        const [rows] = await db.query(
            "SELECT ConfigValue FROM SystemConfig WHERE ConfigKey = 'MAINTENANCE_MODE'"
        );
        
        // Check if a row was found and if its value is the string 'true'
        const config = rows[0];
        const isEnabled = config && config.ConfigValue === 'true';

        return isEnabled;
    } catch (error) {
        // Handle the error (e.g., if the table doesn't exist yet)
        console.error("Database query failed in getMaintenanceStatus:", error.message);
        // Default to safe mode (off) if the query fails
        return false; 
    }
}
//db.js
import mysql from "mysql2/promise";
import dotenv from "dotenv";
import { exec } from 'child_process';
import path from 'path'; // For path manipulation
import fs from 'fs';   // For file system operations (checking/creating directory)

// CORRECTED PATH: logger.js is inside the utils folder.
import systemLogger from "./utils/logger.js"; 

dotenv.config();

// Get DB credentials from environment variables
const DB_HOST = process.env.DB_HOST;
const DB_USER = process.env.DB_USER;
const DB_PASS = process.env.DB_PASSWORD;
const DB_NAME = process.env.DB_NAME;
const DB_PORT = process.env.DB_PORT || 3306;

// --- Backup Directory Setup ---
// Define a dedicated 'backups' folder relative to the project root (process.cwd())
export const BACKUP_DIR = path.join(process.cwd(), 'backups');

/**
 * Ensures the backup directory exists. Creates it if necessary.
 */
function ensureBackupDir() {
    if (!fs.existsSync(BACKUP_DIR)) {
        systemLogger.info(`Creating backup directory: ${BACKUP_DIR}`);
        fs.mkdirSync(BACKUP_DIR, { recursive: true });
    }
}
// --- END Backup Directory Setup ---

// Create the MySQL connection pool
const pool = mysql.createPool({
    host: DB_HOST,
    user: DB_USER,
    password: DB_PASS, 
    database: DB_NAME,
    port: DB_PORT,
    ssl: {
        rejectUnauthorized: true 
    }
});

/**
 * Executes a MySQL database backup using the mysqldump utility.
 * @returns {Promise<string>} - Resolves with the absolute path of the created backup file.
 */
async function runSystemBackup() {
    // 1. Ensure the directory exists before dumping
    ensureBackupDir(); 
    
    // 2. Generate unique filename
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupFileName = `${DB_NAME}_${timestamp}.sql`;
    const backupFilePath = path.join(BACKUP_DIR, backupFileName);

    // 3. Construct the mysqldump command
    // NOTE: The '-p' must be immediately followed by the password with NO SPACE.
    // --single-transaction and --skip-lock-tables are for consistent backups in InnoDB.
    const command = `mysqldump -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} ${DB_NAME} --single-transaction --skip-lock-tables > "${backupFilePath}"`;
    
    // Log the action (excluding the password)
    systemLogger.info(`Starting backup of ${DB_NAME} to ${backupFilePath}`);

    return new Promise((resolve, reject) => {
        exec(command, (error, stdout, stderr) => {
            if (error) {
                // Log and reject on critical command failure
                systemLogger.error(`mysqldump execution error: ${error.message}`);
                reject(new Error(`Backup failed: ${error.message}. Check that 'mysqldump' is in your system PATH.`));
                return;
            }
            if (stderr) {
                // Log stderr content as a warning (often warnings, not fatal errors)
                systemLogger.warn(`mysqldump warnings/stderr: ${stderr}`); 
            }
            // Resolve with the full path of the successful backup file
            resolve(backupFilePath); 
        });
    });
}

// Export the database pool as the default export (used for pool.query())
export default pool;

// Export the utility function and backup directory as named exports (used in admin.js)
export { runSystemBackup };
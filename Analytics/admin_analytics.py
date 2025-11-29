# admin_analytics.py
#!/usr/bin/env python
# coding: utf-8

import mysql.connector
import pandas as pd
import os # 🟢 Added os
from datetime import datetime, timedelta

# ========================
# 1️⃣ Database Connection
# ========================
# 🟢 MODIFIED: Use Environment Variables
db_config = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME", "laundrolink_db"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "ssl_disabled": True # or False depending on TiDB requirement, usually True is fine for basic connector
}

try:
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor(dictionary=True)
    print("✅ Connected to MySQL database.")
except mysql.connector.Error as err:
    print(f"❌ Database connection failed: {err}")
    exit()

# ===================================================================
# 2️⃣ Helper: Create Admin Analytics Tables
# ===================================================================
def create_admin_analytics_tables(cursor):
    """
    Checks for and creates the necessary platform-level analytics tables.
    """
    print("🔍 Checking and creating Admin analytics tables if needed...")
    
    # 1. Platform_Growth_Metrics: Tracks monthly shop and revenue growth
    create_growth_table = """
    CREATE TABLE IF NOT EXISTS Platform_Growth_Metrics (
        MonthYear CHAR(7) PRIMARY KEY, -- YYYY-MM
        NewShops INT DEFAULT 0,
        ChurnedShops INT DEFAULT 0, 
        TotalActiveShops INT,
        MonthlyRevenue DECIMAL(12, 2),
        AnalyzedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );
    """
    
    # 2. Service_Gap_Analysis: Identifies high-demand services not widely offered
    create_gap_table = """
    CREATE TABLE IF NOT EXISTS Service_Gap_Analysis (
        SvcName VARCHAR(50) PRIMARY KEY,
        PlatformOrderCount INT NOT NULL, 
        OfferingShopCount INT NOT NULL, 
        GapScore DECIMAL(10, 2), 
        AnalyzedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );
    """
    
    try:
        cursor.execute(create_growth_table)
        cursor.execute(create_gap_table)
        conn.commit()
        print("✅ Admin Analytics tables are ready.")
    except mysql.connector.Error as err:
        print(f"❌ Error creating Admin analytics tables: {err}")
        exit()

# ===================================================================
# 3️⃣ Analyze Service Gaps
# ===================================================================
def analyze_service_gaps(conn, cursor):
    print("📊 Running Service Gap Analysis...")

    # Step 1: Get total orders per service (Demand)
    # 🟢 FIXED: Join Laundry_Details because Orders table does NOT have SvcID
    demand_query = """
    SELECT 
        s.SvcName, COUNT(ld.LndryDtlID) AS PlatformOrderCount
    FROM Laundry_Details ld
    JOIN Services s ON ld.SvcID = s.SvcID
    GROUP BY s.SvcName;
    """
    demand_df = pd.read_sql(demand_query, conn)

    # Step 2: Get total count of shops offering each service (Supply)
    supply_query = """
    SELECT 
        s.SvcName, COUNT(ss.ShopID) AS OfferingShopCount
    FROM Shop_Services ss
    JOIN Services s ON ss.SvcID = s.SvcID
    GROUP BY s.SvcName;
    """
    supply_df = pd.read_sql(supply_query, conn)
    
    # Merge and calculate Gap Score (Demand / Supply)
    gap_df = pd.merge(demand_df, supply_df, on='SvcName', how='outer').fillna(0)
    
    # Calculate Gap Score: Normalize by demand. Prevent division by zero.
    gap_df['OfferingShopCount'] = gap_df['OfferingShopCount'].replace(0, 1) 
    gap_df['GapScore'] = (gap_df['PlatformOrderCount'] / gap_df['OfferingShopCount'])
    
    gap_df = gap_df.sort_values(by='GapScore', ascending=False)

    # Store in MySQL
    cursor.execute("TRUNCATE TABLE Service_Gap_Analysis;")
    for _, row in gap_df.iterrows():
        cursor.execute("""
            INSERT INTO Service_Gap_Analysis (SvcName, PlatformOrderCount, OfferingShopCount, GapScore)
            VALUES (%s, %s, %s, %s)
        """, (row['SvcName'], int(row['PlatformOrderCount']), int(row['OfferingShopCount']), row['GapScore']))

    conn.commit()
    print("✅ Service Gap Analysis updated successfully.")

# ===================================================================
# 4️⃣ Analyze Platform Growth and Churn
# ===================================================================
def analyze_platform_growth(conn, cursor):
    print("📈 Analyzing Platform Growth and Churn...")
    
    # --- 1. Monthly Revenue (Service + Delivery) ---
    # 🟢 FIXED: Summing Invoices AND Delivery_Payments
    revenue_query = """
    SELECT MonthYear, SUM(Amount) as MonthlyRevenue FROM (
        -- Service Revenue
        SELECT 
            DATE_FORMAT(StatusUpdatedAt, '%Y-%m') AS MonthYear, 
            PayAmount AS Amount
        FROM Invoices 
        WHERE PaymentStatus = 'Paid'
        
        UNION ALL
        
        -- Delivery Revenue
        SELECT 
            DATE_FORMAT(StatusUpdatedAt, '%Y-%m') AS MonthYear, 
            DlvryAmount AS Amount
        FROM Delivery_Payments
        WHERE DlvryPaymentStatus = 'Paid'
    ) as CombinedRevenue
    GROUP BY MonthYear
    ORDER BY MonthYear;
    """
    revenue_df = pd.read_sql(revenue_query, conn)
    
    # --- 2. Monthly New Shops ---
    shop_data_query = """
    SELECT 
        DATE_FORMAT(DateCreated, '%Y-%m') AS MonthYear
    FROM Laundry_Shops
    ORDER BY MonthYear;
    """
    shop_df = pd.read_sql(shop_data_query, conn)

    # Calculate New Shops per month
    new_shops_df = shop_df.groupby('MonthYear').size().reset_index(name='NewShops')
    
    # Merge all data
    growth_df = pd.merge(new_shops_df, revenue_df, on='MonthYear', how='outer').fillna(0)
    
    # --- 3. Calculate Cumulative Active Shops ---
    growth_df['TotalActiveShops'] = growth_df['NewShops'].cumsum()
    growth_df['ChurnedShops'] = 0 # Placeholder for churn logic if needed later

    # Store in MySQL
    cursor.execute("TRUNCATE TABLE Platform_Growth_Metrics;")
    for _, row in growth_df.iterrows():
        cursor.execute("""
            INSERT INTO Platform_Growth_Metrics (MonthYear, NewShops, ChurnedShops, TotalActiveShops, MonthlyRevenue)
            VALUES (%s, %s, %s, %s, %s)
        """, (row['MonthYear'], int(row['NewShops']), int(row['ChurnedShops']), int(row['TotalActiveShops']), float(row['MonthlyRevenue'])))
        
    conn.commit()
    print("✅ Platform Growth Metrics updated successfully.")

# ===================================================================
# 5️⃣ Main Execution
# ===================================================================
if __name__ == '__main__':
    create_admin_analytics_tables(cursor)
    analyze_service_gaps(conn, cursor)
    analyze_platform_growth(conn, cursor)

    cursor.close()
    conn.close()
    print("\n🎯 Admin data analytics processing complete! All platform metrics are live in MySQL.")
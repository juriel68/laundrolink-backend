# customer_segmentation.py
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
    print("✅ Connected to Database")
except mysql.connector.Error as err:
    print(f"❌ Error connecting to DB: {err}")
    exit()

# --- Fetch customer transaction data (Fixed for New Schema) ---
# We join Invoices to get the PayAmount. 
# We group by ShopID AND CustID to segment customers relative to specific shops.
query = """
SELECT 
    o.ShopID,
    o.CustID,
    COUNT(o.OrderID) AS frequency,
    COALESCE(SUM(i.PayAmount), 0) AS total_spent,
    MAX(o.OrderCreatedAt) AS last_order_date
FROM Orders o
JOIN Invoices i ON o.OrderID = i.OrderID
WHERE i.PaymentStatus = 'Paid'
GROUP BY o.ShopID, o.CustID;
"""

cursor.execute(query)
data = cursor.fetchall()

df = pd.DataFrame(data)

if df.empty:
    print("⚠️ No transaction data found. Ensure you have Orders with PAID Invoices.")
    # If empty, we still want to clear the table to avoid showing old/wrong data
    cursor.execute("TRUNCATE TABLE Customer_Segments")
    conn.commit()
    exit()

# --- Calculate Recency (days since last order) ---
df['last_order_date'] = pd.to_datetime(df['last_order_date'])
df['recency'] = (datetime.now() - df['last_order_date']).dt.days

# --- Rename columns for ML readability ---
df.rename(columns={
    'frequency': 'Frequency',
    'total_spent': 'Monetary',
    'recency': 'Recency'
}, inplace=True)

# --- Standardize numeric values ---
scaler = StandardScaler()
scaled_features = scaler.fit_transform(df[['Frequency', 'Monetary', 'Recency']])

# --- Perform KMeans clustering (4 segments) ---
# Note: If data points < 4, KMeans will fail. We add a check.
n_clusters = 4
if len(df) < n_clusters:
    n_clusters = len(df) # Reduce clusters if not enough data

kmeans = KMeans(n_clusters=n_clusters, random_state=42)
df['Segment'] = kmeans.fit_predict(scaled_features)

# --- Map cluster numbers to readable names ---
# In a production app, you assign names dynamically based on cluster centroids.
# Here we use a static map for simplicity, assuming standard distribution.
segment_map = {
    0: "Loyal Regulars",
    1: "High-Value Spenders",
    2: "New or Occasional",
    3: "At-Risk Customers"
}
# Handle cases where n_clusters < 4
df['SegmentName'] = df['Segment'].map(segment_map).fillna("General Customer")

# --- Save segmentation results to DB ---
print("💾 Saving analysis to database...")

cursor.execute("TRUNCATE TABLE Customer_Segments")
conn.commit()

insert_query = """
    INSERT INTO Customer_Segments (ShopID, CustID, SegmentName, TotalSpend, Frequency, Recency)
    VALUES (%s, %s, %s, %s, %s, %s)
"""

for _, row in df.iterrows():
    cursor.execute(insert_query, (
        int(row['ShopID']), 
        str(row['CustID']), # ✅ Key Fix: CustID is passed as String
        row['SegmentName'], 
        float(row['Monetary']), 
        int(row['Frequency']), 
        int(row['Recency'])
    ))

conn.commit()
cursor.close()
conn.close()

print(f"✅ Customer segmentation updated. Processed {len(df)} records.")
import express from "express";
import db from "../db.js";
import multer from 'multer';
import { cloudinary } from "../config/externalServices.js";

const router = express.Router();
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

// 🟢 OPTIMIZED: Use CASE WHEN for better SQL compatibility
const getPartnerIdSql = `CASE WHEN c.Participant1_ID = ? THEN c.Participant2_ID ELSE c.Participant1_ID END`;

router.get("/conversations/:userId", async (req, res) => {
    const { userId } = req.params;
    
    console.log(`[DEBUG] Received request for conversations. UserID: ${userId}`); 
    
    try {
        const query = `
            WITH Partner AS (
                SELECT
                    ${getPartnerIdSql} AS partnerId,
                    c.ConversationID,
                    c.UpdatedAt
                FROM Conversations c
                WHERE c.Participant1_ID = ? OR c.Participant2_ID = ?
            )
            SELECT
                p.ConversationID AS conversationId,
                p.UpdatedAt AS time,
                p.partnerId,
                
                -- 2. COALESCE Name
                COALESCE(
                    cu.CustName, 
                    st.StaffName,
                    so.OwnerName,
                    p.partnerId 
                ) AS name,

                -- 3. COALESCE Picture
                COALESCE(
                    ls.ShopImage_url, -- Shops/Owners usually want their shop logo
                    cc.picture,       -- Customers have Google profile pics
                    'https://placehold.co/40x40/d9edf7/004aad'
                ) AS partnerPicture,

                -- 4. Get the last message text or image
                (
                    SELECT 
                        CASE 
                            WHEN m.MessageText IS NOT NULL AND m.MessageText != '' THEN m.MessageText
                            WHEN m.MessageImage IS NOT NULL AND m.MessageImage != '' THEN '📷 Photo'
                            ELSE ''
                        END
                    FROM Messages m
                    WHERE m.ConversationID = p.ConversationID 
                    ORDER BY m.CreatedAt DESC 
                    LIMIT 1
                ) AS lastMessage,

                -- 5. Count unread messages
                (
                    SELECT COUNT(*) 
                    FROM Messages m 
                    WHERE m.ConversationID = p.ConversationID 
                        AND m.ReceiverID = ? AND m.MessageStatus = 'Delivered' -- 'Delivered' means not yet 'Read'
                ) AS unreadCount

            FROM Partner p

            LEFT JOIN Customers cu ON cu.CustID = p.partnerId
            LEFT JOIN Cust_Credentials cc ON cc.CustID = p.partnerId

            LEFT JOIN Staffs st ON st.StaffID = p.partnerId
            LEFT JOIN Shop_Owners so ON so.OwnerID = p.partnerId

            -- 🟢 FIX: Link to Laundry_Shops using the correct keys
            LEFT JOIN Laundry_Shops ls ON 
                ls.ShopID = st.ShopID 
                OR ls.OwnerID = p.partnerId
                
            ORDER BY p.UpdatedAt DESC;
        `;
        
        // Bindings: [userId (CASE), userId (WHERE P1), userId (WHERE P2), userId (Unread Count)]
        const cleanBindings = [
            userId, 
            userId, 
            userId, 
            userId, 
        ];

        const [conversations] = await db.query(query, cleanBindings);
        
        console.log(`[BACKEND] Found ${conversations.length} conversations for UserID: ${userId}`);

        res.json(conversations);
    } catch (error) {
        console.error("❌ FATAL SQL ERROR fetching conversations:", error);
        res.status(500).json({ error: "Failed to fetch conversations." });
    }
});

/**
 * Fetch message history for a conversation.
 */
router.get("/history/:conversationId", async (req, res) => {
  const { conversationId } = req.params;
  try {
    const query = `
      SELECT
        MessageID as id,
        ConversationID as conversationId,
        SenderID as senderId, 
        ReceiverID as receiverId, 
        MessageText as text, 
        MessageImage as image, 
        CreatedAt as time, 
        MessageStatus as status
      FROM Messages
      WHERE ConversationID = ?
      ORDER BY CreatedAt ASC;
    `;
    const [messages] = await db.query(query, [conversationId]);
    res.json(messages);
  } catch (error) {
    console.error("Error fetching message history:", error);
    res.status(500).json({ error: "Failed to fetch message history" });
  }
});

/**
 * POST /api/messages/upload-image - Uploads image proof and returns URL
 */
router.post("/upload-image", upload.single("file"), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ success: false, message: "No image file provided." });
    }
    
    try {
        const b64 = Buffer.from(req.file.buffer).toString("base64");
        const dataURI = "data:" + req.file.mimetype + ";base64," + b64;
        
        // Upload to Cloudinary
        const uploadResult = await cloudinary.uploader.upload(dataURI, { 
            folder: "laundrolink_chat_images"
        });

        res.json({ 
            success: true, 
            message: "Image uploaded successfully.",
            url: uploadResult.secure_url 
        });

    } catch (error) {
        console.error("Cloudinary chat image upload error:", error);
        res.status(500).json({ success: false, message: "Failed to upload image." });
    }
});


router.post("/", async (req, res) => {
  const { senderId, receiverId, text, image } = req.body;
  if (!senderId || !receiverId || (!text && !image)) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  const connection = await db.getConnection();
  try {
    await connection.beginTransaction();

    // Standardize participant order (lowest ID first) to match Unique Constraint
    const participant1 = senderId < receiverId ? senderId : receiverId;
    const participant2 = senderId < receiverId ? receiverId : senderId;

    // Step 1: Find or Create the Conversation
    let [[conversation]] = await connection.query(
      "SELECT ConversationID FROM Conversations WHERE Participant1_ID = ? AND Participant2_ID = ?",
      [participant1, participant2]
    );

    let conversationId;
    if (conversation) {
      conversationId = conversation.ConversationID;
    } else {
      // 💡 FIX: Let MySQL handle the ID (AUTO_INCREMENT)
      const [result] = await connection.query(
        "INSERT INTO Conversations (Participant1_ID, Participant2_ID, UpdatedAt) VALUES (?, ?, NOW())",
        [participant1, participant2]
      );
      conversationId = result.insertId;
    }

    // Step 2: Insert the new message (MessageID is AUTO_INCREMENT)
    const [msgResult] = await connection.query(
      `INSERT INTO Messages 
        (ConversationID, SenderID, ReceiverID, MessageText, MessageImage, CreatedAt, MessageStatus) 
        VALUES (?, ?, ?, ?, ?, NOW(), 'Sent')`,
      [conversationId, senderId, receiverId, text || null, image || null]
    );
    const newMessageId = msgResult.insertId;

    // Step 3: Update the conversation's timestamp
    await connection.query(
      "UPDATE Conversations SET UpdatedAt = NOW() WHERE ConversationID = ?",
      [conversationId]
    );

    await connection.commit();

    // Step 4: Return the newly created message
    const [[newMessage]] = await db.query("SELECT * FROM Messages WHERE MessageID = ?", [newMessageId]);
    res.status(201).json(newMessage);

  } catch (error) {
    await connection.rollback();
    console.error("Error sending message:", error);
    res.status(500).json({ error: "Failed to send message" });
  } finally {
    connection.release();
  }
});


/**
 * Mark messages in a conversation as read.
 */
router.patch("/read", async (req, res) => {
  const { conversationId, userId } = req.body; // userId is the person reading the messages
  if (!conversationId || !userId) {
    return res.status(400).json({ error: "Conversation ID and User ID are required" });
  }
  try {
    // If I am reading, update messages where ReceiverID = ME and Status = 'Sent'/'Delivered'
    await db.query(
      "UPDATE Messages SET MessageStatus = 'Read' WHERE ConversationID = ? AND ReceiverID = ? AND MessageStatus != 'Read'",
      [conversationId, userId]
    );
    res.status(200).json({ success: true, message: "Messages marked as read" });
  } catch (error) {
    console.error("Error marking messages as read:", error);
    res.status(500).json({ error: "Failed to update message status" });
  }
});


export default router;
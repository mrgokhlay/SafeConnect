const express = require("express");
const router = express.Router();
const admin = require("../firebase");

const db = admin.firestore();

router.post("/message-notification", async (req, res) => {
    try {
        const { receiverId, chatId, senderId } = req.body;

        if (!receiverId || !senderId || !chatId) {
            return res.status(400).json({
                success: false,
                error: "receiverId, senderId and chatId are required",
            });
        }

        // GET RECEIVER
        const userSnap = await db.collection("users").doc(receiverId).get();

        if (!userSnap.exists) {
            return res.status(404).json({ error: "User not found" });
        }

        const fcmToken = userSnap.data()?.fcmToken;

        if (!fcmToken) {
            return res.status(404).json({ error: "FCM token not found" });
        }

        // GET SENDER NAME
        const senderSnap = await db.collection("users").doc(senderId).get();
        const senderName =
            senderSnap.data()?.username ||
            senderSnap.data()?.displayName ||
            "Someone";

        // 🔥 GET UNREAD COUNT FROM CHAT
        const chatSnap = await db.collection("chats").doc(chatId).get();

        let unreadCount = 1;

        if (chatSnap.exists) {
            const data = chatSnap.data();
            const unreadMap = data?.unreadCount || {};
            unreadCount = unreadMap[receiverId] || 1;
        }

        const bodyText =
            unreadCount === 1
                ? "1 new message"
                : `${unreadCount} new messages`;

        const payload = {
            token: fcmToken,

            notification: {
                title: senderName,
                body: bodyText,
            },

            data: {
                chatId: chatId,
                senderId: senderId,
                type: "chat_message",
                unreadCount: String(unreadCount),
            },
        };

        await admin.messaging().send(payload);

        return res.status(200).json({
            success: true,
            message: "Notification sent successfully",
        });

    } catch (error) {
        console.error("FCM Error:", error);

        return res.status(500).json({
            success: false,
            error: error.message,
        });
    }
});
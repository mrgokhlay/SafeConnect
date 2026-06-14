const express = require("express");
const router = express.Router();
const admin = require("../firebase");

const db = admin.firestore();

router.post("/message-notification", async (req, res) => {
    try {
        const { receiverId, message, chatId, senderId } = req.body;

        if (!receiverId || !message) {
            return res.status(400).json({
                success: false,
                error: "receiverId and message are required",
            });
        }

        const userSnap = await db.collection("users").doc(receiverId).get();

        if (!userSnap.exists) {
            return res.status(404).json({
                success: false,
                error: "User not found",
            });
        }

        const fcmToken = userSnap.data()?.fcmToken;

        if (!fcmToken) {
            return res.status(404).json({
                success: false,
                error: "FCM token not found",
            });
        }

        const payload = {
            token: fcmToken,

            notification: {
                title: "New Message 💬",
                body: message,
            },

            data: {
                chatId: chatId || "",
                senderId: senderId || "",
                type: "chat_message",
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

module.exports = router;
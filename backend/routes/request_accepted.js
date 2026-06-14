const router = require("express").Router();
const admin = require("../firebase");
const db = admin.firestore();

router.post("/request-accepted", async (req, res) => {
    try {
        const { receiverId, username } = req.body;

        if (!receiverId || !username) {
            return res.status(400).json({
                success: false,
                error: "receiverId and username are required",
            });
        }

        const userSnap = await db.collection("users").doc(receiverId).get();

        if (!userSnap.exists) {
            return res.status(404).json({
                success: false,
                error: "User not found",
            });
        }

        const token = userSnap.data()?.fcmToken;

        if (!token) {
            return res.status(404).json({
                success: false,
                error: "FCM token not found",
            });
        }

        await admin.messaging().send({
            token,
            notification: {
                title: "Request Accepted 🎉",
                body: `${username} accepted your request`,
            },
            data: {
                type: "request_accepted",
            },
        });

        return res.status(200).json({ success: true });

    } catch (e) {
        console.error("Request Accepted Error:", e);

        return res.status(500).json({
            success: false,
            error: e.message,
        });
    }
});

module.exports = router;
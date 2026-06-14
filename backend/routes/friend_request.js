router.post("/friend-request", async (req, res) => {
    try {
        const { receiverId, senderName } = req.body;

        // 1. Validate input
        if (!receiverId || !senderName) {
            return res.status(400).json({
                success: false,
                error: "receiverId and senderName are required",
            });
        }

        // 2. Get user
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

        // 3. Send notification
        await admin.messaging().send({
            token,
            notification: {
                title: "New Friend Request 👋",
                body: `${senderName} sent you a friend request`,
            },
            data: {
                type: "friend_request",
            },
        });

        return res.status(200).json({
            success: true,
        });

    } catch (e) {
        console.error("Friend Request Error:", e);

        return res.status(500).json({
            success: false,
            error: e.message,
        });
    }
});
const express = require("express");
const cors = require("cors");
const admin = require("./firebase");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

// Health check
app.get("/", (req, res) => {
    res.send("SafeConnect Notification Server Running 🚀");
});

// Send notification
app.post("/sendNotification", async (req, res) => {
    try {
        const { token, title, body } = req.body;

        const message = {
            token,
            notification: {
                title,
                body,
            },
        };

        const response = await admin.messaging().send(message);

        res.json({ success: true, response });
    } catch (error) {
        res.json({ success: false, error: error.message });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log("Server running on port", PORT);
});
const express = require("express");
const cors = require("cors");
require("dotenv").config();

const admin = require("./firebase");

// Routes
const messageNotification = require("./routes/messageNotification");
const friendRequest = require("./routes/friend_request");
const requestAccepted = require("./routes/request_accepted");

const app = express();

app.use(cors());
app.use(express.json());

// =====================
// Health check
// =====================
app.get("/", (req, res) => {
    res.send("SafeConnect Notification Server Running 🚀");
});

// =====================
// Routes
// =====================
app.use("/", messageNotification);
app.use("/", friendRequest);
app.use("/", requestAccepted);

// =====================
// Start server
// =====================
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log("Server running on port", PORT);
});
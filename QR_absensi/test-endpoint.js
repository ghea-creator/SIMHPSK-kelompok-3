const express = require('express');
const app = express();

// Middleware dummy
const verifyToken = (req, res, next) => next();
const checkDbReady = (req, res, next) => next();

// Test endpoint
app.get("/ketidakhadiran", verifyToken, checkDbReady, async (req, res) => {
  try {
    res.json({ message: "Endpoint ketidakhadiran works!" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Test endpoint 2
app.get("/test", (req, res) => {
  res.json({ message: "Test works!" });
});

app.listen(3000, () => {
  console.log("Test server started on port 3000");
});

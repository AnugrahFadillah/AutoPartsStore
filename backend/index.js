const express = require("express");
const cors = require("cors");
const db = require("./models");

const sparepartRoutes = require("./routes/sparepart_route");
const bengkelRoutes = require("./routes/bengkel_route");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Routes
app.use("/api/spareparts", sparepartRoutes);
app.use("/api/bengkels", bengkelRoutes);

// Test endpoint
app.get("/", (req, res) => {
  res.send("API Bengkel & Sparepart ready 🚀");
});

// Sync & start server
db.sequelize.sync({ alter: true }) // agar update field tanpa drop
  .then(() => {
    console.log("Database synced.");
    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  })
  .catch(err => {
    console.error("Failed to sync db:", err);
  });

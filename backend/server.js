const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const dotenv = require("dotenv");
const path = require("path");

// Load environment variables BEFORE importing any routes/config that read them
// Try local .env first, then fallback to repo root .env
dotenv.config({ path: path.resolve(__dirname, ".env") });
dotenv.config({ path: path.resolve(__dirname, "../.env") });

const authRoutes = require("./routes/auth");
const prescriptionRoutes = require("./routes/Prescription");
const medicineRoutes = require("./routes/medicine"); // 👈 change to require
const deliveryRoutes = require("./routes/delivery");
const pharmacyRoutes = require("./routes/pharmacy");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/prescriptions", prescriptionRoutes);
app.use("/api/medicines", medicineRoutes);
app.use("/api/delivery", deliveryRoutes);
app.use("/api/pharmacies", pharmacyRoutes);

// Connect MongoDB - Use same database as web server
const mongoUri = process.env.MONGO_URI || "mongodb+srv://CureCart:Pramod@1997@curecart.ce760px.mongodb.net/?retryWrites=true&w=majority";
const dbName = process.env.MONGODB_DB || "curecart";

mongoose
  .connect(mongoUri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
    dbName: dbName
  })
  .then(() => console.log(`✅ MongoDB Connected to database: ${dbName}`))
  .catch((err) => console.error("❌ MongoDB Error:", err));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));

// models/User.js
const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String },
    role: { type: String, enum: ["patient", "pharmacist", "delivery"], required: true },
    address: String,
    dob: String,
    password: { type: String, required: true },
    pharmacyName: String, // only used if role = pharmacist
    // Delivery partner specific fields
    vehicleType: { type: String, enum: ["bike", "car", "van", "other"], default: "bike" },
    vehicleNumber: String,
    nic: String,
    emergencyContactName: String,
    emergencyContactPhone: String,
  },
  { timestamps: true }
);

module.exports = mongoose.models["User"] || mongoose.model("User", userSchema);

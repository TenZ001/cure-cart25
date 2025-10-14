// models/Patient.js
const mongoose = require("mongoose");

const patientSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String },
    role: { type: String, default: "patient" },
    address: { type: String },
    dob: { type: String },
    password: { type: String, required: true },
  },
  { timestamps: true }
);

module.exports = mongoose.models["Patient"] || mongoose.model("Patient", patientSchema);

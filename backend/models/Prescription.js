// models/Prescription.js
const mongoose = require("mongoose");

const prescriptionSchema = new mongoose.Schema(
  {
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    imageUrl: { type: String, required: true },
    notes: { type: String },
    pharmacyId: { type: mongoose.Schema.Types.ObjectId, ref: "Pharmacy" },
    customerAddress: { type: String },
    customerPhone: { type: String },
    customerAge: { type: Number },
    customerGender: { type: String },
    paymentMethod: { type: String },
    status: { 
      type: String, 
      enum: ['pending', 'approved', 'rejected', 'ordered'], 
      default: 'pending' 
    },
  },
  { timestamps: true }
);

module.exports = mongoose.models["Prescription"] || mongoose.model("Prescription", prescriptionSchema);

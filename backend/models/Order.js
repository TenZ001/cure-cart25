// models/Order.js
const mongoose = require("mongoose");

const deliveryStatusEnum = ["assigned", "picked_up", "en_route", "out_for_delivery", "delivered"];

const orderSchema = new mongoose.Schema(
  {
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: "user", required: true },
    deliveryPartnerId: { type: mongoose.Schema.Types.ObjectId, ref: "user" },
    pharmacy: String,
    pharmacyId: { type: mongoose.Schema.Types.ObjectId, ref: "pharmacy" }, // Added pharmacy reference
    address: String,
    paymentMethod: { type: String, default: "cash" }, // Added payment method
    total: { type: Number, default: 0 }, // Added total amount

    // Location sharing
    customerLat: Number,
    customerLng: Number,
    deliveryLat: Number,
    deliveryLng: Number,

    // Status
    status: { type: String, enum: deliveryStatusEnum, default: "assigned" },
    delivered: { type: Boolean, default: false }, // Track if order has been delivered
    deliveredAt: { type: Date }, // When the order was delivered
    pickedUp: { type: Boolean, default: false }, // Track if order has been picked up
    pickedUpAt: { type: Date }, // When the order was picked up
    paymentStatus: { type: String, default: "unpaid" }, // Payment status
    deliveryStatusHistory: [
      {
        status: { type: String, enum: deliveryStatusEnum },
        at: { type: Date, default: Date.now },
      },
    ],

    // Minimal items info
    items: [
      {
        name: String,
        qty: Number,
        price: { type: Number, default: 0 }, // Added price for items
      },
    ],
    
    // Delivery partner info (for easier access)
    deliveryPartnerName: { type: String },
    deliveryPartnerPhone: { type: String },
    
    // Tracking info
    tracking: {
      lat: { type: Number },
      lng: { type: Number },
      lastUpdatedAt: { type: Date },
      pickedUpAt: { type: Date },
      pickedUpBy: { type: mongoose.Schema.Types.ObjectId, ref: "user" },
      deliveredAt: { type: Date },
      deliveredBy: { type: mongoose.Schema.Types.ObjectId, ref: "user" },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.models["Order"] || mongoose.model("Order", orderSchema);



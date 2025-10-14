const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    items: [
      {
        medicineId: { type: mongoose.Schema.Types.ObjectId, ref: 'Medicine' }, // Made optional for checkout orders
        quantity: { type: Number, required: true },
        price: { type: Number, required: true },
        name: { type: String } // Store medicine name for checkout orders
      }
    ],
    total: { type: Number, required: true },
    status: { type: String, enum: ['pending', 'processing', 'dispatched', 'out_for_delivery', 'delivered', 'cancelled'], default: 'pending' },
    deliveryPartnerId: { type: mongoose.Schema.Types.ObjectId, ref: 'DeliveryPartner' },
    deliveryPartnerName: { type: String }, // Store partner name directly
    deliveryPartnerPhone: { type: String }, // Store partner phone directly
    pharmacyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pharmacy' }, // Added pharmacy reference
    pharmacy: { type: String }, // Added pharmacy name for easier matching
    pharmacyAddress: { type: String }, // Added pharmacy address for delivery reference
    address: { type: String }, // Added delivery address
    paymentMethod: { type: String, default: 'cash' }, // Added payment method
    pickedUp: { type: Boolean, default: false }, // Track if order has been picked up
    pickedUpAt: { type: Date }, // When the order was picked up
    delivered: { type: Boolean, default: false }, // Track if order has been delivered
    deliveredAt: { type: Date }, // When the order was delivered
    tracking: {
      lat: { type: Number },
      lng: { type: Number },
    lastUpdatedAt: { type: Date },
    pickedUpAt: { type: Date },
    pickedUpBy: { type: mongoose.Schema.Types.ObjectId, ref: 'DeliveryPartner' },
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Order', orderSchema);

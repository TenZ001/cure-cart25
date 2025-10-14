const mongoose = require('mongoose');

const deliveryPartnerSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    contact: { type: String },
    vehicleNo: { type: String },
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    nic: { type: String },
    licenseNumber: { type: String },
    status: { type: String, enum: ['pending','approved','rejected'], default: 'pending' },
    active: { type: Boolean, default: true },
    assignedOrders: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Order' }],
  },
  { timestamps: true }
);

module.exports = mongoose.model('DeliveryPartner', deliveryPartnerSchema);



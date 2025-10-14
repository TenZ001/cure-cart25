const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['low_stock', 'expired', 'near_expiry', 'new_order', 'urgent', 'system', 'message'], required: true },
    title: { type: String, required: true },
    body: { type: String },
    data: { type: Object },
    read: { type: Boolean, default: false },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);









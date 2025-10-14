const mongoose = require('mongoose');

const invoiceSchema = new mongoose.Schema(
  {
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order', required: true },
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    amount: { type: Number, required: true },
    paymentMethod: { type: String, enum: ['cash', 'card', 'insurance'], default: 'cash' },
    tax: { type: Number, default: 0 },
    discount: { type: Number, default: 0 },
    status: { type: String, enum: ['paid', 'unpaid', 'partial'], default: 'unpaid' },
    metadata: { type: Object },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Invoice', invoiceSchema);









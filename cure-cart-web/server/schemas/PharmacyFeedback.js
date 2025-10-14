const mongoose = require('mongoose');

const pharmacyFeedbackSchema = new mongoose.Schema(
  {
    pharmacyId: { type: mongoose.Schema.Types.ObjectId, ref: 'Pharmacy', required: true },
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false }, // Make optional for anonymous feedback
    rating: { type: Number, min: 1, max: 5, required: true },
    comment: { type: String, maxlength: 500 },
    hidden: { type: Boolean, default: false },
    // Add customer info for easier display
    customerName: { type: String },
    customerEmail: { type: String },
  },
  { timestamps: true }
);

// Index for efficient queries
pharmacyFeedbackSchema.index({ pharmacyId: 1, createdAt: -1 });
pharmacyFeedbackSchema.index({ customerId: 1, pharmacyId: 1 });

module.exports = mongoose.model('PharmacyFeedback', pharmacyFeedbackSchema);

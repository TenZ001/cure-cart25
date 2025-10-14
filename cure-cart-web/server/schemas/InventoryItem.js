const mongoose = require('mongoose');

const inventoryItemSchema = new mongoose.Schema(
  {
    medicineId: { type: String, unique: true, sparse: true },
    sku: { type: String },
    batchNo: { type: String },
    name: { type: String, required: true },
    category: { type: String, enum: ['Pain Relief', 'Antibiotics', 'Cardiovascular', 'Diabetes', 'Respiratory', 'Digestive', 'Vitamins', 'Skin Care', 'Eye Care', 'Other'], default: 'Other' },
    stock: { type: Number, default: 0 },
    lowStockThreshold: { type: Number, default: 5 },
    expiryDate: { type: Date },
    supplierName: { type: String },
    supplierContact: { type: String },
    purchasePrice: { type: Number, default: 0 },
    sellingPrice: { type: Number, default: 0 },
    discount: { type: Number, default: 0 },
    price: { type: Number, default: 0 },
    available: { type: Boolean, default: true },
    ownerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', index: true },
  },
  { timestamps: true }
);

// Generate unique medicine ID before saving (for new items or items without medicineId)
inventoryItemSchema.pre('save', function(next) {
  if (!this.medicineId) {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substr(2, 5);
    this.medicineId = `MED-${timestamp}-${random}`.toUpperCase();
  }
  next();
});

module.exports = mongoose.model('InventoryItem', inventoryItemSchema);



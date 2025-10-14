const mongoose = require('mongoose');

const prescriptionSchema = new mongoose.Schema(
  {
    customerId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      required: true 
    },
    imageUrl: { 
      type: String, 
      required: true 
    },
    pharmacyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Pharmacy',
    },
    pharmacyName: { type: String },
    pharmacyAddress: { type: String },
    pharmacyContact: { type: String },
    customerAddress: { type: String },
    customerPhone: { type: String },
    customerAge: { type: Number },
    customerGender: { type: String },
    paymentMethod: { type: String },
    orderId: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
    status: { 
      type: String, 
      enum: ['pending', 'approved', 'rejected', 'ordered'], 
      default: 'pending' 
    },
    notes: { 
      type: String 
    },
    patientName: { 
      type: String 
    },
    patientId: { 
      type: String 
    },
    doctorName: { 
      type: String 
    },
    doctorLicense: { 
      type: String 
    },
    medicines: [
      {
        name: { type: String },
        dosage: { type: String },
        duration: { type: String },
      },
    ],
    issuedAt: { 
      type: Date, 
      default: Date.now 
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Prescription', prescriptionSchema);

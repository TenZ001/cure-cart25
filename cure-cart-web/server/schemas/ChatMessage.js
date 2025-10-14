const mongoose = require('mongoose');

const chatMessageSchema = new mongoose.Schema(
  {
    pharmacyId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'Pharmacy', 
      required: true 
    },
    senderId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      required: true 
    },
    senderName: { 
      type: String, 
      required: true 
    },
    senderType: { 
      type: String, 
      enum: ['patient', 'pharmacist'], 
      required: true 
    },
    recipientId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User' 
    },
    recipientName: { 
      type: String 
    },
    message: { 
      type: String, 
      required: true,
      maxlength: 1000 
    },
    isRead: { 
      type: Boolean, 
      default: false 
    },
    readAt: { 
      type: Date 
    },
  },
  { timestamps: true }
);

// Index for efficient querying
chatMessageSchema.index({ pharmacyId: 1, createdAt: -1 });
chatMessageSchema.index({ senderId: 1, createdAt: -1 });

module.exports = mongoose.model('ChatMessage', chatMessageSchema);

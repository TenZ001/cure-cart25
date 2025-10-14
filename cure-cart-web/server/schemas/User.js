const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    password: { type: String, required: true },
    phone: { type: String },
    role: { type: String, enum: ['patient', 'delivery', 'pharmacist', 'admin'], default: 'patient' },
    employeeId: { type: String },
    branch: { type: String },
    gender: { type: String, enum: ['male', 'female', 'other'], required: false },
    age: { type: Number },
    address: { type: String },
    qualifications: { type: String },
    licenseNumber: { type: String },
    shiftTimings: { type: String },
    lastLoginAt: { type: Date },
    rewardPoints: { type: Number, default: 0 },
    dues: { type: Number, default: 0 },
    avatarUrl: { type: String },
    avatar: { type: Buffer },
    avatarMimeType: { type: String },
    status: { type: String, enum: ['active','suspended'], default: 'active' },
    kyc: {
      verified: { type: Boolean, default: false },
      documentType: { type: String },
      documentUrl: { type: String },
      verifiedAt: { type: Date },
    },
    passwordReset: {
      otp: { type: String },
      otpExpires: { type: Date },
      otpAttempts: { type: Number, default: 0 },
      lastAttemptTime: { type: Date },
    },
  },
  { timestamps: true }
);

// Ensure email is stored lowercase
userSchema.pre('save', function(next) {
  if (this.isModified('email') && typeof this.email === 'string') {
    this.email = this.email.trim().toLowerCase();
  }
  if (this.isModified('name') && typeof this.name === 'string') {
    this.name = this.name.trim();
  }
  next();
});

module.exports = mongoose.model('User', userSchema);



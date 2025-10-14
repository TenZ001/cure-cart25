// Script to create a test pharmacist account
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// User schema (simplified)
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['patient', 'delivery', 'pharmacist', 'admin'], default: 'patient' },
  status: { type: String, enum: ['active', 'suspended'], default: 'active' }
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

const createTestUser = async () => {
  try {
    // Connect to MongoDB
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/curecart';
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');

    // Check if test pharmacist exists
    const existingPharmacist = await User.findOne({ email: 'pharmacist@example.com' });
    if (existingPharmacist) {
      console.log('✅ Test pharmacist already exists:', existingPharmacist.email);
      return;
    }

    // Create test pharmacist
    const hashedPassword = await bcrypt.hash('password123', 10);
    const pharmacist = await User.create({
      name: 'Test Pharmacist',
      email: 'pharmacist@example.com',
      password: hashedPassword,
      role: 'pharmacist',
      status: 'active'
    });

    console.log('✅ Test pharmacist created:', {
      id: pharmacist._id,
      email: pharmacist.email,
      role: pharmacist.role
    });

    // Create test admin
    const existingAdmin = await User.findOne({ email: 'admin@example.com' });
    if (!existingAdmin) {
      const admin = await User.create({
        name: 'Test Admin',
        email: 'admin@example.com',
        password: hashedPassword,
        role: 'admin',
        status: 'active'
      });
      console.log('✅ Test admin created:', {
        id: admin._id,
        email: admin.email,
        role: admin.role
      });
    }

  } catch (error) {
    console.error('❌ Error creating test user:', error);
  } finally {
    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
  }
};

createTestUser();

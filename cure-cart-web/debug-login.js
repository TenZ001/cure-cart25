// Debug login issues
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// User schema
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['patient', 'delivery', 'pharmacist', 'admin'], default: 'patient' },
  status: { type: String, enum: ['active', 'suspended'], default: 'active' }
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

const debugLogin = async () => {
  try {
    // Connect to MongoDB
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/curecart';
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');

    // Find the test user
    const user = await User.findOne({ email: 'pharmacist@example.com' });
    console.log('🔍 User found:', {
      exists: !!user,
      email: user?.email,
      role: user?.role,
      status: user?.status,
      hasPassword: !!user?.password
    });

    if (user) {
      // Test password
      const testPassword = 'password123';
      const isMatch = await bcrypt.compare(testPassword, user.password);
      console.log('🔍 Password test:', {
        testPassword,
        isMatch,
        storedPassword: user.password.substring(0, 10) + '...'
      });

      // Test with different password
      const testPassword2 = 'password';
      const isMatch2 = await bcrypt.compare(testPassword2, user.password);
      console.log('🔍 Password test 2:', {
        testPassword: testPassword2,
        isMatch: isMatch2
      });
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
  }
};

debugLogin();

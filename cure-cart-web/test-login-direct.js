// Test login endpoint directly
const axios = require('axios');

const testLogin = async () => {
  try {
    console.log('🔍 Testing login endpoint...');
    
    const response = await axios.post('http://localhost:4000/api/auth/login', {
      email: 'pharmacist@example.com',
      password: 'password123'
    });
    
    console.log('✅ Login successful:', {
      status: response.status,
      hasToken: !!response.data.token,
      user: response.data.user
    });
    
  } catch (error) {
    console.error('❌ Login failed:', {
      status: error.response?.status,
      data: error.response?.data,
      message: error.message
    });
  }
};

testLogin();

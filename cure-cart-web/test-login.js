// Simple test script to debug login issues
const axios = require('axios');

const testLogin = async () => {
  try {
    console.log('🔍 Testing login...');
    
    // Test with a sample pharmacist account
    const response = await axios.post('http://localhost:4000/api/auth/login', {
      email: 'pharmacist@example.com',
      password: 'password123'
    });
    
    console.log('✅ Login successful:', {
      hasToken: !!response.data.token,
      user: response.data.user
    });
    
    // Test /me endpoint
    const token = response.data.token;
    const meResponse = await axios.get('http://localhost:4000/api/auth/me', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    
    console.log('✅ /me endpoint successful:', meResponse.data);
    
  } catch (error) {
    console.error('❌ Login test failed:', {
      status: error.response?.status,
      data: error.response?.data,
      message: error.message
    });
  }
};

// Test with different credentials
const testWithCredentials = async (email, password) => {
  try {
    console.log(`🔍 Testing login with ${email}...`);
    
    const response = await axios.post('http://localhost:4000/api/auth/login', {
      email,
      password
    });
    
    console.log('✅ Login successful:', {
      email,
      hasToken: !!response.data.token,
      user: response.data.user
    });
    
  } catch (error) {
    console.error(`❌ Login failed for ${email}:`, {
      status: error.response?.status,
      data: error.response?.data
    });
  }
};

// Run tests
const runTests = async () => {
  console.log('🚀 Starting login tests...\n');
  
  // Test with common credentials
  await testWithCredentials('pharmacist@example.com', 'password123');
  await testWithCredentials('admin@example.com', 'password123');
  await testWithCredentials('test@example.com', 'password123');
  
  console.log('\n✅ Tests completed');
};

runTests();

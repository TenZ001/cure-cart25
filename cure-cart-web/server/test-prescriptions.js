// Simple test script to check prescription endpoints
const axios = require('axios');

const BASE_URL = 'http://localhost:4000';

async function testPrescriptionEndpoints() {
  console.log('🧪 Testing prescription endpoints...');
  
  try {
    // Test 1: Check if server is running
    console.log('\n1. Testing server health...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Server is running:', healthResponse.data);
    
    // Test 2: Test prescription endpoint without auth
    console.log('\n2. Testing prescription endpoint without auth...');
    try {
      const prescriptionsResponse = await axios.get(`${BASE_URL}/api/prescriptions`);
      console.log('✅ Prescriptions endpoint accessible:', prescriptionsResponse.data.length, 'prescriptions');
    } catch (error) {
      console.log('❌ Prescriptions endpoint error:', error.response?.data || error.message);
    }
    
    // Test 3: Test prescription endpoint with status filter
    console.log('\n3. Testing prescription endpoint with status filter...');
    try {
      const pendingResponse = await axios.get(`${BASE_URL}/api/prescriptions?status=pending`);
      console.log('✅ Pending prescriptions:', pendingResponse.data.length);
    } catch (error) {
      console.log('❌ Pending prescriptions error:', error.response?.data || error.message);
    }
    
    // Test 4: Test debug endpoint
    console.log('\n4. Testing debug endpoint...');
    try {
      const debugResponse = await axios.get(`${BASE_URL}/api/prescriptions/test`);
      console.log('✅ Debug endpoint working:', debugResponse.data);
    } catch (error) {
      console.log('❌ Debug endpoint error:', error.response?.data || error.message);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
testPrescriptionEndpoints();

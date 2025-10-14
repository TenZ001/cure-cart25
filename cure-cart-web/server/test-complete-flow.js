// Complete test of prescription upload flow
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:4000';

async function testCompleteFlow() {
  console.log('🧪 Testing complete prescription upload flow...');
  
  try {
    // Test 1: Check server health
    console.log('\n1. Testing server health...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Server is running:', healthResponse.data);
    
    // Test 2: Check if we can access prescription endpoints
    console.log('\n2. Testing prescription endpoints...');
    try {
      const allPrescriptions = await axios.get(`${BASE_URL}/api/prescriptions/all`);
      console.log('✅ All prescriptions endpoint:', allPrescriptions.data.count, 'prescriptions');
      
      if (allPrescriptions.data.prescriptions.length > 0) {
        console.log('📋 Recent prescriptions:');
        allPrescriptions.data.prescriptions.slice(0, 3).forEach(p => {
          console.log(`  - ID: ${p.id}, Pharmacy: ${p.pharmacyName || 'None'}, Status: ${p.status}`);
        });
      }
    } catch (error) {
      console.log('❌ All prescriptions error:', error.response?.data || error.message);
    }
    
    // Test 3: Test prescription upload (simulate mobile app)
    console.log('\n3. Testing prescription upload...');
    try {
      // Create a test image file
      const testImagePath = path.join(__dirname, 'test-image.txt');
      fs.writeFileSync(testImagePath, 'test image content');
      
      const formData = new FormData();
      formData.append('customerId', 'test-customer-id');
      formData.append('pharmacyId', 'test-pharmacy-id');
      formData.append('notes', 'Test prescription upload');
      formData.append('image', fs.createReadStream(testImagePath));
      
      const uploadResponse = await axios.post(`${BASE_URL}/api/prescriptions`, formData, {
        headers: {
          ...formData.getHeaders(),
          'Content-Type': 'multipart/form-data'
        }
      });
      
      console.log('✅ Prescription upload successful:', uploadResponse.data);
      
      // Clean up test file
      fs.unlinkSync(testImagePath);
      
    } catch (error) {
      console.log('❌ Prescription upload error:', error.response?.data || error.message);
    }
    
    // Test 4: Test prescription retrieval with different filters
    console.log('\n4. Testing prescription retrieval...');
    try {
      const pendingResponse = await axios.get(`${BASE_URL}/api/prescriptions?status=pending`);
      console.log('✅ Pending prescriptions:', pendingResponse.data.length);
      
      const allResponse = await axios.get(`${BASE_URL}/api/prescriptions`);
      console.log('✅ All prescriptions (no filter):', allResponse.data.length);
      
    } catch (error) {
      console.log('❌ Prescription retrieval error:', error.response?.data || error.message);
    }
    
    // Test 5: Test debug endpoints
    console.log('\n5. Testing debug endpoints...');
    try {
      const testResponse = await axios.get(`${BASE_URL}/api/prescriptions/test`);
      console.log('✅ Test endpoint working:', testResponse.data.message);
      console.log('📊 Test data:', {
        user: testResponse.data.user,
        allPrescriptions: testResponse.data.allPrescriptions,
        filteredPrescriptions: testResponse.data.filteredPrescriptions
      });
    } catch (error) {
      console.log('❌ Test endpoint error:', error.response?.data || error.message);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
testCompleteFlow();

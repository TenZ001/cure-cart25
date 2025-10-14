// Test prescription upload
const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:4000';

async function testUpload() {
  console.log('🧪 Testing prescription upload...');
  
  try {
    // Create a test image file
    const testImagePath = path.join(__dirname, 'test-image.txt');
    fs.writeFileSync(testImagePath, 'test image content for prescription');
    
    const formData = new FormData();
    formData.append('customerId', 'test-customer-123');
    formData.append('pharmacyId', 'test-pharmacy-456');
    formData.append('notes', 'Test prescription upload with pharmacyId');
    formData.append('image', fs.createReadStream(testImagePath));
    
    console.log('📤 Uploading prescription...');
    const uploadResponse = await axios.post(`${BASE_URL}/api/prescriptions`, formData, {
      headers: {
        ...formData.getHeaders(),
        'Content-Type': 'multipart/form-data'
      }
    });
    
    console.log('✅ Upload successful:', uploadResponse.data);
    
    // Check if prescription was saved with pharmacyId
    console.log('\n📋 Checking saved prescription...');
    const allResponse = await axios.get(`${BASE_URL}/api/prescriptions/all`);
    const latestPrescription = allResponse.data.prescriptions[0];
    
    console.log('📊 Latest prescription:', {
      id: latestPrescription.id,
      pharmacyId: latestPrescription.pharmacyId,
      pharmacyName: latestPrescription.pharmacyName,
      status: latestPrescription.status
    });
    
    // Clean up test file
    fs.unlinkSync(testImagePath);
    
  } catch (error) {
    console.error('❌ Upload failed:', error.response?.data || error.message);
  }
}

testUpload();

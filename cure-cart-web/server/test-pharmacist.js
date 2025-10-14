// Test pharmacist prescription filtering
const axios = require('axios');

const BASE_URL = 'http://localhost:4000';

async function testPharmacistFlow() {
  console.log('🧪 Testing pharmacist prescription flow...');
  
  try {
    // Test 1: Check all prescriptions
    console.log('\n1. Checking all prescriptions...');
    const allResponse = await axios.get(`${BASE_URL}/api/prescriptions/all`);
    console.log('📋 Total prescriptions:', allResponse.data.count);
    
    if (allResponse.data.prescriptions.length > 0) {
      console.log('📊 Recent prescriptions:');
      allResponse.data.prescriptions.slice(0, 3).forEach(p => {
        console.log(`  - ID: ${p.id}, Pharmacy: ${p.pharmacyId || 'None'}, Status: ${p.status}`);
      });
    }
    
    // Test 2: Check prescription endpoint without auth
    console.log('\n2. Testing prescription endpoint without auth...');
    const prescriptionsResponse = await axios.get(`${BASE_URL}/api/prescriptions`);
    console.log('📋 Prescriptions (no auth):', prescriptionsResponse.data.length);
    
    // Test 3: Check prescription endpoint with status filter
    console.log('\n3. Testing prescription endpoint with status filter...');
    const pendingResponse = await axios.get(`${BASE_URL}/api/prescriptions?status=pending`);
    console.log('📋 Pending prescriptions:', pendingResponse.data.length);
    
    // Test 4: Check if any prescriptions have pharmacyId
    console.log('\n4. Checking prescriptions with pharmacyId...');
    const prescriptionsWithPharmacy = allResponse.data.prescriptions.filter(p => p.pharmacyId);
    console.log('📋 Prescriptions with pharmacyId:', prescriptionsWithPharmacy.length);
    
    if (prescriptionsWithPharmacy.length > 0) {
      console.log('📊 Prescriptions with pharmacy:');
      prescriptionsWithPharmacy.forEach(p => {
        console.log(`  - ID: ${p.id}, Pharmacy: ${p.pharmacyId}, Status: ${p.status}`);
      });
    } else {
      console.log('❌ No prescriptions have pharmacyId - this is the problem!');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testPharmacistFlow();

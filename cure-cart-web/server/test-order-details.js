// Test order details endpoint
const axios = require('axios');

const BASE_URL = 'http://localhost:4000';

async function testOrderDetails() {
  console.log('🧪 Testing order details endpoint...');
  
  try {
    // First, let's get all prescriptions to find an order ID
    console.log('\n1. Getting all prescriptions...');
    const prescriptionsResponse = await axios.get(`${BASE_URL}/api/prescriptions/all`);
    console.log('📋 Total prescriptions:', prescriptionsResponse.data.count);
    
    if (prescriptionsResponse.data.prescriptions.length > 0) {
      const prescription = prescriptionsResponse.data.prescriptions[0];
      console.log('📊 Sample prescription:', {
        id: prescription.id,
        orderId: prescription.orderId,
        customerAddress: prescription.customerAddress,
        pharmacyAddress: prescription.pharmacyAddress
      });
      
      // If prescription has an orderId, test the order details endpoint
      if (prescription.orderId) {
        console.log('\n2. Testing order details endpoint...');
        const orderDetailsResponse = await axios.get(`${BASE_URL}/api/orders/${prescription.orderId}/details`);
        console.log('✅ Order details response:', {
          orderId: orderDetailsResponse.data.order._id,
          hasPrescription: !!orderDetailsResponse.data.prescription,
          customerAddress: orderDetailsResponse.data.prescription?.customerAddress,
          pharmacyAddress: orderDetailsResponse.data.prescription?.pharmacyAddress
        });
      } else {
        console.log('❌ No orderId found in prescription');
      }
    } else {
      console.log('❌ No prescriptions found');
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testOrderDetails();

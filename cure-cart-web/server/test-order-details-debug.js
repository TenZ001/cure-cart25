// Test order details endpoint with debugging
const axios = require('axios');

const BASE_URL = 'http://localhost:4000';

async function testOrderDetailsDebug() {
  console.log('🧪 Testing order details endpoint with debugging...');
  
  try {
    // First, let's check if there are any orders
    console.log('\n1. Checking if there are any orders...');
    try {
      const ordersResponse = await axios.get(`${BASE_URL}/api/orders`);
      console.log('📋 Orders found:', ordersResponse.data.length);
      
      if (ordersResponse.data.length > 0) {
        const order = ordersResponse.data[0];
        console.log('📊 Sample order:', {
          id: order._id,
          customerId: order.customerId,
          address: order.address,
          pharmacyId: order.pharmacyId,
          pharmacy: order.pharmacy,
          status: order.status
        });
        
        // Test order details endpoint
        console.log('\n2. Testing order details endpoint...');
        try {
          const orderDetailsResponse = await axios.get(`${BASE_URL}/api/orders/${order._id}/details`);
          console.log('✅ Order details response:', {
            orderId: orderDetailsResponse.data.order._id,
            hasPrescription: !!orderDetailsResponse.data.prescription,
            customerAddress: orderDetailsResponse.data.prescription?.customerAddress,
            pharmacyAddress: orderDetailsResponse.data.prescription?.pharmacyAddress,
            prescriptionData: orderDetailsResponse.data.prescription
          });
        } catch (detailsError) {
          console.log('❌ Order details error:', detailsError.response?.data || detailsError.message);
        }
      } else {
        console.log('❌ No orders found');
      }
    } catch (ordersError) {
      console.log('❌ Orders endpoint error:', ordersError.response?.data || ordersError.message);
    }
    
    // Check prescriptions directly
    console.log('\n3. Checking prescriptions directly...');
    try {
      const prescriptionsResponse = await axios.get(`${BASE_URL}/api/prescriptions/all`);
      console.log('📋 Prescriptions found:', prescriptionsResponse.data.count);
      
      if (prescriptionsResponse.data.prescriptions.length > 0) {
        const prescription = prescriptionsResponse.data.prescriptions[0];
        console.log('📊 Sample prescription:', {
          id: prescription.id,
          customerAddress: prescription.customerAddress,
          pharmacyAddress: prescription.pharmacyAddress,
          orderId: prescription.orderId,
          status: prescription.status
        });
      }
    } catch (prescriptionsError) {
      console.log('❌ Prescriptions endpoint error:', prescriptionsError.response?.data || prescriptionsError.message);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testOrderDetailsDebug();

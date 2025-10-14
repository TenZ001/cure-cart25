// Test orders and prescriptions data
const mongoose = require('mongoose');

async function testOrdersData() {
  console.log('🧪 Testing orders and prescriptions data...');
  
  try {
    // Connect to MongoDB
    await mongoose.connect('mongodb://localhost:27017/curecart');
    console.log('✅ Connected to MongoDB');
    
    // Import schemas
    const Order = require('./schemas/Order');
    const Prescription = require('./schemas/Prescription');
    
    // Check orders
    console.log('\n1. Checking orders...');
    const orders = await Order.find().limit(5);
    console.log('📋 Total orders:', orders.length);
    
    if (orders.length > 0) {
      console.log('📊 Sample order:', {
        id: orders[0]._id,
        customerId: orders[0].customerId,
        address: orders[0].address,
        pharmacyId: orders[0].pharmacyId,
        pharmacy: orders[0].pharmacy,
        status: orders[0].status
      });
    }
    
    // Check prescriptions
    console.log('\n2. Checking prescriptions...');
    const prescriptions = await Prescription.find().limit(5);
    console.log('📋 Total prescriptions:', prescriptions.length);
    
    if (prescriptions.length > 0) {
      console.log('📊 Sample prescription:', {
        id: prescriptions[0]._id,
        customerId: prescriptions[0].customerId,
        orderId: prescriptions[0].orderId,
        customerAddress: prescriptions[0].customerAddress,
        pharmacyId: prescriptions[0].pharmacyId,
        pharmacyName: prescriptions[0].pharmacyName,
        pharmacyAddress: prescriptions[0].pharmacyAddress,
        status: prescriptions[0].status
      });
    }
    
    // Check if any prescriptions have orderId
    const prescriptionsWithOrder = await Prescription.find({ orderId: { $exists: true, $ne: null } });
    console.log('\n3. Prescriptions with orderId:', prescriptionsWithOrder.length);
    
    // Check if any prescriptions have addresses
    const prescriptionsWithAddress = await Prescription.find({ 
      $or: [
        { customerAddress: { $exists: true, $ne: null } },
        { pharmacyAddress: { $exists: true, $ne: null } }
      ]
    });
    console.log('4. Prescriptions with addresses:', prescriptionsWithAddress.length);
    
    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testOrdersData();

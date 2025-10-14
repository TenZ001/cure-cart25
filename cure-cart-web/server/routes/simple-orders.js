// file: cure-cart-web/server/routes/simple-orders.js
const express = require('express');
const Order = require('../schemas/Order');
const router = express.Router();

// SIMPLE ORDERS ENDPOINT - Just show ALL orders
router.get('/simple-orders', async (req, res) => {
  try {
    console.log('🔍 Simple orders endpoint called');
    
    // Get ALL orders from database
    const allOrders = await Order.find().sort({ createdAt: -1 });
    console.log('📦 Found orders in database:', allOrders.length);
    
    // Simple formatting for web interface
    const simpleOrders = allOrders.map(order => ({
      _id: order._id,
      customerId: order.customerId,
      pharmacyId: order.pharmacyId,
      pharmacy: order.pharmacy || 'Unknown Pharmacy',
      status: order.status || 'pending',
      total: order.total || 0,
      items: order.items || [],
      address: order.address || 'No address',
      paymentMethod: order.paymentMethod || 'cash',
      createdAt: order.createdAt,
      // Required fields for web interface
      orderedByRole: 'customer',
      deliveryDate: null,
      trackingId: null,
      paymentStatus: 'pending',
      invoiceId: null,
      deliveryPartnerId: null,
      tracking: {}
    }));
    
    console.log('📦 Returning orders:', simpleOrders.length);
    console.log('📦 Order details:', simpleOrders.map(o => ({
      id: o._id,
      pharmacy: o.pharmacy,
      status: o.status,
      total: o.total,
      items: o.items.length
    })));
    
    res.json(simpleOrders);
  } catch (e) {
    console.error('Simple orders error:', e);
    res.status(500).json({ error: e.message });
  }
});

// CREATE TEST ORDER ENDPOINT
router.post('/simple-orders/test', async (req, res) => {
  try {
    console.log('🧪 Creating test order...');
    
    const testOrder = await Order.create({
      customerId: 'test-customer-' + Date.now(),
      items: [
        {
          name: 'Test Medicine - Simple Orders',
          quantity: 1,
          price: 50,
        }
      ],
      total: 50,
      status: 'pending',
      pharmacyId: 'test-pharmacy-' + Date.now(),
      pharmacy: 'Test Pharmacy - Simple Orders',
      address: 'Test Address - Simple Orders',
      paymentMethod: 'cash',
    });
    
    console.log('✅ Test order created:', testOrder._id);
    
    res.json({
      message: 'Test order created successfully',
      order: testOrder
    });
  } catch (e) {
    console.error('Test order creation error:', e);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;

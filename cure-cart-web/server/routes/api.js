const express = require('express');
const { authMiddleware } = require('../utils/authMiddleware');
const Order = require('../schemas/Order');
const Prescription = require('../schemas/Prescription');
const InventoryItem = require('../schemas/InventoryItem');
const Feedback = require('../schemas/Feedback');
const PharmacyFeedback = require('../schemas/PharmacyFeedback');
const Invoice = require('../schemas/Invoice');
const Notification = require('../schemas/Notification');
const User = require('../schemas/User');
const Pharmacy = require('../schemas/Pharmacy');
const DeliveryPartner = require('../schemas/DeliveryPartner');
const ChatMessage = require('../schemas/ChatMessage');
const mongoose = require('mongoose');
const router = express.Router();

// Delivery partner signup (request approval)
router.post('/delivery-partners', async (req, res) => {
  try {
    const { name: bodyName, phone, nic, licenseNumber, vehicles } = req.body || {};
    const name = (bodyName && String(bodyName).trim()) || req.user?.name || 'Delivery Partner';
    const dp = await DeliveryPartner.create({ name, contact: phone, nic, licenseNumber, vehicleNo: Array.isArray(vehicles) ? vehicles.join(', ') : '', status: 'pending', ownerId: req.user?.uid });
    res.status(201).json(dp);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Current user's delivery partner record
router.get('/delivery-partners/me', async (req, res) => {
  const ownerId = req.user?.uid;
  const dp = await DeliveryPartner.findOne({ ownerId }).sort({ createdAt: -1 });
  res.json(dp || null);
});
router.patch('/delivery-partners/me', async (req, res) => {
  try {
    const ownerId = req.user?.uid;
    const dp = await DeliveryPartner.findOne({ ownerId }).sort({ createdAt: -1 });
    if (!dp) return res.status(404).json({ error: 'Not found' });
    if (dp.status !== 'approved') return res.status(400).json({ error: 'Not approved yet' });
    const update = {};
    for (const k of ['name','contact','nic','licenseNumber','vehicleNo']) if (k in req.body) update[k] = req.body[k];
    const saved = await DeliveryPartner.findByIdAndUpdate(dp._id, update, { new: true });
    res.json(saved);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Public: Create order from mobile checkout (no auth required)
router.post('/orders', async (req, res) => {
  try {
    const { customerId, items, total, pharmacyId, address, paymentMethod } = req.body;
    console.log('🛒 [PUBLIC] Creating order with pharmacyId:', pharmacyId);
    console.log('🛒 [PUBLIC] Order data:', { customerId, items, total, pharmacyId, address, paymentMethod });

    if (!customerId || !items || !Array.isArray(items) || !total) {
      return res.status(400).json({ error: 'customerId, items, and total are required' });
    }

    // Soft-validate customer; allow creation even if user not present in web DB
    try { await User.findById(customerId).select('_id'); } catch (_) {}

    // Get pharmacy name for the order
    let pharmacyName = 'Unknown Pharmacy';
    if (pharmacyId) {
      try {
        const pharmacy = await Pharmacy.findById(pharmacyId).select('name');
        if (pharmacy) {
          pharmacyName = pharmacy.name;
        }
      } catch (e) {
        console.log('⚠️ Could not find pharmacy name for ID:', pharmacyId);
      }
    }

    // Create the order
    const order = await Order.create({
      customerId,
      items: items.map((item) => ({
        medicineId: null,
        quantity: item.quantity || item.qty || 1,
        price: item.price || 0,
        name: item.name,
      })),
      total: Number(total),
      status: 'pending',
      pharmacyId: pharmacyId ? (typeof pharmacyId === 'string' ? pharmacyId : pharmacyId.toString()) : null,
      pharmacy: pharmacyName,
      address: address || 'No address provided',
      paymentMethod: paymentMethod || 'cash',
    });

    console.log('✅ [PUBLIC] Order created with ID:', order._id, 'pharmacyId:', order.pharmacyId);
    return res.status(201).json({
      message: 'Order created successfully',
      order: {
        _id: order._id,
        customerId: order.customerId,
        items: order.items,
        total: order.total,
        status: order.status,
        pharmacyId: order.pharmacyId,
        pharmacy: order.pharmacy,
        address: order.address,
        paymentMethod: order.paymentMethod,
        createdAt: order.createdAt,
      },
    });
  } catch (e) {
    console.error('[PUBLIC] Order creation error:', e);
    return res.status(400).json({ error: e.message });
  }
});

// Public: Get orders for a specific customer (no auth)
router.get('/orders/customer/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;
    console.log('👤 [PUBLIC] Loading orders for customer:', customerId);
    const orders = await Order.find({ customerId }).sort({ createdAt: -1 });
    return res.json(orders);
  } catch (e) {
    console.error('[PUBLIC] Customer orders error:', e);
    return res.status(500).json({ error: e.message });
  }
});

// Public: Permanently delete an order if customer matches (no auth)
router.delete('/orders/:id', async (req, res) => {
  try {
    const id = req.params.id;
    const claimedCustomerId = (req.query.customerId || req.body?.customerId || '').toString();
    if (!claimedCustomerId) {
      return res.status(400).json({ error: 'customerId required' });
    }
    const ord = await Order.findById(id).select('_id customerId');
    if (!ord) return res.status(404).json({ error: 'Not found' });
    if (String(ord.customerId) !== String(claimedCustomerId)) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    await Order.findByIdAndDelete(id);
    return res.json({ ok: true });
  } catch (e) {
    return res.status(400).json({ error: e.message });
  }
});

router.use(authMiddleware);
// Pharmacies - pharmacist requests and admin approval

// Pharmacist creates or updates a pharmacy request (pending)
router.post('/pharmacies', async (req, res) => {
  try {
    const ownerId = req.user?.uid;
    const { name, address, contact } = req.body || {};
    if (!name) return res.status(400).json({ error: 'Name is required' });
    const existingPending = await Pharmacy.findOne({ ownerId, status: { $in: ['pending','approved'] } });
    if (existingPending && existingPending.status !== 'rejected') {
      return res.status(400).json({ error: 'You already have a pharmacy pending/approved' });
    }
    const ph = await Pharmacy.create({ name, address, contact, ownerId, status: 'pending' });
    res.status(201).json(ph);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Check current user's pharmacy status
router.get('/pharmacies/me', async (req, res) => {
  const ownerId = req.user?.uid;
  const ph = await Pharmacy.findOne({ ownerId }).sort({ createdAt: -1 });
  res.json(ph || null);
});

// Pharmacist updates own approved pharmacy details
router.patch('/pharmacies/me', async (req, res) => {
  try {
    const ownerId = req.user?.uid;
    const ph = await Pharmacy.findOne({ ownerId }).sort({ createdAt: -1 });
    if (!ph) return res.status(404).json({ error: 'No pharmacy found' });
    if (ph.status !== 'approved') return res.status(400).json({ error: 'Pharmacy not approved yet' });
    const update = {};
    for (const key of ['name','address','contact']) if (key in req.body) update[key] = req.body[key];
    const saved = await Pharmacy.findByIdAndUpdate(ph._id, update, { new: true });
    res.json(saved);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Dashboard summary
router.get('/dashboard/summary', async (req, res) => {
  const userId = req.user?.uid;
  const role = req.user?.role;
  let pharmacyId = null;
  if (role === 'pharmacist') {
    const ph = await Pharmacy.findOne({ ownerId: userId }).select('_id');
    pharmacyId = ph?._id || null;
  }
  const presFilter = pharmacyId ? { 'pharmacyId': pharmacyId } : {};
  const orderIds = pharmacyId ? (await Prescription.find({ ...presFilter, orderId: { $exists: true, $ne: null } }).select('orderId')).map(p => p.orderId) : [];
  const orderFilter = pharmacyId ? { _id: { $in: orderIds } } : {};

  const [pendingPrescriptions, approvedPrescriptions, rejectedPrescriptions, lowStock, activeOrders, deliveredOrders, unreadNotifications, urgentNotifications, newOrderNotifications, unreadChatMessages, user, lastOrder] = await Promise.all([
    Prescription.countDocuments({ ...presFilter, status: 'pending' }),
    Prescription.countDocuments({ ...presFilter, status: 'approved' }),
    Prescription.countDocuments({ ...presFilter, status: 'rejected' }),
    InventoryItem.countDocuments({ $expr: { $lte: ['$stock', '$lowStockThreshold'] } }),
    Order.countDocuments({ ...orderFilter, status: { $in: ['processing', 'dispatched'] } }),
    Order.countDocuments({ ...orderFilter, status: 'delivered' }),
    Notification.countDocuments({ read: false }),
    Notification.countDocuments({ type: { $in: ['urgent', 'low_stock'] }, read: false }),
    Notification.countDocuments({ type: 'new_order', read: false }),
    pharmacyId ? require('../schemas/ChatMessage').countDocuments({ 
      pharmacyId, 
      senderType: 'patient', 
      isRead: false 
    }) : 0,
    userId ? User.findById(userId).select('lastLoginAt name') : null,
    Order.findOne(orderFilter).sort({ createdAt: -1 }).select('createdAt'),
  ]);
  res.json({
    pendingPrescriptions,
    approvedPrescriptions,
    rejectedPrescriptions,
    lowStock,
    activeOrders,
    deliveredOrders,
    notifications: { unread: unreadNotifications, urgent: urgentNotifications, newOrders: newOrderNotifications },
    unreadChatMessages,
    recentActivity: { lastLoginAt: user?.lastLoginAt || null, lastTransactionAt: lastOrder?.createdAt || null },
  });
});

// Orders - WORKING VERSION - Simple and reliable with pharmacy filtering
router.get('/orders', async (req, res) => {
  try {
    console.log('🔍 Orders endpoint called');
    
    let filter = {};
    
    // If authenticated pharmacist, scope by pharmacy
    try {
      const jwt = require('jsonwebtoken');
      const Pharmacy = require('../schemas/Pharmacy');
      const Prescription = require('../schemas/Prescription');
      const authHeader = req.headers.authorization;
      const bearer = authHeader && authHeader.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : null;
      
      if (bearer) {
        const decoded = jwt.verify(bearer, process.env.JWT_SECRET || 'devsecret');
        console.log('🔍 Authenticated user:', { role: decoded?.role, uid: decoded?.uid });
        
        if (decoded?.role === 'pharmacist') {
          const ph = await Pharmacy.findOne({ ownerId: decoded.uid }).select('_id name');
          console.log('🏥 Pharmacist pharmacy:', ph);
          
          if (ph) {
            // Get orders from prescriptions linked to this pharmacy
            const pres = await Prescription.find({ pharmacyId: ph._id, orderId: { $exists: true, $ne: null } }).select('orderId');
            const orderIds = pres.map(p => p.orderId).filter(Boolean);
            console.log('📋 Prescription order IDs:', orderIds);
            
            // Get direct orders for this pharmacy
            filter = {
              $or: [
                { _id: { $in: orderIds } },
                { pharmacyId: ph._id },
                { pharmacyId: ph._id.toString() },
                { pharmacy: ph.name },
                { pharmacy: { $regex: ph.name, $options: 'i' } }
              ]
            };
            console.log('🔍 Pharmacy filter applied:', filter);
          } else {
            // Pharmacist without a pharmacy should not see any orders
            filter = { _id: { $in: [] } };
            console.log('❌ No pharmacy found for pharmacist');
          }
        } else if (decoded?.role === 'admin') {
          // Admin can see all orders
          filter = {};
          console.log('👑 Admin access - showing all orders');
        }
      }
    } catch (authError) {
      console.log('⚠️ Auth error, showing all orders:', authError.message);
      // If no auth or error, show all orders (for backward compatibility)
      filter = {};
    }
    
    // Get orders with filter
    const allOrders = await Order.find(filter).sort({ createdAt: -1 });
    console.log('📦 Filtered orders:', allOrders.length);
    
    // Get prescription data for orders that have it
    const Prescription = require('../schemas/Prescription');
    const prescriptions = await Prescription.find({ orderId: { $in: allOrders.map(o => o._id) } });
    const prescriptionMap = new Map(prescriptions.map(p => [String(p.orderId), p]));
    
    // Simple formatting - just what we need
    const orders = allOrders.map(order => {
      const prescription = prescriptionMap.get(String(order._id));
      console.log('📦 Processing order:', {
        id: order._id,
        pharmacyId: order.pharmacyId,
        pharmacy: order.pharmacy,
        status: order.status
      });
      return {
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
        tracking: {},
        // Add prescription data if available
        prescription: prescription ? {
          id: prescription._id,
          patientName: prescription.patientName,
          customerAddress: prescription.customerAddress,
          customerPhone: prescription.customerPhone,
          paymentMethod: prescription.paymentMethod,
          pharmacyName: prescription.pharmacyName,
          pharmacyAddress: prescription.pharmacyAddress,
          medicines: prescription.medicines,
          notes: prescription.notes,
          status: prescription.status
        } : null
      };
    });
    
    console.log('📦 Returning orders:', orders.length);
    console.log('📦 Sample order:', orders[0]);
    console.log('📋 Final orders summary:', orders.map(o => ({
      id: o._id,
      pharmacyId: o.pharmacyId,
      pharmacy: o.pharmacy,
      status: o.status,
      total: o.total
    })));
    
    res.json(orders);
  } catch (e) {
    console.error('Orders fetch error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Debug endpoint to see all orders (temporary)
router.get('/orders/debug', async (req, res) => {
  try {
    const allOrders = await Order.find().select('_id customerId pharmacyId pharmacy status total createdAt items').sort({ createdAt: -1 });
    console.log('🔍 All orders in database:', allOrders.length);
    console.log('📋 Order details:', allOrders.map(o => ({
      id: o._id,
      customerId: o.customerId,
      pharmacyId: o.pharmacyId,
      pharmacy: o.pharmacy,
      status: o.status,
      total: o.total,
      items: o.items,
      createdAt: o.createdAt
    })));
    
    // Also show all pharmacies
    const allPharmacies = await Pharmacy.find().select('_id name ownerId status');
    console.log('🏥 All pharmacies:', allPharmacies.length);
    console.log('🏥 Pharmacy details:', allPharmacies.map(p => ({
      id: p._id,
      name: p.name,
      ownerId: p.ownerId,
      status: p.status
    })));
    
    res.json({
      totalOrders: allOrders.length,
      orders: allOrders,
      totalPharmacies: allPharmacies.length,
      pharmacies: allPharmacies
    });
  } catch (e) {
    console.error('Debug endpoint error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Debug endpoint for pharmacist to see their pharmacy and orders
router.get('/orders/pharmacist-debug', async (req, res) => {
  try {
    const role = req.user?.role;
    const userId = req.user?.uid;
    
    console.log('👤 User info:', { role, userId });
    
    if (role === 'pharmacist') {
      const ph = await Pharmacy.findOne({ ownerId: userId }).select('_id name ownerId status');
      console.log('🏥 Pharmacist pharmacy:', ph);
      
      if (!ph) {
        return res.json({ 
          error: 'No pharmacy found for this pharmacist',
          userId,
          role
        });
      }
      
      if (ph.status !== 'approved') {
        return res.json({ 
          error: `Pharmacy not approved. Status: ${ph.status}`,
          pharmacy: ph
        });
      }
      
      // Get orders from prescriptions
      const pres = await Prescription.find({ pharmacyId: ph._id, orderId: { $exists: true, $ne: null } }).select('orderId');
      const prescriptionOrderIds = pres.map(p => p.orderId).filter(Boolean);
      console.log('📋 Prescription order IDs:', prescriptionOrderIds);
      
      // Get direct orders
      const directOrders = await Order.find({ 
        $or: [
          { pharmacyId: ph._id },
          { pharmacyId: ph._id.toString() }
        ]
      }).select('_id pharmacyId status total createdAt items');
      console.log('🛒 Direct orders:', directOrders);
      
      // Get all orders for this pharmacist
      const allOrderIds = [...prescriptionOrderIds, ...directOrders.map(o => o._id)];
      const orders = await Order.find({ _id: { $in: allOrderIds } }).populate('invoiceId').sort({ createdAt: -1 });
      
      return res.json({
        pharmacist: { userId, role },
        pharmacy: ph,
        prescriptionOrderIds,
        directOrders,
        allOrderIds,
        finalOrders: orders,
        totalOrders: orders.length
      });
    }
    
    res.json({ error: 'Not a pharmacist' });
  } catch (e) {
    console.error('Pharmacist debug error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Get orders for a specific customer
router.get('/orders/customer/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;
    console.log('👤 Loading orders for customer:', customerId);
    
    // Get all orders for this customer
    const orders = await Order.find({ customerId }).sort({ createdAt: -1 });
    console.log('📦 Found orders for customer:', orders.length);
    console.log('📦 Order details:', orders.map(o => ({
      id: o._id,
      customerId: o.customerId,
      pharmacyId: o.pharmacyId,
      pharmacy: o.pharmacy,
      status: o.status,
      total: o.total,
      items: o.items,
      createdAt: o.createdAt
    })));
    
    res.json(orders);
  } catch (e) {
    console.error('Customer orders error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Test endpoint to create a test order
router.post('/orders/test', async (req, res) => {
  try {
    console.log('🧪 Creating test order...');
    
    // Create a test order
    const testOrder = await Order.create({
      customerId: 'test-customer-id',
      items: [
        {
          name: 'Test Medicine',
          quantity: 1,
          price: 100,
        }
      ],
      total: 100,
      status: 'pending',
      pharmacyId: 'test-pharmacy-id',
      pharmacy: 'Test Pharmacy',
      address: 'Test Address',
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

// Enhanced debug endpoint for pharmacist orders
router.get('/orders/pharmacist-debug-enhanced', async (req, res) => {
  try {
    const role = req.user?.role;
    const userId = req.user?.uid;
    
    console.log('👤 Enhanced debug - User info:', { role, userId });
    
    if (role === 'pharmacist') {
      const ph = await Pharmacy.findOne({ ownerId: userId }).select('_id name ownerId status');
      console.log('🏥 Enhanced debug - Pharmacist pharmacy:', ph);
      
      if (!ph) {
        return res.json({ 
          error: 'No pharmacy found for this pharmacist',
          userId,
          role
        });
      }
      
      // Get ALL orders first to see what's in the database
      const allOrders = await Order.find().select('_id customerId pharmacyId pharmacy status total createdAt items').sort({ createdAt: -1 });
      console.log('🔍 Enhanced debug - All orders in database:', allOrders.length);
      
      // Try to find orders with different matching strategies
      const strategy1 = await Order.find({ pharmacyId: ph._id }).select('_id pharmacyId status total createdAt items');
      const strategy2 = await Order.find({ pharmacyId: ph._id.toString() }).select('_id pharmacyId status total createdAt items');
      const strategy3 = await Order.find({ pharmacy: ph.name }).select('_id pharmacy status total createdAt items');
      const strategy4 = await Order.find({ pharmacy: { $regex: ph.name, $options: 'i' } }).select('_id pharmacy status total createdAt items');
      
      return res.json({
        pharmacist: { userId, role },
        pharmacy: ph,
        allOrders: allOrders,
        strategy1: { count: strategy1.length, orders: strategy1 },
        strategy2: { count: strategy2.length, orders: strategy2 },
        strategy3: { count: strategy3.length, orders: strategy3 },
        strategy4: { count: strategy4.length, orders: strategy4 },
        totalOrders: allOrders.length
      });
    }
    
    res.json({ error: 'Not a pharmacist' });
  } catch (e) {
    console.error('Enhanced pharmacist debug error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Test endpoint to create a test order for debugging
router.post('/orders/test', async (req, res) => {
  try {
    const { pharmacyId } = req.body;
    
    if (!pharmacyId) {
      return res.status(400).json({ error: 'pharmacyId required' });
    }
    
    // Get pharmacy name
    let pharmacyName = 'Test Pharmacy';
    try {
      const pharmacy = await Pharmacy.findById(pharmacyId).select('name');
      if (pharmacy) {
        pharmacyName = pharmacy.name;
      }
    } catch (e) {
      console.log('⚠️ Could not find pharmacy name for test order');
    }
    
    const testOrder = await Order.create({
      customerId: new require('mongoose').Types.ObjectId(), // Dummy customer ID
      items: [{
        name: 'Test Medicine',
        quantity: 1,
        price: 100
      }],
      total: 100,
      status: 'pending',
      pharmacyId: pharmacyId,
      pharmacy: pharmacyName,
      address: 'Test Address',
      paymentMethod: 'cash',
    });
    
    console.log('🧪 Test order created:', testOrder);
    
    res.json({
      message: 'Test order created',
      order: testOrder
    });
  } catch (e) {
    console.error('Test order creation error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Simple endpoint to show all orders for current pharmacist
router.get('/orders/my-pharmacy', async (req, res) => {
  try {
    const role = req.user?.role;
    if (role !== 'pharmacist') {
      return res.status(403).json({ error: 'Only pharmacists can access this endpoint' });
    }
    
    const ph = await Pharmacy.findOne({ ownerId: req.user?.uid }).select('_id name status');
    if (!ph) {
      return res.json({ error: 'No pharmacy found for this pharmacist', orders: [] });
    }
    
    console.log('🔍 Pharmacist pharmacy:', { id: ph._id, name: ph.name, status: ph.status });
    
    // Get all orders for this pharmacy (both by ID and by name)
    const orders = await Order.find({
      $or: [
        { pharmacyId: ph._id },
        { pharmacyId: ph._id.toString() },
        { pharmacy: ph.name },
        { pharmacy: { $regex: ph.name, $options: 'i' } }
      ]
    }).sort({ createdAt: -1 });
    
    console.log('📦 Orders found for pharmacist:', orders.length);
    console.log('📦 Order details:', orders.map(o => ({
      id: o._id,
      pharmacyId: o.pharmacyId,
      pharmacy: o.pharmacy,
      status: o.status,
      total: o.total,
      items: o.items,
      createdAt: o.createdAt
    })));
    
    res.json({
      pharmacist: { id: req.user?.uid, role },
      pharmacy: ph,
      orders: orders,
      total: orders.length
    });
  } catch (e) {
    console.error('My pharmacy orders error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Quick test endpoint to see if pharmacist can see ANY orders
router.get('/orders/test-pharmacist', async (req, res) => {
  try {
    console.log('🧪 Testing pharmacist access...');
    console.log('👤 User:', { uid: req.user?.uid, role: req.user?.role });
    
    const ph = await Pharmacy.findOne({ ownerId: req.user?.uid });
    console.log('🏥 Found pharmacy:', ph);
    
    if (!ph) {
      return res.json({ error: 'No pharmacy found', user: req.user });
    }
    
    // Get ALL orders in database
    const allOrders = await Order.find().select('_id pharmacyId pharmacy status total items createdAt').sort({ createdAt: -1 });
    console.log('📦 All orders in database:', allOrders.length);
    console.log('📦 All order details:', allOrders.map(o => ({
      id: o._id,
      pharmacyId: o.pharmacyId,
      pharmacy: o.pharmacy,
      status: o.status,
      total: o.total,
      items: o.items
    })));
    
    // Get orders that should match this pharmacist
    const matchingOrders = await Order.find({
      $or: [
        { pharmacyId: ph._id },
        { pharmacyId: ph._id.toString() },
        { pharmacy: ph.name },
        { pharmacy: { $regex: ph.name, $options: 'i' } }
      ]
    }).select('_id pharmacyId pharmacy status total items createdAt');
    
    console.log('🎯 Matching orders for pharmacist:', matchingOrders.length);
    console.log('🎯 Matching order details:', matchingOrders.map(o => ({
      id: o._id,
      pharmacyId: o.pharmacyId,
      pharmacy: o.pharmacy,
      status: o.status,
      total: o.total,
      items: o.items
    })));
    
    res.json({
      user: req.user,
      pharmacy: ph,
      allOrders: allOrders,
      matchingOrders: matchingOrders,
      totalAll: allOrders.length,
      totalMatching: matchingOrders.length
    });
  } catch (e) {
    console.error('Test pharmacist error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Migration endpoint to fix existing orders (temporary)
router.post('/orders/fix-pharmacy-data', async (req, res) => {
  try {
    const { pharmacyId } = req.body;
    
    if (!pharmacyId) {
      return res.status(400).json({ error: 'pharmacyId required' });
    }
    
    // Get pharmacy name
    const pharmacy = await Pharmacy.findById(pharmacyId).select('name');
    if (!pharmacy) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }
    
    // Update all orders that don't have pharmacyId or pharmacy fields
    const result = await Order.updateMany(
      {
        $or: [
          { pharmacyId: { $exists: false } },
          { pharmacy: { $exists: false } }
        ]
      },
      {
        $set: {
          pharmacyId: pharmacyId,
          pharmacy: pharmacy.name
        }
      }
    );
    
    console.log('🔧 Fixed orders:', result);
    
    res.json({
      message: 'Orders updated successfully',
      pharmacyId: pharmacyId,
      pharmacyName: pharmacy.name,
      modifiedCount: result.modifiedCount,
      matchedCount: result.matchedCount
    });
  } catch (e) {
    console.error('Fix pharmacy data error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Test endpoint to check database connection and collections
router.get('/orders/database-test', async (req, res) => {
  try {
    console.log('🔍 Testing database connection...');
    
    // Get database name
    const dbName = mongoose.connection.db.databaseName;
    console.log('📊 Database name:', dbName);
    
    // List all collections
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('📁 Collections:', collections.map(c => c.name));
    
    // Check if Order collection exists
    const orderCollection = collections.find(c => c.name === 'orders');
    console.log('📦 Order collection exists:', !!orderCollection);
    
    // Count documents in orders collection
    const orderCount = await Order.countDocuments();
    console.log('📊 Total orders in database:', orderCount);
    
    // Get a sample order
    const sampleOrder = await Order.findOne();
    console.log('📄 Sample order:', sampleOrder);
    
    res.json({
      database: dbName,
      collections: collections.map(c => c.name),
      orderCollectionExists: !!orderCollection,
      totalOrders: orderCount,
      sampleOrder: sampleOrder
    });
  } catch (e) {
    console.error('Database test error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Test endpoint to create order directly via web API
router.post('/orders/test-web', async (req, res) => {
  try {
    const { pharmacyId } = req.body;
    
    if (!pharmacyId) {
      return res.status(400).json({ error: 'pharmacyId required' });
    }
    
    // Get pharmacy name
    const pharmacy = await Pharmacy.findById(pharmacyId).select('name');
    if (!pharmacy) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }
    
    // Create test order using web API logic
    const testOrder = await Order.create({
      customerId: new require('mongoose').Types.ObjectId(), // Dummy customer ID
      items: [{
        name: 'Test Medicine (Web API)',
        quantity: 1,
        price: 200
      }],
      total: 200,
      status: 'pending',
      pharmacyId: pharmacyId,
      pharmacy: pharmacy.name,
      address: 'Test Address (Web API)',
      paymentMethod: 'cash',
    });
    
    console.log('🧪 Web API test order created:', testOrder);
    
    res.json({
      message: 'Web API test order created successfully',
      order: testOrder
    });
  } catch (e) {
    console.error('Web API test order creation error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Test endpoint to simulate mobile app order creation
router.post('/orders/test-mobile', async (req, res) => {
  try {
    const { customerId, items, total, pharmacyId, address, paymentMethod } = req.body;
    
    console.log('📱 Simulating mobile app order creation...');
    console.log('📱 Mobile app data:', { customerId, items, total, pharmacyId, address, paymentMethod });
    
    if (!customerId || !items || !Array.isArray(items) || !total) {
      return res.status(400).json({ error: 'customerId, items, and total are required' });
    }

    // Soft-validate customer; allow order creation even if user not present in web DB
    try {
      await User.findById(customerId).select('_id');
    } catch (_) {}

    // Get pharmacy name for the order
    let pharmacyName = 'Unknown Pharmacy';
    if (pharmacyId) {
      try {
        const pharmacy = await Pharmacy.findById(pharmacyId).select('name');
        if (pharmacy) {
          pharmacyName = pharmacy.name;
        }
      } catch (e) {
        console.log('⚠️ Could not find pharmacy name for ID:', pharmacyId);
      }
    }

    // Create the order (same logic as web API)
    const order = await Order.create({
      customerId,
      items: items.map(item => ({
        medicineId: null, // We don't have medicine IDs from checkout, just names
        quantity: item.quantity || item.qty || 1,
        price: item.price || 0,
        name: item.name, // Store medicine name for reference
      })),
      total: Number(total),
      status: 'pending',
      pharmacyId: pharmacyId ? (typeof pharmacyId === 'string' ? pharmacyId : pharmacyId.toString()) : null,
      pharmacy: pharmacyName, // Also store pharmacy name
      // Save both pharmacy address and delivery address
      pharmacyAddress: (typeof req.body?.pharmacyAddress === 'string' && req.body.pharmacyAddress.trim()) ? req.body.pharmacyAddress.trim() : undefined,
      address: address || 'No address provided',
      paymentMethod: paymentMethod || 'cash',
    });

    console.log('✅ Mobile app test order created with ID:', order._id, 'pharmacyId:', order.pharmacyId);

    res.status(201).json({
      message: 'Mobile app test order created successfully',
      order: {
        _id: order._id,
        customerId: order.customerId,
        items: order.items,
        total: order.total,
        status: order.status,
        pharmacyId: order.pharmacyId,
        pharmacy: order.pharmacy,
        address: order.address,
        paymentMethod: order.paymentMethod,
        createdAt: order.createdAt,
      }
    });
  } catch (e) {
    console.error('Mobile app test order creation error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Create new order from checkout
router.post('/orders', async (req, res) => {
  try {
    const { customerId, items, total, pharmacyId, address, paymentMethod } = req.body;
    
    console.log('🛒 Creating order with pharmacyId:', pharmacyId);
    console.log('🛒 Order data:', { customerId, items, total, pharmacyId, address, paymentMethod });
    
    if (!customerId || !items || !Array.isArray(items) || !total) {
      return res.status(400).json({ error: 'customerId, items, and total are required' });
    }

    // Validate customer exists
    const customer = await User.findById(customerId);
    if (!customer) {
      return res.status(404).json({ error: 'Customer not found' });
    }

    // Get pharmacy name for the order
    let pharmacyName = 'Unknown Pharmacy';
    if (pharmacyId) {
      try {
        const pharmacy = await Pharmacy.findById(pharmacyId).select('name');
        if (pharmacy) {
          pharmacyName = pharmacy.name;
        }
      } catch (e) {
        console.log('⚠️ Could not find pharmacy name for ID:', pharmacyId);
      }
    }

    // Create the order
    const order = await Order.create({
      customerId,
      items: items.map(item => ({
        medicineId: null, // We don't have medicine IDs from checkout, just names
        quantity: item.quantity || item.qty || 1,
        price: item.price || 0,
        name: item.name, // Store medicine name for reference
      })),
      total: Number(total),
      status: 'pending',
      pharmacyId: pharmacyId ? (typeof pharmacyId === 'string' ? pharmacyId : pharmacyId.toString()) : null,
      pharmacy: pharmacyName, // Also store pharmacy name
      address: address || 'No address provided',
      paymentMethod: paymentMethod || 'cash',
    });

    // Do not create a prescription for checkout orders

    console.log('✅ Order created with ID:', order._id, 'pharmacyId:', order.pharmacyId);
    console.log('✅ Order pharmacy name:', order.pharmacy);
    console.log('✅ Order details:', {
      id: order._id,
      customerId: order.customerId,
      pharmacyId: order.pharmacyId,
      pharmacy: order.pharmacy,
      status: order.status,
      total: order.total,
      items: order.items
    });

    res.status(201).json({
      message: 'Order created successfully',
      order: {
        _id: order._id,
        customerId: order.customerId,
        items: order.items,
        total: order.total,
        status: order.status,
        pharmacyId: order.pharmacyId,
        pharmacy: order.pharmacy,
        pharmacyAddress: order.pharmacyAddress,
        address: order.address,
        paymentMethod: order.paymentMethod,
        createdAt: order.createdAt,
      }
    });
  } catch (e) {
    console.error('Order creation error:', e);
    res.status(400).json({ error: e.message });
  }
});
router.get('/orders/:id/details', async (req, res) => {
  try {
    console.log('🔍 [ORDER DETAILS] Fetching details for order:', req.params.id);
    const order = await Order.findById(req.params.id).populate('invoiceId');
    if (!order) {
      console.log('❌ [ORDER DETAILS] Order not found:', req.params.id);
      return res.status(404).json({ error: 'Order not found' });
    }
    
    const pres = await Prescription.findOne({ orderId: order._id });
    console.log('📋 [ORDER DETAILS] Found prescription:', pres ? 'Yes' : 'No');
    
    // Optional authentication check - only restrict if user is authenticated as pharmacist
    if (req.user?.role === 'pharmacist') {
      const ph = await Pharmacy.findOne({ ownerId: req.user?.uid }).select('_id');
      if (!ph || String(pres?.pharmacyId) !== String(ph._id)) {
        console.log('❌ [ORDER DETAILS] Pharmacist not authorized for this order');
        return res.status(403).json({ error: 'Forbidden' });
      }
    }
    
    const response = {
      order,
      prescription: pres ? {
        id: pres._id,
        patientName: pres.patientName,
        customerAddress: pres.customerAddress,
        customerPhone: pres.customerPhone,
        paymentMethod: pres.paymentMethod,
        pharmacyName: pres.pharmacyName,
        pharmacyAddress: pres.pharmacyAddress,
        medicines: pres.medicines,
        notes: pres.notes,
        status: pres.status
      } : null,
    };
    
    console.log('✅ [ORDER DETAILS] Returning order details:', {
      orderId: order._id,
      hasPrescription: !!pres,
      customerAddress: pres?.customerAddress,
      pharmacyAddress: pres?.pharmacyAddress
    });
    
    res.json(response);
  } catch (e) {
    console.log('❌ [ORDER DETAILS] Error:', e.message);
    res.status(400).json({ error: e.message });
  }
});
router.patch('/orders/:id/status', async (req, res) => {
  const { status } = req.body;
  const order = await Order.findByIdAndUpdate(req.params.id, { status }, { new: true });
  res.json(order);
});
router.delete('/orders/:id', async (req, res) => {
  try {
    const order = await Order.findByIdAndDelete(req.params.id);
    if (!order) return res.status(404).json({ error: 'Not found' });
    res.json({ ok: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});
// Delivery partners (approved)
router.get('/delivery-partners/approved', async (_req, res) => {
  const items = await DeliveryPartner.find({ status: 'approved' }).select('_id name contact vehicleNo');
  res.json(items);
});

// Create order from a prescription
router.post('/orders/from-prescription', async (req, res) => {
  try {
    const { prescriptionId, deliveryPartnerId, total, paymentMethod } = req.body || {};
    if (!prescriptionId) return res.status(400).json({ error: 'prescriptionId required' });
    
    const pres = await Prescription.findById(prescriptionId);
    if (!pres) return res.status(404).json({ error: 'Prescription not found' });
    
    // Validate prescription has required customerId
    if (!pres.customerId) {
      return res.status(400).json({ error: 'Prescription missing customerId' });
    }
    // Pharmacist can only create orders for their own pharmacy's prescriptions
    if (req.user?.role === 'pharmacist') {
      console.log('Pharmacist authorization check:', {
        userId: req.user?.uid,
        userRole: req.user?.role,
        prescriptionId: pres._id,
        prescriptionPharmacyId: pres.pharmacyId
      });
      
      const ph = await Pharmacy.findOne({ ownerId: req.user?.uid }).select('_id status');
      console.log('Found pharmacy:', ph);
      
      if (!ph) {
        console.log('No pharmacy found for pharmacist');
        return res.status(403).json({ error: 'Forbidden: No pharmacy found for this pharmacist' });
      }
      
      if (ph.status !== 'approved') {
        console.log('Pharmacy not approved:', ph.status);
        return res.status(403).json({ error: `Forbidden: Pharmacy status is ${ph.status}. Only approved pharmacies can create orders.` });
      }
      
      if (String(pres.pharmacyId) !== String(ph._id)) {
        console.log('Pharmacy mismatch:', {
          prescriptionPharmacyId: pres.pharmacyId,
          pharmacistPharmacyId: ph._id
        });
        return res.status(403).json({ error: 'Forbidden: Prescription does not belong to your pharmacy' });
      }
    }
    const order = await Order.create({
      customerId: pres.customerId,
      items: [],
      total: Number(total) || 0,
      status: 'processing',
      deliveryPartnerId: deliveryPartnerId || undefined,
    });
    pres.orderId = order._id;
    if (paymentMethod) pres.paymentMethod = paymentMethod;
    pres.status = 'ordered';
    await pres.save();
    res.status(201).json({ order, prescription: pres });
  } catch (e) {
    console.error('Order creation error:', e);
    res.status(400).json({ error: e.message, details: e.toString() });
  }
});
// Test endpoint to check authentication
router.get('/test-auth', async (req, res) => {
  console.log('🔍 Auth test - User:', req.user);
  res.json({ 
    user: req.user,
    message: 'Auth test successful',
    timestamp: new Date().toISOString()
  });
});

// Assign delivery partner to order
router.put('/orders/:orderId/assign-delivery', async (req, res) => {
  try {
    console.log('🚀 Assign delivery partner called:', {
      orderId: req.params.orderId,
      deliveryPartnerId: req.body.deliveryPartnerId,
      user: req.user
    });

    const { orderId } = req.params;
    const { deliveryPartnerId } = req.body;

    if (!deliveryPartnerId) {
      return res.status(400).json({ error: 'deliveryPartnerId is required' });
    }

    const order = await Order.findByIdAndUpdate(
      orderId,
      { 
        deliveryPartnerId: deliveryPartnerId,
        status: 'assigned'
      },
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    console.log('✅ Delivery partner assigned to order:', orderId);

    res.json({ 
      message: 'Delivery partner assigned', 
      data: order
    });
  } catch (err) {
    console.error('❌ Assign delivery partner error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Confirm order
router.put('/orders/:orderId/confirm', async (req, res) => {
  try {
    console.log('🚀 Confirm order called:', {
      orderId: req.params.orderId,
      user: req.user
    });

    const { orderId } = req.params;

    const order = await Order.findByIdAndUpdate(
      orderId,
      { status: 'confirmed' },
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    console.log('✅ Order confirmed:', orderId);

    res.json({ 
      message: 'Order confirmed', 
      data: order
    });
  } catch (err) {
    console.error('❌ Confirm order error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Update order logistics fields
router.patch('/orders/:id', async (req, res) => {
  try {
    const { trackingId, deliveryDate, paymentStatus, deliveryPartnerId, status } = req.body || {};
    // Pharmacist can only update orders that belong to their pharmacy
    if (req.user?.role === 'pharmacist') {
      const ph = await Pharmacy.findOne({ ownerId: req.user?.uid }).select('_id name');
      if (!ph) return res.status(403).json({ error: 'Forbidden' });
      // Prefer prescription linkage when present
      const pres = await Prescription.findOne({ orderId: req.params.id }).select('pharmacyId');
      if (pres) {
        if (String(pres.pharmacyId) !== String(ph._id)) {
          return res.status(403).json({ error: 'Forbidden' });
        }
      } else {
        // For direct checkout orders (no prescription), verify by order's pharmacyId or pharmacy name
        const order = await Order.findById(req.params.id).select('_id pharmacyId pharmacy');
        if (!order) return res.status(404).json({ error: 'Order not found' });
        const matchesById = String(order.pharmacyId || '') === String(ph._id);
        const matchesByName = typeof order.pharmacy === 'string' && (
          order.pharmacy === ph.name || new RegExp(ph.name, 'i').test(order.pharmacy)
        );
        if (!matchesById && !matchesByName) {
          return res.status(403).json({ error: 'Forbidden' });
        }
      }
      // Require a delivery partner when confirming to processing via web
      if (status === 'processing' && (deliveryPartnerId === undefined || deliveryPartnerId === null || String(deliveryPartnerId).trim() === '')) {
        return res.status(400).json({ error: 'deliveryPartnerId is required to confirm order' });
      }
    }
    const update = {};
    if (trackingId !== undefined) update.trackingId = trackingId;
    if (deliveryDate !== undefined) update.deliveryDate = deliveryDate;
    if (paymentStatus !== undefined) update.paymentStatus = paymentStatus;
    if (deliveryPartnerId !== undefined) update.deliveryPartnerId = deliveryPartnerId;
    if (status !== undefined) update.status = status;
    const order = await Order.findByIdAndUpdate(req.params.id, update, { new: true });
    res.json(order);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Prescriptions endpoints moved to dedicated prescription routes
// This prevents conflicts with the main prescription routes

// Inventory
router.get('/inventory', async (req, res) => {
  const role = req.user?.role;
  const filter = {};
  if (role === 'pharmacist') Object.assign(filter, { ownerId: req.user?.uid });
  const items = await InventoryItem.find(filter).sort({ name: 1 });
  res.json(items);
});

// Migration endpoint to add medicine IDs to existing items
router.post('/inventory/migrate-ids', async (_req, res) => {
  try {
    const itemsWithoutId = await InventoryItem.find({ medicineId: { $exists: false } });
    let updated = 0;
    
    for (const item of itemsWithoutId) {
      const timestamp = Date.now().toString(36);
      const random = Math.random().toString(36).substr(2, 5);
      item.medicineId = `MED-${timestamp}-${random}`.toUpperCase();
      await item.save();
      updated++;
    }
    
    res.json({ message: `Updated ${updated} items with medicine IDs` });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
router.post('/inventory', async (req, res) => {
  try {
    // Check for duplicate medicine name
    const nameFilter = { name: { $regex: new RegExp(`^${req.body.name}$`, 'i') } };
    const scopeFilter = req.user?.role === 'pharmacist' ? { ownerId: req.user?.uid } : {};
    const existingMedicine = await InventoryItem.findOne({ 
      ...nameFilter,
      ...scopeFilter,
    });
    if (existingMedicine) {
      return res.status(400).json({ error: 'Medicine with this name already exists' });
    }
    const payload = { ...req.body };
    if (req.user?.role === 'pharmacist') payload.ownerId = req.user?.uid;
    const item = await InventoryItem.create(payload);
    res.status(201).json(item);
  } catch (error) {
    if (error.code === 11000) {
      res.status(400).json({ error: 'Duplicate medicine ID or SKU' });
    } else {
      res.status(400).json({ error: error.message });
    }
  }
});
router.patch('/inventory/:id', async (req, res) => {
  try {
    // Check for duplicate medicine name (excluding current item)
    if (req.body.name) {
      const scopeFilter = req.user?.role === 'pharmacist' ? { ownerId: req.user?.uid } : {};
      const existingMedicine = await InventoryItem.findOne({ 
        name: { $regex: new RegExp(`^${req.body.name}$`, 'i') },
        _id: { $ne: req.params.id },
        ...scopeFilter,
      });
      if (existingMedicine) {
        return res.status(400).json({ error: 'Medicine with this name already exists' });
      }
    }
    const filter = { _id: req.params.id };
    if (req.user?.role === 'pharmacist') Object.assign(filter, { ownerId: req.user?.uid });
    const item = await InventoryItem.findOneAndUpdate(filter, req.body, { new: true });
    if (!item) {
      return res.status(404).json({ error: 'Medicine not found' });
    }
    res.json(item);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
router.delete('/inventory/:id', async (req, res) => {
  try {
    const filter = { _id: req.params.id };
    if (req.user?.role === 'pharmacist') Object.assign(filter, { ownerId: req.user?.uid });
    const item = await InventoryItem.findOneAndDelete(filter);
    if (!item) {
      return res.status(404).json({ error: 'Medicine not found' });
    }
    res.json({ message: 'Medicine deleted successfully' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Customers
router.get('/customers', async (req, res) => {
  const role = req.user?.role;
  if (role === 'pharmacist') {
    const ph = await Pharmacy.findOne({ ownerId: req.user?.uid }).select('_id');
    if (!ph) return res.json([]);
    const approved = await Prescription.find({ status: 'approved', pharmacyId: ph._id })
      .sort({ createdAt: -1 })
      .select('customerId patientName customerAddress customerPhone customerAge customerGender createdAt');
    const byCustomer = new Map();
    for (const p of approved) {
      const key = String(p.customerId || p._id);
      if (!byCustomer.has(key)) byCustomer.set(key, p);
    }
    const rows = Array.from(byCustomer.entries()).map(([id, p]) => ({
      _id: id,
      name: p.patientName || 'Patient',
      email: '',
      phone: p.customerPhone || '',
      address: p.customerAddress || '',
      age: p.customerAge || undefined,
      gender: p.customerGender || undefined,
      rewardPoints: 0,
      dues: 0,
      createdAt: p.createdAt,
    }));
    return res.json(rows);
  }
  // Admin/others: original behavior
  const users = await User.find({ role: 'customer' }).select('_id name email phone address age gender rewardPoints dues createdAt');
  const approved = await Prescription.find({ status: 'approved' }).sort({ createdAt: -1 }).select('customerId patientName customerAddress customerPhone customerAge customerGender createdAt');
  const userIds = new Set(users.map(u => String(u._id)));
  const byCustomer = new Map();
  for (const p of approved) {
    const key = String(p.customerId || p._id);
    if (!byCustomer.has(key)) byCustomer.set(key, p);
  }
  const extras = Array.from(byCustomer.entries())
    .filter(([id]) => !userIds.has(id))
    .map(([id, p]) => ({
      _id: id,
      name: p.patientName || 'Patient',
      email: '',
      phone: p.customerPhone || '',
      address: p.customerAddress || '',
      age: p.customerAge || undefined,
      gender: p.customerGender || undefined,
      rewardPoints: 0,
      dues: 0,
      createdAt: p.createdAt,
    }));
  res.json([...users, ...extras]);
});
router.delete('/customers/:id', async (req, res) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
router.get('/customers/:id', async (req, res) => {
  const [customer, orders, prescriptions] = await Promise.all([
    User.findById(req.params.id).select('_id name email phone address age gender rewardPoints dues createdAt'),
    Order.find({ customerId: req.params.id }).sort({ createdAt: -1 }),
    Prescription.find({ customerId: req.params.id }).sort({ createdAt: -1 }),
  ]);
  res.json({ customer, orders, prescriptions });
});
router.post('/customers/:id/reminders', async (req, res) => {
  const { title = 'Reminder', body = 'Please review your prescription/refill.' } = req.body || {};
  const notif = await Notification.create({ type: 'message', title, body, userId: req.params.id, data: { kind: 'reminder' } });
  res.status(201).json(notif);
});

// Update a customer profile
router.patch('/customers/:id', async (req, res) => {
  const allowed = ['name','phone','address','age','gender','rewardPoints','dues'];
  const update = {};
  for (const key of allowed) if (key in req.body) update[key] = req.body[key];
  if (typeof update.name === 'string') update.name = update.name.trim();
  const customer = await User.findByIdAndUpdate(req.params.id, update, { new: true }).select('_id name email phone address age gender rewardPoints dues createdAt');
  res.json(customer);
});

// Notifications
router.get('/notifications', async (req, res) => {
  const { unread } = req.query;
  const where = unread ? { read: false } : {};
  const items = await Notification.find(where).sort({ createdAt: -1 });
  res.json(items);
});
router.post('/notifications/mark-all-read', async (_req, res) => {
  await Notification.updateMany({ read: false }, { $set: { read: true } });
  res.json({ ok: true });
});
router.delete('/notifications', async (_req, res) => {
  await Notification.deleteMany({});
  res.json({ ok: true });
});

// Invoices / Billing
router.get('/invoices', async (_req, res) => {
  const invoices = await Invoice.find().sort({ createdAt: -1 });
  res.json(invoices);
});
router.get('/invoices/:id', async (req, res) => {
  const invoice = await Invoice.findById(req.params.id);
  res.json(invoice);
});
router.post('/orders/:id/invoice', async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: 'Order not found' });
  const paymentMethod = (req.body?.paymentMethod || 'cash');
  const invoice = await Invoice.create({ orderId: order._id, customerId: order.customerId, amount: order.total, paymentMethod, tax: 0, discount: 0, status: 'unpaid' });
  order.invoiceId = invoice._id;
  await order.save();
  res.status(201).json(invoice);
});

// Feedback
router.get('/feedback', async (_req, res) => {
  const items = await Feedback.find().sort({ createdAt: -1 });
  res.json(items);
});

// Pharmacy Feedback
router.post('/pharmacy-feedback', async (req, res) => {
  try {
    const { pharmacyId, customerId, rating, comment } = req.body;
    
    console.log('🔍 [API] Pharmacy feedback submission:', { pharmacyId, customerId, rating, comment });
    
    if (!pharmacyId || !customerId || !rating) {
      return res.status(400).json({ error: 'pharmacyId, customerId, and rating are required' });
    }
    
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }
    
    // Get customer info for easier display
    const customer = await User.findById(customerId);
    if (!customer) {
      return res.status(404).json({ error: 'Customer not found' });
    }
    
    // Check if pharmacy exists
    const pharmacy = await Pharmacy.findById(pharmacyId);
    if (!pharmacy) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }
    
    // Create feedback
    const feedback = new PharmacyFeedback({
      pharmacyId,
      customerId,
      rating,
      comment: comment || '',
      customerName: customer.name || 'Anonymous',
      customerEmail: customer.email || '',
    });
    
    await feedback.save();
    
    console.log('✅ [API] Pharmacy feedback created:', feedback._id);
    
    res.status(201).json({
      message: 'Feedback submitted successfully',
      feedback: {
        _id: feedback._id,
        rating: feedback.rating,
        comment: feedback.comment,
        createdAt: feedback.createdAt
      }
    });
  } catch (error) {
    console.error('❌ [API] Pharmacy feedback error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get pharmacy feedback
router.get('/pharmacy-feedback/:pharmacyId', async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    
    console.log('🔍 [API] Getting pharmacy feedback for:', pharmacyId);
    console.log('🔍 [API] Query params:', { page, limit });
    
    const skip = (parseInt(page) - 1) * parseInt(limit);
    
    const feedback = await PharmacyFeedback.find({ 
      pharmacyId, 
      hidden: false 
    })
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit))
    .populate('customerId', 'name email');
    
    console.log('🔍 [API] Found feedback items:', feedback.length);
    console.log('🔍 [API] Feedback details:', feedback.map(f => ({
      _id: f._id,
      pharmacyId: f.pharmacyId,
      rating: f.rating,
      comment: f.comment,
      customerName: f.customerName,
      createdAt: f.createdAt
    })));
    
    const total = await PharmacyFeedback.countDocuments({ 
      pharmacyId, 
      hidden: false 
    });
    
    // Calculate average rating
    const avgRating = await PharmacyFeedback.aggregate([
      { $match: { pharmacyId: new mongoose.Types.ObjectId(pharmacyId), hidden: false } },
      { $group: { _id: null, averageRating: { $avg: '$rating' }, count: { $sum: 1 } } }
    ]);
    
    const averageRating = avgRating.length > 0 ? avgRating[0].averageRating : 0;
    const totalReviews = avgRating.length > 0 ? avgRating[0].count : 0;
    
    console.log('✅ [API] Found feedback:', { count: feedback.length, averageRating, totalReviews });
    
    res.json({
      feedback,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      },
      stats: {
        averageRating: Math.round(averageRating * 10) / 10,
        totalReviews
      }
    });
  } catch (error) {
    console.error('❌ [API] Get pharmacy feedback error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete pharmacy feedback
router.delete('/pharmacy-feedback/:feedbackId', async (req, res) => {
  try {
    const { feedbackId } = req.params;
    const userId = req.user?.uid;
    
    console.log('🔍 [API] Deleting feedback:', { feedbackId, userId });
    
    // Find the feedback first to check ownership
    const feedback = await PharmacyFeedback.findById(feedbackId);
    if (!feedback) {
      return res.status(404).json({ error: 'Feedback not found' });
    }
    
    // Get the user's pharmacy to verify ownership
    const userPharmacy = await Pharmacy.findOne({ ownerId: userId });
    if (!userPharmacy) {
      return res.status(403).json({ error: 'No pharmacy found for user' });
    }
    
    // Check if the feedback belongs to the user's pharmacy
    if (feedback.pharmacyId.toString() !== userPharmacy._id.toString()) {
      return res.status(403).json({ error: 'Not authorized to delete this feedback' });
    }
    
    // Delete the feedback
    await PharmacyFeedback.findByIdAndDelete(feedbackId);
    
    console.log('✅ [API] Feedback deleted successfully:', feedbackId);
    
    res.json({ message: 'Feedback deleted successfully' });
  } catch (error) {
    console.error('❌ [API] Delete feedback error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Reports mock
router.get('/reports/sales', async (req, res) => {
  const period = (req.query.period || 'daily').toString();
  let groupStage;
  if (period === 'monthly') {
    groupStage = { _id: { $dateToString: { format: '%Y-%m', date: '$createdAt' } } };
  } else if (period === 'weekly') {
    groupStage = { _id: { $concat: [ { $toString: { $isoWeekYear: '$createdAt' } }, '-', { $toString: { $isoWeek: '$createdAt' } } ] } };
  } else {
    groupStage = { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } } };
  }
  const rows = await Order.aggregate([
    { $match: { status: 'delivered' } },
    { $group: Object.assign({}, groupStage, { total: { $sum: '$total' } }) },
    { $sort: { _id: 1 } },
  ]);
  res.json(rows);
});

// Chat API endpoints
// Get all users who have chatted with the pharmacy
router.get('/chat/:pharmacyId/users', authMiddleware, async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const userId = req.user?.uid;

    console.log('🔍 [API] Getting chat users for pharmacy:', pharmacyId);

    // Get user's pharmacy to verify access
    const userPharmacy = await Pharmacy.findOne({ ownerId: userId });
    if (!userPharmacy) {
      return res.status(403).json({ error: 'No pharmacy found for user' });
    }

    // Check if the pharmacyId matches the user's pharmacy
    if (userPharmacy._id.toString() !== pharmacyId) {
      return res.status(403).json({ error: 'Not authorized to access this pharmacy chat' });
    }

    // Get all unique users who have sent messages to this pharmacy
    const chatUsers = await ChatMessage.aggregate([
      { $match: { pharmacyId: mongoose.Types.ObjectId(pharmacyId), senderType: 'patient' } },
      { $group: { 
        _id: '$senderId', 
        senderName: { $first: '$senderName' },
        lastMessage: { $last: '$message' },
        lastMessageTime: { $last: '$createdAt' },
        unreadCount: { $sum: { $cond: [{ $eq: ['$isRead', false] }, 1, 0] } }
      }},
      { $sort: { lastMessageTime: -1 } }
    ]);

    console.log('✅ [API] Found chat users:', chatUsers.length);
    res.json({ users: chatUsers });
  } catch (error) {
    console.error('❌ [API] Get chat users error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get chat messages for a specific user and pharmacy
router.get('/chat/:pharmacyId/user/:userId', authMiddleware, async (req, res) => {
  try {
    const { pharmacyId, userId: targetUserId } = req.params;
    const currentUserId = req.user?.uid;

    console.log('🔍 [API] Getting chat messages for pharmacy:', pharmacyId, 'user:', targetUserId);

    // Get user's pharmacy to verify access
    const userPharmacy = await Pharmacy.findOne({ ownerId: currentUserId });
    if (!userPharmacy) {
      return res.status(403).json({ error: 'No pharmacy found for user' });
    }

    // Check if the pharmacyId matches the user's pharmacy
    if (userPharmacy._id.toString() !== pharmacyId) {
      return res.status(403).json({ error: 'Not authorized to access this pharmacy chat' });
    }

    const messages = await ChatMessage.find({ 
      pharmacyId,
      $or: [
        { senderId: targetUserId },
        { recipientId: targetUserId }
      ]
    })
      .sort({ createdAt: 1 })
      .limit(100);

    console.log('✅ [API] Found chat messages:', messages.length);
    res.json({ messages });
  } catch (error) {
    console.error('❌ [API] Get chat messages error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get chat messages for a pharmacy (legacy endpoint - now returns all messages)
router.get('/chat/:pharmacyId', authMiddleware, async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const userId = req.user?.uid;

    console.log('🔍 [API] Getting chat messages for pharmacy:', pharmacyId, 'user:', userId);

    // Get user's pharmacy to verify access
    const userPharmacy = await Pharmacy.findOne({ ownerId: userId });
    if (!userPharmacy) {
      return res.status(403).json({ error: 'No pharmacy found for user' });
    }

    // Check if the pharmacyId matches the user's pharmacy
    if (userPharmacy._id.toString() !== pharmacyId) {
      return res.status(403).json({ error: 'Not authorized to access this pharmacy chat' });
    }

    const messages = await ChatMessage.find({ pharmacyId })
      .sort({ createdAt: 1 })
      .limit(100);

    console.log('✅ [API] Found chat messages:', messages.length);

    res.json({ messages });
  } catch (error) {
    console.error('❌ [API] Get chat messages error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Send a chat message
router.post('/chat/:pharmacyId', authMiddleware, async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const { message, senderId, senderName, senderType, recipientId, recipientName } = req.body;
    const userId = req.user?.uid;

    console.log('🔍 [API] Sending chat message:', { pharmacyId, message, senderId, senderName, senderType, recipientId, recipientName });

    if (!message || !senderId || !senderName || !senderType) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Get user's pharmacy to verify access
    const userPharmacy = await Pharmacy.findOne({ ownerId: userId });
    if (!userPharmacy) {
      return res.status(403).json({ error: 'No pharmacy found for user' });
    }

    // Check if the pharmacyId matches the user's pharmacy
    if (userPharmacy._id.toString() !== pharmacyId) {
      return res.status(403).json({ error: 'Not authorized to send messages to this pharmacy' });
    }

    const chatMessage = new ChatMessage({
      pharmacyId,
      senderId,
      senderName,
      senderType,
      message,
      recipientId,
      recipientName,
    });

    await chatMessage.save();

    console.log('✅ [API] Chat message created:', chatMessage._id);

    res.status(201).json({ message: chatMessage });
  } catch (error) {
    console.error('❌ [API] Send chat message error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Mark messages as read
router.patch('/chat/:pharmacyId/read', authMiddleware, async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const userId = req.user?.uid;

    console.log('🔍 [API] Marking messages as read for pharmacy:', pharmacyId);

    // Get user's pharmacy to verify access
    const userPharmacy = await Pharmacy.findOne({ ownerId: userId });
    if (!userPharmacy) {
      return res.status(403).json({ error: 'No pharmacy found for user' });
    }

    // Check if the pharmacyId matches the user's pharmacy
    if (userPharmacy._id.toString() !== pharmacyId) {
      return res.status(403).json({ error: 'Not authorized to mark messages as read' });
    }

    await ChatMessage.updateMany(
      { pharmacyId, senderType: 'patient', isRead: false },
      { isRead: true, readAt: new Date() }
    );

    console.log('✅ [API] Messages marked as read');

    res.json({ message: 'Messages marked as read' });
  } catch (error) {
    console.error('❌ [API] Mark messages as read error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete all chat messages for a pharmacy
router.delete('/chat/:pharmacyId', authMiddleware, async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const userId = req.user?.uid;

    console.log('🔍 [API] Deleting chat messages for pharmacy:', pharmacyId);

    // Get user's pharmacy to verify access
    const userPharmacy = await Pharmacy.findOne({ ownerId: userId });
    if (!userPharmacy) {
      return res.status(403).json({ error: 'No pharmacy found for user' });
    }

    // Check if the pharmacyId matches the user's pharmacy
    if (userPharmacy._id.toString() !== pharmacyId) {
      return res.status(403).json({ error: 'Not authorized to delete messages for this pharmacy' });
    }

    const result = await ChatMessage.deleteMany({ pharmacyId });
    
    console.log('✅ [API] Deleted chat messages:', result.deletedCount);

    res.json({ 
      message: 'Chat messages deleted successfully',
      deletedCount: result.deletedCount 
    });
  } catch (error) {
    console.error('❌ [API] Delete chat messages error:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;



const express = require('express');
const Order = require('../schemas/Order');

const router = express.Router();

// 📌 Place new order
router.post('/', async (req, res) => {
  try {
    const { customerId, items, total, pharmacyId, address, paymentMethod, deliveryPartnerId, deliveryPartnerName, deliveryPartnerPhone } = req.body;

    // Get pharmacy name for the order
    let pharmacyName = 'Unknown Pharmacy';
    if (pharmacyId) {
      try {
        const Pharmacy = require('../schemas/Pharmacy');
        const pharmacy = await Pharmacy.findById(pharmacyId).select('name');
        if (pharmacy) {
          pharmacyName = pharmacy.name;
        }
      } catch (e) {
        console.log('⚠️ Could not find pharmacy name for ID:', pharmacyId);
      }
    }

    const newOrder = new Order({
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
      deliveryPartnerId: deliveryPartnerId || null,
      deliveryPartnerName: deliveryPartnerName || null,
      deliveryPartnerPhone: deliveryPartnerPhone || null,
    });

    await newOrder.save();

    console.log('✅ Order created with ID:', newOrder._id, 'pharmacyId:', newOrder.pharmacyId);

    res.status(201).json({ 
      message: 'Order placed', 
      data: newOrder
    });
  } catch (err) {
    console.error('Order creation error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 📌 Fetch orders (scoped for pharmacists)
router.get('/', async (req, res) => {
  try {
    let filter = {};
    // If authenticated pharmacist, scope by pharmacy via linked prescriptions AND direct checkout orders
    try {
      const jwt = require('jsonwebtoken');
      const Pharmacy = require('../schemas/Pharmacy');
      const Prescription = require('../schemas/Prescription');
      const authHeader = req.headers.authorization;
      const bearer = authHeader && authHeader.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : null;
      if (bearer) {
        const decoded = jwt.verify(bearer, process.env.JWT_SECRET || 'devsecret');
        if (decoded?.role === 'pharmacist') {
          const ph = await Pharmacy.findOne({ ownerId: decoded.uid }).select('_id name');
          if (ph) {
            const pres = await Prescription.find({ pharmacyId: ph._id, orderId: { $exists: true, $ne: null } }).select('orderId');
            const orderIds = pres.map(p => p.orderId).filter(Boolean);
            filter = {
              $or: [
                { _id: { $in: orderIds } },
                { pharmacyId: ph._id },
                { pharmacyId: ph._id.toString() },
                { pharmacy: ph.name },
                { pharmacy: { $regex: ph.name, $options: 'i' } },
              ]
            };
          } else {
            // Pharmacist without a pharmacy should not see any orders
            filter = { _id: { $in: [] } };
          }
        }
      }
    } catch (_) {}
    
    const orders = await Order.find(filter).populate('customerId').populate('invoiceId').sort({ createdAt: -1 });
    
    // Get prescription data for orders that have it
    const Prescription = require('../schemas/Prescription');
    const prescriptions = await Prescription.find({ orderId: { $in: orders.map(o => o._id) } });
    const prescriptionMap = new Map(prescriptions.map(p => [String(p.orderId), p]));
    
    // Format orders with prescription data
    const formattedOrders = orders.map(order => {
      const prescription = prescriptionMap.get(String(order._id));
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
        invoiceId: order.invoiceId || null,
        deliveryPartnerId: order.deliveryPartnerId || null,
        deliveryPartnerName: order.deliveryPartnerName || null,
        deliveryPartnerPhone: order.deliveryPartnerPhone || null,
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
    
    res.json(formattedOrders);
  } catch (err) {
    console.error('Orders fetch error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 📌 Process prescription order
router.post('/process-prescription', async (req, res) => {
  try {
    const { prescriptionId, pharmacyId, customerAddress, customerPhone, paymentMethod, deliveryPartnerId } = req.body;

    // Create order from prescription
    const newOrder = new Order({
      customerId: null, // Will be set from prescription
      items: [], // Will be populated from prescription
      total: 0, // Will be calculated
      status: 'pending',
      pharmacyId: pharmacyId,
      address: customerAddress,
      paymentMethod: paymentMethod,
      deliveryPartnerId: deliveryPartnerId || null,
      prescriptionId: prescriptionId,
    });

    await newOrder.save();

    console.log('✅ Prescription order processed with ID:', newOrder._id);

    res.status(201).json({ 
      message: 'Prescription order processed', 
      data: newOrder
    });
  } catch (err) {
    console.error('Process prescription order error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 📌 Assign delivery partner to order
router.put('/:orderId/assign-delivery', async (req, res) => {
  try {
    const { orderId } = req.params;
    const { deliveryPartnerId } = req.body;

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
    console.error('Assign delivery partner error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 📌 Confirm order
router.put('/:orderId/confirm', async (req, res) => {
  try {
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
    console.error('Confirm order error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 📌 Create order from prescription
router.post('/from-prescription', async (req, res) => {
  try {
    const { prescriptionId, deliveryPartnerId, total, paymentMethod } = req.body;

    // Get prescription details
    const Prescription = require('../schemas/Prescription');
    const prescription = await Prescription.findById(prescriptionId);
    
    if (!prescription) {
      return res.status(404).json({ error: 'Prescription not found' });
    }

    // Create order from prescription
    const newOrder = new Order({
      customerId: prescription.customerId,
      items: prescription.medicines ? prescription.medicines.map(med => ({
        medicineId: null,
        quantity: 1,
        price: 0, // Will be calculated by pharmacy
        name: med.name || 'Medicine',
      })) : [],
      total: Number(total) || 0,
      status: 'processing',
      pharmacyId: prescription.pharmacyId,
      pharmacy: prescription.pharmacyName || 'Unknown Pharmacy',
      address: prescription.customerAddress || 'No address provided',
      paymentMethod: paymentMethod || prescription.paymentMethod || 'cash',
      deliveryPartnerId: deliveryPartnerId || null,
      prescriptionId: prescriptionId,
    });

    await newOrder.save();

    // Update prescription status
    prescription.status = 'processing';
    prescription.orderId = newOrder._id;
    await prescription.save();

    console.log('✅ Order created from prescription with ID:', newOrder._id);

    res.status(201).json({ 
      message: 'Order created from prescription', 
      data: newOrder
    });
  } catch (err) {
    console.error('Create order from prescription error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 📌 Delete order
router.delete('/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;
    const { customerId } = req.query;

    console.log('🗑️ Attempting to delete order:', orderId, 'for customer:', customerId);

    // Find the order first
    const order = await Order.findById(orderId);
    if (!order) {
      console.log('❌ Order not found:', orderId);
      return res.status(404).json({ error: 'Order not found' });
    }

    // If customerId is provided, verify the order belongs to that customer
    if (customerId && order.customerId && order.customerId.toString() !== customerId) {
      console.log('❌ Order does not belong to customer:', customerId);
      return res.status(403).json({ error: 'Order does not belong to this customer' });
    }

    // Delete the order
    await Order.findByIdAndDelete(orderId);

    console.log('✅ Order deleted successfully:', orderId);

    res.json({ 
      message: 'Order deleted successfully',
      orderId: orderId
    });
  } catch (err) {
    console.error('Delete order error:', err);
    res.status(500).json({ error: err.message });
  }
});

// 📌 Update order status and payment
router.patch('/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;
    const updateData = req.body;

    console.log('📝 Updating order:', orderId, 'with data:', updateData);

    const order = await Order.findByIdAndUpdate(
      orderId,
      updateData,
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    console.log('✅ Order updated successfully:', orderId);
    console.log('✅ Updated order data:', {
      _id: order._id,
      deliveryPartnerId: order.deliveryPartnerId,
      deliveryPartnerName: order.deliveryPartnerName,
      deliveryPartnerPhone: order.deliveryPartnerPhone
    });

    // Return the order in the same format as GET endpoint
    const formattedOrder = {
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
      orderedByRole: 'customer',
      deliveryDate: null,
      trackingId: null,
      paymentStatus: order.paymentStatus || 'pending',
      invoiceId: order.invoiceId || null,
      deliveryPartnerId: order.deliveryPartnerId || null,
      deliveryPartnerName: order.deliveryPartnerName || null,
      deliveryPartnerPhone: order.deliveryPartnerPhone || null,
      tracking: order.tracking || {}
    };

    res.json({ 
      message: 'Order updated successfully',
      ...formattedOrder
    });
  } catch (err) {
    console.error('Update order error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

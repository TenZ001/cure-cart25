const express = require('express');
const Pharmacy = require('../schemas/Pharmacy');
const Order = require('../schemas/Order');
const Prescription = require('../schemas/Prescription');
const DeliveryPartner = require('../schemas/DeliveryPartner');
const PharmacyFeedback = require('../schemas/PharmacyFeedback');
const User = require('../schemas/User');
const ChatMessage = require('../schemas/ChatMessage');

const router = express.Router();

// Public: list approved pharmacies for customers to choose on mobile upload
router.get('/pharmacies', async (_req, res) => {
  try {
    const rows = await Pharmacy.find({ status: 'approved' })
      .select('_id name address contact')
      .sort({ name: 1 });
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Public: list available delivery partners
router.get('/delivery-partners/available', async (_req, res) => {
  try {
    const rows = await DeliveryPartner.find({ status: 'approved', active: true })
      .select('_id name contact vehicleNo')
      .sort({ name: 1 });
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Public: get assigned orders for a delivery partner (with prescription data)
router.get('/delivery/assigned', async (req, res) => {
  try {
    const { partnerId } = req.query;
    console.log('🔍 [PUBLIC] Assigned orders for partner:', partnerId);
    
    if (!partnerId) {
      return res.status(400).json({ error: 'partnerId is required' });
    }
    
    // Get all assigned orders for this partner (not delivered yet)
    const orders = await Order.find({
      deliveryPartnerId: partnerId,
      status: { $in: ['processing', 'dispatched', 'out_for_delivery'] }
    }).sort({ createdAt: -1 });
    
    console.log('📦 [PUBLIC] Found assigned orders:', orders.length);
    
    // Get prescription data for these orders
    const presByOrder = await Prescription.find({ 
      orderId: { $in: orders.map(o => o._id) } 
    }).select('orderId customerAddress customerPhone paymentMethod pharmacyName pharmacyAddress');
    
    const map = new Map(presByOrder.map(p => [String(p.orderId), p]));
    console.log('📋 [PUBLIC] Found prescriptions:', presByOrder.length);
    
    // Format the response with prescription data
    const assigned = orders.map(order => {
      const pres = map.get(String(order._id));
      return {
        _id: order._id,
        pharmacy: pres?.pharmacyName || order.pharmacy || 'Unknown Pharmacy',
        address: pres?.pharmacyAddress || order.pharmacyAddress || order.address || 'No address',
        customerAddress: pres?.customerAddress || order.address || 'No address',
        customerPhone: pres?.customerPhone || '',
        paymentMethod: pres?.paymentMethod || order.paymentMethod || '',
        total: order.total || 0,
        status: order.status,
        createdAt: order.createdAt,
        items: order.items || []
      };
    });
    
    console.log('📋 [PUBLIC] Assigned orders formatted with prescription data:', assigned.length);
    console.log('📋 [PUBLIC] Sample order:', assigned.isNotEmpty ? assigned[0] : 'No data');
    res.json(assigned);
  } catch (e) {
    console.error('❌ [PUBLIC] Assigned orders error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Public: get delivery history for a delivery partner
router.get('/delivery/history', async (req, res) => {
  try {
    const { partnerId } = req.query;
    console.log('🔍 [PUBLIC] Delivery history for partner:', partnerId);
    
    if (!partnerId) {
      return res.status(400).json({ error: 'partnerId is required' });
    }
    
    // First, let's see ALL orders assigned to this partner for debugging
    const allAssignedOrders = await Order.find({
      deliveryPartnerId: partnerId
    }).sort({ createdAt: -1 });
    
    console.log('🔍 [PUBLIC] All orders assigned to partner:', allAssignedOrders.length);
    console.log('🔍 [PUBLIC] All assigned order details:', allAssignedOrders.map(o => ({
      id: o._id,
      status: o.status,
      delivered: o.delivered,
      deliveredAt: o.deliveredAt,
      createdAt: o.createdAt,
      pharmacy: o.pharmacy
    })));
    
    // Get only truly delivered orders for this partner
    // Only include orders that have been explicitly marked as delivered
    const orders = await Order.find({
      deliveryPartnerId: partnerId,
      $or: [
        { status: 'delivered' },
        { delivered: true }
      ]
    }).sort({ deliveredAt: -1, createdAt: -1 });
    
    console.log('📦 [PUBLIC] Found delivered orders:', orders.length);
    console.log('📦 [PUBLIC] Order details:', orders.map(o => ({
      id: o._id,
      status: o.status,
      delivered: o.delivered,
      deliveredAt: o.deliveredAt,
      createdAt: o.createdAt,
      paymentStatus: o.paymentStatus
    })));
    
    // Additional debugging: Check if any orders have the delivered flag set
    const deliveredOrders = allAssignedOrders.filter(o => o.delivered === true);
    console.log('🔍 [PUBLIC] Orders with delivered=true:', deliveredOrders.length);
    console.log('🔍 [PUBLIC] Delivered orders details:', deliveredOrders.map(o => ({
      id: o._id,
      status: o.status,
      delivered: o.delivered,
      deliveredAt: o.deliveredAt
    })));
    
    // Only show truly delivered orders - no fallback to assigned orders
    let ordersToShow = orders;
    
    // Format the response with delivery information
    const history = ordersToShow.map(order => ({
      _id: order._id,
      pharmacy: order.pharmacy || 'Unknown Pharmacy',
      address: order.address || 'No address',
      total: order.total || 0,
      status: order.status,
      delivered: order.delivered || false,
      deliveredAt: order.deliveredAt || order.updatedAt,
      createdAt: order.createdAt,
      items: order.items || [],
      // Add more details for better display
      orderDate: order.createdAt,
      deliveryDate: order.deliveredAt || order.updatedAt,
      isCompleted: order.status === 'delivered' || order.delivered === true || order.status === 'completed',
      // Add delivery partner info for verification
      deliveryPartnerId: order.deliveryPartnerId,
      deliveryPartnerName: order.deliveryPartnerName,
      deliveryPartnerPhone: order.deliveryPartnerPhone,
      // Add tracking info if available
      tracking: order.tracking || {},
      // Add payment status
      paymentStatus: order.paymentStatus || 'unpaid'
    }));
    
    console.log('📋 [PUBLIC] Delivery history formatted:', history.length);
    res.json(history);
  } catch (e) {
    console.error('❌ [PUBLIC] Delivery history error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Public: update delivery status for an order
router.patch('/orders/:orderId/delivery', async (req, res) => {
  try {
    const { orderId } = req.params;
    const { partnerId, status, delivered, deliveredAt, pickedUp, pickedUpAt } = req.body;
    
    console.log('🚚 [PUBLIC] Delivery update for order:', orderId);
    console.log('🚚 [PUBLIC] Update data:', { partnerId, status, delivered, deliveredAt, pickedUp, pickedUpAt });
    
    if (!partnerId) {
      return res.status(400).json({ error: 'partnerId is required' });
    }
    
    // Verify the order is assigned to this partner
    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    console.log('🔍 [PUBLIC] Order found:', {
      orderId: order._id,
      deliveryPartnerId: order.deliveryPartnerId,
      status: order.status
    });
    
    // Convert both to strings for comparison
    const orderPartnerId = order.deliveryPartnerId?.toString();
    const requestPartnerId = partnerId?.toString();
    
    console.log('🔍 [PUBLIC] Comparing partner IDs:', {
      orderPartnerId,
      requestPartnerId,
      match: orderPartnerId === requestPartnerId
    });
    
    if (orderPartnerId !== requestPartnerId) {
      console.log('❌ [PUBLIC] Partner ID mismatch:', {
        orderPartnerId,
        requestPartnerId
      });
      return res.status(403).json({ error: 'Order not assigned to this delivery partner' });
    }
    
    // Update the order with delivery information
    const updateData = {};
    if (status) updateData.status = status;
    if (delivered !== undefined) updateData.delivered = delivered;
    if (deliveredAt) updateData.deliveredAt = deliveredAt;
    if (pickedUp !== undefined) updateData.pickedUp = pickedUp;
    if (pickedUpAt) updateData.pickedUpAt = pickedUpAt;
    
    // Handle specific status updates
    if (status === 'delivered') {
      updateData.status = 'delivered';
      updateData.delivered = true;
      updateData.deliveredAt = deliveredAt || new Date();
      updateData.paymentStatus = 'paid'; // Mark payment as paid when delivered
      console.log('✅ [PUBLIC] Setting order as delivered with payment status paid');
    } else if (status === 'out_for_delivery' && pickedUp) {
      updateData.status = 'out_for_delivery';
      updateData.pickedUp = true;
      updateData.pickedUpAt = pickedUpAt || new Date();
    }
    
    const updatedOrder = await Order.findByIdAndUpdate(
      orderId,
      updateData,
      { new: true }
    );
    
    console.log('✅ [PUBLIC] Order delivery updated:', {
      orderId: updatedOrder._id,
      status: updatedOrder.status,
      delivered: updatedOrder.delivered,
      deliveredAt: updatedOrder.deliveredAt,
      pickedUp: updatedOrder.pickedUp,
      pickedUpAt: updatedOrder.pickedUpAt
    });
    
    console.log('🔍 [PUBLIC] Update data applied:', updateData);
    
    res.json({
      message: 'Delivery status updated successfully',
      order: {
        _id: updatedOrder._id,
        status: updatedOrder.status,
        delivered: updatedOrder.delivered,
        deliveredAt: updatedOrder.deliveredAt,
        pickedUp: updatedOrder.pickedUp,
        pickedUpAt: updatedOrder.pickedUpAt
      }
    });
  } catch (e) {
    console.error('❌ [PUBLIC] Delivery update error:', e);
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;

// Public order details (joined with prescription minimal fields)
router.get('/orders/:id/details', async (req, res) => {
  try {
    const order = await Order.findById(req.params.id).select('_id total status customerId deliveryPartnerId createdAt deliveryDate tracking pharmacy pharmacyAddress address paymentMethod pharmacyId');
    if (!order) return res.status(404).json({ error: 'Order not found' });
    const pres = await Prescription.findOne({ orderId: order._id }).select('customerAddress customerPhone paymentMethod pharmacyName pharmacyAddress');
    // If prescription missing some fields, include order-level fallbacks
    const payload = {
      order,
      prescription: pres
    };
    return res.json(payload);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});


// Public: update delivery date for an order (validated by partner assignment)
router.patch('/orders/:id/delivery', async (req, res) => {
  try {
    const { partnerId, deliveryDate, pickedUp, delivered, deliveredAt, status } = req.body || {};
    if (!partnerId) return res.status(400).json({ error: 'partnerId required' });
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ error: 'Order not found' });
    if (!order.deliveryPartnerId || String(order.deliveryPartnerId) !== String(partnerId)) {
      return res.status(403).json({ error: 'Not assigned to this partner' });
    }
    
    if (deliveryDate !== undefined) order.deliveryDate = deliveryDate;
    
    // Handle status updates
    if (status) {
      order.status = status;
    }
    
    if (pickedUp) {
      order.tracking = Object.assign({}, order.tracking || {}, {
        pickedUpAt: new Date(),
        pickedUpBy: order.deliveryPartnerId,
        lastUpdatedAt: new Date(),
      });
      // Update status to out_for_delivery when picked up
      order.status = 'out_for_delivery';
    }
    
    if (delivered || status === 'delivered') {
      // Update order status to delivered
      order.status = 'delivered';
      order.paymentStatus = 'paid'; // Update payment status to paid
      order.tracking = Object.assign({}, order.tracking || {}, {
        deliveredAt: deliveredAt ? new Date(deliveredAt) : new Date(),
        deliveredBy: order.deliveryPartnerId,
        lastUpdatedAt: new Date(),
      });
      
      // Update prescription status to delivered
      try {
        const prescription = await Prescription.findOne({ orderId: order._id });
        if (prescription) {
          prescription.status = 'delivered';
          await prescription.save();
        }
      } catch (e) {
        console.error('Error updating prescription status:', e);
      }
      
      // Update invoice payment status to paid
      try {
        const Invoice = require('../schemas/Invoice');
        const invoice = await Invoice.findOne({ orderId: order._id });
        if (invoice) {
          invoice.status = 'paid';
          await invoice.save();
        }
      } catch (e) {
        console.error('Error updating invoice payment status:', e);
      }
    }
    
    await order.save();
    res.json(order);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Public: Submit pharmacy feedback (no authentication required)
router.post('/pharmacy-feedback', async (req, res) => {
  try {
    const { pharmacyId, customerId, rating, comment } = req.body;
    
    console.log('🔍 [PUBLIC] Pharmacy feedback submission:', { pharmacyId, customerId, rating, comment });
    
    if (!pharmacyId || !customerId || !rating) {
      return res.status(400).json({ error: 'pharmacyId, customerId, and rating are required' });
    }
    
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }
    
    // Get customer info for easier display (optional - allow anonymous feedback)
    let customer = null;
    let customerName = 'Anonymous';
    let customerEmail = '';
    
    try {
      customer = await User.findById(customerId);
      if (customer) {
        customerName = customer.name || 'Anonymous';
        customerEmail = customer.email || '';
        console.log('✅ [PUBLIC] Customer found:', { id: customer._id, name: customerName });
      } else {
        console.log('⚠️ [PUBLIC] Customer not found, using anonymous feedback');
      }
    } catch (error) {
      console.log('⚠️ [PUBLIC] Error finding customer, using anonymous feedback:', error.message);
    }
    
    // Check if pharmacy exists
    const pharmacy = await Pharmacy.findById(pharmacyId);
    if (!pharmacy) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }
    
    // Create feedback
    const feedback = new PharmacyFeedback({
      pharmacyId,
      customerId: customer ? customerId : null, // Only set customerId if customer exists
      rating,
      comment: comment || '',
      customerName: customerName,
      customerEmail: customerEmail,
    });
    
    await feedback.save();
    
    console.log('✅ [PUBLIC] Pharmacy feedback created:', feedback._id);
    
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
    console.error('❌ [PUBLIC] Pharmacy feedback error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Public: Get chat messages for a pharmacy (for patients)
router.get('/chat/:pharmacyId', async (req, res) => {
  try {
    const { pharmacyId } = req.params;

    console.log('🔍 [PUBLIC] Getting chat messages for pharmacy:', pharmacyId);

    // Check if pharmacy exists
    const pharmacy = await Pharmacy.findById(pharmacyId);
    if (!pharmacy) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }

    const messages = await ChatMessage.find({ pharmacyId })
      .sort({ createdAt: 1 })
      .limit(100);

    console.log('✅ [PUBLIC] Found chat messages:', messages.length);

    res.json({ messages });
  } catch (error) {
    console.error('❌ [PUBLIC] Get chat messages error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Public: Send chat message (for patients)
router.post('/chat/:pharmacyId', async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const { message, senderId, senderName, senderType } = req.body;

    console.log('🔍 [PUBLIC] Sending chat message:', { pharmacyId, message, senderId, senderName, senderType });

    if (!message || !senderId || !senderName || !senderType) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if pharmacy exists
    const pharmacy = await Pharmacy.findById(pharmacyId);
    if (!pharmacy) {
      return res.status(404).json({ error: 'Pharmacy not found' });
    }

    const chatMessage = new ChatMessage({
      pharmacyId,
      senderId,
      senderName,
      senderType,
      message,
    });

    await chatMessage.save();

    console.log('✅ [PUBLIC] Chat message created:', chatMessage._id);

    res.status(201).json({ message: chatMessage });
  } catch (error) {
    console.error('❌ [PUBLIC] Send chat message error:', error);
    res.status(500).json({ error: error.message });
  }
});



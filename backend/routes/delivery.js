// routes/delivery.js
const express = require("express");
const Order = require("../models/Order");
const User = require("../models/user");

const router = express.Router();

// Assigned orders for a delivery partner
router.get("/assigned", async (req, res) => {
  try {
    const { partnerId } = req.query;
    if (!partnerId) return res.status(400).json({ message: "partnerId required" });

    const orders = await Order.find({
      deliveryPartnerId: partnerId,
      status: { $ne: "delivered" },
    })
      .sort({ createdAt: -1 });

    res.json(orders);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update delivery status
router.patch("/orders/:id/status", async (req, res) => {
  try {
    const { status } = req.body;
    const valid = ["assigned", "picked_up", "en_route", "dispatched", "delivered"]; 
    if (!valid.includes(status)) return res.status(400).json({ message: "Invalid status" });

    const updateData = {
      status,
      $push: { deliveryStatusHistory: { status, at: new Date() } },
    };

    // Handle specific status updates
    if (status === 'delivered') {
      updateData.delivered = true;
      updateData.deliveredAt = new Date();
      updateData.paymentStatus = 'paid'; // Mark payment as paid when delivered
      console.log('✅ [BACKEND] Setting order as delivered with payment status paid');
    } else if (status === 'picked_up') {
      updateData.pickedUp = true;
      updateData.pickedUpAt = new Date();
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    );
    if (!order) return res.status(404).json({ message: "Order not found" });
    
    console.log('✅ [BACKEND] Order status updated:', {
      orderId: order._id,
      status: order.status,
      delivered: order.delivered,
      deliveredAt: order.deliveredAt,
      paymentStatus: order.paymentStatus
    });
    
    res.json(order);
  } catch (err) {
    console.error('❌ [BACKEND] Delivery status update error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Update delivery partner live location
router.patch("/orders/:id/location", async (req, res) => {
  try {
    const { lat, lng } = req.body;
    if (typeof lat !== "number" || typeof lng !== "number") {
      return res.status(400).json({ message: "lat and lng must be numbers" });
    }
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { deliveryLat: lat, deliveryLng: lng },
      { new: true }
    );
    if (!order) return res.status(404).json({ message: "Order not found" });
    res.json(order);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Delivery history
router.get("/orders/history", async (req, res) => {
  try {
    const { partnerId } = req.query;
    if (!partnerId) return res.status(400).json({ message: "partnerId required" });
    
    console.log('🔍 [BACKEND] Delivery history for partner:', partnerId);
    
    // Get only truly delivered orders for this partner
    // Only include orders that have been explicitly marked as delivered
    const orders = await Order.find({
      deliveryPartnerId: partnerId,
      $or: [
        { status: 'delivered' },
        { delivered: true }
      ]
    }).sort({ deliveredAt: -1, updatedAt: -1 });
    
    console.log('📦 [BACKEND] Found delivered orders:', orders.length);
    console.log('📦 [BACKEND] Order details:', orders.map(o => ({
      id: o._id,
      status: o.status,
      delivered: o.delivered,
      deliveredAt: o.deliveredAt,
      createdAt: o.createdAt
    })));
    
    res.json(orders);
  } catch (err) {
    console.error('❌ [BACKEND] Delivery history error:', err);
    res.status(500).json({ message: err.message });
  }
});

// Get order by id (for tracking)
router.get("/orders/:id", async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: "Order not found" });
    res.json(order);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get customer contact/location details for an order
router.get("/orders/:id/contact", async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: "Order not found" });

    const customer = await User.findById(order.customerId).select("name phone address");
    res.json({
      customer,
      address: order.address,
      customerLat: order.customerLat,
      customerLng: order.customerLng,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Notify admin when a delivery partner logs in (stub)
router.post("/login-notify", async (req, res) => {
  try {
    const { userId } = req.body;
    console.log(`📣 Delivery partner logged in: ${userId}`);
    // Integrate with email/SMS/FCM as needed
    res.json({ message: "Admin notified" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;



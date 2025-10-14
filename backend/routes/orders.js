// routes/orders.js
const express = require("express");
const Order = require("../models/Order");
const User = require("../models/user");

const router = express.Router();

// Create a new order
router.post("/", async (req, res) => {
  try {
    const { customerId, items, pharmacy, address, status = "assigned" } = req.body;

    if (!customerId || !items || !Array.isArray(items)) {
      return res.status(400).json({ message: "customerId and items array required" });
    }

    // Validate customer exists
    const customer = await User.findById(customerId);
    if (!customer) {
      return res.status(404).json({ message: "Customer not found" });
    }

    // Create the order
    const order = new Order({
      customerId,
      items: items.map(item => ({
        name: item.name,
        qty: item.qty || 1,
        price: item.price || 0, // Add price field
      })),
      pharmacy: pharmacy || "Unknown Pharmacy",
      pharmacyId: pharmacy, // Also store as pharmacyId for web API compatibility
      address: address || "No address provided",
      status,
    });

    await order.save();

    res.status(201).json({
      message: "Order created successfully",
      order: {
        _id: order._id,
        customerId: order.customerId,
        items: order.items,
        pharmacy: order.pharmacy,
        address: order.address,
        status: order.status,
        createdAt: order.createdAt,
      }
    });
  } catch (err) {
    console.error("Order creation error:", err);
    res.status(500).json({ message: err.message });
  }
});

// Get all orders (for pharmacy management)
router.get("/", async (req, res) => {
  try {
    const orders = await Order.find()
      .populate("customerId", "name email phone")
      .sort({ createdAt: -1 });

    res.json(orders);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get orders by pharmacy
router.get("/pharmacy/:pharmacyId", async (req, res) => {
  try {
    const { pharmacyId } = req.params;
    const orders = await Order.find({ pharmacy: pharmacyId })
      .populate("customerId", "name email phone")
      .sort({ createdAt: -1 });

    res.json(orders);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Get order by ID
router.get("/:id", async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate("customerId", "name email phone");
    
    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    res.json(order);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Update order status
router.patch("/:id/status", async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ["assigned", "picked_up", "en_route", "delivered"];
    
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { 
        status,
        $push: { deliveryStatusHistory: { status, at: new Date() } }
      },
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }

    res.json(order);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

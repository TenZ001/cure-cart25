// routes/auth.js
const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/user");
const router = express.Router();

// REGISTER
router.post("/register", async (req, res) => {
  try {
    const { name, email, phone, role, address, dob, pharmacyName, password, vehicleType, vehicleNumber, nic, emergencyContactName, emergencyContactPhone } = req.body;

    // Use curecartmobile collection for mobile registration
    const mongoose = require('mongoose');
    const mobileDb = mongoose.connection.useDb('curecartmobile');
    const MobileUser = mobileDb.model('User', User.schema);

    const existing = await MobileUser.findOne({ email });
    if (existing) return res.status(400).json({ message: "User already exists" });

    // Only require vehicle fields for delivery role
    if (role === 'delivery' && (!vehicleType || !vehicleNumber)) {
      return res.status(400).json({ message: "Vehicle type and number are required for delivery role" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = new MobileUser({
      name,
      email,
      phone,
      role,
      address,
      dob,
      pharmacyName,
      password: hashedPassword,
      // Only include vehicle fields for delivery role
      ...(role === 'delivery' && { vehicleType, vehicleNumber }),
      nic,
      emergencyContactName,
      emergencyContactPhone,
    });
    await user.save();

    res.status(201).json({ message: `${role} registered successfully` });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/auth/mobile-users - List mobile users from curecartmobile collection
router.get("/mobile-users", async (req, res) => {
  try {
    // Connect to the curecartmobile database
    const mongoose = require('mongoose');
    const mobileDb = mongoose.connection.useDb('curecartmobile');
    const MobileUser = mobileDb.model('User', User.schema);
    
    const users = await MobileUser.find({}).select('name email role phone address');
    res.json(users);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/auth/reset-mobile-password - Reset mobile user password
router.post("/reset-mobile-password", async (req, res) => {
  try {
    const { email, newPassword, role } = req.body;
    
    const mongoose = require('mongoose');
    const mobileDb = mongoose.connection.useDb('curecartmobile');
    const MobileUser = mobileDb.model('User', User.schema);
    
    const user = await MobileUser.findOne({ email, role });
    if (!user) return res.status(404).json({ message: "User not found" });
    
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    user.password = hashedPassword;
    await user.save();
    
    res.json({ message: "Mobile user password updated successfully", user: { name: user.name, email: user.email, role: user.role } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// LOGIN
router.post("/login", async (req, res) => {
  try {
    const { email, password, role } = req.body;

    // First try curecartmobile collection
    const mongoose = require('mongoose');
    const mobileDb = mongoose.connection.useDb('curecartmobile');
    const MobileUser = mobileDb.model('User', User.schema);
    
    let user = await MobileUser.findOne({ email, role });
    
    // If not found in mobile collection, try main collection
    if (!user) {
      user = await User.findOne({ email, role });
    }
    
    if (!user) return res.status(400).json({ message: "User not found" });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: "Invalid credentials" });

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.SESSION_SECRET, {
      expiresIn: "1d",
    });

    res.json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

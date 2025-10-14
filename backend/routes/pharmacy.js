// routes/pharmacy.js
const express = require("express");
const Pharmacy = require("../models/Pharmacy");
const router = express.Router();

// GET /api/pharmacies - List approved pharmacies from database
router.get("/", async (req, res) => {
  try {
    console.log("🔍 Fetching pharmacies from database...");
    
    // First, let's see ALL pharmacies (for debugging)
    const allPharmacies = await Pharmacy.find({})
      .select('_id name address contact status')
      .sort({ name: 1 });
    
    console.log(`📊 Total pharmacies in database: ${allPharmacies.length}`);
    console.log("📋 All pharmacy data:", allPharmacies);
    
    // Then filter for approved ones
    const approvedPharmacies = allPharmacies.filter(pharmacy => pharmacy.status === 'approved');
    
    console.log(`✅ Found ${approvedPharmacies.length} approved pharmacies`);
    res.json(approvedPharmacies);
  } catch (err) {
    console.error("❌ Error fetching pharmacies:", err);
    res.status(500).json({ message: err.message });
  }
});

// GET /api/pharmacies/:id - Get specific pharmacy
router.get("/:id", async (req, res) => {
  try {
    const pharmacy = await Pharmacy.findById(req.params.id);
    if (!pharmacy) {
      return res.status(404).json({ message: "Pharmacy not found" });
    }
    res.json(pharmacy);
  } catch (err) {
    console.error("❌ Error fetching pharmacy:", err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

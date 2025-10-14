const express = require("express");
const router = express.Router();

// Expanded common medicines list
const medicines = [
  // 🟢 Pain & Fever
  { name: "Paracetamol", price: 120, description: "Pain reliever & fever reducer" },
  { name: "Dolo-650", price: 150, description: "Pain reliever for fever and headaches" },
  { name: "Ibuprofen", price: 180, description: "Reduces inflammation, pain, and fever" },
  { name: "Aspirin", price: 200, description: "Pain relief & blood thinner" },

  // 🟢 Antibiotics
  { name: "Amoxicillin", price: 250, description: "Antibiotic for bacterial infections" },
  { name: "Azithromycin", price: 500, description: "Antibiotic for throat and chest infections" },
  { name: "Ciprofloxacin", price: 480, description: "Antibiotic for urinary tract infections" },
  { name: "Doxycycline", price: 320, description: "Antibiotic for skin & respiratory infections" },

  // 🟢 Cold & Allergy
  { name: "Cetirizine", price: 90, description: "Antihistamine for allergies and runny nose" },
  { name: "Loratadine", price: 110, description: "Allergy relief tablet" },
  { name: "Montelukast", price: 300, description: "Asthma & allergy treatment" },

  // 🟢 Gastric & Digestion
  { name: "Omeprazole", price: 220, description: "Reduces stomach acid, used for ulcers" },
  { name: "Pantoprazole", price: 240, description: "Used for acidity & acid reflux" },
  { name: "Ranitidine", price: 200, description: "Reduces stomach acid (now less used)" },
  { name: "Domperidone", price: 180, description: "Relieves nausea and vomiting" },

  // 🟢 Diabetes
  { name: "Metformin", price: 300, description: "Used for type 2 diabetes" },
  { name: "Glimepiride", price: 350, description: "Blood sugar control in type 2 diabetes" },
  { name: "Insulin", price: 900, description: "Essential for type 1 & advanced type 2 diabetes" },

  // 🟢 Blood Pressure & Heart
  { name: "Amlodipine", price: 260, description: "Blood pressure medication" },
  { name: "Losartan", price: 280, description: "Used for high blood pressure" },
  { name: "Atenolol", price: 200, description: "Beta-blocker for heart & BP" },
  { name: "Enalapril", price: 250, description: "Controls blood pressure & heart failure" },

  // 🟢 Vitamins & Supplements
  { name: "Vitamin C", price: 80, description: "Boosts immunity" },
  { name: "Vitamin D3", price: 150, description: "Bone health & immunity" },
  { name: "Calcium", price: 220, description: "Bone strength supplement" },
  { name: "Iron Tablets", price: 170, description: "Treats anemia" },
  { name: "Multivitamin", price: 300, description: "Daily nutrition supplement" },
];

// GET /api/medicines/search?query=para
router.get("/search", (req, res) => {
  const query = (req.query.query || "").toLowerCase();
  const results = medicines.filter(med =>
    med.name.toLowerCase().includes(query)
  );
  res.json(results);
});

module.exports = router;

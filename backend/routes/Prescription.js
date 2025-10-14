// routes/prescription.js
const express = require("express");
const Prescription = require("../models/Prescription");
const upload = require("../middleware/multer");
const cloudinary = require("../config/cloudinary");

const router = express.Router();

// Temporary: env presence check (do NOT enable in production)
router.get("/env-check", (req, res) => {
  res.json({
    hasCloudinaryCloudName: Boolean(process.env.CLOUDINARY_CLOUD_NAME),
    hasCloudinaryApiKey: Boolean(process.env.CLOUDINARY_API_KEY),
    hasCloudinaryApiSecret: Boolean(process.env.CLOUDINARY_API_SECRET),
  });
});

// 📌 Upload prescription
router.post("/upload", upload.single("image"), async (req, res) => {
  try {
    const { customerId, notes, pharmacyId, customerAddress, customerPhone, customerAge, customerGender, paymentMethod } = req.body;

    if (!req.file) {
      return res.status(400).json({ message: "No file uploaded" });
    }

    console.log('📤 [BACKEND] Uploading prescription with data:', {
      customerId,
      pharmacyId,
      hasFile: !!req.file
    });

    // Upload to Cloudinary via stream
    const uploadStream = cloudinary.uploader.upload_stream(
      { folder: "prescriptions" },
      async (error, uploadResult) => {
        if (error) {
          return res.status(500).json({ message: error.message });
        }
        try {
          // Save in MongoDB with all fields (including pharmacyId)
          const prescription = new Prescription({
            customerId,
            imageUrl: uploadResult.secure_url,
            notes,
            pharmacyId: pharmacyId || undefined,
            customerAddress: customerAddress || undefined,
            customerPhone: customerPhone || undefined,
            customerAge: customerAge ? parseInt(customerAge) : undefined,
            customerGender: customerGender || undefined,
            paymentMethod: paymentMethod || undefined,
          });
          await prescription.save();
          console.log('✅ [BACKEND] Prescription saved with ID:', prescription._id);
          return res.json({
            message: "Prescription uploaded successfully",
            prescription,
          });
        } catch (err) {
          console.error('❌ [BACKEND] Prescription save error:', err);
          return res.status(500).json({ message: err.message });
        }
      }
    );

    // Pipe buffer to Cloudinary upload
    require("streamifier").createReadStream(req.file.buffer).pipe(uploadStream);
  } catch (err) {
    console.error('❌ [BACKEND] Upload error:', err);
    res.status(500).json({ message: err.message });
  }
});

// 📌 Get prescriptions by user
router.get("/:customerId", async (req, res) => {
  try {
    const prescriptions = await Prescription.find({ customerId: req.params.customerId })
      .sort({ createdAt: -1 });
    res.json(prescriptions);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

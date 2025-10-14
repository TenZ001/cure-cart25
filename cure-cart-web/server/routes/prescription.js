// file: server/routes/prescription.js
const express = require('express');
const multer = require('multer');
const cloudinary = require('../utils/cloudinary');
const Prescription = require('../schemas/Prescription');
const Notification = require('../schemas/Notification');
const jwt = require('jsonwebtoken');

const router = express.Router();
const upload = multer({ dest: 'uploads/' }); // temporary storage

// 📌 Upload prescription
router.post('/', upload.single('image'), async (req, res) => {
  try {
    console.log('📤 [PRESCRIPTIONS] Uploading prescription with data:', {
      customerId: req.body.customerId,
      pharmacyId: req.body.pharmacyId,
      status: req.body.status || 'pending',
      hasFile: !!req.file
    });
    
    let imageUrl = req.body.imageUrl;

    // If a file is provided, upload to Cloudinary
    if (req.file) {
      try {
        const result = await cloudinary.uploader.upload(req.file.path, {
          folder: 'prescriptions',
        });
        imageUrl = result.secure_url;
        console.log('☁️ [PRESCRIPTIONS] Image uploaded to Cloudinary:', imageUrl);
      } catch (cloudinaryError) {
        console.log('⚠️ [PRESCRIPTIONS] Cloudinary upload failed:', cloudinaryError.message);
        // Use a placeholder URL if Cloudinary fails
        imageUrl = `http://localhost:4000/uploads/${req.file.filename}`;
        console.log('📁 [PRESCRIPTIONS] Using local file URL:', imageUrl);
      }
    }

    // Attach pharmacy info if provided (always save pharmacyId, let filtering handle approval)
    let pharmacyFields = {};
    if (req.body.pharmacyId) {
      // Always save the pharmacyId, even if pharmacy lookup fails
      pharmacyFields.pharmacyId = req.body.pharmacyId;
      console.log('🏥 [PRESCRIPTIONS] Saving pharmacyId:', req.body.pharmacyId);
      
      try {
        const Pharmacy = require('../schemas/Pharmacy');
        const ph = await Pharmacy.findById(req.body.pharmacyId).select('_id name address contact status');
        console.log('🏥 [PRESCRIPTIONS] Found pharmacy:', ph);
        if (ph) {
          pharmacyFields.pharmacyName = ph.name;
          pharmacyFields.pharmacyAddress = ph.address;
          pharmacyFields.pharmacyContact = ph.contact;
          console.log('✅ [PRESCRIPTIONS] Pharmacy fields set:', pharmacyFields);
          console.log('📋 [PRESCRIPTIONS] Pharmacy status:', ph.status);
        } else {
          console.log('⚠️ [PRESCRIPTIONS] Pharmacy not found for ID:', req.body.pharmacyId);
        }
      } catch (pharmacyError) {
        console.log('❌ [PRESCRIPTIONS] Pharmacy lookup error:', pharmacyError.message);
        console.log('📋 [PRESCRIPTIONS] Will save prescription with pharmacyId only');
      }
    }

    // Create prescription document
    const prescriptionData = {
      customerId: req.body.customerId,
      imageUrl,
      notes: req.body.notes,
      customerAddress: req.body.customerAddress,
      customerPhone: req.body.customerPhone,
      customerAge: req.body.customerAge,
      customerGender: req.body.customerGender,
      paymentMethod: req.body.paymentMethod,
      patientName: req.body.patientName,
      patientId: req.body.patientId,
      doctorName: req.body.doctorName,
      doctorLicense: req.body.doctorLicense,
      medicines: req.body.medicines ? JSON.parse(req.body.medicines) : [],
      issuedAt: req.body.issuedAt,
      status: req.body.status || 'pending',
      ...pharmacyFields,
    };
    
    console.log('💾 [PRESCRIPTIONS] Creating prescription with data:', prescriptionData);
    const newPrescription = new Prescription(prescriptionData);

    await newPrescription.save();
    console.log('✅ [PRESCRIPTIONS] Prescription saved with ID:', newPrescription._id);

    // Notify assigned pharmacy owner if targeted
    try {
      if (newPrescription.pharmacyId) {
        const Pharmacy = require('../schemas/Pharmacy');
        const ph = await Pharmacy.findById(newPrescription.pharmacyId).select('_id ownerId name');
        if (ph?.ownerId) {
          await Notification.create({
            type: 'new_prescription',
            title: 'New prescription received',
            body: `A new prescription was sent to your pharmacy${ph.name ? ' "' + ph.name + '"' : ''}.`,
            userId: ph.ownerId,
            data: { kind: 'prescription', prescriptionId: newPrescription._id, pharmacyId: ph._id }
          });
        }
      }
    } catch (_) {}

    // Emit real-time event to pharmacists
    try {
      const io = req.app.get('io');
      if (io) io.emit('prescription:new', newPrescription);
    } catch (_e) {}

    res.status(201).json({ message: 'Uploaded successfully', data: newPrescription });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 📌 Fetch prescriptions (with optional status filter)
router.get('/', async (req, res) => {
  try {
    console.log('🔍 [PRESCRIPTIONS] Fetching prescriptions with query:', req.query);
    
    const filter = {};
    
    // Handle authentication manually (similar to orders route)
    try {
      const jwt = require('jsonwebtoken');
      const Pharmacy = require('../schemas/Pharmacy');
      const authHeader = req.headers.authorization;
      const bearer = authHeader && authHeader.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : null;
      
      if (bearer) {
        const decoded = jwt.verify(bearer, process.env.JWT_SECRET || 'devsecret');
        console.log('🔐 [PRESCRIPTIONS] Authenticated user:', { role: decoded?.role, uid: decoded?.uid });
        
        if (decoded?.role === 'pharmacist') {
          const ph = await Pharmacy.findOne({ ownerId: decoded.uid }).select('_id name');
          console.log('🏥 [PRESCRIPTIONS] Pharmacist pharmacy:', ph);
          if (ph) filter.pharmacyId = ph._id;
        } else if (decoded?.role === 'patient') {
          // Optional: ensure a patient only sees own prescriptions unless overridden by explicit query
          if (!req.query.customerId) filter.customerId = decoded.uid;
        }
      }
    } catch (authError) {
      console.log('⚠️ [PRESCRIPTIONS] Auth error, showing all prescriptions:', authError.message);
      // If no auth or error, show all prescriptions (for backward compatibility)
    }
    
    if (req.query.status) {
      filter.status = req.query.status;
    }
    if (req.query.customerId) {
      filter.customerId = req.query.customerId;
    }
    console.log('🔍 [PRESCRIPTIONS] Final filter:', filter);
    const prescriptions = await Prescription.find(filter).sort({ createdAt: -1 }).populate('customerId');
    console.log('📋 [PRESCRIPTIONS] Found prescriptions:', prescriptions.length);

    // Attach linked order status when available so mobile can reflect 'Dispatched'
    try {
      const orderIds = prescriptions.map(p => p.orderId).filter(Boolean);
      if (orderIds.length) {
        const Order = require('../schemas/Order');
        const orders = await Order.find({ _id: { $in: orderIds } }).select('_id status');
        const map = new Map(orders.map(o => [String(o._id), o.status]));
        prescriptions.forEach(p => {
          if (p.orderId && map.has(String(p.orderId))) {
            // @ts-ignore
            p = p.toObject ? Object.assign(p, {}) : p;
            // Monkey-patch a virtual field in plain JSON response
            // We'll add orderStatus when serializing
          }
        });
        const payload = prescriptions.map(p => {
          const json = p.toObject ? p.toObject() : p;
          if (p.orderId && map.has(String(p.orderId))) {
            json.orderStatus = map.get(String(p.orderId));
          }
          return json;
        });
        return res.json(payload);
      }
    } catch (_e) {}

    res.json(prescriptions);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 📌 Update prescription (status or details)
router.patch('/:id', async (req, res) => {
  try {
    const update = {};
    const allowedScalar = ['status','notes','patientName','patientId','doctorName','doctorLicense','issuedAt','customerAddress','customerPhone','customerAge','customerGender','paymentMethod'];
    for (const k of allowedScalar) if (req.body[k] !== undefined) update[k] = req.body[k];
    if (req.body.medicines !== undefined) {
      try {
        update.medicines = Array.isArray(req.body.medicines) ? req.body.medicines : JSON.parse(req.body.medicines);
      } catch { update.medicines = []; }
    }
    const updated = await Prescription.findByIdAndUpdate(
      req.params.id,
      update,
      { new: true }
    );
    if (!updated) return res.status(404).json({ error: 'Not found' });
    // If approved, backfill customer record fields when missing
    try {
      if (updated.status === 'approved' && updated.customerId) {
        const User = require('../schemas/User');
        const set = {};
        if (updated.patientName && !updated.patientName.includes('Unknown')) set.name = updated.patientName;
        if (updated.customerPhone) set.phone = updated.customerPhone;
        if (updated.customerAddress) set.address = updated.customerAddress;
        if (updated.customerAge != null) set.age = updated.customerAge;
        if (updated.customerGender) set.gender = updated.customerGender;
        if (Object.keys(set).length) {
          await User.findByIdAndUpdate(updated.customerId, { $set: set });
        }
      }
    } catch (_e) {}
    try {
      const io = req.app.get('io');
      if (io) io.emit('prescription:updated', updated);
    } catch (_e) {}
    res.json(updated);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Test endpoint to check prescription flow
router.get('/test', async (req, res) => {
  try {
    console.log('🧪 [PRESCRIPTIONS] Test endpoint called');
    
    // Handle authentication manually
    let user = null;
    try {
      const jwt = require('jsonwebtoken');
      const authHeader = req.headers.authorization;
      const bearer = authHeader && authHeader.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : null;
      
      if (bearer) {
        const decoded = jwt.verify(bearer, process.env.JWT_SECRET || 'devsecret');
        user = { role: decoded?.role, uid: decoded?.uid };
        console.log('🔐 [PRESCRIPTIONS] Authenticated user:', user);
      }
    } catch (authError) {
      console.log('⚠️ [PRESCRIPTIONS] Auth error:', authError.message);
    }
    
    // Get all prescriptions for debugging
    const allPrescriptions = await Prescription.find({}).sort({ createdAt: -1 }).limit(10);
    console.log('📋 [PRESCRIPTIONS] All prescriptions (last 10):', allPrescriptions.length);
    
    // Get prescriptions for current user's pharmacy if pharmacist
    let filteredPrescriptions = [];
    let pharmacistPharmacy = null;
    if (user?.role === 'pharmacist') {
      const Pharmacy = require('../schemas/Pharmacy');
      pharmacistPharmacy = await Pharmacy.findOne({ ownerId: user.uid }).select('_id name status');
      console.log('🏥 [PRESCRIPTIONS] Pharmacist pharmacy:', pharmacistPharmacy);
      if (pharmacistPharmacy) {
        filteredPrescriptions = await Prescription.find({ pharmacyId: pharmacistPharmacy._id }).sort({ createdAt: -1 });
        console.log('🏥 [PRESCRIPTIONS] Pharmacist prescriptions:', filteredPrescriptions.length);
      }
    }
    
    res.json({
      message: 'Prescription test endpoint',
      user: user,
      pharmacistPharmacy: pharmacistPharmacy,
      allPrescriptions: allPrescriptions.length,
      filteredPrescriptions: filteredPrescriptions.length,
      recentPrescriptions: allPrescriptions.map(p => ({
        id: p._id,
        customerId: p.customerId,
        pharmacyId: p.pharmacyId,
        pharmacyName: p.pharmacyName,
        status: p.status,
        createdAt: p.createdAt
      })),
      pharmacistPrescriptions: filteredPrescriptions.map(p => ({
        id: p._id,
        customerId: p.customerId,
        pharmacyId: p.pharmacyId,
        pharmacyName: p.pharmacyName,
        status: p.status,
        createdAt: p.createdAt
      }))
    });
  } catch (err) {
    console.error('❌ [PRESCRIPTIONS] Test endpoint error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Debug endpoint to check pharmacist authentication and pharmacy
router.get('/debug-pharmacist', async (req, res) => {
  try {
    console.log('🔍 [DEBUG] Pharmacist debug endpoint called');
    
    // Handle authentication manually
    let user = null;
    try {
      const jwt = require('jsonwebtoken');
      const authHeader = req.headers.authorization;
      const bearer = authHeader && authHeader.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : null;
      
      if (bearer) {
        const decoded = jwt.verify(bearer, process.env.JWT_SECRET || 'devsecret');
        user = { role: decoded?.role, uid: decoded?.uid };
        console.log('🔐 [DEBUG] Authenticated user:', user);
      }
    } catch (authError) {
      console.log('⚠️ [DEBUG] Auth error:', authError.message);
    }
    
    if (!user || user.role !== 'pharmacist') {
      return res.json({ error: 'Not a pharmacist', user: user });
    }
    
    const Pharmacy = require('../schemas/Pharmacy');
    const ph = await Pharmacy.findOne({ ownerId: user.uid }).select('_id name status ownerId');
    console.log('🏥 [DEBUG] Pharmacist pharmacy:', ph);
    
    if (!ph) {
      return res.json({ 
        error: 'No pharmacy found for this pharmacist',
        pharmacist: { role: user.role, uid: user.uid }
      });
    }
    
    // Check prescriptions for this pharmacy
    const prescriptions = await Prescription.find({ pharmacyId: ph._id }).sort({ createdAt: -1 });
    console.log('📋 [DEBUG] Prescriptions for pharmacy:', prescriptions.length);
    
    res.json({
      message: 'Pharmacist debug info',
      pharmacist: { role: user.role, uid: user.uid },
      pharmacy: ph,
      prescriptionsCount: prescriptions.length,
      prescriptions: prescriptions.map(p => ({
        id: p._id,
        customerId: p.customerId,
        pharmacyId: p.pharmacyId,
        status: p.status,
        createdAt: p.createdAt
      }))
    });
  } catch (err) {
    console.error('❌ [DEBUG] Pharmacist debug error:', err);
    res.status(500).json({ error: err.message });
  }
});

// Simple endpoint to check all prescriptions (for debugging)
router.get('/all', async (req, res) => {
  try {
    console.log('🔍 [PRESCRIPTIONS] Getting all prescriptions');
    const prescriptions = await Prescription.find({}).sort({ createdAt: -1 });
    console.log('📋 [PRESCRIPTIONS] Total prescriptions:', prescriptions.length);
    
    res.json({
      message: 'All prescriptions',
      count: prescriptions.length,
      prescriptions: prescriptions.map(p => ({
        id: p._id,
        customerId: p.customerId,
        pharmacyId: p.pharmacyId,
        pharmacyName: p.pharmacyName,
        status: p.status,
        createdAt: p.createdAt
      }))
    });
  } catch (err) {
    console.error('❌ [PRESCRIPTIONS] All prescriptions error:', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

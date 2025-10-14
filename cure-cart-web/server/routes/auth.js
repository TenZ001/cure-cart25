const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const User = require('../schemas/User');
const multer = require('multer');
const path = require('path');
const { generateOTP, sendOTPEmail, testEmailConfig } = require('../utils/emailService');

const router = express.Router();

const registerSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  password: z.string().min(6),
  phone: z.string().optional(),
  role: z.enum(['patient','delivery','pharmacist','admin']).optional(),
});

router.post('/register', async (req, res) => {
  try {
    const data = registerSchema.parse(req.body);
    const normalizedEmail = data.email.trim().toLowerCase();
    const name = data.name.trim();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) return res.status(409).json({ error: 'Email already registered' });
    const hashed = await bcrypt.hash(data.password, 10);
    const requestedRole = (data.role || 'patient');
    const user = await User.create({ ...data, role: requestedRole, name, email: normalizedEmail, password: hashed });
    res.status(201).json({ id: user._id, name: user.name, email: user.email });
  } catch (err) {
    // Handle duplicate key errors from Mongo uniquely
    if (err && err.code === 11000) {
      return res.status(409).json({ error: 'Email already registered' });
    }
    return res.status(400).json({ error: err.message });
  }
});

const loginSchema = z.object({ email: z.string().email(), password: z.string().min(6) });

router.post('/login', async (req, res) => {
  try {
    console.log('🔍 [AUTH] Login attempt:', { email: req.body.email, role: req.body.role });
    
    const { email, password } = loginSchema.parse(req.body);
    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    
    console.log('🔍 [AUTH] User found:', { 
      found: !!user, 
      userId: user?._id, 
      role: user?.role, 
      status: user?.status 
    });
    
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    
    // Check if user is active
    if (user.status === 'suspended') {
      console.log('❌ [AUTH] User suspended:', user._id);
      return res.status(401).json({ error: 'Account suspended' });
    }
    
    const ok = await bcrypt.compare(password, user.password);
    if (!ok) {
      console.log('❌ [AUTH] Password mismatch for user:', user._id);
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const token = jwt.sign({ uid: user._id, role: user.role }, process.env.JWT_SECRET || 'devsecret', { expiresIn: '7d' });
    
    // Also set cookie for optional server-side usage, but client should use Authorization header
    res.cookie('cc_auth', token, { httpOnly: true, sameSite: 'lax', secure: false, maxAge: 7 * 24 * 60 * 60 * 1000 });
    
    // Update last login timestamp
    await User.findByIdAndUpdate(user._id, { lastLoginAt: new Date() });
    
    console.log('✅ [AUTH] Login successful for user:', { id: user._id, role: user.role });
    
    // Return token for mobile apps along with user info
    res.json({
      token,
      user: { id: user._id, name: user.name, email: user.email, role: user.role, lastLoginAt: user.lastLoginAt }
    });
  } catch (err) {
    console.error('❌ [AUTH] Login error:', err);
    res.status(400).json({ error: err.message });
  }
});

router.post('/logout', (_req, res) => {
  res.clearCookie('cc_auth');
  res.json({ ok: true });
});

router.get('/me', async (req, res) => {
  try {
    // Prefer Authorization header to ensure correct identity on refresh
    const authHeader = req.headers.authorization;
    const bearer = authHeader && authHeader.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : null;
    const token = bearer || req.cookies?.cc_auth;
    
    console.log('🔍 [AUTH] /me request:', { 
      hasAuthHeader: !!authHeader, 
      hasBearer: !!bearer, 
      hasCookie: !!req.cookies?.cc_auth 
    });
    
    if (!token) {
      console.log('❌ [AUTH] No token found');
      return res.status(200).json(null);
    }
    
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'devsecret');
    console.log('🔍 [AUTH] Token decoded:', { uid: decoded.uid, role: decoded.role });
    
    const user = await User.findById(decoded.uid).select('_id name email role lastLoginAt rewardPoints dues branch employeeId phone avatarUrl status');
    
    if (!user) {
      console.log('❌ [AUTH] User not found for token');
      return res.status(200).json(null);
    }
    
    if (user.status === 'suspended') {
      console.log('❌ [AUTH] User suspended');
      return res.status(200).json(null);
    }
    
    console.log('✅ [AUTH] User found:', { id: user._id, role: user.role, status: user.status });
    res.json(user);
  } catch (err) {
    console.error('❌ [AUTH] /me error:', err.message);
    res.status(200).json(null);
  }
});

// Update own profile
router.patch('/me', async (req, res) => {
  try {
    const token = req.cookies?.cc_auth || req.headers.authorization?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'devsecret');
    const allowed = ['name','phone','branch','employeeId','qualifications','licenseNumber','address','age','gender'];
    const update = {};
    for (const key of allowed) if (key in req.body) update[key] = req.body[key];
    if (typeof update.name === 'string') update.name = update.name.trim();
    const user = await User.findByIdAndUpdate(decoded.uid, update, { new: true }).select('_id name email role lastLoginAt rewardPoints dues branch employeeId phone qualifications licenseNumber address age gender');
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// Avatar upload to database (Buffer)
const upload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 2 * 1024 * 1024 } });

router.post('/me/avatar', upload.single('avatar'), async (req, res) => {
  try {
    const token = req.cookies?.cc_auth || req.headers.authorization?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ error: 'Unauthorized' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'devsecret');
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });
    const base = `${req.protocol}://${req.get('host')}`;
    const update = {
      avatar: req.file.buffer,
      avatarMimeType: req.file.mimetype,
      avatarUrl: `${base}/api/users/${decoded.uid}/avatar`,
    };
    const user = await User.findByIdAndUpdate(decoded.uid, update, { new: true }).select('_id name email avatarUrl');
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});


// Forgot password - send OTP
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    
    if (!user) {
      // Don't reveal if email exists or not for security
      return res.json({ message: 'If the email exists, an OTP has been sent' });
    }

    // Check if user has too many recent OTP attempts with time-based reset
    const now = new Date();
    const lastAttemptTime = user.passwordReset?.lastAttemptTime;
    const otpAttempts = user.passwordReset?.otpAttempts || 0;
    
    // Reset attempts if more than 30 minutes has passed since last attempt (reduced from 60 minutes)
    if (lastAttemptTime && (now - new Date(lastAttemptTime)) > 30 * 60 * 1000) {
      await User.findByIdAndUpdate(user._id, {
        'passwordReset.otpAttempts': 0,
        'passwordReset.lastAttemptTime': null
      });
    } else if (otpAttempts >= 5) {
      const timeRemaining = lastAttemptTime ? 
        Math.ceil((30 * 60 * 1000 - (now - new Date(lastAttemptTime))) / (60 * 1000)) : 30;
      return res.status(429).json({ 
        error: `Too many OTP attempts. Please wait ${timeRemaining} minutes before trying again.` 
      });
    }

    // Generate new OTP
    const otp = generateOTP();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Update user with new OTP
    await User.findByIdAndUpdate(user._id, {
      'passwordReset.otp': otp,
      'passwordReset.otpExpires': otpExpires,
      'passwordReset.otpAttempts': (user.passwordReset?.otpAttempts || 0) + 1,
      'passwordReset.lastAttemptTime': now
    });

    // Send OTP email
    const emailResult = await sendOTPEmail(user.email, otp, user.name);
    
    if (!emailResult.success) {
      console.error('❌ [AUTH] Failed to send OTP email:', emailResult.error);
      return res.status(500).json({ error: 'Failed to send OTP email' });
    }

    console.log('✅ [AUTH] OTP sent successfully to:', user.email);
    res.json({ message: 'If the email exists, an OTP has been sent' });
  } catch (err) {
    console.error('❌ [AUTH] Forgot password error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Verify OTP and reset password
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    
    if (!email || !otp || !newPassword) {
      return res.status(400).json({ error: 'Email, OTP, and new password are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters long' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    
    if (!user) {
      return res.status(400).json({ error: 'Invalid email' });
    }

    // Check if OTP exists and is valid
    if (!user.passwordReset?.otp || !user.passwordReset?.otpExpires) {
      return res.status(400).json({ error: 'No OTP found. Please request a new one.' });
    }

    // Check if OTP has expired
    if (new Date() > user.passwordReset.otpExpires) {
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    // Check if OTP matches
    if (user.passwordReset.otp !== otp) {
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    // Hash new password and update user
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await User.findByIdAndUpdate(user._id, {
      password: hashedPassword,
      'passwordReset.otp': null,
      'passwordReset.otpExpires': null,
      'passwordReset.otpAttempts': 0
    });

    console.log('✅ [AUTH] Password reset successful for user:', user._id);
    res.json({ message: 'Password reset successful' });
  } catch (err) {
    console.error('❌ [AUTH] Verify OTP error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Check OTP attempt status
router.post('/check-otp-status', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    
    if (!user) {
      return res.json({ canRequest: true, attemptsRemaining: 5 });
    }

    const now = new Date();
    const lastAttemptTime = user.passwordReset?.lastAttemptTime;
    const otpAttempts = user.passwordReset?.otpAttempts || 0;
    
    // Reset attempts if more than 30 minutes has passed (reduced from 60 minutes)
    if (lastAttemptTime && (now - new Date(lastAttemptTime)) > 30 * 60 * 1000) {
      await User.findByIdAndUpdate(user._id, {
        'passwordReset.otpAttempts': 0,
        'passwordReset.lastAttemptTime': null
      });
      return res.json({ canRequest: true, attemptsRemaining: 5 });
    }
    
    if (otpAttempts >= 5) {
      const timeRemaining = lastAttemptTime ? 
        Math.ceil((30 * 60 * 1000 - (now - new Date(lastAttemptTime))) / (60 * 1000)) : 30;
      return res.json({ 
        canRequest: false, 
        attemptsRemaining: 0,
        timeRemaining: timeRemaining,
        message: `Please wait ${timeRemaining} minutes before trying again.`
      });
    }
    
    return res.json({ 
      canRequest: true, 
      attemptsRemaining: 5 - otpAttempts 
    });
  } catch (err) {
    console.error('❌ [AUTH] Check OTP status error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Reset OTP attempts (for debugging/emergency)
router.post('/reset-otp-attempts', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Reset OTP attempts
    await User.findByIdAndUpdate(user._id, {
      'passwordReset.otpAttempts': 0,
      'passwordReset.lastAttemptTime': null,
      'passwordReset.otp': null,
      'passwordReset.otpExpires': null
    });

    console.log('✅ [AUTH] OTP attempts reset for user:', user._id);
    res.json({ message: 'OTP attempts reset successfully. You can now request a new OTP.' });
  } catch (err) {
    console.error('❌ [AUTH] Reset OTP attempts error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Test email configuration (for debugging)
router.get('/test-email', async (req, res) => {
  try {
    const result = await testEmailConfig();
    if (result.success) {
      res.json({ message: 'Email configuration is working correctly' });
    } else {
      res.status(500).json({ error: 'Email configuration failed', details: result.error });
    }
  } catch (err) {
    console.error('❌ [AUTH] Email test error:', err);
    res.status(500).json({ error: 'Email test failed', details: err.message });
  }
});

module.exports = router;



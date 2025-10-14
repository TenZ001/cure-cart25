require('dotenv').config();
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const http = require('http');
const { Server } = require('socket.io');
const mongoose = require('mongoose');
const path = require('path');

// Import routes
const prescriptionRoutes = require('./routes/prescription');
const orderRoutes = require('./routes/order'); // raw/basic orders router (mounted under /api/orders-raw)
const authRoutes = require('./routes/auth');
const publicRoutes = require('./routes/public');
const apiRoutes = require('./routes/api');
const adminRoutes = require('./routes/admin');

const app = express();
const server = http.createServer(app);

// Socket.io setup
const io = new Server(server, {
  cors: { origin: true, credentials: true },
});

// Make io available to routes via app locals
app.set('io', io);

// Middlewares
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: '5mb' }));
app.use(cookieParser());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Basic health check
app.get('/health', (_req, res) => res.json({ ok: true }));

// Routes
// Prescription routes with optional authentication (let routes handle auth internally)
app.use('/api/prescriptions', prescriptionRoutes);
// Mount raw orders under a non-conflicting path so /api/orders uses the unified handler in apiRoutes
app.use('/api/orders-raw', orderRoutes);
app.use('/api/auth', authRoutes);
// Unified API (includes /api/orders for web pharmacist)
app.use('/api', apiRoutes);
app.use('/api/admin', adminRoutes);
app.use('/public', publicRoutes);

// Serve avatar images
app.get('/api/users/:id/avatar', async (req, res) => {
  try {
    const User = require('./schemas/User');
    const user = await User.findById(req.params.id).select('avatar avatarMimeType');
    if (!user || !user.avatar) return res.status(404).send('Not found');
    res.set('Content-Type', user.avatarMimeType || 'image/jpeg');
    res.send(user.avatar);
  } catch (_e) {
    res.status(404).send('Not found');
  }
});

// Socket.io events
io.on('connection', (socket) => {
  console.log('New client connected');
  socket.on('join', (roomId) => {
    socket.join(roomId);
  });
  socket.on('message', ({ roomId, message }) => {
    io.to(roomId).emit('message', { message, at: new Date().toISOString() });
  });
  socket.on('disconnect', () => {
    console.log('Client disconnected');
  });
});

// Start server + MongoDB
const start = async () => {
  try {
    // Build Mongo URI safely
    let mongoUri = process.env.MONGODB_URI;
    if (!mongoUri && process.env.MONGO_USER && process.env.MONGO_PASS && process.env.MONGO_HOST) {
      const encPass = encodeURIComponent(process.env.MONGO_PASS);
      mongoUri = `mongodb+srv://${process.env.MONGO_USER}:${encPass}@${process.env.MONGO_HOST}/?retryWrites=true&w=majority`;
    }
    if (!mongoUri) {
      throw new Error('MONGODB_URI not set');
    }

    await mongoose.connect(mongoUri, { dbName: process.env.MONGODB_DB || 'curecart' });
    console.log('✅ MongoDB connected');

    const port = process.env.PORT || 4000;
    server.listen(port, () => console.log(`🚀 Server listening on :${port}`));
  } catch (err) {
    console.error('❌ Failed to start server', err);
    process.exit(1);
  }
};

start();

const express = require('express');
const { authMiddleware } = require('../utils/authMiddleware');
const { adminMiddleware } = require('../utils/adminMiddleware');
const User = require('../schemas/User');
const Order = require('../schemas/Order');
const Feedback = require('../schemas/Feedback');
const Pharmacy = require('../schemas/Pharmacy');
const Notification = require('../schemas/Notification');
const DeliveryPartner = require('../schemas/DeliveryPartner');
const SupportTicket = require('../schemas/SupportTicket');

const router = express.Router();

router.use(authMiddleware, adminMiddleware);

// Users
router.get('/users', async (_req, res) => {
  const users = await User.find().select('_id name email role createdAt phone status kyc lastLoginAt');
  res.json(users);
});
router.patch('/users/:id/role', async (req, res) => {
  const { role } = req.body || {};
  if (!['admin','pharmacist','customer','doctor'].includes(role)) return res.status(400).json({ error: 'Invalid role' });
  const user = await User.findByIdAndUpdate(req.params.id, { role }, { new: true }).select('_id name email role');
  res.json(user);
});
router.patch('/users/:id/status', async (req, res) => {
  const { status } = req.body || {};
  if (!['active','suspended'].includes(status)) return res.status(400).json({ error: 'Invalid status' });
  const user = await User.findByIdAndUpdate(req.params.id, { status }, { new: true }).select('_id name email role status');
  res.json(user);
});
router.patch('/users/:id/kyc', async (req, res) => {
  const { verified, documentType, documentUrl } = req.body || {};
  const update = { 'kyc.verified': !!verified };
  if (documentType !== undefined) update['kyc.documentType'] = documentType;
  if (documentUrl !== undefined) update['kyc.documentUrl'] = documentUrl;
  if (verified) update['kyc.verifiedAt'] = new Date();
  const user = await User.findByIdAndUpdate(req.params.id, update, { new: true }).select('_id name email role kyc');
  res.json(user);
});

// Pharmacies approval
router.get('/pharmacies', async (_req, res) => {
  const items = await Pharmacy.find().populate('ownerId', 'name email');
  res.json(items);
});
router.post('/pharmacies', async (req, res) => {
  const { name, address, contact, ownerId } = req.body || {};
  if (!name) return res.status(400).json({ error: 'Name required' });
  const ph = await Pharmacy.create({ name, address, contact, ownerId, status: 'approved' });
  res.status(201).json(ph);
});
router.patch('/pharmacies/:id/approve', async (req, res) => {
  const ph = await Pharmacy.findByIdAndUpdate(req.params.id, { status: 'approved', rejectionReason: undefined }, { new: true });
  try {
    if (ph?.ownerId) {
      await Notification.create({
        type: 'system',
        title: 'Pharmacy approved',
        body: `Your pharmacy "${ph.name}" has been approved.`,
        userId: ph.ownerId,
        data: { kind: 'pharmacy_approved', pharmacyId: ph._id }
      });
    }
  } catch (_) {}
  res.json(ph);
});
router.patch('/pharmacies/:id/reject', async (req, res) => {
  const { reason } = req.body || {};
  const ph = await Pharmacy.findByIdAndUpdate(req.params.id, { status: 'rejected', rejectionReason: reason || 'Not specified' }, { new: true });
  try {
    if (ph?.ownerId) {
      await Notification.create({
        type: 'system',
        title: 'Pharmacy rejected',
        body: `Your pharmacy "${ph.name}" was rejected. Reason: ${ph.rejectionReason || 'Not specified'}.`,
        userId: ph.ownerId,
        data: { kind: 'pharmacy_rejected', pharmacyId: ph._id }
      });
    }
  } catch (_) {}
  res.json(ph);
});

// Delete pharmacy
router.delete('/pharmacies/:id', async (req, res) => {
  try {
    const ph = await Pharmacy.findByIdAndDelete(req.params.id);
    if (!ph) return res.status(404).json({ error: 'Not found' });
    try {
      if (ph?.ownerId) {
        await Notification.create({
          type: 'system',
          title: 'Pharmacy deleted',
          body: `Your pharmacy "${ph.name}" was removed by admin.`,
          userId: ph.ownerId,
          data: { kind: 'pharmacy_deleted', pharmacyId: ph._id }
        });
      }
    } catch (_) {}
    res.json({ ok: true });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Orders monitoring
router.get('/orders', async (_req, res) => {
  const orders = await Order.find().sort({ createdAt: -1 });
  res.json(orders);
});
// Update order tracking (lat/lng, status, partner assign)
router.patch('/orders/:id', async (req, res) => {
  const { status, deliveryPartnerId, tracking } = req.body || {};
  const update = {};
  if (status) update.status = status;
  if (deliveryPartnerId !== undefined) update.deliveryPartnerId = deliveryPartnerId;
  if (tracking) {
    update.tracking = Object.assign({}, tracking, { lastUpdatedAt: new Date() });
  }
  const order = await Order.findByIdAndUpdate(req.params.id, update, { new: true });
  res.json(order);
});

// Delete order (admin only - no customerId required)
router.delete('/orders/:id', async (req, res) => {
  try {
    const order = await Order.findByIdAndDelete(req.params.id);
    if (!order) return res.status(404).json({ error: 'Order not found' });
    res.json({ ok: true, message: 'Order deleted successfully' });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Analytics endpoints
router.get('/analytics/overview', async (_req, res) => {
  const [orders, users] = await Promise.all([
    Order.aggregate([
      { $group: { _id: '$status', count: { $sum: 1 }, revenue: { $sum: '$total' } } },
    ]),
    User.countDocuments(),
  ]);
  const byStatus = orders.reduce((acc, r) => { acc[r._id] = r.count; return acc }, {})
  const revenue = orders.reduce((sum, r) => sum + (r.revenue || 0), 0)
  res.json({ users, byStatus, revenue })
});
router.get('/analytics/top-products', async (_req, res) => {
  const rows = await Order.aggregate([
    { $unwind: '$items' },
    { $group: { _id: '$items.medicineId', qty: { $sum: '$items.quantity' }, sales: { $sum: { $multiply: ['$items.quantity', '$items.price'] } } } },
    { $sort: { qty: -1 } },
    { $limit: 10 },
  ]);
  res.json(rows)
});
router.get('/analytics/customers', async (_req, res) => {
  const repeat = await Order.aggregate([{ $group: { _id: '$customerId', count: { $sum: 1 } } }, { $group: { _id: null, repeat: { $sum: { $cond: [{ $gt: ['$count', 1] }, 1, 0] } }, total: { $sum: 1 } } }])
  const row = repeat[0] || { repeat: 0, total: 0 }
  res.json({ repeat: row.repeat, new: Math.max(0, row.total - row.repeat) })
});
router.get('/analytics/sales', async (req, res) => {
  const period = (req.query.period || 'daily').toString();
  let fmt = '%Y-%m-%d';
  if (period === 'weekly') fmt = '%G-%V';
  if (period === 'monthly') fmt = '%Y-%m';
  const rows = await Order.aggregate([
    { $match: { status: 'delivered' } },
    { $group: { _id: { $dateToString: { format: fmt, date: '$createdAt' } }, total: { $sum: '$total' } } },
    { $sort: { _id: 1 } },
  ])
  res.json(rows)
});

// Feedback moderation
router.get('/feedback', async (_req, res) => {
  const items = await Feedback.find().sort({ createdAt: -1 });
  res.json(items);
});
router.patch('/feedback/:id/hide', async (req, res) => {
  const item = await Feedback.findByIdAndUpdate(req.params.id, { hidden: true }, { new: true });
  res.json(item);
});
router.patch('/feedback/:id/show', async (req, res) => {
  const item = await Feedback.findByIdAndUpdate(req.params.id, { hidden: false }, { new: true });
  res.json(item);
});

// Delivery partners
router.get('/delivery-partners', async (_req, res) => {
  const items = await DeliveryPartner.find();
  res.json(items);
});
router.post('/delivery-partners', async (req, res) => {
  const { name, contact, vehicleNo } = req.body || {};
  if (!name) return res.status(400).json({ error: 'Name required' });
  const dp = await DeliveryPartner.create({ name, contact, vehicleNo, status: 'approved' });
  res.status(201).json(dp);
});
router.patch('/delivery-partners/:id', async (req, res) => {
  const dp = await DeliveryPartner.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(dp);
});
router.patch('/delivery-partners/:id/approve', async (req, res) => {
  const dp = await DeliveryPartner.findByIdAndUpdate(req.params.id, { status: 'approved' }, { new: true });
  res.json(dp);
});
router.patch('/delivery-partners/:id/reject', async (req, res) => {
  const dp = await DeliveryPartner.findByIdAndUpdate(req.params.id, { status: 'rejected' }, { new: true });
  res.json(dp);
});

// Assign delivery partner to order
router.post('/orders/:orderId/assign/:partnerId', async (req, res) => {
  const { orderId, partnerId } = req.params;
  const dp = await DeliveryPartner.findByIdAndUpdate(partnerId, { $addToSet: { assignedOrders: orderId } }, { new: true });
  res.json(dp);
});

// Support tickets
router.get('/support', async (_req, res) => {
  const items = await SupportTicket.find().populate('createdBy', 'name email').sort({ createdAt: -1 });
  res.json(items);
});
router.patch('/support/:id', async (req, res) => {
  const { status, assignee, priority } = req.body || {};
  const update = {};
  if (status) update.status = status;
  if (assignee) update.assignee = assignee;
  if (priority) update.priority = priority;
  const t = await SupportTicket.findByIdAndUpdate(req.params.id, update, { new: true });
  res.json(t);
});

module.exports = router;



function adminMiddleware(req, res, next) {
  const role = req.user?.role
  // Allow both admin and pharmacist roles to access admin endpoints
  if (role !== 'admin' && role !== 'pharmacist') {
    return res.status(403).json({ error: 'Forbidden - Admin or Pharmacist access required' })
  }
  next()
}

module.exports = { adminMiddleware }



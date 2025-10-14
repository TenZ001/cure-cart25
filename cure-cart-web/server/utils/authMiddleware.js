const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  // Prefer Authorization header over cookie to avoid cross-account bleed
  const authHeader = req.headers.authorization;
  const bearer = authHeader && authHeader.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : null;
  const token = bearer || req.cookies?.cc_auth;
  
  console.log('🔍 [AUTH MIDDLEWARE] Request:', { 
    path: req.path, 
    hasAuthHeader: !!authHeader, 
    hasBearer: !!bearer, 
    hasCookie: !!req.cookies?.cc_auth 
  });
  
  if (!token) {
    console.log('❌ [AUTH MIDDLEWARE] No token found');
    return res.status(401).json({ error: 'Unauthorized' });
  }
  
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET || 'devsecret');
    console.log('✅ [AUTH MIDDLEWARE] Token verified:', { uid: payload.uid, role: payload.role });
    req.user = payload;
    next();
  } catch (err) {
    console.log('❌ [AUTH MIDDLEWARE] Token verification failed:', err.message);
    return res.status(401).json({ error: 'Unauthorized' });
  }
}

module.exports = { authMiddleware };



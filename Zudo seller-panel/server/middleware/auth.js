const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');
const User = require('../models/User');
const Seller = require('../models/Seller');

const protect = async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    try {
      token = req.headers.authorization.split(' ')[1];
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      const Admin = req.getModel('Admin');
      const Seller = req.getModel('Seller');
      const User = req.getModel('User');

      // Check Admin
      let account = await Admin.findById(decoded.id).select('-password');
      if (account) {
        req.admin = account;
        req.user = account; 
        return next();
      }

      // Check Seller
      account = await Seller.findById(decoded.id).select('-password');
      if (account) {
        req.user = account;
        return next();
      }

      // Check User
      account = await User.findById(decoded.id).select('-password');
      if (account) {
        req.user = account;
        return next();
      }

      return res.status(401).json({ message: 'Not authorized, account not found' });
    } catch (error) {
      return res.status(401).json({ message: 'Not authorized, token failed' });
    }
  }

  if (!token) {
    return res.status(401).json({ message: 'Not authorized, no token' });
  }
};

const superAdmin = (req, res, next) => {
  if (req.admin && req.admin.role === 'super_admin') {
    next();
  } else {
    res.status(403).json({ message: 'Not authorized as super admin' });
  }
};

module.exports = { protect, superAdmin };


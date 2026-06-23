const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const multiTenant = require('../middleware/multiTenant');
const { getModel } = require('../utils/model_loader');

// @route   GET /api/users
// @desc    Get all users for the current tenant
router.get('/', protect, multiTenant, async (req, res) => {
  try {
    const UserModel = getModel('User', req);
    const users = await UserModel.find().select('-password');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/users/b2b/pending
// @desc    Get B2B users waiting for approval in current tenant
router.get('/b2b/pending', protect, multiTenant, async (req, res) => {
  try {
    const UserModel = getModel('User', req);
    const users = await UserModel.find({ 
      role: 'b2b', 
      isWaitingApproval: true 
    }).select('-password');
    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/users/sales/my-b2b
// @desc    Get all B2B accounts matching the logged-in sales associate's pincodes
router.get('/sales/my-b2b', protect, multiTenant, async (req, res) => {
  try {
    if (!req.admin || req.admin.role !== 'sales') {
      return res.status(403).json({ message: 'Access denied. Sales role required.' });
    }

    const assignedPincodes = req.admin.pincodes || [];
    if (assignedPincodes.length === 0) {
      return res.json([]);
    }

    const UserModel = getModel('User', req);
    // Find verified B2B users with matching pincodes
    const users = await UserModel.find({
      role: 'b2b',
      isVerified: true,
      pincode: { $in: assignedPincodes.map(p => p.trim()) }
    }).select('-password');

    res.json(users);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const Admin = require('../models/Admin');
const User = require('../models/User');
const { protect, superAdmin } = require('../middleware/auth');

// Helper to format user response
const formatUser = (user) => ({
  _id: user._id,
  name: user.name,
  email: user.email,
  role: user.role,
  phone: user.phone,
  profilePicture: user.profilePicture,
  isVerified: user.isVerified,
  isWaitingApproval: user.isWaitingApproval,
  gstPdf: user.gstPdf,
  storePic: user.storePic,
  gstNumber: user.gstNumber,
  panNumber: user.panNumber,
  aadhaarNumber: user.aadhaarNumber,
  savedAddresses: user.savedAddresses,
  businessName: user.businessName
});

// @route   POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const admin = await Admin.findOne({ email });
    if (admin && (await admin.comparePassword(password))) {
      const token = jwt.sign({ id: admin._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
      res.json({ _id: admin._id, name: admin.name, email: admin.email, role: admin.role, token });
    } else {
      res.status(401).json({ message: 'Invalid email or password' });
    }
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role, phone, businessName, gstPdf } = req.body;

    // Check if account with THIS EXACT role already exists
    const userExists = await User.findOne({ email, role: role || 'b2c' });
    if (userExists) {
      return res.status(400).json({ message: `An account with the ${role.toUpperCase()} role already exists for this email.` });
    }

    // Create user with ALL provided fields (including B2B docs if present)
    const user = await User.create({
      name,
      email,
      password,
      role: role || 'b2c',
      phone,
      businessName: businessName || '',
      gstPdf: gstPdf || '',
      isWaitingApproval: role === 'b2b' ? true : false
    });

    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
    res.status(201).json({ token, user: formatUser(user) });
  } catch (error) {
    console.error('Registration Error:', error);
    res.status(400).json({ message: error.message });
  }
});

// @route   POST /api/auth/user-login
router.post('/user-login', async (req, res) => {
  const { email, password, role } = req.body;
  try {
    const targetRole = role || 'b2c';
    const user = await User.findOne({ email, role: targetRole });

    if (user && (await user.comparePassword(password))) {
      const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
      res.json({ token, user: formatUser(user) });
    } else {
      // Check if user exists with DIFFERENT role to provide better error
      const otherRoleUser = await User.findOne({ email });
      if (otherRoleUser) {
        return res.status(401).json({
          message: `This account is currently registered as ${otherRoleUser.role.toUpperCase()}. Please switch to the correct portal or register a new ${targetRole.toUpperCase()} profile.`,
          hasOtherRole: true
        });
      }
      res.status(401).json({ message: 'Invalid email or password' });
    }
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   GET /api/auth/profile
router.get('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    if (user) res.json(formatUser(user));
    else res.status(404).json({ message: 'User not found' });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   PUT /api/auth/profile
router.put('/profile', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (user) {
      user.name = req.body.name || user.name;
      user.phone = req.body.phone || user.phone;
      user.profilePicture = req.body.profilePicture || user.profilePicture;
      if (req.body.savedAddresses) user.savedAddresses = req.body.savedAddresses;
      if (req.body.password) user.password = req.body.password;

      const updatedUser = await user.save();
      res.json(formatUser(updatedUser));
    } else {
      res.status(404).json({ message: 'User not found' });
    }
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   POST /api/auth/b2b-verify-submit
router.post('/b2b-verify-submit', protect, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.gstPdf = req.body.gstPdf;
    user.storePic = req.body.storePic;
    user.gstNumber = req.body.gstNumber;
    user.panNumber = req.body.panNumber;
    user.aadhaarNumber = req.body.aadhaarNumber;
    user.isWaitingApproval = true;

    const savedUser = await user.save();
    res.status(200).json(formatUser(savedUser));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/auth/google-login
router.post('/google-login', async (req, res) => {
  const { name, email, profilePicture, role } = req.body;
  const targetRole = role || 'b2c';
  try {
    let user = await User.findOne({ email, role: targetRole });

    if (!user) {
      user = await User.create({
        name, email, profilePicture, role: targetRole,
        password: Math.random().toString(36).slice(-10),
        isWaitingApproval: targetRole === 'b2b' ? true : false
      });
    }
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
    res.json({ token, user: formatUser(user) });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const Driver = require('../models/Driver');
const { protect } = require('../middleware/auth');

// @route   GET /api/drivers
// @desc    Get all drivers
router.get('/', protect, async (req, res) => {
  try {
    const Driver = req.getModel('Driver');
    const drivers = await Driver.find();
    res.json(drivers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/drivers
// @desc    Create a driver profile
router.post('/', protect, async (req, res) => {
  const { name, phone, email, licenseNumber, vehicleDetails } = req.body;
  try {
    const Driver = req.getModel('Driver');
    const driver = await Driver.create({ name, phone, email, licenseNumber, vehicleDetails });
    res.status(201).json(driver);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { getTenantConnection } = require('../utils/tenant');
const locationSchema = require('../models/Location');

// @route   GET /api/locations
// @desc    Get all active locations from zudo-central
router.get('/', async (req, res) => {
  try {
    // Connect to zudo-central
    const centralConn = getTenantConnection('central');
    const Location = centralConn.model('Location', locationSchema);
    
    const locations = await Location.find({ isActive: true });
    res.json(locations);
  } catch (error) {
    console.error('Error fetching locations:', error);
    res.status(500).json({ message: 'Failed to fetch locations' });
  }
});

module.exports = router;

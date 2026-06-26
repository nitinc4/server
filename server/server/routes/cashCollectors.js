const express = require('express');
const router = express.Router();
const CashCollector = require('../models/CashCollector');
const { protect } = require('../middleware/auth');

// @route   GET /api/cashcollectors/:id
// @desc    Get cash collector by ID
router.get('/:id', protect, async (req, res) => {
  try {
    const CashCollectorModel = req.models?.CashCollector || CashCollector;
    const collector = await CashCollectorModel.findById(req.params.id);
    if (!collector) {
      return res.status(404).json({ message: 'Cash collector not found' });
    }
    res.json(collector);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/cashcollectors
// @desc    Get all cash collectors
router.get('/', protect, async (req, res) => {
  try {
    const CashCollectorModel = req.models?.CashCollector || CashCollector;
    const collectors = await CashCollectorModel.find();
    res.json(collectors);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

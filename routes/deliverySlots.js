const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');

const getModels = (req) => req.models || {
  DeliverySlot: require('../models/DeliverySlot')
};

// @route   GET /api/deliveryslots
// @desc    Get all delivery slots
router.get('/', async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const deliverySlots = await aggregateGET('DeliverySlot', req);
      res.json(deliverySlots);
    } else {
      const { DeliverySlot } = getModels(req);
      const deliverySlots = await DeliverySlot.find();
      res.json(deliverySlots);
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/deliveryslots
// @desc    Create a delivery slot
router.post('/', protect, async (req, res) => {
  try {
    const { DeliverySlot } = getModels(req);
    const newSlot = await DeliverySlot.create(req.body);
    res.status(201).json(newSlot);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   PUT /api/deliveryslots/:id
// @desc    Update a delivery slot
router.put('/:id', protect, async (req, res) => {
  try {
    const { DeliverySlot } = getModels(req);
    const updatedSlot = await DeliverySlot.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );
    if (!updatedSlot) return res.status(404).json({ message: 'Delivery slot not found' });
    res.json(updatedSlot);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   DELETE /api/deliveryslots/:id
// @desc    Delete a delivery slot
router.delete('/:id', protect, async (req, res) => {
  try {
    const { DeliverySlot } = getModels(req);
    const deletedSlot = await DeliverySlot.findByIdAndDelete(req.params.id);
    if (!deletedSlot) return res.status(404).json({ message: 'Delivery slot not found' });
    res.json({ message: 'Delivery slot removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

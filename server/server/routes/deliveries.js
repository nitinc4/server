const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const DeliverySlot = require('../models/DeliverySlot');
const { protect } = require('../middleware/auth');
const { getModel } = require('../utils/model_loader');

// @route   GET /api/deliveries/stats
// @desc    Get delivery statistics
router.get('/stats', protect, async (req, res) => {
  try {
    const OrderModel = getModel('Order', req);
    const orders = await OrderModel.find({ orderStatus: 'Delivered' });

    let totalDeliveryTime = 0;
    let deliveredCount = 0;

    orders.forEach(order => {
      if (order.assignedAt && order.deliveredAt) {
        const diff = order.deliveredAt - order.assignedAt;
        totalDeliveryTime += diff;
        deliveredCount++;
      }
    });

    const avgDeliveryTimeMs = deliveredCount > 0 ? totalDeliveryTime / deliveredCount : 0;
    const avgDeliveryTimeMinutes = Math.round(avgDeliveryTimeMs / (1000 * 60));

    const stats = {
      avgDeliveryTime: avgDeliveryTimeMinutes,
      totalDelivered: deliveredCount,
      successRate: orders.length > 0 ? (deliveredCount / orders.length) * 100 : 0,
      avgRating: 4.8 // Placeholder
    };

    res.json(stats);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/deliveries/slots
// @desc    Get all delivery slots
router.get('/slots', protect, async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const slots = await aggregateGET('DeliverySlot', req);
      return res.json(slots);
    }
    const SlotModel = getModel('DeliverySlot', req);
    const slots = await SlotModel.find();
    res.json(slots);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/deliveries/slots
// @desc    Create a delivery slot
router.post('/slots', protect, async (req, res) => {
  try {
    const SlotModel = getModel('DeliverySlot', req);
    const { startTime, endTime, isActive, isSameDay, globalIsSameDay, orderedBeforeTime, SameDayCutoff } = req.body;

    const slot = await SlotModel.create({
      startTime,
      endTime,
      SameDayCutoff,
      isActive,
      isSameDay,
      globalIsSameDay,
      orderedBeforeTime: orderedBeforeTime || '',
      locationId: req.locationId || req.user.locationId
    });

    res.status(201).json(slot);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   PUT /api/deliveries/slots/:id
// @desc    Update a delivery slot
router.put('/slots/:id', protect, async (req, res) => {
  try {
    const SlotModel = getModel('DeliverySlot', req);
    const slot = await SlotModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!slot) return res.status(404).json({ message: 'Slot not found' });
    res.json(slot);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   DELETE /api/deliveries/slots/:id
// @desc    Delete a delivery slot
router.delete('/slots/:id', protect, async (req, res) => {
  try {
    const SlotModel = getModel('DeliverySlot', req);
    const slot = await SlotModel.findByIdAndDelete(req.params.id);
    if (!slot) return res.status(404).json({ message: 'Slot not found' });
    res.json({ message: 'Slot deleted' });
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

module.exports = router;


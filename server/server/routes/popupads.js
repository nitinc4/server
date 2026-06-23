const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { getModel } = require('../utils/model_loader');

console.log('Popup Ads router loaded');

// @route   GET /api/popup-ads
// @desc    Get all popup ads
router.get('/', protect, async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const ads = await aggregateGET('PopupAd', req, {}, [], '', { createdAt: -1 });
      return res.json(ads);
    }
    const PopupAdModel = getModel('PopupAd', req);
    const ads = await PopupAdModel.find().sort({ createdAt: -1 });
    res.json(ads);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/popup-ads
// @desc    Create a new popup ad
router.post('/', protect, async (req, res) => {
  try {
    const PopupAdModel = getModel('PopupAd', req);
    const ad = await PopupAdModel.create({
      ...req.body,
      locationId: req.locationId
    });
    res.status(201).json(ad);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   PUT /api/popup-ads/:id
// @desc    Update a popup ad
router.put('/:id', protect, async (req, res) => {
  try {
    const PopupAdModel = getModel('PopupAd', req);
    const ad = await PopupAdModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!ad) return res.status(404).json({ message: 'Ad not found' });
    res.json(ad);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   DELETE /api/popup-ads/:id
// @desc    Delete a popup ad
router.delete('/:id', protect, async (req, res) => {
  try {
    const PopupAdModel = getModel('PopupAd', req);
    const ad = await PopupAdModel.findByIdAndDelete(req.params.id);
    if (!ad) return res.status(404).json({ message: 'Ad not found' });
    res.json({ message: 'Ad removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

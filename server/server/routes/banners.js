const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { getModel } = require('../utils/model_loader');

console.log('Banners router loaded');

// @route   GET /api/banners
// @desc    Get all banners
router.get('/', protect, async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const banners = await aggregateGET('Banner', req, {}, [], '', { createdAt: -1 });
      return res.json(banners);
    }
    const BannerModel = getModel('Banner', req);
    const banners = await BannerModel.find().sort({ createdAt: -1 });
    res.json(banners);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/banners
// @desc    Create a new banner
router.post('/', protect, async (req, res) => {
  try {
    const BannerModel = getModel('Banner', req);
    console.log(`Creating banner for location: ${req.locationId || 'Global'}`);
    const banner = await BannerModel.create({
      ...req.body,
      locationId: req.locationId
    });
    res.status(201).json(banner);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   PUT /api/banners/:id
// @desc    Update a banner
router.put('/:id', protect, async (req, res) => {
  try {
    const BannerModel = getModel('Banner', req);
    const banner = await BannerModel.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!banner) return res.status(404).json({ message: 'Banner not found' });
    res.json(banner);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
});

// @route   DELETE /api/banners/:id
// @desc    Delete a banner
router.delete('/:id', protect, async (req, res) => {
  try {
    const BannerModel = getModel('Banner', req);
    const banner = await BannerModel.findByIdAndDelete(req.params.id);
    if (!banner) return res.status(404).json({ message: 'Banner not found' });
    res.json({ message: 'Banner removed' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

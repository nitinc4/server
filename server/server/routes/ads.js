const express = require('express');
const router = express.Router();
const { getModel } = require('../utils/model_loader');

// @route   GET /api/ads/popup
// @desc    Get active popup ads for the current tenant
router.get('/popup', async (req, res) => {
  try {
    const PopupAdModel = getModel('PopupAd', req);
    const ads = await PopupAdModel.find({ 
      isActive: true,
      showOn: 'Home'
    }).sort({ createdAt: -1 });

    console.log(`[DEBUG] Found ${ads.length} active popup ads for Home`);
    res.json(ads);
  } catch (err) {
    console.error('[ERROR] Failed to fetch popup ads:', err);
    res.status(500).json({ message: 'Error fetching ads' });
  }
});

module.exports = router;

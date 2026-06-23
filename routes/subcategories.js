const express = require('express');
const router = express.Router();
const SubCategory = require('../models/SubCategory');

// @route   GET /api/subcategories
// @desc    Get all subcategories
router.get('/', async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const subCategories = await aggregateGET('SubCategory', req);
      res.json(subCategories);
    } else {
      const SubCategoryModel = req.models?.SubCategory || SubCategory;
      const subCategories = await SubCategoryModel.find();
      res.json(subCategories);
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

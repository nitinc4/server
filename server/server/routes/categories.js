const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');

const getModels = (req) => req.models || {
  Category: require('../models/Category'),
  SubCategory: require('../models/SubCategory')
};

// @route   GET /api/categories
// @desc    Get all categories with subcategories
router.get('/', async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const categories = await aggregateGET('Category', req);
      const subCategories = await aggregateGET('SubCategory', req);
      
      const result = categories.map((cat) => {
        const subCats = subCategories.filter(
          sub => sub.categoryId?.toString() === cat._id?.toString() && sub.locationId?.toString() === cat.locationId?.toString()
        );
        return { ...cat, subCategories: subCats };
      });
      res.json(result);
    } else {
      const { Category, SubCategory } = getModels(req);
      const categories = await Category.find();
      const result = await Promise.all(categories.map(async (cat) => {
        const subCats = await SubCategory.find({ categoryId: cat._id });
        return { ...cat._doc, subCategories: subCats };
      }));
      res.json(result);
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/categories
// @desc    Create a category
router.post('/', protect, async (req, res) => {
  const { name, imageUrl } = req.body;
  try {
    const { Category } = getModels(req);
    const category = await Category.create({ name, imageUrl });
    res.status(201).json(category);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/categories/sub
// @desc    Create a subcategory
router.post('/sub', protect, async (req, res) => {
  const { name, imageUrl, categoryId } = req.body;
  try {
    const { SubCategory } = getModels(req);
    const subCategory = await SubCategory.create({ name, imageUrl, categoryId });
    res.status(201).json(subCategory);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

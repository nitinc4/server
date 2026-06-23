const express = require('express');
const router = express.Router();
const Review = require('../models/Review');
const { protect } = require('../middleware/auth');

// @route   POST /api/reviews
// @desc    Create a new review
router.post('/', protect, async (req, res) => {
  try {
    const { productId, rating, comment, media } = req.body;
    const Review = req.getModel('Review');
    const review = await Review.create({
      userId: req.user._id,
      productId,
      rating,
      comment,
      media
    });
    
    const populatedReview = await Review.findById(review._id).populate('userId', 'name profilePicture role');
    res.status(201).json(populatedReview);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/reviews/product/:id
// @desc    Get reviews for a product
router.get('/product/:id', async (req, res) => {
  try {
    const Review = req.getModel('Review');
    const reviews = await Review.find({ productId: req.params.id })
      .populate('userId', 'name profilePicture role')
      .sort({ createdAt: -1 });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/reviews
// @desc    Get all reviews (Admin)
router.get('/', protect, async (req, res) => {
  try {
    const Review = req.getModel('Review');
    const reviews = await Review.find()
      .populate('userId', 'name email role')
      .populate('productId', 'name')
      .sort({ createdAt: -1 });
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   DELETE /api/reviews/:id
// @desc    Delete a review
router.delete('/:id', protect, async (req, res) => {
  try {
    const Review = req.getModel('Review');
    const review = await Review.findById(req.params.id);
    if (!review) return res.status(404).json({ message: 'Review not found' });
    
    await review.deleteOne();
    res.json({ message: 'Review deleted' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

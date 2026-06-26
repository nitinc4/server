const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const FeedPost = require('../models/FeedPost');
const Seller = require('../models/Seller');

const getModels = (req) => {
  return {
    FeedPost: req.models?.FeedPost || FeedPost,
    Seller: req.models?.Seller || Seller
  };
};

// @route   GET /api/feed
// @desc    Get all active feed posts
router.get('/', async (req, res) => {
  try {
    const { FeedPost: FeedPostModel, Seller: SellerModel } = getModels(req);
    let posts = await FeedPostModel.find({ isActive: true })
      .populate('sellerId')
      .sort({ createdAt: -1 });

    if (posts.length === 0) {
      // Find or create an active seller for seeding
      let seller = await SellerModel.findOne();
      if (!seller) {
        seller = await SellerModel.create({
          name: 'Green Farms Organic',
          email: 'greenfarms@zudo.com',
          password: 'password123',
          storeName: 'Green Farms Organic',
          businessName: 'Green Farms Organic',
          businessAddress: '12 Organic Valley, Bengaluru',
          phone: '9876543210',
          isVerified: true
        });
      }

      const seedPosts = [
        {
          sellerId: seller._id,
          title: 'Vibrant Summer Mango Fest!',
          description: 'Get ready for the sweetest summer ever! Grab 25% discount on all premium, chemically-free Alphonso & Kesar Mangoes. Handpicked directly from organic orchards for ultimate rich taste and freshness.',
          imageUrl: 'https://images.unsplash.com/photo-1553279768-865429fa0078?q=80&w=600&auto=format&fit=crop',
          discountPercent: 25,
          offerCode: 'MANGO25',
          isActive: true
        },
        {
          sellerId: seller._id,
          title: 'Fresh Strawberries Flash Sale',
          description: 'Flash Sale Alert! 15% off on freshly plucked, luscious red strawberries from Mahabaleshwar. Perfect for shakes, desserts, or direct snacking. Order today before stock runs out!',
          imageUrl: 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?q=80&w=600&auto=format&fit=crop',
          discountPercent: 15,
          offerCode: 'BERRY15',
          isActive: true
        },
        {
          sellerId: seller._id,
          title: 'Organic Green Groceries Special',
          description: 'Upgrade your health with Green Farms! Enjoy 20% off on all organic green leafy vegetables, broccoli, lettuce, and premium avocados. Cultivated with 100% natural fertilizers.',
          imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=600&auto=format&fit=crop',
          discountPercent: 20,
          offerCode: 'ORGANIC20',
          isActive: true
        },
        {
          sellerId: seller._id,
          title: 'Exotic Dragon Fruits Deal',
          description: 'Supercharge your antioxidant intake! Get buy 1 get 1 free or direct 30% discount on vibrant Exotic Pink Dragon Fruits imported directly from farm partners. Rich, sweet, and incredibly fresh.',
          imageUrl: 'https://images.unsplash.com/photo-1528825871115-3581a5387919?q=80&w=600&auto=format&fit=crop',
          discountPercent: 30,
          offerCode: 'DRAGON30',
          isActive: true
        }
      ];

      await FeedPostModel.create(seedPosts);
      posts = await FeedPostModel.find({ isActive: true })
        .populate('sellerId')
        .sort({ createdAt: -1 });
    }

    res.json(posts);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/feed
// @desc    Create a new feed post
router.post('/', protect, async (req, res) => {
  const { title, description, imageUrl, discountPercent, offerCode } = req.body;
  try {
    const { FeedPost: FeedPostModel } = getModels(req);
    const post = await FeedPostModel.create({
      sellerId: req.user._id,
      title,
      description,
      imageUrl,
      discountPercent,
      offerCode
    });
    res.status(201).json(post);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { getModel } = require('../utils/model_loader');

// ─── Multer storage ───────────────────────────────────────────────
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, '../uploads/feeds');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const suffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, 'feed-' + suffix + path.extname(file.originalname));
  }
});

const allowedMime = [
  'image/jpeg', 'image/png', 'image/webp', 'image/gif',
  'video/mp4', 'video/webm', 'video/quicktime'
];

const upload = multer({
  storage,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB
  fileFilter: (req, file, cb) => {
    if (allowedMime.includes(file.mimetype)) cb(null, true);
    else cb(new Error(`Unsupported file type: ${file.mimetype}`));
  }
});

// ─── POST /api/feeds/upload ───────────────────────────────────────
router.post('/upload', (req, res) => {
  upload.single('file')(req, res, async (err) => {
    if (err) return res.status(400).json({ message: err.message });
    if (!req.file) return res.status(400).json({ message: 'No file uploaded' });

    try {
      const FeedModel = getModel('Feed', req);
      const isVideo = req.file.mimetype.startsWith('video/');
      const productionDomain = 'https://lightgreen-trout-176417.hostingersite.com';
      const url = `${productionDomain}/uploads/feeds/${req.file.filename}`;

      const feed = await FeedModel.create({
        url,
        type: req.body.type || (isVideo ? 'video' : 'image'),
        filename: req.file.filename,
        title: req.body.title || '',
        description: req.body.description || '',
        sellerId: req.body.sellerId || null
      });

      res.status(201).json({ message: 'Uploaded successfully', feed });
    } catch (error) {
      res.status(500).json({ message: 'Server error', error: error.message });
    }
  });
});

// ─── GET /api/feeds ───────────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const FeedModel = getModel('Feed', req);
    const feeds = await FeedModel.find().sort({ createdAt: -1 });
    res.json(feeds);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// ─── DELETE /api/feeds/:id ────────────────────────────────────────
router.delete('/:id', async (req, res) => {
  try {
    const FeedModel = getModel('Feed', req);
    const feed = await FeedModel.findByIdAndDelete(req.params.id);

    if (!feed) return res.status(404).json({ message: 'Feed item not found' });

    // Remove physical file
    if (feed.filename) {
      const filePath = path.join(__dirname, '../uploads/feeds', feed.filename);
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    }

    res.json({ message: 'Deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;

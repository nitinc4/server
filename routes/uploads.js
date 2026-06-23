const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Configure Multer for persistent storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = process.env.UPLOAD_DIR || path.join(__dirname, '../uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf', 'video/mp4', 'video/quicktime', 'video/webm'];
    const allowedExts = ['.jpg', '.jpeg', '.png', '.webp', '.pdf', '.mp4', '.mov', '.webm'];
    const ext = path.extname(file.originalname).toLowerCase();

    if (allowedTypes.includes(file.mimetype) || allowedExts.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type (${file.mimetype}). Supported: JPEG, PNG, WEBP, PDF, MP4, MOV, WEBM.`));
    }
  }
});

// @route   POST /api/upload
// @desc    Generic upload for images and PDFs
router.post('/', (req, res) => {
  upload.single('file')(req, res, (err) => {
    if (err) {
      console.error('Multer Error:', err);
      return res.status(500).json({ message: 'Multer upload error', error: err.message });
    }

    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    try {
      const productionDomain = 'https://lightgreen-trout-176417.hostingersite.com';
      const fileUrl = `${productionDomain}/uploads/${req.file.filename}`;
      res.status(200).json({
        message: 'File uploaded successfully',
        url: fileUrl,
        filename: req.file.filename,
        mimetype: req.file.mimetype
      });
    } catch (error) {
      console.error('Upload Process Error:', error);
      res.status(500).json({ message: 'Error processing upload', error: error.message });
    }
  });
});

module.exports = router;

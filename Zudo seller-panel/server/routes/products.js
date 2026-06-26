const express = require('express');
const router = express.Router();
const multer = require('multer');
const xlsx = require('xlsx');
const path = require('path');
const fs = require('fs');
const Product = require('../models/Product');
const Category = require('../models/Category');
const SubCategory = require('../models/SubCategory');
const { protect } = require('../middleware/auth');

// Configure Multer for persistent storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const uploadDir = path.join(__dirname, '../uploads');
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
    const allowedTypes = [
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
      'application/vnd.ms-excel', // .xls
      'text/csv', // .csv
      'application/octet-stream' // generic fallback
    ];

    const extension = path.extname(file.originalname).toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.pdf', '.xlsx', '.xls', '.csv'];

    if (allowedTypes.includes(file.mimetype) || allowedExtensions.includes(extension)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type (${file.mimetype}). Only images, PDF, Excel and CSV are allowed.`));
    }
  }
});

// @route   GET /api/products
// @desc    Get all products
router.get('/', async (req, res) => {
  try {
    const Product = req.getModel('Product');
    const products = await Product.find().populate('categoryId').populate('subCategoryId');
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/products
// @desc    Create a single product with image and/or pdf upload
router.post('/', protect, upload.fields([{ name: 'image', maxCount: 1 }, { name: 'pdf', maxCount: 1 }]), async (req, res) => {
  try {
    const { name, categoryId, subCategoryId, price, b2bPrice, moq, unit, sellerId, stock, gstRate, gstPercent, description, sku } = req.body;

    let imageUrl = req.body.imageUrl || '';
    if (req.files && req.files['image']) {
      imageUrl = `/uploads/${req.files['image'][0].filename}`;
    }

    let pdfUrl = req.body.pdfUrl || '';
    if (req.files && req.files['pdf']) {
      pdfUrl = `/uploads/${req.files['pdf'][0].filename}`;
    }

    // Parse stringified JSON arrays sent from multipart form
    let b2c = [];
    if (req.body.b2c) {
      try {
        b2c = typeof req.body.b2c === 'string' ? JSON.parse(req.body.b2c) : req.body.b2c;
      } catch (e) {
        console.error('Failed to parse b2c:', e);
      }
    }

    let b2b = [];
    if (req.body.b2b) {
      try {
        b2b = typeof req.body.b2b === 'string' ? JSON.parse(req.body.b2b) : req.body.b2b;
      } catch (e) {
        console.error('Failed to parse b2b:', e);
      }
    }

    let priceTiers = [];
    if (req.body.priceTiers) {
      try {
        priceTiers = typeof req.body.priceTiers === 'string' ? JSON.parse(req.body.priceTiers) : req.body.priceTiers;
      } catch (e) {
        console.error('Failed to parse priceTiers:', e);
      }
    }

    // Set correct sellerId and sellerName
    const finalSellerId = (sellerId && sellerId !== 'undefined' && sellerId !== 'null' && sellerId !== '') ? sellerId : req.user._id;
    const finalSellerName = req.user ? (req.user.storeName || req.user.businessName || req.user.name) : undefined;

    const Product = req.getModel('Product');
    const product = await Product.create({
      name,
      categoryId,
      subCategoryId: subCategoryId || null,
      price: price || 0,
      b2bPrice: b2bPrice || 0,
      moq,
      unit,
      sellerId: finalSellerId,
      sellerName: finalSellerName,
      stock: stock || 0, // Save stock
      gstRate: Number(gstPercent !== undefined ? gstPercent : gstRate) || 0, // Save GST rate
      gstPercent: Number(gstPercent !== undefined ? gstPercent : gstRate) || 0, // Save GST percent
      description,
      sku,
      imageUrl,
      pdfUrl,
      rating: 0,
      b2b,
      b2c,
      priceTiers
    });

    res.status(201).json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/products/bulk-upload
// @desc    Bulk upload products via Excel
router.post('/bulk-upload', protect, upload.single('file'), async (req, res) => {
  if (!req.file) return res.status(400).json({ message: 'No file uploaded' });

  try {
    const workbook = xlsx.readFile(req.file.path);
    const sheetName = workbook.SheetNames[0];
    const data = xlsx.utils.sheet_to_json(workbook.Sheets[sheetName]);

    const ProductModel = req.getModel('Product');
    const CategoryModel = req.getModel('Category');
    const SubCategoryModel = req.getModel('SubCategory');

    const results = [];
    for (const item of data) {
      // 1. Resolve Category
      let categoryId = item.categoryId || item.CategoryId;
      if (!categoryId && item.Category) {
        let category = await CategoryModel.findOne({ name: { $regex: new RegExp(`^${item.Category}$`, 'i') } });
        if (!category) {
          category = await CategoryModel.create({
            name: item.Category,
            imageUrl: item.CategoryImageUrl || 'https://via.placeholder.com/150?text=Category'
          });
        }
        categoryId = category._id;
      }

      if (!categoryId) continue; // Skip if no category found or created

      // 2. Resolve SubCategory
      let subCategoryId = item.subCategoryId || item.SubCategoryId;
      if (!subCategoryId && item.SubCategory) {
        let subCategory = await SubCategoryModel.findOne({
          name: { $regex: new RegExp(`^${item.SubCategory}$`, 'i') },
          categoryId: categoryId
        });
        if (!subCategory) {
          subCategory = await SubCategoryModel.create({
            name: item.SubCategory,
            imageUrl: item.SubCategoryImageUrl || 'https://via.placeholder.com/150?text=SubCategory',
            categoryId: categoryId
          });
        }
        subCategoryId = subCategory._id;
      }

      // 3. Create Product
      const product = await ProductModel.create({
        name: item.Name || item.name,
        categoryId: categoryId,
        subCategoryId: subCategoryId || null,
        price: Number(item.Price || item.price),
        b2bPrice: Number(item.B2BPrice || item.b2bPrice),
        moq: Number(item.MOQ || item.moq || 1),
        unit: item.Unit || item.unit || 'pcs',
        stock: Number(item.Stock || item.stock || 0),
        gstRate: Number(item.GST || item.gst || item.GSTRate || item.gstRate || 0),
        description: item.Description || item.description || '',
        imageUrl: item.ImageUrl || item.imageUrl || 'https://via.placeholder.com/150?text=Product',
        sellerId: req.user._id, // Essential: Link to seller
        rating: Number(item.Rating || item.rating || 0)
      });
      results.push(product);
    }

    // Clean up
    fs.unlinkSync(req.file.path);

    res.status(201).json({
      message: `Successfully uploaded ${results.length} products`,
      count: results.length
    });
  } catch (error) {
    console.error('Bulk upload error:', error);
    if (req.file && fs.existsSync(req.file.path)) fs.unlinkSync(req.file.path);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/products/:id
router.get('/:id', async (req, res) => {
  try {
    const Product = req.getModel('Product');
    console.log(`[DEBUG] Fetching product ${req.params.id} from database: ${Product.db.name}`);
    const product = await Product.findById(req.params.id);
    if (!product) {
      console.log(`[DEBUG] Product ${req.params.id} NOT found in database: ${Product.db.name}`);
      return res.status(404).json({ message: 'Product not found' });
    }
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   PUT /api/products/:id
router.put('/:id', protect, async (req, res) => {
  try {
    const Product = req.getModel('Product');
    const product = await Product.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json(product);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   DELETE /api/products/:id
router.delete('/:id', protect, async (req, res) => {
  try {
    const Product = req.getModel('Product');
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ message: 'Product not found' });
    res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

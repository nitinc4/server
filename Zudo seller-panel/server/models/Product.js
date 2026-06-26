const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true },
  subCategoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'SubCategory' }, // Optional as requested
  price: { type: Number, required: true },
  b2bPrice: { type: Number, required: true },
  moq: { type: Number, default: 1 },
  unit: { type: String, required: true },
  imageUrl: { type: String },
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  stock: { type: Number, default: 0 }, // Added stock
  gstRate: { type: Number, default: 0 }, // Added GST rate (bracket) in %
  gstPercent: { type: Number, default: 0 }, // Support both naming variants
  description: { type: String },
  sku: { type: String },
  pdfUrl: { type: String },
  rating: { type: Number, default: 0 },
  b2b: [{
    packetSize: String,
    price: Number,
    stock: Number,
    gstPercent: Number,
    priceTiers: Array
  }],
  b2c: [{
    packetSize: String,
    price: Number,
    stock: Number,
    gstPercent: Number
  }],
  priceTiers: [{
    minQty: Number,
    price: Number
  }],
  sellerName: String
}, { timestamps: true });

module.exports = mongoose.model('Product', productSchema);


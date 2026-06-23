const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  name: { type: String, required: true },
  categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true },
  subCategoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'SubCategory' }, // Optional as requested
  price: { type: Number, required: true },
  b2bPrice: { type: Number, required: true },
  gstPercent: { type: Number, default: 0 },
  moq: { type: Number, default: 1 },
  unit: { type: String, required: true },
  imageUrl: { type: String },
  sellerId: { type: mongoose.Schema.Types.ObjectId, ref: 'Seller' },
  sellerName: { type: String, default: 'Zudo Official' },
  stock: { type: Number, default: 0 }, // Added stock
  description: { type: String },
  pdfUrl: { type: String },
  rating: { type: Number, default: 0 },
  variants: [{
    sizeName: { type: String, required: true }, // e.g. "1kg", "500g"
    price: { type: Number, required: true },
    b2bPrice: { type: Number, required: true },
    stock: { type: Number, default: 0 },
    gstPercent: { type: Number, default: 0 },
    priceTiers: [{
      minQty: { type: Number, required: true },
      price: { type: Number, required: true }
    }]
  }],
  b2c: [{
    packetSize: { type: String },
    mrp: { type: Number },
    price: { type: Number },
    stock: { type: Number, default: 0 },
    gstPercent: { type: Number, default: 0 }
  }],
  b2b: [{
    packetSize: { type: String },
    mrp: { type: Number },
    price: { type: Number },
    stock: { type: Number, default: 0 },
    gstPercent: { type: Number, default: 0 },
    priceTiers: [{
      minQty: { type: Number, required: true },
      price: { type: Number, required: true }
    }]
  }],
  priceTiers: [{
    minQty: { type: Number, required: true },
    price: { type: Number, required: true }
  }]
}, { timestamps: true });

module.exports = mongoose.model('Product', productSchema);

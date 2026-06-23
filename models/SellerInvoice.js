const mongoose = require('mongoose');

const sellerInvoiceSchema = new mongoose.Schema({
  sellerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Seller',
    required: true
  },
  startDate: {
    type: Date,
    required: true
  },
  endDate: {
    type: Date,
    required: true
  },
  totalAmount: {
    type: Number,
    required: true,
    default: 0
  },
  totalCommission: {
    type: Number,
    required: true,
    default: 0
  },
  netAmount: {
    type: Number,
    required: true,
    default: 0
  },
  orderCount: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    enum: ['Pending', 'Cleared'],
    default: 'Pending'
  },
  orders: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order'
  }],
  generatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Seller'
  }
}, { timestamps: true });

module.exports = mongoose.model('SellerInvoice', sellerInvoiceSchema);

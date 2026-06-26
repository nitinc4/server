const mongoose = require('mongoose');

const cashTransactionSchema = new mongoose.Schema({
  type: {
    type: String,
    required: true
  },
  name: {
    type: String,
    required: true
  },
  phone: {
    type: String,
    required: true
  },
  email: {
    type: String
  },
  amount: {
    type: Number,
    required: true
  },
  description: {
    type: String
  },
  paymentMethod: {
    type: String,
    default: 'Cash'
  },
  date: {
    type: Date,
    default: Date.now
  }
}, { timestamps: true });

module.exports = mongoose.model('CashTransaction', cashTransactionSchema);

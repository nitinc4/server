const mongoose = require('mongoose');

const commissionSchema = new mongoose.Schema({
  categoryId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Category',
    required: true
  },
  unit: {
    type: String,
    required: true
  },
  commissionType: {
    type: String,
    enum: ['flat', 'percentage'],
    default: 'flat'
  },
  commissionValue: {
    type: Number,
    required: true
  }
}, { timestamps: true });

module.exports = mongoose.model('Commission', commissionSchema);

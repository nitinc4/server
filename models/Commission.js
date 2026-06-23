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
    enum: ['percentage', 'flat'],
    default: 'percentage'
  },
  commissionValue: {
    type: Number,
    required: true,
    default: 0
  }
}, { timestamps: true });

// Enforce unique combination of category and unit
commissionSchema.index({ categoryId: 1, unit: 1 }, { unique: true });

module.exports = mongoose.model('Commission', commissionSchema);

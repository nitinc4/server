const mongoose = require('mongoose');

const pincodeSchema = new mongoose.Schema({
  code: { type: String, required: true },
  locationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Location', required: true },
  isActive: { type: Boolean, default: true }
}, { timestamps: true });

module.exports = mongoose.model('Pincode', pincodeSchema);

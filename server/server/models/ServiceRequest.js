const mongoose = require('mongoose');

const serviceRequestSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true },
  mobile: { type: String },
  pincode: { type: String, required: true },
  city: { type: String },
  requestedAt: { type: Date, default: Date.now }
}, { timestamps: true });

// This model should always use the central database
module.exports = mongoose.model('ServiceRequest', serviceRequestSchema);

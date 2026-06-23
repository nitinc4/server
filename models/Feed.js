const mongoose = require('mongoose');

const feedSchema = new mongoose.Schema({
  url: { type: String, required: true },
  type: { type: String, enum: ['image', 'video'], default: 'image' },
  filename: String,
  title: { type: String, default: '' },
  description: { type: String, default: '' },
  sellerId: String,
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Feed', feedSchema);

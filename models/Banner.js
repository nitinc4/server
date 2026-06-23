const mongoose = require('mongoose');

const bannerSchema = new mongoose.Schema({
  title: { type: String },
  imageUrl: { type: String, required: true },
  link: { type: String },
  isActive: { type: Boolean, default: true },
  locationId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Location',
    default: null 
  },
  type: {
    type: String,
    enum: ['Main', 'Sidebar', 'Promotion'],
    default: 'Main'
  }
}, { timestamps: true });

module.exports = mongoose.model('Banner', bannerSchema);

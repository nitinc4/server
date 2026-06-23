const mongoose = require('mongoose');

const popupAdSchema = new mongoose.Schema({
  title: { type: String, required: true },
  imageUrl: { type: String, required: true },
  link: { type: String },
  isActive: { type: Boolean, default: true },
  locationId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Location',
    default: null 
  },
  showOn: {
    type: String,
    enum: ['Home', 'Categories', 'Products', 'All'],
    default: 'Home'
  },
  expiresAt: { type: Date }
}, { timestamps: true });

module.exports = mongoose.model('PopupAd', popupAdSchema);

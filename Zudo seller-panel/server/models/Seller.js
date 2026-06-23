const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const sellerSchema = new mongoose.Schema({
  name: { type: String },
  email: { type: String, unique: true },
  password: { type: String },
  phone: { type: String },
  role: { type: String, default: 'seller' },
  businessName: { type: String },
  businessAddress: { type: String },
  storeName: { type: String },
  billingAddress: { type: String },
  pickupLocation: {
    lat: Number,
    lng: Number,
    address: String
  },
  isProfileComplete: { type: Boolean, default: false },
  isVerified: { type: Boolean, default: false },
  storePic: { type: String },
  gstDoc: { type: String },
  panDoc: { type: String },
  tradeLicenseDoc: { type: String },
  rmcAmpcDoc: { type: String }
}, { timestamps: true });

// Hash password before saving
sellerSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Compare password
sellerSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Seller', sellerSchema);

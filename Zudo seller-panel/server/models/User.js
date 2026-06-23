const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true },
  phone: { type: String },
  password: { type: String, required: true },
  role: { type: String, enum: ['b2c', 'b2b', 'seller'], default: 'b2c' },
  profilePicture: { type: String },
  // B2B specific fields
  businessName: { type: String },
  businessAddress: { type: String },
  gstNumber: { type: String },
  panNumber: { type: String },
  aadhaarNumber: { type: String },
  gstPdf: { type: String },
  panPdf: { type: String },
  storePic: { type: String },
  isVerified: { type: Boolean, default: false },
  isWaitingApproval: { type: Boolean, default: false },
  savedAddresses: [{
    name: String,
    phone: String,
    address: String,
    city: String,
    pincode: String,
    state: String,
    lat: Number,
    lng: Number,
    isDefault: { type: Boolean, default: false }
  }]
}, { timestamps: true });

userSchema.index({ email: 1, role: 1 }, { unique: true });

userSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 10);
});

userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);

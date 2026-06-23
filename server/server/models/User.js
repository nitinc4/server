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
  pincode: { type: String },
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
  }],
  bankDetails: {
    accountName: { type: String },
    accountNumber: { type: String },
    ifscCode: { type: String },
    bankName: { type: String }
  },
  resetPasswordToken: String,
  resetPasswordExpires: Date,
  fcmToken: { type: String },
  tokenVersion: { type: Number, default: 0 },
  isBlocked: { type: Boolean, default: false },
  status: { type: String, enum: ['active', 'inactive', 'suspended', 'deleted'], default: 'active' },

  // Authentication & Security
  authProvider: { type: String, enum: ['local', 'google', 'facebook', 'apple'], default: 'local' },
  providerId: { type: String }, // For Google/Facebook/Apple ID
  lastLogin: { type: Date },
  lastActive: { type: Date },
  loginIp: { type: String },
  deviceType: { type: String }, // e.g., 'iOS', 'Android', 'Web'

  // Financial & Engagement
  walletBalance: { type: Number, default: 0 },
  loyaltyPoints: { type: Number, default: 0 },
  totalOrders: { type: Number, default: 0 },
  lifetimeValue: { type: Number, default: 0 },
  referralCode: { type: String },
  referredBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  // Personalization & Preferences
  dateOfBirth: { type: Date },
  gender: { type: String, enum: ['Male', 'Female', 'Other', 'Prefer not to say'] },
  preferences: {
    newsletter: { type: Boolean, default: true },
    pushNotifications: { type: Boolean, default: true },
    smsNotifications: { type: Boolean, default: true },
    language: { type: String, default: 'en' },
    currency: { type: String, default: 'INR' }
  },

  // Metadata
  metadata: { type: mongoose.Schema.Types.Mixed },
  currentSessionToken: { type: String, default: null }
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

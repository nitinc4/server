const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const cashCollectorSchema = new mongoose.Schema({
  type: {
    type: String,
    required: true,
    enum: ['B2C', 'B2B', 'B2C (Driver)', 'Account']
  },
  name: {
    type: String,
    required: true
  },
  phone: {
    type: String,
    required: true,
    unique: true
  },
  email: {
    type: String
  },
  password: {
    type: String
  },
  status: {
    type: String,
    enum: ['active', 'inactive'],
    default: 'active'
  },
  amount: {
    type: Number
  },
  description: {
    type: String
  },
  paymentMethod: {
    type: String,
    default: 'Cash'
  },
  date: {
    type: Date,
    default: Date.now
  },
  tokenVersion: {
    type: Number,
    default: 0
  }
}, { 
  timestamps: true,
  collection: 'cashcollectors' 
});

// Hash password before saving
cashCollectorSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  if (!this.password) return;
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Compare password method
cashCollectorSchema.methods.comparePassword = async function(candidatePassword) {
  if (!this.password) return false;
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('CashCollector', cashCollectorSchema);

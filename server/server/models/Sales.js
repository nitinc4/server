const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const salesSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { 
    type: String, 
    default: 'sales' 
  },
  name: { type: String, required: true },
  phone: { type: String },
  locationId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Location',
    default: null 
  },
  pincodes: [{ type: String }],
  currentSessionToken: { type: String, default: null }
}, { timestamps: true });

salesSchema.pre('save', async function() {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 10);
});

salesSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('Sales', salesSchema);

const mongoose = require('mongoose');

const SettingSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true
  },
  value: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  tenantId: {
    type: String,
    default: 'default'
  }
}, { timestamps: true });

module.exports = mongoose.model('Setting', SettingSchema);

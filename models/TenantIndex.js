const mongoose = require('mongoose');

const tenantIndexSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  locationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Location', required: true },
  dbName: { type: String, required: true }
}, { timestamps: true });

module.exports = mongoose.model('TenantIndex', tenantIndexSchema);

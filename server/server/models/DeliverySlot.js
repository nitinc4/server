const mongoose = require('mongoose');

const deliverySlotSchema = new mongoose.Schema({
  startTime: { type: String, required: false },
  endTime: { type: String, required: false },
  SameDayCutoff: { type: String, required: false },
  isActive: { type: Boolean, default: true },
  isSameDay: { type: Boolean, default: false },
  globalIsSameDay: { type: Boolean, default: false },
  orderedBeforeTime: { type: String, default: "" },
  locationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Location', default: null }
}, { timestamps: true });

module.exports = mongoose.model('DeliverySlot', deliverySlotSchema, 'deliveryslots');


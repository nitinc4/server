const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  driverId: { type: mongoose.Schema.Types.ObjectId, ref: 'Driver', required: true },
  date: { type: Date, required: true },
  status: { type: String, enum: ['Present', 'Absent', 'Half-day', 'Off'], required: true },
  checkInTime: { type: Date },
  checkOutTime: { type: Date },
  deliveriesCompleted: { type: Number, default: 0 }
}, { timestamps: true });

// Ensure one attendance record per driver per day
attendanceSchema.index({ driverId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);

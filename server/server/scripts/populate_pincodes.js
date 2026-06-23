const mongoose = require('mongoose');
require('dotenv').config({ path: '../server/.env' });

const MONGODB_URI = process.env.MONGODB_URI;

const populatePincodes = async () => {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to zudo-bangalore.');

    // 1. Find the Bangalore location ID
    const LocationSchema = new mongoose.Schema({
      name: String
    }, { strict: false });
    const Location = mongoose.model('Location', LocationSchema);
    
    const bangalore = await Location.findOne({ name: 'zudo-bangalore' });
    if (!bangalore) {
      console.error('Bangalore location not found!');
      process.exit(1);
    }
    const locationId = bangalore._id;
    console.log(`Found Bangalore Location ID: ${locationId}`);

    // 2. Define Pincode Schema
    const PincodeSchema = new mongoose.Schema({
      code: { type: String, required: true },
      locationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Location', required: true },
      isActive: { type: Boolean, default: true }
    }, { timestamps: true });

    const Pincode = mongoose.model('Pincode', PincodeSchema);

    // 3. Generate and Insert Pincodes
    console.log('Generating pincodes...');
    const pincodeDocs = [];
    for (let i = 1; i <= 110; i++) {
      pincodeDocs.push({
        code: '560' + i.toString().padStart(3, '0'),
        locationId: locationId,
        isActive: true
      });
    }

    console.log(`Inserting ${pincodeDocs.length} pincodes...`);
    await Pincode.insertMany(pincodeDocs);
    console.log('Successfully populated pincodes collection.');

    process.exit(0);
  } catch (error) {
    console.error('Population failed:', error);
    process.exit(1);
  }
};

populatePincodes();

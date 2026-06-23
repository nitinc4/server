const mongoose = require('mongoose');
require('dotenv').config({ path: '../server/.env' });

const URI = process.env.MONGODB_URI;
const CENTRAL_DB_NAME = 'zudo-central';

const lastSlashIndex = URI.lastIndexOf('/');
const lastQuestionIndex = URI.indexOf('?', lastSlashIndex);
const CENTRAL_URI = URI.substring(0, lastSlashIndex + 1) + CENTRAL_DB_NAME + (lastQuestionIndex !== -1 ? URI.substring(lastQuestionIndex) : '');

const createCentralMapping = async () => {
  try {
    const conn = await mongoose.createConnection(CENTRAL_URI).asPromise();
    console.log('Connected to zudo-central.');

    const MappingSchema = new mongoose.Schema({
      pincode: { type: String, required: true, unique: true },
      dbName: { type: String, required: true },
      city: { type: String, required: true }
    });

    const Mapping = conn.model('PincodeMapping', MappingSchema, 'pincodemappings');

    // Clear existing
    await Mapping.deleteMany({});

    const mappings = [];

    // Coimbatore
    const coimbatorePincodes = ['641001', '641002', '641003', '641004'];
    coimbatorePincodes.forEach(pc => {
      mappings.push({ pincode: pc, dbName: 'zudo-coimbatore', city: 'Coimbatore' });
    });

    // Bengaluru
    for (let i = 1; i <= 110; i++) {
      const pc = '560' + i.toString().padStart(3, '0');
      mappings.push({ pincode: pc, dbName: 'zudo-bengaluru', city: 'Bengaluru' });
    }

    await Mapping.insertMany(mappings);
    console.log(`Inserted ${mappings.length} pincode mappings into pincodemappings collection.`);

    // Also populate 'locations' collection for visibility
    const LocationMappingSchema = new mongoose.Schema({
      city: String,
      dbName: String
    });
    const LocationMapping = conn.model('CentralLocation', LocationMappingSchema, 'locations');
    await LocationMapping.deleteMany({});
    await LocationMapping.insertMany([
      { city: 'Coimbatore', dbName: 'zudo-coimbatore' },
      { city: 'Bengaluru', dbName: 'zudo-bengaluru' }
    ]);
    console.log('Populated locations collection in zudo-central.');

    await conn.close();
    process.exit(0);
  } catch (error) {
    console.error('Failed to create central mapping:', error);
    process.exit(1);
  }
};

createCentralMapping();

const mongoose = require('mongoose');
require('dotenv').config({ path: '../server/.env' });

const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
  console.error('MONGODB_URI not found in .env file');
  process.exit(1);
}

// Function to generate pincodes for Bangalore
const getBangalorePincodes = () => {
  const codes = [];
  for (let i = 1; i <= 110; i++) {
    codes.push('560' + i.toString().padStart(3, '0'));
  }
  return codes.join(', ');
};

const setupBangalore = async () => {
  try {
    // 1. Connect to the existing database
    console.log('Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to current database.');

    // 2. Identify the new database URI
    const newDbName = 'zudo-bangalore';
    const newUri = MONGODB_URI.replace(/\/zudodb\?/, `/${newDbName}?`);
    
    console.log(`New Database Name: ${newDbName}`);
    
    // 3. Define the Location Schema (matching your model)
    const LocationSchema = new mongoose.Schema({
      name: { type: String, required: true },
      city: { type: String, required: true },
      state: { type: String, required: true },
      pincode: { type: String, required: true },
      isActive: { type: Boolean, default: true }
    }, { timestamps: true });

    // Close old connection and connect to new database to create it
    await mongoose.disconnect();
    console.log('Connecting to new database...');
    await mongoose.connect(newUri);
    const Location = mongoose.model('Location', LocationSchema);

    // 4. Create Bangalore Location record
    const bangaloreLocation = new Location({
      name: 'zudo-bangalore',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: getBangalorePincodes(),
      isActive: true
    });

    await bangaloreLocation.save();
    console.log('Successfully added Bangalore location with pincodes.');

    // 5. Output instructions to user
    console.log('\n--- NEXT STEPS ---');
    console.log('1. Update your .env file MONGODB_URI to use "zudo-bangalore" instead of "zudodb".');
    console.log(`Current URI part: /zudodb?`);
    console.log(`Updated URI part: /${newDbName}?`);
    console.log('\n2. If you need to migrate old data, you should use mongodump and mongorestore.');

    process.exit(0);
  } catch (error) {
    console.error('Error during setup:', error);
    process.exit(1);
  }
};

setupBangalore();

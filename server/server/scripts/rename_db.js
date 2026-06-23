const mongoose = require('mongoose');
require('dotenv').config({ path: '../server/.env' });

// We need the OLD URI to connect to zudodb first
// If .env is already updated, we construct the old one
const NEW_URI = process.env.MONGODB_URI;
const OLD_URI = NEW_URI.replace(/\/zudo-bangalore\?/, '/zudodb?');

const migrateDatabase = async () => {
  try {
    console.log('Connecting to OLD database (zudodb)...');
    const oldConn = await mongoose.createConnection(OLD_URI).asPromise();
    console.log('Connected to zudodb.');

    console.log('Connecting to NEW database (zudo-bangalore)...');
    const newConn = await mongoose.createConnection(NEW_URI).asPromise();
    console.log('Connected to zudo-bangalore.');

    const collections = await oldConn.db.listCollections().toArray();
    console.log(`Found ${collections.length} collections to migrate.`);

    for (const collection of collections) {
      const name = collection.name;
      if (name.startsWith('system.')) continue; // Skip system collections

      console.log(`Migrating collection: ${name}...`);
      const documents = await oldConn.db.collection(name).find().toArray();
      
      if (documents.length > 0) {
        await newConn.db.collection(name).insertMany(documents);
      }
      console.log(`Finished migrating ${name} (${documents.length} documents).`);
    }

    // Now add the Bangalore location record to the new database
    const LocationSchema = new mongoose.Schema({
      name: { type: String, required: true },
      city: { type: String, required: true },
      state: { type: String, required: true },
      pincode: { type: String, required: true },
      isActive: { type: Boolean, default: true }
    }, { timestamps: true });

    const Location = newConn.model('Location', LocationSchema);
    
    const getBangalorePincodes = () => {
      const codes = [];
      for (let i = 1; i <= 110; i++) {
        codes.push('560' + i.toString().padStart(3, '0'));
      }
      return codes.join(', ');
    };

    const bangaloreLocation = new Location({
      name: 'zudo-bangalore',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: getBangalorePincodes(),
      isActive: true
    });

    await bangaloreLocation.save();
    console.log('Added Bangalore location to the migrated database.');

    // DROP the old database
    console.log('Dropping the old database (zudodb)...');
    await oldConn.db.dropDatabase();
    console.log('Old database zudodb dropped.');

    console.log('\n--- MIGRATION COMPLETE ---');
    console.log('The database zudodb has been successfully renamed to zudo-bangalore.');
    
    await oldConn.close();
    await newConn.close();
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
};

migrateDatabase();

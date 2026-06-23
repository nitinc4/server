const mongoose = require('mongoose');
require('dotenv').config({ path: '../server/.env' });

const NEW_URI = process.env.MONGODB_URI; // This currently points to zudo-bangalore if I didn't change it back
const OLD_DB_NAME = 'zudo-bangalore';
const NEW_DB_NAME = 'zudo-bengaluru';

const OLD_URI = NEW_URI.includes(OLD_DB_NAME) ? NEW_URI : NEW_URI.replace(/\/.*?\?/, `/${OLD_DB_NAME}?`);
const REAL_NEW_URI = OLD_URI.replace(`/${OLD_DB_NAME}?`, `/${NEW_DB_NAME}?`);

const renameToBengaluru = async () => {
  try {
    console.log(`Connecting to OLD database (${OLD_DB_NAME})...`);
    const oldConn = await mongoose.createConnection(OLD_URI).asPromise();
    
    console.log(`Connecting to NEW database (${NEW_DB_NAME})...`);
    const newConn = await mongoose.createConnection(REAL_NEW_URI).asPromise();

    const collections = await oldConn.db.listCollections().toArray();
    for (const col of collections) {
      const name = col.name;
      if (name.startsWith('system.')) continue;
      
      console.log(`Migrating ${name}...`);
      const docs = await oldConn.db.collection(name).find().toArray();
      if (docs.length > 0) {
        await newConn.db.collection(name).insertMany(docs);
      }
    }

    // Update records in the new database
    console.log('Updating records in new database...');
    await newConn.db.collection('locations').updateMany(
      { city: 'Bangalore' },
      { $set: { city: 'Bengaluru', name: 'zudo-bengaluru' } }
    );
    
    // Also update TenantIndex if any
    await newConn.db.collection('tenantindexes').updateMany(
      { dbName: OLD_DB_NAME },
      { $set: { dbName: NEW_DB_NAME } }
    );

    console.log('Dropping old database...');
    await oldConn.db.dropDatabase();
    
    console.log('\n--- RENAME COMPLETE ---');
    console.log(`${OLD_DB_NAME} -> ${NEW_DB_NAME}`);
    
    await oldConn.close();
    await newConn.close();
    
    process.exit(0);
  } catch (error) {
    console.error('Rename failed:', error);
    process.exit(1);
  }
};

renameToBengaluru();

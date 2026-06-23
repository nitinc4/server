/**
 * Seed script to insert the minimumBillAmount setting into all tenant DBs.
 * Run: node seed_min_bill.js
 */
const { MongoClient } = require('mongodb');
const path = require('path');

// Load .env from server directory
require('dotenv').config({ path: path.join(__dirname, '.env') });

async function seedMinBill() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI not set in .env');
    process.exit(1);
  }

  const client = new MongoClient(uri);
  await client.connect();

  const adminDb = client.db('admin');
  const dbList = await adminDb.admin().listDatabases();

  // Filter to only Zudo tenant databases (skip admin, local, config)
  const systemDbs = ['admin', 'local', 'config'];

  for (const { name } of dbList.databases) {
    if (systemDbs.includes(name)) continue;

    const db = client.db(name);
    const collections = await db.listCollections().toArray();
    const hasProducts = collections.find(c => c.name === 'products');
    if (!hasProducts) continue; // skip non-tenant DBs

    const result = await db.collection('settings').updateOne(
      { key: 'minimumBillAmount' },
      { $setOnInsert: { key: 'minimumBillAmount', value: 2000 } },
      { upsert: true }
    );

    console.log(`[${name}] minimumBillAmount: ${result.upsertedCount > 0 ? 'INSERTED' : 'ALREADY EXISTS'}`);
  }

  await client.close();
  console.log('\nDone! Minimum bill amount set to ₹2,000 in all tenant databases.');
}

seedMinBill().catch(err => {
  console.error('Seeding failed:', err);
  process.exit(1);
});

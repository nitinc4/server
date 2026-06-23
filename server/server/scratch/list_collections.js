require('dotenv').config();
const mongoose = require('mongoose');

async function run() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB.');

    const activeDb = mongoose.connection.db;
    const collections = await activeDb.listCollections().toArray();
    console.log('Collections:');
    console.log(collections.map(c => c.name));

    // Let's check if there is a 'commissions' collection and print its contents
    const hasCommissions = collections.some(c => c.name === 'commissions');
    if (hasCommissions) {
      console.log('\n--- Commissions ---');
      const commissions = await activeDb.collection('commissions').find().toArray();
      console.log(commissions);
    } else {
      console.log('\nNo commissions collection found.');
    }

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

run();

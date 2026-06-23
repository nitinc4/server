require('dotenv').config();
const mongoose = require('mongoose');
const CashCollector = require('./models/CashCollector');

const seedCashCollector = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const collectorId = '69fc41007860360d852e5cb5';
    // Check if it already exists
    const existing = await CashCollector.findById(collectorId);
    if (existing) {
      console.log('Collector already exists:', existing);
      process.exit(0);
    }

    const newCollector = new CashCollector({
      _id: new mongoose.Types.ObjectId(collectorId),
      name: 'Ramesh Kumar',
      phone: '9876543210',
      email: 'ramesh.collector@zudo.com',
      address: 'Central Hub, Delhi',
      status: 'active'
    });

    await newCollector.save();
    console.log('Cash collector seeded successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Seeding error:', err);
    process.exit(1);
  }
};

seedCashCollector();

const mongoose = require('mongoose');
require('dotenv').config();

async function checkIndexes() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');
    
    const User = mongoose.model('User', new mongoose.Schema({}, { strict: false }));
    const indexes = await User.collection.indexes();
    console.log('User collection indexes:', JSON.stringify(indexes, null, 2));
    
    await mongoose.disconnect();
  } catch (err) {
    console.error('Error:', err);
  }
}

checkIndexes();

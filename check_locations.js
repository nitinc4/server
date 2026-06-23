require('dotenv').config();
const mongoose = require('mongoose');
const Location = require('./models/Location');

async function test() {
  await mongoose.connect(process.env.MONGODB_URI);
  const locs = await Location.find();
  console.log('Locations in DB:', locs);
  process.exit(0);
}
test();

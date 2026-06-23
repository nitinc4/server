const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Driver = require('../models/Driver');

const createDrivers = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Delete existing test drivers to avoid duplicates
    await Driver.deleteMany({ phone: { $in: ['1234567890', '0987654321'] } });
    console.log('Cleaned up existing test drivers');

    // Create B2C Driver
    const b2cDriver = await Driver.create({
      name: 'B2C Driver Test',
      phone: '1234567890',
      email: 'b2c.driver@test.com',
      password: 'driverpassword123',
      licenseNumber: 'B2C12345',
      vehicleDetails: 'Splendor Plus (B2C Bike)',
      type: 'b2c',
      status: 'active'
    });
    console.log('B2C Driver Created:', b2cDriver);

    // Create B2B Driver
    const b2bDriver = await Driver.create({
      name: 'B2B Driver Test',
      phone: '0987654321',
      email: 'b2b.driver@test.com',
      password: 'driverpassword123',
      licenseNumber: 'B2B67890',
      vehicleDetails: 'Tata Ace (B2B Mini Truck)',
      type: 'b2b',
      status: 'active'
    });
    console.log('B2B Driver Created:', b2bDriver);

    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  } catch (error) {
    console.error('Error creating drivers:', error);
    process.exit(1);
  }
};

createDrivers();

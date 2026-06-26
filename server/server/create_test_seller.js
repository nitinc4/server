const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

async function createSeller() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const email = 'seller@test.com';
    const password = 'password123';
    const role = 'b2b';

    const existingUser = await User.findOne({ email, role });
    if (existingUser) {
      console.log('Test seller already exists:', email);
      process.exit(0);
    }

    const user = await User.create({
      name: 'Test Seller',
      email,
      password,
      role,
      phone: '1234567890',
      businessName: 'Zudo Test Store',
      businessAddress: '123 Tech Park, Bangalore',
      isVerified: true
    });

    console.log('Test seller created successfully!');
    console.log('Email:', email);
    console.log('Password:', password);
    process.exit(0);
  } catch (error) {
    console.error('Failed to create seller:', error);
    process.exit(1);
  }
}

createSeller();

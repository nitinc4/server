require('dotenv').config();
const mongoose = require('mongoose');
const Admin = require('./models/Admin');

async function seedSuperAdmin() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    const email = 'zudo.superadmin@gmail.com';
    const password = 'Zudo@12345';

    let admin = await Admin.findOne({ email });
    if (admin) {
      admin.password = password;
      await admin.save();
      console.log('Super Admin password reset.');
    } else {
      await Admin.create({
        name: 'Super Admin',
        email,
        password,
        role: 'super_admin',
        locationId: null,
        permissions: []
      });
      console.log('Super Admin account created.');
    }

    process.exit(0);
  } catch (error) {
    console.error('Seed Error:', error);
    process.exit(1);
  }
}

seedSuperAdmin();

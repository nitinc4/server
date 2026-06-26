require('dotenv').config();
const mongoose = require('mongoose');
const Admin = require('./models/Admin');
const Location = require('./models/Location');

async function debugLogin(emailToSearch = 'zudosales123@gmail.com') {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log(`Searching for: ${emailToSearch}`);
    
    console.log('\n--- Global Database ---');
    const globalAdmin = await Admin.findOne({ email: new RegExp(`^${emailToSearch}$`, 'i') });
    if (globalAdmin) {
      console.log(` ✅ Found in Global DB: ${globalAdmin.email} (${globalAdmin.role})`);
    } else {
      console.log(` ❌ NOT Found in Global DB`);
    }

    const locations = await Location.find();
    console.log(`\n--- Tenant Databases ---`);
    for (const loc of locations) {
      const dbName = `zudo-${loc.city.toLowerCase().replace(/\s+/g, '-')}`;
      console.log(`Checking ${loc.city} (${dbName})...`);
      
      try {
        const uri = process.env.MONGODB_URI;
        const lastSlashIndex = uri.lastIndexOf('/');
        const dbUri = uri.substring(0, lastSlashIndex + 1) + dbName + (uri.includes('?') ? '?' + uri.split('?')[1] : '');
        
        const conn = await mongoose.createConnection(dbUri).asPromise();
        const TenantAdmin = conn.model('Admin', Admin.schema);
        const admin = await TenantAdmin.findOne({ email: new RegExp(`^${emailToSearch}$`, 'i') });
        
        if (admin) {
          console.log(` ✅ FOUND in ${dbName}! Role: ${admin.role}`);
        } else {
          console.log(` ❌ Not found in ${dbName}`);
        }
        await conn.close();
      } catch (err) {
        console.log(` ⚠️ Error checking ${dbName}: ${err.message}`);
      }
    }

    process.exit(0);
  } catch (error) {
    console.error('Debug Error:', error);
    process.exit(1);
  }
}

debugLogin();


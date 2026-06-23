require('dotenv').config();
const mongoose = require('mongoose');
const Admin = require('./models/Admin');
const Location = require('./models/Location');

async function debugLogin() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    const locations = await Location.find();
    console.log(`Checking ${locations.length} location databases...`);

    for (const loc of locations) {
      const dbName = `zudo-${loc.city.toLowerCase().replace(/\s+/g, '-')}`;
      console.log(`\n--- DB: ${dbName} ---`);
      try {
        const uri = process.env.MONGODB_URI;
        const dbUri = uri.substring(0, uri.lastIndexOf('/') + 1) + dbName;
        const conn = await mongoose.createConnection(dbUri).asPromise();
        const TenantAdmin = conn.model('Admin', Admin.schema);
        const admins = await TenantAdmin.find();
        console.log(`Found ${admins.length} admins:`);
        admins.forEach(a => console.log(` - ${a.email} (${a.role})`));
        await conn.close();
      } catch (err) {
        console.log(` ⚠️ Could not connect: ${err.message}`);
      }
    }

    process.exit(0);
  } catch (error) {
    console.error('Debug Error:', error);
    process.exit(1);
  }
}

debugLogin();

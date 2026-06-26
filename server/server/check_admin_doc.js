const mongoose = require('mongoose');
require('dotenv').config();

async function check() {
  const uri = process.env.MONGODB_URI;
  const uriWithoutQuery = uri.split('?')[0];
  const query = uri.includes('?') ? '?' + uri.split('?')[1] : '';
  const lastSlashIndex = uriWithoutQuery.lastIndexOf('/');
  
  const blrUri = uriWithoutQuery.substring(0, lastSlashIndex + 1) + 'zudo-bengaluru' + query;
  const blrConn = await mongoose.createConnection(blrUri).asPromise();
  const BlrAdmin = blrConn.model('Admin', require('./models/Admin').schema);
  const blrAdmin = await BlrAdmin.findOne({ email: 'zudo.superadmin@gmail.com' });
  console.log("Admin doc:", blrAdmin);
  
  blrConn.close();
}
check();

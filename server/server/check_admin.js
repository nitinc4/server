const mongoose = require('mongoose');
require('dotenv').config();

async function check() {
  const uri = process.env.MONGODB_URI;
  const uriWithoutQuery = uri.split('?')[0];
  const query = uri.includes('?') ? '?' + uri.split('?')[1] : '';
  const lastSlashIndex = uriWithoutQuery.lastIndexOf('/');
  const centralUri = uriWithoutQuery.substring(0, lastSlashIndex + 1) + 'zudodb' + query;
  
  const conn = await mongoose.createConnection(centralUri).asPromise();
  const Admin = conn.model('Admin', require('./models/Admin').schema);
  const admin = await Admin.findOne({ email: 'zudo.superadmin@gmail.com' });
  console.log("Admin in zudodb:", admin ? admin.role : "Not found");
  
  const blrUri = uriWithoutQuery.substring(0, lastSlashIndex + 1) + 'zudo-bengaluru' + query;
  const blrConn = await mongoose.createConnection(blrUri).asPromise();
  const BlrAdmin = blrConn.model('Admin', require('./models/Admin').schema);
  const blrAdmin = await BlrAdmin.findOne({ email: 'zudo.superadmin@gmail.com' });
  console.log("Admin in zudo-bengaluru:", blrAdmin ? blrAdmin.role : "Not found");
  
  conn.close();
  blrConn.close();
}
check();

const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

async function check() {
  try {
    const uri = process.env.MONGODB_URI;
    const uriWithoutQuery = uri.split('?')[0];
    const query = uri.includes('?') ? '?' + uri.split('?')[1] : '';
    const lastSlashIndex = uriWithoutQuery.lastIndexOf('/');
    
    const BlrUri = uriWithoutQuery.substring(0, lastSlashIndex + 1) + 'zudo-bengaluru' + query;
    const blrConn = await mongoose.createConnection(BlrUri).asPromise();
    
    const ProductModel = blrConn.model('Product', new mongoose.Schema({}, {strict: false}));
    
    const total = await ProductModel.countDocuments();
    const withB2b = await ProductModel.countDocuments({ b2b: { $exists: true, $not: {$size: 0} } });
    const withB2c = await ProductModel.countDocuments({ b2c: { $exists: true, $not: {$size: 0} } });
    const withoutB2c = await ProductModel.countDocuments({ b2c: { $exists: false } });
    
    console.log(`Total: ${total}, with b2b: ${withB2b}, with b2c: ${withB2c}`);
    
    blrConn.close();
  } catch(e) {
    console.error(e);
  }
}
check();

const mongoose = require('mongoose');
require('dotenv').config();

async function check() {
  try {
    const uri = process.env.MONGODB_URI;
    console.log("URI:", uri);
    
    // Connect to central DB
    const uriWithoutQuery = uri.split('?')[0];
    const query = uri.includes('?') ? '?' + uri.split('?')[1] : '';
    const lastSlashIndex = uriWithoutQuery.lastIndexOf('/');
    
    const centralUri = uriWithoutQuery.substring(0, lastSlashIndex + 1) + 'zudo-central' + query;
    const centralConn = await mongoose.createConnection(centralUri).asPromise();
    const LocationModel = centralConn.model('Location', require('./models/Location').schema);
    const locs = await LocationModel.find();
    console.log(`Central DB locations count: ${locs.length}`);
    
    const BlrUri = uriWithoutQuery.substring(0, lastSlashIndex + 1) + 'zudo-bengaluru' + query;
    const blrConn = await mongoose.createConnection(BlrUri).asPromise();
    const ProductModel = blrConn.model('Product', require('./models/Product').schema);
    const count = await ProductModel.countDocuments();
    console.log(`Bengaluru DB products count: ${count}`);

    centralConn.close();
    blrConn.close();
  } catch(e) {
    console.error(e);
  }
}

check();

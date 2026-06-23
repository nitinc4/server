const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

async function applyNewVariants() {
  try {
    const uri = process.env.MONGODB_URI;
    console.log("URI:", uri);
    
    const uriWithoutQuery = uri.split('?')[0];
    const query = uri.includes('?') ? '?' + uri.split('?')[1] : '';
    const lastSlashIndex = uriWithoutQuery.lastIndexOf('/');
    
    const BlrUri = uriWithoutQuery.substring(0, lastSlashIndex + 1) + 'zudo-bengaluru' + query;
    const blrConn = await mongoose.createConnection(BlrUri).asPromise();
    
    // Use raw collection to avoid Mongoose strict schema stripping
    const collection = blrConn.collection('products');
    
    const newB2C = [
      { packetSize: "500gm", mrp: 150, price: 100, stock: 100, _id: new mongoose.Types.ObjectId() },
      { packetSize: "1kg", mrp: 200, price: 150, stock: 100, _id: new mongoose.Types.ObjectId() }
    ];
    
    const newB2B = [
      { packetSize: "5kg", mrp: 1000, price: 900, stock: 100, _id: new mongoose.Types.ObjectId() },
      { packetSize: "50kg", mrp: 5000, price: 4670, stock: 100, _id: new mongoose.Types.ObjectId() }
    ];

    console.log("Updating all products...");
    
    const result = await collection.updateMany({}, {
      $set: {
        price: 0,
        b2bPrice: 0,
        b2c: newB2C,
        b2b: newB2B,
        variants: []
      }
    });
    
    console.log(`Successfully updated ${result.modifiedCount} products.`);
    
    blrConn.close();
  } catch(e) {
    console.error("Error:", e);
  }
}

applyNewVariants();

const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const ProductSchema = require('../models/Product').schema;

async function updateMrp() {
  try {
    const uri = process.env.MONGODB_URI;
    console.log("URI:", uri);
    
    const uriWithoutQuery = uri.split('?')[0];
    const query = uri.includes('?') ? '?' + uri.split('?')[1] : '';
    const lastSlashIndex = uriWithoutQuery.lastIndexOf('/');
    
    const BlrUri = uriWithoutQuery.substring(0, lastSlashIndex + 1) + 'zudo-bengaluru' + query;
    const blrConn = await mongoose.createConnection(BlrUri).asPromise();
    const ProductModel = blrConn.model('Product', ProductSchema);
    
    console.log("Connected to DB. Fetching products...");
    
    const products = await ProductModel.find({});
    let updatedCount = 0;
    
    for (const product of products) {
      let changed = false;
      
      // Update base product MRP (price)
      if (product.price !== 5000) {
        product.price = 5000;
        changed = true;
      }
      
      // Update variant MRPs (price) if any exist
      if (product.variants && product.variants.length > 0) {
        for (const variant of product.variants) {
          if (variant.price !== 5000) {
            variant.price = 5000;
            changed = true;
          }
        }
      }
      
      if (changed) {
        await product.save();
        updatedCount++;
      }
    }
    
    console.log(`Updated MRP to 5000 for ${updatedCount} products.`);
    
    blrConn.close();
  } catch(e) {
    console.error("Error:", e);
  }
}

updateMrp();

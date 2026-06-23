require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const mongoose = require('mongoose');
const Product = require('../models/Product');

mongoose.connect(process.env.MONGODB_URI).then(async () => {
  const products = await Product.find({});
  
  const b2cVariants = [
    { packetSize: '250gm', price: 50, stock: 100 },
    { packetSize: '500gm', price: 100, stock: 100 },
    { packetSize: '1kg', price: 175, stock: 100 },
    { packetSize: '5kg', price: 450, stock: 100 }
  ];

  const b2bVariants = [
    { packetSize: '5kg', price: 400, stock: 100 },
    { packetSize: '10kg', price: 800, stock: 100 },
    { packetSize: '15kg', price: 1000, stock: 100 },
    { packetSize: '25kg', price: 1500, stock: 100 }
  ];
  
  for (let p of products) {
    p.b2b = b2bVariants;
    p.b2c = b2cVariants;
    // Set old variants field to empty or undefined if we removed it from schema
    p.set('variants', undefined);
    await p.save();
  }
  
  console.log(`Successfully migrated ${products.length} products`);
  process.exit(0);
}).catch(console.error);

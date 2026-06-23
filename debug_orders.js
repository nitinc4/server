const mongoose = require('mongoose');
const Product = require('./models/Product');
const Order = require('./models/Order');
const User = require('./models/User');
require('dotenv').config();

async function debugOrders() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const sellerEmail = 'seller@test.com';
    const seller = await User.findOne({ email: sellerEmail, role: 'b2b' });
    
    if (!seller) {
      console.log('Seller not found');
      process.exit(1);
    }
    
    console.log('Seller ID:', seller._id);

    const products = await Product.find({ 
      $or: [
        { sellerId: seller._id.toString() },
        { seller: seller._id }
      ]
    });
    
    console.log(`Found ${products.length} products for this seller.`);
    const productIds = products.map(p => p._id.toString());
    console.log('Product IDs:', productIds);

    const allOrders = await Order.find();
    console.log(`Total orders in DB: ${allOrders.length}`);

    const sellerOrders = allOrders.filter(order => {
      return order.items.some(item => {
        const pId = item.productId ? item.productId.toString() : null;
        return productIds.includes(pId);
      });
    });

    console.log(`Found ${sellerOrders.length} orders for this seller via manual filter.`);
    
    if (sellerOrders.length > 0) {
        console.log('First order items:', JSON.stringify(sellerOrders[0].items.map(i => ({ pId: i.productId, name: i.name })), null, 2));
    }

    process.exit(0);
  } catch (error) {
    console.error('Debug failed:', error);
    process.exit(1);
  }
}

debugOrders();

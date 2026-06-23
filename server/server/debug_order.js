require('dotenv').config();
const mongoose = require('mongoose');
const Order = require('./models/Order');

const debugOrder = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const order = await Order.findOne({ cashPersonId: { $exists: true } });
    if (order) {
      console.log('Found order with cashPersonId:', JSON.stringify(order, null, 2));
    } else {
      console.log('No order found with cashPersonId');
      const anyOrder = await Order.findOne();
      console.log('Example order fields:', Object.keys(anyOrder.toObject()));
      if (anyOrder.cashPersonId) {
          console.log('Wait, anyOrder.cashPersonId exists:', anyOrder.cashPersonId);
      }
    }
    process.exit(0);
  } catch (err) {
    console.error('Debug error:', err);
    process.exit(1);
  }
};

debugOrder();

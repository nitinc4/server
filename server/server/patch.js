require('dotenv').config();
const mongoose = require('mongoose');

mongoose.connect(process.env.MONGODB_URI).then(async () => {
  const db = mongoose.connection.useDb('zudo-bengaluru');
  const Order = db.model('Order', new mongoose.Schema({}, { strict: false }));
  
  const deliveredOrders = await Order.find({ orderStatus: 'Delivered' });
  
  const seller1Id = new mongoose.Types.ObjectId('69f9cedc75ccb3c21c3d176e'); // new seller
  const seller2Id = new mongoose.Types.ObjectId('69faeeddccdf0937a9c92714'); // seller1
  
  for (let i = 0; i < deliveredOrders.length; i++) {
    const order = deliveredOrders[i];
    const assignedSellerId = (i % 2 === 0) ? seller1Id : seller2Id;
    
    const updatedItems = order.get('items').map(item => {
      return {
        ...item,
        seller: { sellerId: assignedSellerId },
        sellerId: assignedSellerId,
        price: item.price || 1500, // mock price if it was 0 or undefined
        quantity: item.quantity || 1
      };
    });
    
    await Order.updateOne({ _id: order._id }, { $set: { items: updatedItems } });
  }
  
  console.log('Successfully patched ' + deliveredOrders.length + ' orders with valid Seller links!');
  process.exit(0);
}).catch(console.error);

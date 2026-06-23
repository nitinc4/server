const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { getModel } = require('../utils/model_loader');

// @route   GET /api/payments/sellers
// @desc    Get all sellers with their total sales, total paid, and outstanding balances (Admin)
router.get('/sellers', protect, async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      
      const [sellers, products, orders, payouts] = await Promise.all([
        aggregateGET('Seller', req, {}, [], '-password'),
        aggregateGET('Product', req, {}, [], '_id sellerId'),
        aggregateGET('Order', req, { orderStatus: 'Delivered' }),
        aggregateGET('SellerPayment', req)
      ]);

      const productSellerMap = {};
      products.forEach(p => {
        if (p.sellerId) {
          productSellerMap[p._id.toString()] = p.sellerId.toString();
        }
      });

      const sellerPaymentStats = sellers.map(seller => {
        const sellerIdStr = seller._id.toString();

        let totalSales = 0;
        let orderCount = 0;

        orders.forEach(order => {
          let hasSellerItem = false;
          order.items.forEach(item => {
            let itemSellerId = item.seller?.sellerId?.toString() || item.sellerId?.toString();
            
            if (!itemSellerId && item.productId) {
              itemSellerId = productSellerMap[item.productId.toString()];
            }

            if (itemSellerId === sellerIdStr) {
              totalSales += (item.price * item.quantity);
              hasSellerItem = true;
            }
          });
          if (hasSellerItem) {
            orderCount++;
          }
        });

        const sellerPayouts = payouts.filter(p => p.sellerId.toString() === sellerIdStr);
        const totalPaid = sellerPayouts.reduce((sum, p) => sum + p.amount, 0);

        return {
          seller,
          totalSales,
          totalPaid,
          outstandingBalance: totalSales - totalPaid,
          orderCount,
          payoutCount: sellerPayouts.length
        };
      });

      return res.json(sellerPaymentStats);
    }

    const SellerModel = getModel('Seller', req);
    const OrderModel = getModel('Order', req);
    const SellerPaymentModel = getModel('SellerPayment', req);
    const ProductModel = getModel('Product', req);

    // Fetch all sellers
    const sellers = await SellerModel.find().select('-password');

    // Fetch all products to map productId to sellerId
    const products = await ProductModel.find().select('_id sellerId');
    const productSellerMap = {};
    products.forEach(p => {
      if (p.sellerId) {
        productSellerMap[p._id.toString()] = p.sellerId.toString();
      }
    });

    // Fetch all Delivered orders
    const orders = await OrderModel.find({ 
      orderStatus: 'Delivered'
    });

    // Fetch all payouts
    const payouts = await SellerPaymentModel.find();

    // Map sellers to their stats
    const sellerPaymentStats = sellers.map(seller => {
      const sellerIdStr = seller._id.toString();

      // Compute total sales for this seller from delivered orders
      let totalSales = 0;
      let orderCount = 0;

      orders.forEach(order => {
        let hasSellerItem = false;
        order.items.forEach(item => {
          let itemSellerId = item.seller?.sellerId?.toString() || item.sellerId?.toString();
          
          if (!itemSellerId && item.productId) {
            itemSellerId = productSellerMap[item.productId.toString()];
          }

          if (itemSellerId === sellerIdStr) {
            totalSales += (item.price * item.quantity);
            hasSellerItem = true;
          }
        });
        if (hasSellerItem) {
          orderCount++;
        }
      });

      // Compute total payouts made to this seller
      const sellerPayouts = payouts.filter(p => p.sellerId.toString() === sellerIdStr);
      const totalPaid = sellerPayouts.reduce((sum, p) => sum + p.amount, 0);

      return {
        seller,
        totalSales,
        totalPaid,
        outstandingBalance: totalSales - totalPaid,
        orderCount,
        payoutCount: sellerPayouts.length
      };
    });

    res.json(sellerPaymentStats);
  } catch (error) {
    console.error('Fetch seller payments error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/payments/sellers/:sellerId/history
// @desc    Get payment and order history for a specific seller (Admin)
router.get('/sellers/:sellerId/history', protect, async (req, res) => {
  try {
    const sellerId = req.params.sellerId;

    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      
      const [payouts, sellerProducts, allOrders] = await Promise.all([
        aggregateGET('SellerPayment', req, { sellerId }, [], '', { date: -1 }),
        aggregateGET('Product', req, { $or: [{ sellerId: sellerId }, { seller: sellerId }] }, [], '_id'),
        aggregateGET('Order', req, {
          orderStatus: 'Delivered',
          'items': {
            $elemMatch: {
              $or: [
                { 'seller.sellerId': sellerId },
                { 'sellerId': sellerId }
              ]
            }
          }
        }, ['userId'], '', { createdAt: -1 })
      ]);

      const productIds = sellerProducts.map(p => p._id.toString());
      
      const sales = [];
      allOrders.forEach(order => {
        order.items.forEach(item => {
          let itemSellerId = item.seller?.sellerId?.toString() || item.sellerId?.toString();
          let isSellerItem = false;

          if (itemSellerId === sellerId) {
            isSellerItem = true;
          } else if (!itemSellerId && item.productId && productIds.includes(item.productId.toString())) {
            isSellerItem = true;
          }

          if (isSellerItem) {
            sales.push({
              orderId: order._id,
              customerName: order.userId?.name || 'Customer',
              productName: item.name,
              quantity: item.quantity,
              price: item.price,
              total: item.price * item.quantity,
              date: order.createdAt
            });
          }
        });
      });

      return res.json({ payouts, sales });
    }

    const OrderModel = getModel('Order', req);
    const SellerPaymentModel = getModel('SellerPayment', req);
    const ProductModel = getModel('Product', req);

    // Fetch all payouts for this seller
    const payouts = await SellerPaymentModel.find({ sellerId }).sort({ date: -1 });

    // Fetch all products belonging to this seller
    const sellerProducts = await ProductModel.find({ 
      $or: [
        { sellerId: sellerId },
        { seller: sellerId }
      ]
    }).select('_id');
    const productIds = sellerProducts.map(p => p._id.toString());

    // Fetch all delivered orders that contain items belonging to this seller
    const allOrders = await OrderModel.find({
      orderStatus: 'Delivered',
      'items': {
        $elemMatch: {
          $or: [
            { 'seller.sellerId': sellerId },
            { 'sellerId': sellerId },
            { 'productId': { $in: productIds } }
          ]
        }
      }
    })
    .populate('userId', 'name email phone')
    .sort({ createdAt: -1 });

    // Format sales items specifically for this seller
    const sales = [];
    allOrders.forEach(order => {
      order.items.forEach(item => {
        let itemSellerId = item.seller?.sellerId?.toString() || item.sellerId?.toString();
        let isSellerItem = false;

        if (itemSellerId === sellerId) {
          isSellerItem = true;
        } else if (!itemSellerId && item.productId && productIds.includes(item.productId.toString())) {
          isSellerItem = true;
        }

        if (isSellerItem) {
          sales.push({
            orderId: order._id,
            customerName: order.userId?.name || 'Customer',
            productName: item.name,
            quantity: item.quantity,
            price: item.price,
            total: item.price * item.quantity,
            date: order.createdAt
          });
        }
      });
    });

    res.json({
      payouts,
      sales
    });
  } catch (error) {
    console.error('Fetch seller history error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   POST /api/payments/clear
// @desc    Record a new payment payout to a seller (Admin)
router.post('/clear', protect, async (req, res) => {
  const { sellerId, amount, paymentMethod, transactionId, remarks } = req.body;

  if (!sellerId || !amount || !paymentMethod) {
    return res.status(400).json({ message: 'Seller ID, amount, and payment method are required' });
  }

  try {
    const SellerPaymentModel = getModel('SellerPayment', req);
    const SellerModel = getModel('Seller', req);

    // Verify seller exists
    const seller = await SellerModel.findById(sellerId);
    if (!seller) {
      return res.status(404).json({ message: 'Seller not found' });
    }

    const newPayout = new SellerPaymentModel({
      sellerId,
      amount: parseFloat(amount),
      paymentMethod,
      transactionId: transactionId || '',
      remarks: remarks || '',
      date: new Date()
    });

    const savedPayout = await newPayout.save();
    res.status(201).json(savedPayout);
  } catch (error) {
    console.error('Create payout error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

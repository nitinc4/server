const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Seller = require('../models/Seller');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Driver = require('../models/Driver');
const { protect } = require('../middleware/auth');
const tenantMiddleware = require('../middleware/tenant');

// @route   POST /api/sellers/login
// @desc    Seller Login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  console.log(`Login attempt for: ${email} (Sellers Collection)`);

  try {
    const SellerModel = req.getModel('Seller');
    console.log(`[DEBUG] Login: Searching for ${email} in database: ${SellerModel.db.name}`);

    // Search in the Sellers collection of the location database
    const user = await SellerModel.findOne({
      email: { $regex: new RegExp(`^${email}$`, 'i') }
    });

    if (!user) {
      console.log(`[DEBUG] Login failed: No seller found for ${email} in ${SellerModel.db.name}`);
      return res.status(401).json({ message: 'No seller account found with this email in this location' });
    }

    console.log(`[DEBUG] Login: Found user ${user.email}, verifying password...`);
    const isMatch = await user.comparePassword(password);
    if (isMatch) {
      const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
      console.log(`Login successful for: ${email}`);

      // Check if profile is complete (handle both b2b and seller field names)
      const businessName = user.businessName || user.storeName;
      const businessAddress = user.businessAddress || user.billingAddress;
      const isProfileComplete = !!(businessName && businessAddress && user.phone && user.storePic);

      res.json({
        token,
        _id: user._id,
        name: user.name,
        email: user.email,
        isProfileComplete,
        businessName: businessName,
        phone: user.phone,
        storePic: user.storePic
      });
    } else {
      console.log(`Login failed: Incorrect password for ${email}`);
      res.status(401).json({ message: 'Invalid password' });
    }
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/sellers/me
// @desc    Get current seller profile
router.get('/me', protect, (req, res) => {
  res.json(req.user);
});

// @route   PUT /api/sellers/profile
// @desc    Update seller profile
router.put('/profile', protect, async (req, res) => {
  try {
    const user = req.user;

    // Update fields (handle multiple naming conventions)
    user.name = req.body.name || user.name;
    user.phone = req.body.phone || user.phone;
    user.businessName = req.body.businessName || req.body.storeName || user.businessName;
    user.businessAddress = req.body.businessAddress || req.body.billingAddress || user.businessAddress;
    user.gstNumber = req.body.gstNumber || user.gstNumber;
    user.panNumber = req.body.panNumber || user.panNumber;

    // Support legacy field names in the database object itself if they exist
    if (user.storeName) user.storeName = req.body.storeName || req.body.businessName || user.storeName;
    if (user.billingAddress) user.billingAddress = req.body.billingAddress || req.body.businessAddress || user.billingAddress;

    // Legal Documents
    user.storePic = req.body.storePic || user.storePic;
    user.gstDoc = req.body.gstDoc || user.gstDoc;
    user.panDoc = req.body.panDoc || user.panDoc;
    user.tradeLicenseDoc = req.body.tradeLicenseDoc || user.tradeLicenseDoc;
    user.rmcAmpcDoc = req.body.rmcAmpcDoc || user.rmcAmpcDoc;

    // Pickup Location handling
    if (req.body.pickupLocation) {
      user.pickupLocation = req.body.pickupLocation;
    }

    // Mark profile as complete
    user.isProfileComplete = true;

    const updatedUser = await user.save();
    console.log(`Profile updated successfully for: ${user.email}`);
    res.json(updatedUser);
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      message: 'Failed to update profile',
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// @route   GET /api/sellers/products
// @desc    Get seller's products
router.get('/products', protect, async (req, res) => {
  try {
    const Product = req.getModel('Product');
    const products = await Product.find({
      $or: [
        { sellerId: req.user._id.toString() },
        { sellerId: req.user._id },
        { seller: req.user._id.toString() },
        { seller: req.user._id },
        { sellerId: { $exists: false } },
        { sellerId: null }
      ]
    }).populate('categoryId subCategoryId');
    res.json(products);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

function parsePacketSizeAndUnit(packetSizeStr, defaultUnit = 'pcs') {
  if (!packetSizeStr) {
    return { value: 1, unit: defaultUnit.toLowerCase() };
  }
  const str = packetSizeStr.trim().toLowerCase();
  const valMatch = str.match(/^[\d\.]+/);
  const unitMatch = str.match(/[a-zA-Z]+$/);

  const value = valMatch ? parseFloat(valMatch[0]) : 1;
  const unit = unitMatch ? unitMatch[0] : defaultUnit.toLowerCase();

  return { value, unit };
}

function calculateItemCommission(item, product, commissions, orderRole) {
  if (!product) return 0;

  const catId = product.categoryId ? product.categoryId.toString() : '';
  const commissionRule = commissions.find(c => c.categoryId && c.categoryId.toString() === catId);

  if (!commissionRule) return 0;

  const isB2b = orderRole === 'b2b';
  const variants = isB2b ? (product.b2b || []) : (product.b2c || []);
  const matchingVariant = variants.find(v => Number(v.price) === Number(item.price));
  const packetSize = matchingVariant ? matchingVariant.packetSize : product.unit;

  if (commissionRule.commissionType === 'percentage') {
    return item.price * (commissionRule.commissionValue / 100);
  } else {
    let multiplier = 1;
    const ruleUnit = commissionRule.unit.trim().toLowerCase();
    const { value: pVal, unit: pUnit } = parsePacketSizeAndUnit(packetSize, product.unit);

    if (ruleUnit === 'kg') {
      if (pUnit === 'kg') multiplier = pVal;
      else if (pUnit === 'g' || pUnit === 'gm') multiplier = pVal / 1000;
    } else if (ruleUnit === 'ltr' || ruleUnit === 'lit') {
      if (pUnit === 'ltr' || pUnit === 'lit') multiplier = pVal;
      else if (pUnit === 'ml') multiplier = pVal / 1000;
    } else if (ruleUnit === 'pc' || ruleUnit === 'pcs' || ruleUnit === 'piece') {
      const isPieceUnit = ['pc', 'pcs', 'piece', 'pieces', 'packet', 'pack', 'box', 'boxes'].includes(pUnit);
      if (isPieceUnit) multiplier = pVal;
      else multiplier = 1;
    }
    return commissionRule.commissionValue * multiplier;
  }
}

// @route   GET /api/sellers/orders
// @desc    Get seller's orders
router.get('/orders', protect, async (req, res) => {
  try {
    const sellerId = req.user._id;
    const Product = req.getModel('Product');
    const Order = req.getModel('Order');
    const UserModel = req.getModel('User');
    const DriverModel = req.getModel('Driver');
    const CommissionModel = req.getModel('Commission');

    // 1. Find all products belonging to this seller with full schema details for commissions
    const sellerProducts = await Product.find({
      $or: [
        { sellerId: sellerId.toString() },
        { sellerId: sellerId },
        { seller: sellerId.toString() },
        { seller: sellerId }
      ]
    }).select('_id categoryId unit b2b b2c');

    if (!sellerProducts || sellerProducts.length === 0) {
      return res.json([]);
    }

    const productIds = [
      ...sellerProducts.map(p => p._id),
      ...sellerProducts.map(p => p._id.toString())
    ];
    const productMap = new Map(sellerProducts.map(p => [p._id.toString(), p]));

    // Fetch all commissions
    const commissions = await CommissionModel.find({});

    // 2. Find orders that contain ANY of these product IDs
    // We check both productId and product._id for compatibility
    const orders = await Order.find({
      $or: [
        { 'items.productId': { $in: productIds } },
        { 'items.product._id': { $in: productIds } }
      ]
    })
      .populate({
        path: 'userId',
        model: UserModel,
        select: 'name email phone role',
        strictPopulate: false
      })
      .populate({
        path: 'deliveryBoyId',
        model: UserModel,
        select: 'name phone email',
        strictPopulate: false
      })
      .populate({
        path: 'driverId',
        model: DriverModel,
        select: 'name phone vehicleDetails',
        strictPopulate: false
      })
      .sort({ createdAt: -1 })
      .lean();

    // Map through the orders and enrich them
    const enrichedOrders = orders.map(order => {
      const orderRole = (order.userId && order.userId.role) ? order.userId.role : 'b2c';

      // Filter items to only include items belonging to this seller
      const sellerItems = (order.items || [])
        .filter(item => {
          const itemPid = item.productId || (item.product && item.product._id) || item._id;
          return itemPid && productIds.some(pid => pid.toString() === itemPid.toString());
        })
        .map(item => {
          const itemPid = item.productId || (item.product && item.product._id) || item._id;
          const product = productMap.get(itemPid.toString());

          let commission;
          let netPrice;
          if (item.normalPrice !== undefined && item.normalPrice !== null) {
            netPrice = item.normalPrice;
            commission = Math.max(0, item.price - item.normalPrice);
          } else {
            commission = calculateItemCommission(item, product, commissions, orderRole);
            netPrice = Math.max(0, item.price - commission);
          }
          const netTotal = netPrice * item.quantity;
          const totalCommission = commission * item.quantity;

          return {
            ...item,
            commission,
            totalCommission,
            netPrice,
            netTotal
          };
        });

      const sellerItemsSubtotal = sellerItems.reduce((acc, item) => acc + (item.price * item.quantity), 0);
      const sellerItemsCommission = sellerItems.reduce((acc, item) => acc + item.totalCommission, 0);
      const sellerItemsNetTotal = sellerItems.reduce((acc, item) => acc + item.netTotal, 0);

      return {
        ...order,
        items: sellerItems,
        sellerItemsSubtotal,
        sellerItemsCommission,
        sellerItemsNetTotal
      };
    });

    res.json(enrichedOrders);
  } catch (error) {
    console.error('Seller orders fetch error:', error);
    res.status(500).json({
      message: 'Failed to fetch seller orders',
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// @route   GET /api/sellers/pickups
// @desc    Get seller's pickups
router.get('/pickups', protect, async (req, res) => {
  try {
    const sellerId = req.user._id;
    const Product = req.getModel('Product');
    const Order = req.getModel('Order');
    const UserModel = req.getModel('User');
    const DriverModel = req.getModel('Driver');
    const CommissionModel = req.getModel('Commission');

    // 1. Find all products belonging to this seller
    const sellerProducts = await Product.find({
      $or: [
        { sellerId: sellerId.toString() },
        { sellerId: sellerId },
        { seller: sellerId.toString() },
        { seller: sellerId }
      ]
    }).select('_id categoryId unit b2b b2c');
    const productIds = [
      ...sellerProducts.map(p => p._id),
      ...sellerProducts.map(p => p._id.toString())
    ];
    const productMap = new Map(sellerProducts.map(p => [p._id.toString(), p]));

    // Fetch all commissions
    const commissions = await CommissionModel.find({});

    // 2. Find orders that are ready for pickup (Packed), already Picked Up, or Pending
    const orders = await Order.find({
      $and: [
        {
          $or: [
            { 'items.productId': { $in: productIds } },
            { 'items.product._id': { $in: productIds } }
          ]
        },
        { orderStatus: { $in: ['Pending', 'Packed', 'Picked Up', 'Shipped', 'Delivered'] } }
      ]
    })
      .populate({ path: 'userId', model: UserModel, select: 'name email phone role' })
      .populate({ path: 'deliveryBoyId', model: UserModel, select: 'name phone' })
      .populate({ path: 'driverId', model: DriverModel, select: 'name phone vehicleDetails' })
      .sort({ updatedAt: -1 });

    console.log(`[DEBUG] Found ${orders.length} orders for pickups`);

    // Format for frontend and generate code if missing
    const pickups = await Promise.all(orders.map(async (order) => {
      try {
        // Generate pickup code if missing (and ensure it's on the object even if save fails)
        let pickupCode = order.pickupCode;
        if (!pickupCode) {
          pickupCode = Math.floor(1000 + Math.random() * 9000).toString();
          order.pickupCode = pickupCode;
          try {
            await order.save();
          } catch (saveErr) {
            console.error('Failed to save pickup code:', saveErr);
          }
        }

        // Generate a consistent pickup ID from the order's internal ID
        const generatedId = order._id ? order._id.toString().slice(-6).toUpperCase() : 'UNKNOWN';

        // Extract driver info safely
        let driverInfo = null;
        if (order.driverId && typeof order.driverId === 'object' && order.driverId.name) {
          driverInfo = {
            _id: order.driverId._id,
            name: order.driverId.name,
            phone: order.driverId.phone,
            vehicleDetails: order.driverId.vehicleDetails
          };
        } else if (order.deliveryBoyId && typeof order.deliveryBoyId === 'object' && order.deliveryBoyId.name) {
          driverInfo = {
            _id: order.deliveryBoyId._id,
            name: order.deliveryBoyId.name,
            phone: order.deliveryBoyId.phone,
            vehicleDetails: order.deliveryBoyId.vehicleDetails || null
          };
        }

        const orderRole = (order.userId && order.userId.role) ? order.userId.role : 'b2c';

        // Filter and enrich items belonging to this seller
        const sellerItems = (order.items || [])
          .filter(item => {
            const itemPid = item.productId || (item.product && item.product._id) || item._id;
            return itemPid && productIds.some(pid => pid.toString() === itemPid.toString());
          })
          .map(item => {
            const itemPid = item.productId || (item.product && item.product._id) || item._id;
            const product = productMap.get(itemPid.toString());

            let commission;
            let netPrice;
            const itemObj = item.toObject ? item.toObject() : item;
            if (itemObj.normalPrice !== undefined && itemObj.normalPrice !== null) {
              netPrice = itemObj.normalPrice;
              commission = Math.max(0, itemObj.price - itemObj.normalPrice);
            } else {
              commission = calculateItemCommission(item, product, commissions, orderRole);
              netPrice = Math.max(0, item.price - commission);
            }
            const netTotal = netPrice * item.quantity;
            const totalCommission = commission * item.quantity;
            return {
              ...itemObj,
              commission,
              totalCommission,
              netPrice,
              netTotal
            };
          });

        const sellerItemsNetTotal = sellerItems.reduce((acc, item) => acc + item.netTotal, 0);

        return {
          _id: order._id,
          pickupId: order.orderId || generatedId,
          status: order.orderStatus || 'Pending',
          scheduledDate: order.updatedAt || order.createdAt,
          timeSlot: 'Standard',
          address: order.shippingAddress?.address ? `${order.shippingAddress.address}, ${order.shippingAddress.city || ''}` : 'No address provided',
          itemCount: sellerItems.length,
          items: sellerItems,
          driver: driverInfo,
          customer: order.userId || null,
          pickupCode: pickupCode,
          totalAmount: order.totalAmountWithoutCommissions !== undefined ? order.totalAmountWithoutCommissions : sellerItemsNetTotal
        };
      } catch (err) {
        console.error(`Error processing order ${order._id}:`, err);
        return null;
      }
    }));

    res.json(pickups.filter(p => p !== null));
  } catch (error) {
    console.error('Pickups fetch error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/sellers/returns
// @desc    Get return orders for the seller
router.get('/returns', protect, async (req, res) => {
  try {
    const sellerId = req.user._id;
    const Product = req.getModel('Product');
    const Order = req.getModel('Order');
    const UserModel = req.getModel('User');
    const CommissionModel = req.getModel('Commission');

    // 1. Find all products belonging to this seller
    const sellerProducts = await Product.find({
      $or: [
        { sellerId: sellerId.toString() },
        { sellerId: sellerId },
        { seller: sellerId.toString() },
        { seller: sellerId }
      ]
    }).select('_id categoryId unit b2b b2c');

    const productIds = [
      ...sellerProducts.map(p => p._id),
      ...sellerProducts.map(p => p._id.toString())
    ];
    const productMap = new Map(sellerProducts.map(p => [p._id.toString(), p]));

    // Fetch all commissions
    const commissions = await CommissionModel.find({});

    // 2. Find orders that contain these products AND have return info or status
    const orders = await Order.find({
      $and: [
        {
          $or: [
            { 'items.productId': { $in: productIds } },
            { 'items.product._id': { $in: productIds } }
          ]
        },
        {
          $or: [
            { orderStatus: 'Returned' },
            { returnReason: { $ne: null, $exists: true } }
          ]
        }
      ]
    })
      .populate({ path: 'userId', model: UserModel, select: 'name email phone role' })
      .sort({ updatedAt: -1 })
      .lean();

    const enrichedOrders = orders.map(order => {
      const orderRole = (order.userId && order.userId.role) ? order.userId.role : 'b2c';

      const sellerItems = (order.items || [])
        .filter(item => {
          const itemPid = item.productId || (item.product && item.product._id) || item._id;
          return itemPid && productIds.some(pid => pid.toString() === itemPid.toString());
        })
        .map(item => {
          const itemPid = item.productId || (item.product && item.product._id) || item._id;
          const product = productMap.get(itemPid.toString());

          let commission;
          let netPrice;
          if (item.normalPrice !== undefined && item.normalPrice !== null) {
            netPrice = item.normalPrice;
            commission = Math.max(0, item.price - item.normalPrice);
          } else {
            commission = calculateItemCommission(item, product, commissions, orderRole);
            netPrice = Math.max(0, item.price - commission);
          }
          const netTotal = netPrice * item.quantity;
          const totalCommission = commission * item.quantity;
          return {
            ...item,
            commission,
            totalCommission,
            netPrice,
            netTotal
          };
        });

      const sellerItemsSubtotal = sellerItems.reduce((acc, item) => acc + (item.price * item.quantity), 0);
      const sellerItemsCommission = sellerItems.reduce((acc, item) => acc + item.totalCommission, 0);
      const sellerItemsNetTotal = sellerItems.reduce((acc, item) => acc + item.netTotal, 0);

      return {
        ...order,
        items: sellerItems,
        sellerItemsSubtotal,
        sellerItemsCommission,
        sellerItemsNetTotal
      };
    });

    res.json(enrichedOrders);
  } catch (error) {
    console.error('Returns fetch error:', error);
    res.status(500).json({ message: error.message });
  }
});

router.get('/stats', protect, async (req, res) => {
  try {
    const sellerId = req.user._id;
    const Product = req.getModel('Product');
    const Order = req.getModel('Order');
    const UserModel = req.getModel('User');
    const CommissionModel = req.getModel('Commission');

    // Total Products
    const totalProducts = await Product.countDocuments({
      $or: [
        { sellerId: sellerId.toString() },
        { sellerId: sellerId },
        { seller: sellerId.toString() },
        { seller: sellerId }
      ]
    });

    // Seller Products IDs with category, unit, variants
    const sellerProducts = await Product.find({
      $or: [
        { sellerId: sellerId.toString() },
        { sellerId: sellerId },
        { seller: sellerId.toString() },
        { seller: sellerId }
      ]
    }).select('_id categoryId unit b2b b2c');

    const productIds = [
      ...sellerProducts.map(p => p._id),
      ...sellerProducts.map(p => p._id.toString())
    ];
    const productMap = new Map(sellerProducts.map(p => [p._id.toString(), p]));

    // Fetch all commissions
    const commissions = await CommissionModel.find({});

    // Orders stats (populate userId to verify role)
    const orders = await Order.find({
      'items.productId': { $in: productIds }
    }).populate({ path: 'userId', model: UserModel, select: 'role' }).lean();

    const activeOrders = orders.filter(o => ['Pending', 'Processing', 'Shipped'].includes(o.orderStatus)).length;

    // Today's Orders
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayOrders = orders.filter(o => new Date(o.createdAt) >= today).length;

    let outstandingPayments = 0;
    const totalSales = orders
      .filter(o => o.orderStatus !== 'Cancelled')
      .reduce((acc, curr) => {
        // Only sum items belonging to THIS seller
        const sellerItems = (curr.items || []).filter(item =>
          item.productId && productIds.some(pid => pid.toString() === item.productId.toString())
        );

        const orderRole = (curr.userId && curr.userId.role) ? curr.userId.role : 'b2c';

        const sellerTotal = sellerItems.reduce((s, i) => {
          const product = productMap.get(i.productId.toString());
          let netPrice;
          if (i.normalPrice !== undefined && i.normalPrice !== null) {
            netPrice = i.normalPrice;
          } else {
            const commission = calculateItemCommission(i, product, commissions, orderRole);
            netPrice = Math.max(0, i.price - commission);
          }
          return s + (netPrice * i.quantity);
        }, 0);

        if (curr.paymentStatus === 'Pending') {
          outstandingPayments += sellerTotal;
        }

        return acc + sellerTotal;
      }, 0);

    // Low Stock Products (Less than 10)
    const lowStockProducts = await Product.find({
      $or: [
        { sellerId: sellerId.toString() },
        { sellerId: sellerId },
        { seller: sellerId.toString() },
        { seller: sellerId }
      ],
      stock: { $lt: 10 }
    }).select('name stock imageUrl price');

    res.json({
      totalProducts,
      activeOrders,
      totalSales,
      totalOrders: orders.length,
      todayOrders,
      outstandingPayments,
      lowStockCount: lowStockProducts.length,
      lowStockProducts
    });
  } catch (error) {
    console.error('Seller stats error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

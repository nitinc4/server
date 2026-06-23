const { connectDBByLocation } = require('../utils/db_manager');
const Admin = require('../models/Admin');
const Category = require('../models/Category');
const SubCategory = require('../models/SubCategory');
const Product = require('../models/Product');
const Order = require('../models/Order');
const User = require('../models/User');
const Driver = require('../models/Driver');
const Seller = require('../models/Seller');
const Location = require('../models/Location');

const multiTenant = async (req, res, next) => {
  // 1. Skip if no admin is logged in (handled by protect middleware)
  if (!req.admin) {
    return next();
  }

  // 2. Skip for Global Super Admins who haven't switched context
  const effectiveLocationId = req.isGlobalAccess ? null : (req.locationId || req.admin.locationId);
  if (req.admin.role === 'super_admin' && !effectiveLocationId) {
    req.isTenant = false;
    return next();
  }

  // 3. Handle Location-based context
  const locationId = effectiveLocationId;

  if (locationId) {
    try {
      // Connect to tenant DB using the dbName preserved in the request
      const connection = await connectDBByLocation(locationId, req.dbName || req.admin.dbName);

      req.isTenant = true;
      req.tenantId = locationId;

      const models = {
        User: connection.models.User || connection.model('User', require('../models/User').schema),
        Product: connection.models.Product || connection.model('Product', require('../models/Product').schema),
        Order: connection.models.Order || connection.model('Order', require('../models/Order').schema),
        Category: connection.models.Category || connection.model('Category', require('../models/Category').schema),
        SubCategory: connection.models.SubCategory || connection.model('SubCategory', require('../models/SubCategory').schema),
        Location: connection.models.Location || connection.model('Location', require('../models/Location').schema),
        Driver: connection.models.Driver || connection.model('Driver', require('../models/Driver').schema),
        Review: connection.models.Review || connection.model('Review', require('../models/Review').schema),
        Deposit: connection.models.Deposit || connection.model('Deposit', require('../models/Deposit').schema),
        Seller: connection.models.Seller || connection.model('Seller', require('../models/Seller').schema),
        SellerPayment: connection.models.SellerPayment || connection.model('SellerPayment', require('../models/SellerPayment').schema),
        Admin: connection.models.Admin || connection.model('Admin', require('../models/Admin').schema),
        CashCollector: connection.models.CashCollector || connection.model('CashCollector', require('../models/CashCollector').schema),
        DeliverySlot: connection.models.DeliverySlot || connection.model('DeliverySlot', require('../models/DeliverySlot').schema),
        Notification: connection.models.Notification || connection.model('Notification', require('../models/Notification').schema),
        PopupAd: connection.models.PopupAd || connection.model('PopupAd', require('../models/PopupAd').schema),
        Banner: connection.models.Banner || connection.model('Banner', require('../models/Banner').schema),
        Feed: connection.models.Feed || connection.model('Feed', require('../models/Feed').schema),
        Attendance: connection.models.Attendance || connection.model('Attendance', require('../models/Attendance').schema),
        Commission: connection.models.Commission || connection.model('Commission', require('../models/Commission').schema),
      };

      req.db = connection;
      req.models = models;
      req.tenantModels = models;
      req.dbName = connection.name;

      console.log(`[Multi-Tenant] Switched to database for location: ${locationId}`);
      next();
    } catch (error) {
      console.error('[Multi-Tenant] Middleware Error:', error);
      res.status(500).json({ message: 'Error connecting to branch database' });
    }
  } else {
    next();
  }
};

module.exports = multiTenant;

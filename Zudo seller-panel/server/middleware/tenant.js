const { getTenantConnection } = require('../utils/tenant');
const Seller = require('../models/Seller');
const User = require('../models/User');
const Admin = require('../models/Admin');
const Product = require('../models/Product');
const Order = require('../models/Order');
const Driver = require('../models/Driver');
const Category = require('../models/Category');
const SubCategory = require('../models/SubCategory');
const Review = require('../models/Review');
const CashCollector = require('../models/CashCollector');
const Feed = require('../models/Feed');
const Commission = require('../models/Commission');

// Store schemas to avoid re-compiling models unnecessarily
const schemas = {
  Seller: Seller.schema,
  User: User.schema,
  Admin: Admin.schema,
  Product: Product.schema,
  Order: Order.schema,
  Driver: Driver.schema,
  Category: Category.schema,
  SubCategory: SubCategory.schema,
  Review: Review.schema,
  CashCollector: CashCollector.schema,
  Feed: Feed.schema,
  Commission: Commission.schema
};

const tenantMiddleware = (req, res, next) => {
  const location = (req.body && req.body.location) || 
                   (req.query && req.query.location) ||
                   req.headers['x-location'];
  
  if (location) {
    const source = (req.body && req.body.location) ? 'body' : 
                   (req.query && req.query.location) ? 'query' : 'header';
    console.log(`[DEBUG] Tenant: Identified location "${location}" from ${source}`);
  }

  // Helper to get model for the current tenant
  req.getModel = (modelName) => {
    if (!location) {
      console.log(`[DEBUG] Tenant: No location, returning default model for ${modelName}`);
      return require(`../models/${modelName}`);
    }
    
    const conn = getTenantConnection(location);
    if (conn.models[modelName]) return conn.models[modelName];
    
    console.log(`[DEBUG] Tenant: Registering model ${modelName} on connection ${conn.name}`);
    return conn.model(modelName, schemas[modelName]);
  };

  next();
};

module.exports = tenantMiddleware;

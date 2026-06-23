/**
 * Helper to get the correct model (Tenant or Global)
 * @param {string} modelName - The name of the model (e.g., 'Category')
 * @param {Object} req - The request object containing tenantModels
 * @returns {mongoose.Model}
 */
const getModel = (modelName, req) => {
  if (req && req.tenantModels && req.tenantModels[modelName]) {
    return req.tenantModels[modelName];
  }
  
  // Fallback to global model
  return require(`../models/${modelName}`);
};

module.exports = { getModel };

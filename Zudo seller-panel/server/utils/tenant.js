const mongoose = require('mongoose');

// Cache for tenant connections
const connections = {};

// Cache for allowed databases
let ALLOWED_DATABASES = new Set(['zudodb', 'zudo-central', 'zudo-coimbatore', 'zudo-bengaluru', 'zudo-kozhikode']);
const refreshAllowedDatabases = async () => {
  try {
    // Wait for the main connection to be ready if it's not
    if (mongoose.connection.readyState !== 1) {
      console.log('[INFO] Waiting for MongoDB connection before refreshing allowed databases...');
      return; 
    }

    const centralDb = mongoose.connection.useDb('zudo-central', { useCache: true });
    const locations = await centralDb.collection('locations').find({}).toArray();
    
    if (!locations || locations.length === 0) {
      console.warn('[WARN] Seller-Panel: No locations found in zudo-central.');
    }

    const dbNames = locations.map(loc => loc.dbName?.trim().toLowerCase()).filter(Boolean);
    const permanentDbs = ['zudodb', 'zudo-central', 'zudo-coimbatore', 'zudo-bengaluru', 'zudo-kozhikode'];
    ALLOWED_DATABASES = new Set([...permanentDbs, ...dbNames]);
    console.log('[INFO] Seller-Panel: Allowed Databases refreshed (Permanent + Dynamic):', Array.from(ALLOWED_DATABASES));
  } catch (err) {
    console.error('[WARN] Seller-Panel: Failed to refresh allowed databases:', err.message);
  }
};

// Refresh every 5 mins
setInterval(refreshAllowedDatabases, 5 * 60 * 1000);

/**
 * Get a connection for a specific tenant (location)
 * @param {string} location - The location name (e.g., 'bengaluru' or 'zudo-bengaluru')
 */
const getTenantConnection = (location) => {
  if (!location) {
    console.log('[DEBUG] No location provided, using default connection');
    return mongoose.connection;
  }

  let sanitizedLocation = location.trim().toLowerCase();
  
  // Normalize dbName: Ensure single zudo- prefix
  while (sanitizedLocation.startsWith('zudo-zudo-')) {
    sanitizedLocation = sanitizedLocation.replace('zudo-zudo-', 'zudo-');
  }
  
  let dbName = sanitizedLocation.startsWith('zudo-') ? sanitizedLocation : `zudo-${sanitizedLocation}`;
  
  // Hard fallback for default database
  if (sanitizedLocation === 'zudodb') dbName = 'zudodb';

  // VALIDATION: Only allow connections to existing whitelisted databases
  if (!ALLOWED_DATABASES.has(dbName)) {
    const alternative = Array.from(ALLOWED_DATABASES).find(d => 
      d === sanitizedLocation || 
      d === `zudo-${sanitizedLocation}` ||
      `zudo-${d}` === sanitizedLocation
    );
    
    if (alternative) {
      dbName = alternative;
    } else {
      // If we only have defaults, maybe the cache hasn't loaded. 
      // In a real multi-tenant app, we might want to block until loaded, 
      // but for now let's just log a very detailed warning.
      console.warn(`[WARN] Unauthorized DB: "${dbName}" (Input: "${location}"). Whitelist:`, Array.from(ALLOWED_DATABASES));
      
      // If the cache is empty (only defaults), we might want to return default DB
      // but if the user specifically asked for a location, they expect that data.
      return mongoose.connection.useDb('zudodb', { useCache: true });
    }
  }
  
  console.log(`[DEBUG] Switching to Database: ${dbName} for location: ${location}`);

  if (connections[dbName]) {
    return connections[dbName];
  }

  // Create a new connection using the same URI but different DB name
  const conn = mongoose.connection.useDb(dbName, { useCache: true });
  connections[dbName] = conn;
  return conn;
};

/**
 * Get a model for a specific tenant
 * @param {string} location - The location name
 * @param {string} modelName - The name of the model
 * @param {mongoose.Schema} schema - The schema for the model
 */
const getTenantModel = (location, modelName, schema) => {
  const conn = getTenantConnection(location);
  return conn.model(modelName, schema);
};

module.exports = {
  getTenantConnection,
  getTenantModel,
  refreshAllowedDatabases
};

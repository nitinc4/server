const mongoose = require('mongoose');

const getCentralConn = async () => {
  const URI = process.env.MONGODB_URI;
  const CENTRAL_DB_NAME = 'zudo-central';
  const lastSlashIndex = URI.lastIndexOf('/');
  const lastQuestionIndex = URI.indexOf('?', lastSlashIndex);
  const CENTRAL_URI = URI.substring(0, lastSlashIndex + 1) + CENTRAL_DB_NAME + (lastQuestionIndex !== -1 ? URI.substring(lastQuestionIndex) : '');
  
  return mongoose.createConnection(CENTRAL_URI);
};

const MappingSchema = new mongoose.Schema({
  pincode: { type: String, required: true, unique: true },
  dbName: { type: String, required: true },
  city: { type: String, required: true }
});

const syncToCentral = async (city, dbName, pincodes) => {
  let conn;
  try {
    const rawConn = await getCentralConn();
    conn = await rawConn.asPromise();
    const Mapping = conn.model('PincodeMapping', MappingSchema);

    // pincodes can be a comma separated string or array
    const pcList = Array.isArray(pincodes) 
      ? pincodes 
      : pincodes.split(',').map(p => p.trim());

    for (const pc of pcList) {
      if (!pc) continue;
      // Upsert mapping
      await Mapping.findOneAndUpdate(
        { pincode: pc },
        { dbName, city },
        { upsert: true, new: true }
      );
    }
    console.log(`Synced ${pcList.length} pincodes to central mapping for ${city}`);
  } catch (error) {
    console.error('Central Sync Error:', error);
    throw error;
  } finally {
    if (conn) await conn.close();
  }
};

const removeFromCentral = async (pincodes) => {
  let conn;
  try {
    const rawConn = await getCentralConn();
    conn = await rawConn.asPromise();
    const Mapping = conn.model('PincodeMapping', MappingSchema);
    
    const pcList = Array.isArray(pincodes) 
      ? pincodes 
      : pincodes.split(',').map(p => p.trim());

    await Mapping.deleteMany({ pincode: { $in: pcList } });
  } catch (error) {
    console.error('Central Removal Error:', error);
  } finally {
    if (conn) await conn.close();
  }
};

module.exports = { syncToCentral, removeFromCentral };

require('dotenv').config();
const { MongoClient } = require('mongodb');

const MONGODB_URI = process.env.MONGODB_URI;
if (!MONGODB_URI) {
  console.error("MONGODB_URI is not set in .env file.");
  process.exit(1);
}

const OLD_URL = 'https://zudo.co.in/storage/';
const NEW_URL = 'https://snbtradingco.in/uploads/';

function recursivelyReplace(obj) {
  let isModified = false;
  
  if (obj === null || obj === undefined) return { modified: false };

  if (typeof obj === 'string') {
    if (obj.includes(OLD_URL)) {
      return { 
        modified: true, 
        value: obj.split(OLD_URL).join(NEW_URL) 
      };
    }
    return { modified: false };
  }

  if (Array.isArray(obj)) {
    for (let i = 0; i < obj.length; i++) {
      const res = recursivelyReplace(obj[i]);
      if (res.modified) {
        obj[i] = res.value !== undefined ? res.value : obj[i];
        isModified = true;
      }
    }
  } else if (typeof obj === 'object') {
    // Exclude MongoDB ObjectIDs, Dates, etc.
    if (obj._bsontype || obj instanceof Date) {
      return { modified: false };
    }
    
    for (const key of Object.keys(obj)) {
      const res = recursivelyReplace(obj[key]);
      if (res.modified) {
        obj[key] = res.value !== undefined ? res.value : obj[key];
        isModified = true;
      }
    }
  }

  return { modified: isModified };
}

async function run() {
  const client = new MongoClient(MONGODB_URI);
  try {
    console.log("Connecting to MongoDB...");
    await client.connect();
    console.log("Connected successfully.");
    const db = client.db();

    const collections = await db.listCollections().toArray();
    
    const collectionsToScan = collections
      .map(c => c.name)
      .filter(name => !name.startsWith('system.') && !name.includes('_backup_'));
      
    console.log(`\nScanning ${collectionsToScan.length} collections for URLs containing "${OLD_URL}"...\n`);

    const summary = [];

    for (const colName of collectionsToScan) {
      const collection = db.collection(colName);
      
      // We will iterate over all documents since we want to check all nested fields
      const cursor = collection.find({});
      
      const bulkOps = [];
      let matchCount = 0;
      
      while (await cursor.hasNext()) {
        const doc = await cursor.next();
        
        // Fast check before doing recursive deep replacement
        if (!JSON.stringify(doc).includes(OLD_URL)) {
          continue;
        }

        const res = recursivelyReplace(doc);
        if (res.modified) {
          matchCount++;
          bulkOps.push({
            replaceOne: {
              filter: { _id: doc._id },
              replacement: doc
            }
          });
        }
      }

      if (matchCount > 0) {
        console.log(`[${colName}] Found ${matchCount} documents to update.`);
        
        // Create backup of the collection
        const backupColName = `${colName}_backup_url_migration_${Date.now()}`;
        console.log(`[${colName}] Creating backup to collection: ${backupColName}...`);
        await collection.aggregate([{ $match: {} }, { $out: backupColName }]).toArray();
        console.log(`[${colName}] Backup completed.`);

        // Execute updates
        console.log(`[${colName}] Updating documents...`);
        const result = await collection.bulkWrite(bulkOps);
        console.log(`[${colName}] Successfully modified ${result.modifiedCount} documents.\n`);
        
        summary.push({
          collection: colName,
          matched: matchCount,
          modified: result.modifiedCount
        });
      }
    }
    
    console.log("\n=============================");
    console.log("     MIGRATION SUMMARY       ");
    console.log("=============================\n");
    if (summary.length === 0) {
      console.log("No documents found containing the old URL.");
    } else {
      console.table(summary);
    }
    
  } catch (err) {
    console.error("Migration failed:", err);
  } finally {
    await client.close();
  }
}

run();

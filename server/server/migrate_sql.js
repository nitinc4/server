const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const Product = require('./models/Product');
const Category = require('./models/Category');
const SubCategory = require('./models/SubCategory');

// Standard values as requested
const STANDARD_B2C_PRICE = 100;
const STANDARD_B2B_PRICE = 80;
const STANDARD_MOQ = 10;
const STANDARD_UNIT = '1kg';
const BASE_IMAGE_URL = 'https://zudo.co.in/storage/';
const IMAGE_SUFFIX = '';

async function migrate() {
  try {
    const sqlPath = path.join(__dirname, '..', 'u892881718_zudo.sql');
    if (!fs.existsSync(sqlPath)) {
      console.error('SQL file not found at:', sqlPath);
      process.exit(1);
    }

    const sqlContent = fs.readFileSync(sqlPath, 'utf8');
    console.log('SQL file read successfully');

    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing data
    await Product.deleteMany({});
    await Category.deleteMany({});
    await SubCategory.deleteMany({});
    console.log('Existing data cleared');

    // Helper to parse SQL INSERT values
    // This is a basic parser that handles simple INSERT INTO statements
    function parseInsert(sql, tableName) {
      const chunks = sql.split(new RegExp(`INSERT INTO \`${tableName}\``, 'g'));
      console.log(`Table ${tableName}: Found ${chunks.length - 1} INSERT INTO chunks`);
      const allValues = [];

      for (let i = 1; i < chunks.length; i++) {
        const chunk = chunks[i];
        const valuesIndex = chunk.indexOf('VALUES');
        if (valuesIndex === -1) continue;

        let valuesStr = chunk.substring(valuesIndex + 6).trim();
        let actualValuesStr = '';
        let inString = false;
        for (let j = 0; j < valuesStr.length; j++) {
          const char = valuesStr[j];
          if (char === "'" && (j === 0 || valuesStr[j-1] !== '\\')) {
            inString = !inString;
          }
          if (!inString && char === ';') {
            actualValuesStr = valuesStr.substring(0, j);
            break;
          }
        }
        if (!actualValuesStr) actualValuesStr = valuesStr;

        const rows = [];
        let currentRow = '';
        let inRowString = false;
        let parenLevel = 0;

        for (let k = 0; k < actualValuesStr.length; k++) {
          const char = actualValuesStr[k];
          if (char === "'" && (k === 0 || actualValuesStr[k-1] !== '\\')) {
            inRowString = !inRowString;
          }
          if (!inRowString) {
            if (char === '(') parenLevel++;
            if (char === ')') parenLevel--;
          }
          
          currentRow += char;

          if (!inRowString && parenLevel === 0 && currentRow.trim().length > 0) {
            if (char === ')' || k === actualValuesStr.length - 1) {
              let row = currentRow.trim();
              if (row.startsWith(',')) row = row.substring(1).trim();
              if (row.startsWith('(') && row.endsWith(')')) {
                row = row.substring(1, row.length - 1);
                rows.push(row);
              }
              currentRow = '';
            }
          }
        }

        for (const row of rows) {
          const vals = [];
          let currentVal = '';
          let inStr = false;
          for (let m = 0; m < row.length; m++) {
            const char = row[m];
            if (char === "'" && (m === 0 || row[m-1] !== '\\')) {
              inStr = !inStr;
            }
            if (!inStr && char === ',') {
              vals.push(parseVal(currentVal.trim()));
              currentVal = '';
            } else {
              currentVal += char;
            }
          }
          vals.push(parseVal(currentVal.trim()));
          allValues.push(vals);
        }
      }
      return allValues;
    }

    function parseVal(val) {
      if (val === 'NULL' || val === 'null' || val === 'NULL' || val === 'null') return null;
      if (val.startsWith("'") && val.endsWith("'")) {
        return val.substring(1, val.length - 1).replace(/\\'/g, "'").replace(/\\r\\n/g, '\n').replace(/\\n/g, '\n');
      }
      if (!isNaN(val) && val.trim() !== '') return Number(val);
      return val;
    }

    // 1. Parse Categories
    console.log('Parsing Categories...');
    const rawCategories = parseInsert(sqlContent, 'categories');
    console.log(`Found ${rawCategories.length} raw category rows`);
    
    const sqlCatMap = new Map();
    for (const vals of rawCategories) {
      const [id, row_order, name, slug, subtitle, image, status, product_rating, web_image, parent_id] = vals;
      sqlCatMap.set(id, { id, name, image, parent_id, vals });
    }

    // Process main categories
    const mongoCatMap = new Map(); // SQL ID -> MongoDB _id
    for (const cat of sqlCatMap.values()) {
      if (cat.parent_id === 0) {
        const category = await Category.create({
          name: cat.name,
          imageUrl: cat.image ? (cat.image.startsWith('http') ? cat.image : BASE_IMAGE_URL + cat.image + IMAGE_SUFFIX) : (BASE_IMAGE_URL + 'categories/default.png' + IMAGE_SUFFIX)
        });
        mongoCatMap.set(cat.id, category._id);
        console.log(`Created Category: ${cat.name} (ID: ${cat.id})`);
      }
    }

    // Process sub-categories
    const mongoSubCatMap = new Map(); // SQL ID -> MongoDB _id
    for (const cat of sqlCatMap.values()) {
      if (cat.parent_id !== 0) {
        // Find parent - it might be nested, so we check both main and sub maps
        let parentMongoId = mongoCatMap.get(cat.parent_id);
        
        // If not found in main categories, it might be a nested subcategory.
        // For our MongoDB model (which only supports 2 levels), we'll link it to the root category.
        if (!parentMongoId) {
            let current = sqlCatMap.get(cat.parent_id);
            while (current && current.parent_id !== 0) {
                current = sqlCatMap.get(current.parent_id);
            }
            if (current) {
                parentMongoId = mongoCatMap.get(current.id);
            }
        }

        if (parentMongoId) {
          const subCategory = await SubCategory.create({
            name: cat.name,
            imageUrl: cat.image ? (cat.image.startsWith('http') ? cat.image : BASE_IMAGE_URL + cat.image + IMAGE_SUFFIX) : (BASE_IMAGE_URL + 'subcategories/default.png' + IMAGE_SUFFIX),
            categoryId: parentMongoId
          });
          mongoSubCatMap.set(cat.id, subCategory._id);
          console.log(`Created SubCategory: ${cat.name} (ID: ${cat.id}) under parent ID ${cat.parent_id}`);
        } else {
          console.warn(`Parent category ${cat.parent_id} not found for subcategory ${cat.name}`);
        }
      }
    }

    // 2. Parse Products
    console.log('Parsing Products...');
    const rawProducts = parseInsert(sqlContent, 'products');
    console.log(`Found ${rawProducts.length} raw product entries`);
    
    let productCount = 0;
    for (const vals of rawProducts) {
      if (vals.length < 16) {
        console.warn('Skipping row with insufficient columns:', vals.length);
        continue;
      }
      const [id, seller_id, row_order, name, tags, tax_id, brand_id, slug, category_id, indicator, manufacturer, made_in, return_status, cancelable_status, till_status, image] = vals;
      
      let finalCategoryId = null;
      let finalSubCategoryId = null;

      // Check if category_id is a subcategory
      if (mongoSubCatMap.has(category_id)) {
        finalSubCategoryId = mongoSubCatMap.get(category_id);
        const sqlSubCat = sqlCatMap.get(category_id);
        finalCategoryId = mongoCatMap.get(sqlSubCat.parent_id);
      } else if (mongoCatMap.has(category_id)) {
        finalCategoryId = mongoCatMap.get(category_id);
      }

      if (!finalCategoryId) {
        // console.warn(`Skipping product ${name}: Category ${category_id} not found`);
        continue;
      }

      await Product.create({
        name: name,
        categoryId: finalCategoryId,
        subCategoryId: finalSubCategoryId,
        price: STANDARD_B2C_PRICE,
        b2bPrice: STANDARD_B2B_PRICE,
        moq: STANDARD_MOQ,
        unit: STANDARD_UNIT,
        imageUrl: image ? (image.startsWith('http') ? image : BASE_IMAGE_URL + image + IMAGE_SUFFIX) : (BASE_IMAGE_URL + 'products/default.png' + IMAGE_SUFFIX),
        rating: 0
      });
      productCount++;
    }

    console.log(`Successfully migrated ${productCount} products`);
    console.log('Migration completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrate();

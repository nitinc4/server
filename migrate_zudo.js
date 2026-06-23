const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const Product = require('./models/Product');
const Category = require('./models/Category');
const SubCategory = require('./models/SubCategory');

const JSON_FILES = [
  'C:\\Users\\nitin\\OneDrive\\Desktop\\projects\\Work\\sadhana_cart-main\\products_1777445761180.json',
  'C:\\Users\\nitin\\OneDrive\\Desktop\\projects\\Work\\sadhana_cart-main\\products_1777446028658.json'
];

async function migrate() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing data (optional, already done manually but good for script completeness)
    await Product.deleteMany({});
    await Category.deleteMany({});
    await SubCategory.deleteMany({});
    console.log('Existing data cleared');

    let allProducts = [];
    for (const file of JSON_FILES) {
      if (fs.existsSync(file)) {
        const data = JSON.parse(fs.readFileSync(file, 'utf8'));
        allProducts = allProducts.concat(data);
      }
    }

    console.log(`Found ${allProducts.length} products to migrate`);

    const categoryMap = new Map();
    const subCategoryMap = new Map();

    // First pass: Create Categories and SubCategories
    for (const p of allProducts) {
      const catName = p.category || 'Uncategorized';
      const subCatName = p.subcategory || '';

      if (!categoryMap.has(catName)) {
        let category = await Category.findOne({ name: catName });
        if (!category) {
          category = await Category.create({
            name: catName,
            imageUrl: p.images && p.images[0] ? p.images[0] : 'https://zudo.co.in/storage/app/public/categories/default.png'
          });
          console.log(`Created Category: ${catName}`);
        }
        categoryMap.set(catName, category._id);
      }

      if (subCatName && !subCategoryMap.has(`${catName}:${subCatName}`)) {
        const categoryId = categoryMap.get(catName);
        let subCategory = await SubCategory.findOne({ name: subCatName, categoryId });
        if (!subCategory) {
          subCategory = await SubCategory.create({
            name: subCatName,
            categoryId,
            imageUrl: p.images && p.images[0] ? p.images[0] : 'https://zudo.co.in/storage/app/public/subcategories/default.png'
          });
          console.log(`Created SubCategory: ${subCatName} under ${catName}`);
        }
        subCategoryMap.set(`${catName}:${subCatName}`, subCategory._id);
      }
    }

    // Second pass: Create Products
    let count = 0;
    for (const p of allProducts) {
      const categoryId = categoryMap.get(p.category || 'Uncategorized');
      const subCategoryId = subCategoryMap.get(`${p.category || 'Uncategorized'}:${p.subcategory || ''}`);

      await Product.create({
        name: p.name,
        categoryId,
        subCategoryId,
        price: p.price || 0,
        b2bPrice: p.offerprice || p.price || 0,
        moq: p.moq || 1,
        unit: 'piece', // Default unit
        imageUrl: p.images && p.images[0] ? p.images[0] : 'https://zudo.co.in/storage/app/public/products/default.png',
        rating: p.rating || 0
      });
      count++;
    }

    console.log(`Successfully migrated ${count} products`);
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

migrate();

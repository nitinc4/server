const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const Product = require('./models/Product');
const Category = require('./models/Category');
const SubCategory = require('./models/SubCategory');

async function verify() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const catCount = await Category.countDocuments();
    const subCatCount = await SubCategory.countDocuments();
    const prodCount = await Product.countDocuments();

    console.log(`Categories: ${catCount}`);
    console.log(`SubCategories: ${subCatCount}`);
    console.log(`Products: ${prodCount}`);

    const sampleProduct = await Product.findOne().populate('categoryId').populate('subCategoryId');
    if (sampleProduct) {
      console.log('Sample Product:');
      console.log(`  Name: ${sampleProduct.name}`);
      console.log(`  Category: ${sampleProduct.categoryId ? sampleProduct.categoryId.name : 'None'}`);
      console.log(`  SubCategory: ${sampleProduct.subCategoryId ? sampleProduct.subCategoryId.name : 'None'}`);
      console.log(`  Price: ${sampleProduct.price}`);
      console.log(`  Image: ${sampleProduct.imageUrl}`);
    }

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

verify();

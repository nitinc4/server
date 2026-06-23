const Admin = require('../models/Admin');
const Category = require('../models/Category');
const SubCategory = require('../models/SubCategory');
const User = require('../models/User');
const Location = require('../models/Location');

/**
 * Seed a new location database with original data from the main database
 * @param {mongoose.Connection} connection - The dynamic mongoose connection
 * @param {string} locationId - The location ID (for logging)
 */
const seedLocationDB = async (connection, locationId) => {
  try {
    const AdminModel = connection.model('Admin', Admin.schema);
    const CategoryModel = connection.model('Category', Category.schema);
    const SubCategoryModel = connection.model('SubCategory', SubCategory.schema);
    const UserModel = connection.model('User', User.schema);
    const LocationModel = connection.model('Location', Location.schema);

    console.log(`[Seeder] Copying original data from main database to location: ${locationId}`);

    // 1. Fetch data from main database (default connection)
    // We use .lean() to get plain JavaScript objects and avoid Mongoose overhead/middleware
    const [admins, categories, subcategories, users, locations] = await Promise.all([
      Admin.find().lean(),
      Category.find().lean(),
      SubCategory.find().lean(),
      User.find().lean(),
      Location.find().lean()
    ]);

    // 2. Clear existing collections in the new database for idempotency
    // This ensures we start with an exact copy
    await Promise.all([
      AdminModel.deleteMany({}),
      CategoryModel.deleteMany({}),
      SubCategoryModel.deleteMany({}),
      UserModel.deleteMany({}),
      LocationModel.deleteMany({})
    ]);

    // 3. Insert original data into the new location database
    // We only perform insertMany if there is data to insert to avoid errors
    const insertPromises = [];
    
    if (admins.length > 0) insertPromises.push(AdminModel.insertMany(admins));
    if (categories.length > 0) insertPromises.push(CategoryModel.insertMany(categories));
    if (subcategories.length > 0) insertPromises.push(SubCategoryModel.insertMany(subcategories));
    if (users.length > 0) insertPromises.push(UserModel.insertMany(users));
    if (locations.length > 0) insertPromises.push(LocationModel.insertMany(locations));

    if (insertPromises.length > 0) {
      await Promise.all(insertPromises);
    }

    console.log(`[Seeder] Successfully synced location ${locationId}:`);
    console.log(` - ${admins.length} Admins`);
    console.log(` - ${categories.length} Categories`);
    console.log(` - ${subcategories.length} SubCategories`);
    console.log(` - ${users.length} Users`);
    console.log(` - ${locations.length} Locations`);

  } catch (error) {
    console.error(`[Seeder] Error syncing data for location ${locationId}:`, error);
    throw error;
  }
};

module.exports = { seedLocationDB };


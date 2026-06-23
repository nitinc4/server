require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(require('./middleware/tenant'));

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}
app.use('/api/uploads', express.static(uploadDir));
app.use('/uploads', express.static(uploadDir)); // Keep fallback for compatibility

// Connect to MongoDB
const { refreshAllowedDatabases } = require('./utils/tenant');
mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('Connected to MongoDB');
    await refreshAllowedDatabases();
  })
  .catch(err => console.error('MongoDB connection error:', err));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/categories', require('./routes/categories'));
app.use('/api/products', require('./routes/products'));
app.use('/api/drivers', require('./routes/drivers'));
app.use('/api/upload', require('./routes/uploads'));
app.use('/api/orders', require('./routes/orders'));
app.use('/api/subcategories', require('./routes/subcategories'));
app.use('/api/reviews', require('./routes/reviews'));
app.use('/api/sellers', require('./routes/sellers'));
app.use('/api/locations', require('./routes/locations'));
app.use('/api/feeds', require('./routes/feeds'));

// Base route
app.get('/', (req, res) => {
  res.send('Zudo API is running...');
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

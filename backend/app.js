const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();

const prescriptionRoutes = require('./routes/Prescription');
const orderRoutes = require('./routes/orders');
const deliveryRoutes = require('./routes/delivery');

const app = express();
app.use(express.json());
app.use('/api', prescriptionRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/delivery', deliveryRoutes);

mongoose.connect(process.env.MONGO_URI, { 
  useNewUrlParser: true, 
  useUnifiedTopology: true,
  dbName: process.env.MONGODB_DB || 'curecart' // Use same database as web system
})
  .then(() => app.listen(3000, () => console.log('Server running on port 3000')))
  .catch(err => console.error(err));
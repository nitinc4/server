const express = require('express');
const router = express.Router();
const CashCollector = require('../models/CashCollector');

// @route   GET api/cash
// @desc    Get all cash transactions
// @access  Private (Admin)
router.get('/', async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const transactions = await aggregateGET('CashCollector', req, {}, [], '', { date: -1 });
      return res.json(transactions);
    }
    const CashCollectorModel = req.models?.CashCollector || CashCollector;
    const transactions = await CashCollectorModel.find().sort({ date: -1 });
    res.json(transactions);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   POST api/cash
// @desc    Record a new cash transaction / collector
// @access  Private (Admin)
router.post('/', async (req, res) => {
  const { type, name, phone, email, password, amount, description, paymentMethod } = req.body;

  try {
    const CashCollectorModel = req.models?.CashCollector || CashCollector;
    const newTransaction = new CashCollectorModel({
      type,
      name,
      phone,
      email,
      password,
      amount,
      description,
      paymentMethod
    });

    let transaction;
    try {
      transaction = await newTransaction.save();
    } catch (saveErr) {
      if (saveErr.code === 11000 && saveErr.message.includes('phone_1')) {
        console.log('Dropping legacy phone_1 unique index from cashcollectors...');
        await CashCollectorModel.collection.dropIndex('phone_1').catch(e => console.log('Error dropping index:', e.message));
        transaction = await newTransaction.save();
      } else {
        throw saveErr;
      }
    }

    res.json(transaction);
  } catch (err) {
    console.error('Error logging transaction:', err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

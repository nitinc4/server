const express = require('express');
const router = express.Router();
const CashTransaction = require('../models/CashTransaction');

// @route   GET api/cash
// @desc    Get all cash transactions
// @access  Private (Admin)
router.get('/', async (req, res) => {
  try {
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const transactions = await aggregateGET('CashTransaction', req, {}, [], '', { date: -1 });
      return res.json(transactions);
    }
    const CashTransactionModel = req.models?.CashTransaction || CashTransaction;
    const transactions = await CashTransactionModel.find().sort({ date: -1 });
    res.json(transactions);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server Error');
  }
});

// @route   POST api/cash
// @desc    Record a new cash transaction
// @access  Private (Admin)
router.post('/', async (req, res) => {
  const { type, name, phone, email, amount, description, paymentMethod } = req.body;

  try {
    const CashTransactionModel = req.models?.CashTransaction || CashTransaction;
    const newTransaction = new CashTransactionModel({
      type,
      name,
      phone,
      email,
      amount,
      description,
      paymentMethod
    });

    const transaction = await newTransaction.save();
    res.json(transaction);
  } catch (err) {
    console.error('Error logging transaction:', err);
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;

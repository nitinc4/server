const express = require('express');
const router = express.Router();
const Setting = require('../models/Setting');

// Get a setting by key
router.get('/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const setting = await Setting.findOne({ key, tenantId: req.tenantId || 'default' });
    if (!setting) {
      return res.status(404).json({ message: 'Setting not found' });
    }
    res.json(setting);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// Update or create a setting
router.post('/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const { value } = req.body;
    
    let setting = await Setting.findOne({ key, tenantId: req.tenantId || 'default' });
    if (setting) {
      setting.value = value;
      await setting.save();
    } else {
      setting = new Setting({
        key,
        value,
        tenantId: req.tenantId || 'default'
      });
      await setting.save();
    }
    res.json(setting);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const { getModel } = require('../utils/model_loader');

// Get a setting by key
router.get('/:key', async (req, res) => {
  try {
    const { key } = req.params;
    const SettingModel = getModel('Setting', req);
    const setting = await SettingModel.findOne({ key });
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
    
    const SettingModel = getModel('Setting', req);
    let setting = await SettingModel.findOne({ key });
    if (setting) {
      setting.value = value;
      await setting.save();
    } else {
      setting = new SettingModel({
        key,
        value,
        tenantId: req.locationId || 'default'
      });
      await setting.save();
    }
    res.json(setting);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

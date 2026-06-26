const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const { protect } = require('../middleware/auth');
const sendEmail = require('../utils/email');

// @route   POST /api/orders
// @desc    Create a new order
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const { items, totalAmount, shippingAddress, paymentMethod } = req.body;
    
    if (!items || items.length === 0) {
      return res.status(400).json({ message: 'No order items' });
    }

    const Product = require('../models/Product');
    const enrichedItems = await Promise.all(items.map(async (item) => {
      const pId = item.product || item.id || item._id;
      let name = item.name;
      let image = item.image || item.imageUrl;

      // If name or image is missing, fetch from database
      if (!name || !image) {
        const productData = await Product.findById(pId);
        if (productData) {
          name = name || productData.name;
          image = image || productData.imageUrl || productData.image;
        }
      }

      return {
        productId: pId,
        name: name || 'Unknown Product',
        quantity: item.quantity,
        price: item.price,
        image: image,
        product: {
          name: name || 'Unknown Product',
          image: image,
          imageUrl: image
        }
      };
    }));

    const deliveryOtp = Math.floor(1000 + Math.random() * 9000).toString();

    const order = new Order({
      userId: req.user._id,
      items: enrichedItems,
      totalAmount,
      shippingAddress,
      paymentMethod,
      paymentStatus: paymentMethod === 'COD' ? 'Pending' : 'Completed',
      orderStatus: 'Pending',
      deliveryOtp
    });

    const createdOrder = await order.save();
    res.status(201).json(createdOrder);
  } catch (error) {
    console.error('Order creation error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/orders/myorders
// @desc    Get logged in user orders
// @access  Private
router.get('/myorders', protect, async (req, res) => {
  try {
    const orders = await Order.find({ userId: req.user._id })
      .populate('cashPersonId')
      .sort({ createdAt: -1 });
    res.json(orders);
  } catch (error) {

    console.error('Fetch orders error:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/orders/admin/all
// @desc    Get all orders (Admin only)
router.get('/admin/all', protect, async (req, res) => {
  try {
    const orders = await Order.find()
      .populate('userId', 'name email role')
      .sort({ createdAt: -1 });
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   PUT /api/orders/:id/status
// @desc    Update order status
// @access  Private
router.put('/:id/status', protect, async (req, res) => {
  try {
    const { status } = req.body;
    
    if (!status) {
      return res.status(400).json({ message: 'Status is required' });
    }

    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }
    
    // Authorization check: User can only cancel their own order
    if (order.userId.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({ message: 'Not authorized to update this order' });
    }

    order.orderStatus = status;
    
    // If status is 'Returned', save reason and image
    if (status === 'Returned') {
      order.returnReason = req.body.returnReason || null;
      order.returnComment = req.body.returnComment || null;
      order.returnImage = req.body.returnImage || null;
    }
    
    // If cancelled, also update payment status if it was COD
    if (status === 'Cancelled' && order.paymentMethod === 'COD') {
      order.paymentStatus = 'Cancelled';
    }

    await order.save();

    // Send email notification for Return Request
    if (status === 'Returned') {
      try {
        const adminEmail = process.env.EMAIL_USER;
        const userEmail = req.user.email;
        const orderId = order._id.toString().slice(-6).toUpperCase();

        // 1. Send to Admin
        await sendEmail({
          to: adminEmail,
          subject: `Return Request: Order #${orderId}`,
          html: `
            <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #eee; border-radius: 10px; overflow: hidden;">
              <div style="background-color: #f59e0b; color: white; padding: 20px; text-align: center;">
                <h1 style="margin: 0;">New Return Request</h1>
              </div>
              <div style="padding: 20px;">
                <p><strong>Order ID:</strong> #${orderId}</p>
                <p><strong>Customer:</strong> ${req.user.name} (${req.user.email})</p>
                <p><strong>Reason:</strong> ${order.returnReason}</p>
                <p><strong>Comment:</strong> ${order.returnComment || 'No comment'}</p>
                <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;" />
                ${order.returnImage ? `<p><strong>Evidence:</strong> <br/><img src="${order.returnImage}" style="max-width: 100%; border-radius: 10px; margin-top: 10px;"/></p>` : ''}
              </div>
              <div style="background-color: #f4f4f4; padding: 10px; text-align: center; font-size: 12px; color: #777;">
                Sent from Zudo Admin Panel
              </div>
            </div>
          `
        });

        // 2. Send confirmation to User
        await sendEmail({
          to: userEmail,
          subject: `Return Request Received: Order #${orderId}`,
          html: `
            <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #eee; border-radius: 10px; overflow: hidden;">
              <div style="background-color: #059669; color: white; padding: 20px; text-align: center;">
                <h1 style="margin: 0;">Hello ${req.user.name}!</h1>
              </div>
              <div style="padding: 20px;">
                <p>We have received your return request for <strong>Order #${orderId}</strong>.</p>
                <p>Our team will review the details and evidence provided and get back to you shortly regarding the next steps.</p>
                <div style="background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0;">
                  <p style="margin: 0;"><strong>Reason:</strong> ${order.returnReason}</p>
                  <p style="margin: 0; font-size: 12px; color: #666; margin-top: 5px;">Your request is being processed.</p>
                </div>
                <p>Best regards,<br/><strong>Team Zudo</strong></p>
              </div>
              <div style="background-color: #f4f4f4; padding: 10px; text-align: center; font-size: 12px; color: #777;">
                This is an automated response. Please do not reply directly to this email.
              </div>
            </div>
          `
        });
      } catch (emailError) {
        console.error('Return request email notification failed:', emailError);
      }
    }

    res.json(order);
  } catch (error) {
    console.error('Order status update error:', error);
    res.status(500).json({ 
      message: 'Failed to update order status', 
      error: error.message,
      details: error.errors ? Object.values(error.errors).map(err => err.message) : []
    });
  }
});

// @route   POST /api/orders/:id/delivery-otp
// @desc    Generate/Regenerate delivery OTP
// @access  Private (Admin only or system)
router.post('/:id/delivery-otp', protect, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Generate new 4-digit OTP
    const newOtp = Math.floor(1000 + Math.random() * 9000).toString();
    order.deliveryOtp = newOtp;
    
    await order.save();
    res.json({ 
      message: 'Delivery OTP updated successfully', 
      deliveryOtp: newOtp 
    });
  } catch (error) {
    console.error('OTP generation error:', error);
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

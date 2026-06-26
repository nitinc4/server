const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const sendEmail = require('../utils/email');
const PDFDocument = require('pdfkit-table');
const Order = require('../models/Order');
const SellerInvoice = require('../models/SellerInvoice');

const getModels = (req) => {
  return {
    Order: req.models?.Order || Order,
    SellerInvoice: req.models?.SellerInvoice || SellerInvoice,
    Seller: req.models?.Seller || require('../models/Seller')
  };
};

router.param('id', async (req, res, next, id) => {
  if (req.isTenant || req.locationId) return next();
  try {
    const { getTenantConnections } = require('../utils/db_manager');
    const connections = await getTenantConnections();
    for (const [dbName, tenantConn] of Object.entries(connections)) {
      const TenantInvoice = tenantConn.models.SellerInvoice || tenantConn.model('SellerInvoice', require('../models/SellerInvoice').schema);
      try {
        const exists = await TenantInvoice.exists({ _id: id });
        if (exists) {
          req.models = {
            Order: tenantConn.models.Order || tenantConn.model('Order', require('../models/Order').schema),
            SellerInvoice: TenantInvoice,
            Seller: tenantConn.models.Seller || tenantConn.model('Seller', require('../models/Seller').schema)
          };
          req.db = tenantConn;
          return next();
        }
      } catch (e) {}
    }
  } catch (error) {
    console.error('Error resolving tenant:', error);
  }
  next();
});

// @route   POST /api/seller-invoices/generate
// @desc    Generate a new invoice for a seller
router.post('/generate', protect, async (req, res) => {
  try {
    if (req.user?.role !== 'seller' && !req.admin) {
      return res.status(403).json({ message: 'Not authorized to generate invoices' });
    }

    const { startDate, endDate } = req.body;
    let sellerId = req.user?._id;
    
    if (req.admin) {
      if (!req.body.sellerId) {
        return res.status(400).json({ message: 'sellerId is required when generating as admin' });
      }
      sellerId = req.body.sellerId;
    }

    if (!startDate || !endDate) {
      return res.status(400).json({ message: 'Start date and end date are required' });
    }

    const { Order: OrderModel, SellerInvoice: InvoiceModel, Seller: SellerModel } = getModels(req);

    // Check for overlapping cleared/pending invoices
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);
    
    // An invoice overlaps if (invoice.start <= requested.end AND invoice.end >= requested.start)
    const overlappingInvoice = await InvoiceModel.findOne({
      sellerId: sellerId,
      startDate: { $lte: end },
      endDate: { $gte: start }
    });

    if (overlappingInvoice) {
      return res.status(400).json({ 
        message: 'You already have an invoice generated that overlaps with this date range. Status: ' + overlappingInvoice.status 
      });
    }

    const seller = await SellerModel.findById(sellerId);
    if (!seller) {
      return res.status(404).json({ message: 'Seller not found' });
    }

    // Query all Delivered orders within date range
    const orders = await OrderModel.find({
      orderStatus: { $in: ['Delivered', 'Partially Returned', 'Returned'] },
      createdAt: { $gte: start, $lte: end }
    }).populate('items.productId');

    let totalAmount = 0;
    let orderIds = [];
    const validOrders = [];

    // Calculate totals specifically for this seller's items
    orders.forEach(order => {
      let sellerItemsInOrder = order.items.filter(item => {
        const matchesSellerObj = item.seller && item.seller.sellerId && item.seller.sellerId.toString() === sellerId.toString();
        const matchesProductRef = item.productId && item.productId.sellerId && item.productId.sellerId.toString() === sellerId.toString();
        const matchesName = item.sellerName && seller.name && item.sellerName.toLowerCase() === seller.name.toLowerCase();
        const matchesStore = item.sellerName && seller.storeName && item.sellerName.toLowerCase() === seller.storeName.toLowerCase();
        const matchesBusiness = item.sellerName && seller.businessName && item.sellerName.toLowerCase() === seller.businessName.toLowerCase();
        const productMatchesName = item.product && item.product.sellerName && seller.name && item.product.sellerName.toLowerCase() === seller.name.toLowerCase();
        const productMatchesStore = item.product && item.product.sellerName && seller.storeName && item.product.sellerName.toLowerCase() === seller.storeName.toLowerCase();
        
        return matchesSellerObj || matchesProductRef || matchesName || matchesStore || matchesBusiness || productMatchesName || productMatchesStore;
      });
      
      if (sellerItemsInOrder.length > 0) {
        orderIds.push(order._id);
        validOrders.push(order);
        sellerItemsInOrder.forEach(item => {
          if (item.returnStatus !== 'Returned to Seller') {
            totalAmount += (item.normalPrice || item.price) * item.quantity;
          }
        });
      }
    });

    if (orderIds.length === 0) {
      return res.status(400).json({ message: 'No delivered orders found in this date range.' });
    }

    // Create Invoice Record
    const newInvoice = new InvoiceModel({
      sellerId: sellerId,
      startDate: start,
      endDate: end,
      totalAmount: totalAmount,
      totalCommission: 0, // Simplified for now
      netAmount: totalAmount,
      orderCount: orderIds.length,
      orders: orderIds,
      status: 'Pending',
      generatedBy: req.user._id
    });

    await newInvoice.save();
    
    // Generate PDF Invoice
    const doc = new PDFDocument({ margin: 30, size: 'A4' });
    const chunks = [];
    doc.on('data', chunk => chunks.push(chunk));
    doc.on('end', async () => {
      const pdfBuffer = Buffer.concat(chunks);
      
      // Email Admin
      try {
        const adminEmail = process.env.EMAIL_USER;
        await sendEmail({
          to: adminEmail,
          subject: `New Seller Invoice: ${seller.businessName}`,
          html: `
            <h3>New Invoice Generated</h3>
            <p><strong>Seller:</strong> ${seller.businessName}</p>
            <p><strong>Date Range:</strong> ${start.toDateString()} to ${end.toDateString()}</p>
            <p><strong>Total Amount:</strong> ₹${totalAmount}</p>
            <p><strong>Total Orders:</strong> ${orderIds.length}</p>
          `,
          attachments: [
            {
              filename: `Invoice_${seller.businessName.replace(/\s+/g, '_')}_${newInvoice._id}.pdf`,
              content: pdfBuffer,
              contentType: 'application/pdf'
            }
          ]
        });
      } catch (err) {
        console.error('Error emailing invoice:', err);
      }
    });

    // Build PDF Content
    doc.fontSize(20).text('SELLER INVOICE', { align: 'center' }).moveDown();
    doc.fontSize(12).text(`Seller: ${seller.businessName}`);
    if (seller.gstNumber) {
      doc.text(`GSTIN: ${seller.gstNumber}`);
    }
    doc.text(`Invoice ID: ${newInvoice._id}`);
    doc.text(`Date Range: ${start.toDateString()} to ${end.toDateString()}`);
    doc.text(`Total Orders: ${orderIds.length}`);
    doc.text(`Total Amount: ₹${totalAmount}`);
    doc.moveDown();

    const table = {
      title: "Order Breakdown",
      headers: ["Order ID", "Date", "Amount"],
      rows: validOrders.map(o => [
        o._id.toString(),
        new Date(o.createdAt).toLocaleDateString(),
        `Rs. ${o.items.filter(item => {
          const matchesSellerObj = item.seller && item.seller.sellerId && item.seller.sellerId.toString() === sellerId.toString();
          const matchesProductRef = item.productId && item.productId.sellerId && item.productId.sellerId.toString() === sellerId.toString();
          const matchesName = item.sellerName && seller.name && item.sellerName.toLowerCase() === seller.name.toLowerCase();
          const matchesStore = item.sellerName && seller.storeName && item.sellerName.toLowerCase() === seller.storeName.toLowerCase();
          const matchesBusiness = item.sellerName && seller.businessName && item.sellerName.toLowerCase() === seller.businessName.toLowerCase();
          const productMatchesName = item.product && item.product.sellerName && seller.name && item.product.sellerName.toLowerCase() === seller.name.toLowerCase();
          const productMatchesStore = item.product && item.product.sellerName && seller.storeName && item.product.sellerName.toLowerCase() === seller.storeName.toLowerCase();
          return matchesSellerObj || matchesProductRef || matchesName || matchesStore || matchesBusiness || productMatchesName || productMatchesStore;
        }).reduce((sum, i) => sum + (i.normalPrice || i.price) * i.quantity, 0)}`
      ])
    };
    
    await doc.table(table, { width: 500 });
    doc.end();

    res.status(201).json(newInvoice);
  } catch (error) {
    console.error('Error generating invoice:', error);
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/seller-invoices/my-invoices
// @desc    Get all invoices for logged in seller
router.get('/my-invoices', protect, async (req, res) => {
  try {
    if (req.user.role !== 'seller') {
      return res.status(403).json({ message: 'Only sellers can access this' });
    }
    const { SellerInvoice: InvoiceModel } = getModels(req);
    const invoices = await InvoiceModel.find({ sellerId: req.user._id }).sort({ createdAt: -1 });
    res.json(invoices);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/seller-invoices/admin/all
// @desc    Get all invoices for admin
router.get('/admin/all', protect, async (req, res) => {
  try {
    if (!req.admin) {
      return res.status(403).json({ message: 'Admin only' });
    }
    
    if (!req.locationId) {
      const { aggregateGET } = require('../utils/aggregator');
      const invoices = await aggregateGET(
        'SellerInvoice', 
        req, 
        {}, 
        [{ path: 'sellerId', select: 'businessName name email' }], 
        '', 
        { createdAt: -1 }
      );
      return res.json(invoices);
    } else {
      const { SellerInvoice: InvoiceModel } = getModels(req);
      const invoices = await InvoiceModel.find().populate('sellerId', 'businessName name email').sort({ createdAt: -1 });
      return res.json(invoices);
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   PUT /api/seller-invoices/admin/:id/clear
// @desc    Mark invoice as cleared
router.put('/admin/:id/clear', protect, async (req, res) => {
  try {
    if (!req.admin) {
      return res.status(403).json({ message: 'Admin only' });
    }
    const { SellerInvoice: InvoiceModel } = getModels(req);
    const invoice = await InvoiceModel.findById(req.params.id);
    if (!invoice) return res.status(404).json({ message: 'Invoice not found' });
    
    invoice.status = 'Cleared';
    await invoice.save();
    res.json(invoice);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// @route   GET /api/seller-invoices/:id/download
// @desc    Download invoice PDF
router.get('/:id/download', protect, async (req, res) => {
  try {
    const { SellerInvoice: InvoiceModel, Seller: SellerModel, Order: OrderModel } = getModels(req);
    const invoice = await InvoiceModel.findById(req.params.id);
    if (!invoice) return res.status(404).json({ message: 'Invoice not found' });

    // Auth check
    const isOwner = req.user._id.toString() === invoice.sellerId.toString();
    if (!isOwner && !req.admin) {
      return res.status(403).json({ message: 'Not authorized' });
    }

    const seller = await SellerModel.findById(invoice.sellerId);
    const orders = await OrderModel.find({ _id: { $in: invoice.orders } });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=Invoice_${invoice._id}.pdf`);

    const doc = new PDFDocument({ margin: 30, size: 'A4' });
    doc.pipe(res);

    doc.fontSize(20).text('SELLER INVOICE', { align: 'center' }).moveDown();
    doc.fontSize(12).text(`Seller: ${seller.businessName}`);
    if (seller.gstNumber) {
      doc.text(`GSTIN: ${seller.gstNumber}`);
    }
    doc.text(`Invoice ID: ${invoice._id}`);
    doc.text(`Status: ${invoice.status}`);
    doc.text(`Date Range: ${new Date(invoice.startDate).toDateString()} to ${new Date(invoice.endDate).toDateString()}`);
    doc.text(`Total Orders: ${invoice.orderCount}`);
    doc.text(`Total Amount: Rs. ${invoice.totalAmount}`);
    doc.moveDown();

    const table = {
      title: "Order Breakdown",
      headers: ["Order ID", "Date", "Amount"],
      rows: orders.map(o => [
        o._id.toString(),
        new Date(o.createdAt).toLocaleDateString(),
        `Rs. ${o.items.filter(item => {
          const matchesSellerObj = item.seller && item.seller.sellerId && item.seller.sellerId.toString() === seller._id.toString();
          const matchesProductRef = item.productId && item.productId.sellerId && item.productId.sellerId.toString() === seller._id.toString();
          const matchesName = item.sellerName && seller.name && item.sellerName.toLowerCase() === seller.name.toLowerCase();
          const matchesStore = item.sellerName && seller.storeName && item.sellerName.toLowerCase() === seller.storeName.toLowerCase();
          const matchesBusiness = item.sellerName && seller.businessName && item.sellerName.toLowerCase() === seller.businessName.toLowerCase();
          const productMatchesName = item.product && item.product.sellerName && seller.name && item.product.sellerName.toLowerCase() === seller.name.toLowerCase();
          const productMatchesStore = item.product && item.product.sellerName && seller.storeName && item.product.sellerName.toLowerCase() === seller.storeName.toLowerCase();
          return matchesSellerObj || matchesProductRef || matchesName || matchesStore || matchesBusiness || productMatchesName || productMatchesStore;
        }).reduce((sum, i) => sum + (i.normalPrice || i.price) * i.quantity, 0)}`
      ])
    };
    
    await doc.table(table, { width: 500 });
    doc.end();
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;

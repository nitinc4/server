import React, { useState, useEffect, useRef } from 'react';
import api from '../utils/api';
import { 
  Receipt, Printer, Search, Filter, Calendar, CheckCircle2, FileText, X, ChevronDown, Edit2, Download
} from 'lucide-react';

const Invoices = () => {
  const [loading, setLoading] = useState(false);
  const [orders, setOrders] = useState([]);
  const [filteredOrders, setFilteredOrders] = useState([]);
  const [productGstMap, setProductGstMap] = useState({});
  
  // Filters
  const [invoiceType, setInvoiceType] = useState('order'); // 'order', 'purchase', or 'seller_generated'
  const [segmentType, setSegmentType] = useState('All'); // 'B2B', 'B2C', 'All'
  const [searchTerm, setSearchTerm] = useState(''); // Seller or Buyer name
  const [dateFilter, setDateFilter] = useState('All Time');
  const [customDate, setCustomDate] = useState({ start: '', end: '' });
  const [collation, setCollation] = useState('All'); // 'Collated', 'Uncollated', 'All'

  // Print Preview
  const [showPreview, setShowPreview] = useState(false);
  const [previewOrders, setPreviewOrders] = useState([]);
  const [pageSize, setPageSize] = useState('A4');
  const iframeRef = useRef(null);

  // Edit Pricing State
  // Map of orderId -> itemIndex -> newPrice
  const [customPrices, setCustomPrices] = useState({});

  const [sellerInvoices, setSellerInvoices] = useState([]);

  useEffect(() => {
    if (invoiceType === 'seller_generated') {
      if (sellerInvoices.length === 0) fetchSellerInvoices();
    } else {
      if (orders.length === 0) fetchOrders();
    }
  }, [invoiceType]);

  const fetchSellerInvoices = async () => {
    setLoading(true);
    try {
      const { data } = await api.get('/seller-invoices/admin/all');
      setSellerInvoices(data);
    } catch (err) {
      console.error('Failed to fetch seller invoices:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleClearInvoice = async (id) => {
    if (!window.confirm('Are you sure you want to mark this invoice as cleared?')) return;
    try {
      await api.put(`/seller-invoices/admin/${id}/clear`);
      setSellerInvoices(sellerInvoices.map(inv => inv._id === id ? { ...inv, status: 'Cleared' } : inv));
    } catch (err) {
      alert('Failed to clear invoice');
    }
  };

  const handleDownloadInvoice = async (id) => {
    try {
      const response = await api.get(`/seller-invoices/${id}/download`, { responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `Seller_Invoice_${id}.pdf`);
      document.body.appendChild(link);
      link.click();
      link.remove();
    } catch (err) {
      alert('Failed to download invoice');
    }
  };

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const [ordersRes, productsRes] = await Promise.all([
        api.get('/orders/admin/all'),
        api.get('/products')
      ]);
      const productMap = {};
      if (productsRes && productsRes.data) {
        productsRes.data.forEach(p => {
          productMap[p._id] = p.gstPercent || 0;
        });
      }
      setProductGstMap(productMap);
      setOrders(ordersRes.data);
      setFilteredOrders(ordersRes.data);
    } catch (error) {
      console.error('Failed to fetch orders:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    applyFilters();
  }, [invoiceType, segmentType, searchTerm, dateFilter, customDate, collation, orders]);

  const applyFilters = () => {
    let result = [...orders];

    // Segment Filter
    if (segmentType !== 'All') {
      result = result.filter(o => (o.userId?.role?.toUpperCase() || 'B2C') === segmentType);
    }

    // Search Filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      result = result.filter(o => {
        const buyerName = o.userId?.name?.toLowerCase() || '';
        const sellerName = o.sellerId?.name?.toLowerCase() || o.sellerId?.companyName?.toLowerCase() || '';
        return buyerName.includes(term) || sellerName.includes(term);
      });
    }

    // Date Filter
    const today = new Date();
    if (dateFilter === 'Today') {
      result = result.filter(o => new Date(o.createdAt).toDateString() === today.toDateString());
    } else if (dateFilter === 'This Week') {
      const firstDay = new Date(today.setDate(today.getDate() - today.getDay()));
      result = result.filter(o => new Date(o.createdAt) >= firstDay);
    } else if (dateFilter === 'This Month') {
      result = result.filter(o => new Date(o.createdAt).getMonth() === new Date().getMonth() && new Date(o.createdAt).getFullYear() === new Date().getFullYear());
    } else if (dateFilter === 'Custom' && customDate.start && customDate.end) {
      result = result.filter(o => {
        const oDate = new Date(o.createdAt);
        return oDate >= new Date(customDate.start) && oDate <= new Date(customDate.end);
      });
    }

    // Collation is UI only for now unless specified
    if (collation === 'Collated') {
      // Mock logic or actual logic if exists
    } else if (collation === 'Uncollated') {
      // Mock logic
    }

    setFilteredOrders(result);
  };

  const handlePriceChange = (orderId, itemIndex, newPrice) => {
    setCustomPrices(prev => ({
      ...prev,
      [`${orderId}_${itemIndex}`]: Number(newPrice)
    }));
  };

  const calculateItemPrice = (orderId, itemIndex, originalPrice) => {
    const key = `${orderId}_${itemIndex}`;
    return customPrices[key] !== undefined ? customPrices[key] : originalPrice;
  };

  const handlePreview = (selectedOrders = filteredOrders) => {
    setPreviewOrders(selectedOrders);
    setShowPreview(true);
  };

  const generatePrintHTML = () => {
    let pagesHtml = '';

    if (collation === 'Collated') {
      let subtotal = 0;
      let grandTotal = 0;
      const gstBrackets = {};

      const itemsHtml = previewOrders.map((order) => {
        return order.items.map((item, i) => {
          const rawPrice = item.price || 0;
          const currentPrice = calculateItemPrice(order._id, i, rawPrice);
          const itemTotal = currentPrice * item.quantity;
          subtotal += itemTotal;
          
          const gstPercent = item.gstPercent || item.productId?.gstPercent || item.product?.gstPercent || productGstMap[item.productId?._id || item.productId] || 0;
          const gstAmount = (itemTotal * gstPercent) / 100;
          grandTotal += (itemTotal + gstAmount);
          
          if (!gstBrackets[gstPercent]) {
            gstBrackets[gstPercent] = { amount: 0, itemsCount: 0 };
          }
          gstBrackets[gstPercent].amount += gstAmount;
          gstBrackets[gstPercent].itemsCount += item.quantity;

          return `
            <tr>
              <td style="border: 1px solid #e2e8f0; padding: 8px 16px;">
                <div style="font-weight: 600;">${item.name}</div>
                <div style="font-size: 10px; color: #64748b;">Raw Price: ₹${rawPrice.toFixed(2)} | GST: ${gstPercent}% | Order: #${order._id.slice(-8).toUpperCase()}</div>
              </td>
              <td style="text-align: center; border: 1px solid #e2e8f0; padding: 8px 16px;">${item.quantity}</td>
              <td style="text-align: right; border: 1px solid #e2e8f0; padding: 8px 16px;">₹${currentPrice.toFixed(2)}</td>
              <td style="text-align: right; border: 1px solid #e2e8f0; padding: 8px 16px;">₹${itemTotal.toFixed(2)}</td>
            </tr>
          `;
        }).join('');
      }).join('');

      let gstRowsHtml = Object.keys(gstBrackets).map(percent => {
        const bracket = gstBrackets[percent];
        if (bracket.amount === 0 && Number(percent) === 0) return '';
        return `
          <tr class="total-row">
            <td colspan="3" style="text-align: right;">GST (${percent}%) [${bracket.itemsCount} items in bracket]:</td>
            <td style="text-align: right;">₹${bracket.amount.toFixed(2)}</td>
          </tr>
        `;
      }).join('');

      pagesHtml = `
        <div class="invoice-page-container">
          <div class="invoice-page">
            <div class="header">
              <h1 class="brand-title">ZUDO</h1>
              <p class="brand-subtitle">COLLATED ${invoiceType === 'purchase' ? 'SELLER PURCHASE INVOICE' : 'CUSTOMER ORDER INVOICE'}</p>
            </div>
            
            <div class="info-grid">
              <div class="info-box">
                <strong>${invoiceType === 'purchase' ? 'Invoice From' : 'Multi-Order Report'}</strong><br/>
                Total Orders: ${previewOrders.length}<br/>
                Date Range: ${dateFilter}
              </div>
              <div class="info-box text-right">
                <strong>Report Generated:</strong> ${new Date().toLocaleDateString()}<br/>
                <strong>Segment:</strong> ${segmentType.toUpperCase()}<br/>
              </div>
            </div>

            <table class="items-table">
              <thead>
                <tr>
                  <th style="width: 50%;">Product Details</th>
                  <th style="width: 10%; text-align: center;">Qty</th>
                  <th style="width: 20%; text-align: right;">Unit Price</th>
                  <th style="width: 20%; text-align: right;">Total</th>
                </tr>
              </thead>
              <tbody>
                ${itemsHtml}
                <tr class="total-row">
                  <td colspan="3" style="text-align: right;">Subtotal:</td>
                  <td style="text-align: right;">₹${subtotal.toFixed(2)}</td>
                </tr>
                ${gstRowsHtml}
                <tr class="total-row" style="font-size: 16px; font-weight: 800;">
                  <td colspan="3" style="text-align: right; color: #6366f1;">Grand Total:</td>
                  <td style="text-align: right; color: #6366f1;">₹${grandTotal.toFixed(2)}</td>
                </tr>
              </tbody>
            </table>
            
            <div class="footer text-center" style="margin-top: 30px; font-size: 10px; color: #64748b;">
              This is a computer-generated collated invoice and does not require a signature.
            </div>
          </div>
        </div>
      `;
    } else {
      pagesHtml = previewOrders.map((order, index) => {
        const pageBreakClass = index > 0 ? 'page-break' : '';
        let subtotal = 0;
        let grandTotal = 0;
        const gstBrackets = {};

        const itemsHtml = order.items.map((item, i) => {
          const rawPrice = item.price || 0;
          const currentPrice = calculateItemPrice(order._id, i, rawPrice);
          const itemTotal = currentPrice * item.quantity;
          subtotal += itemTotal;
          
          const gstPercent = item.gstPercent || item.productId?.gstPercent || item.product?.gstPercent || productGstMap[item.productId?._id || item.productId] || 0;
          const gstAmount = (itemTotal * gstPercent) / 100;
          grandTotal += (itemTotal + gstAmount);
          
          if (!gstBrackets[gstPercent]) {
            gstBrackets[gstPercent] = { amount: 0, itemsCount: 0 };
          }
          gstBrackets[gstPercent].amount += gstAmount;
          gstBrackets[gstPercent].itemsCount += item.quantity;

          return `
            <tr>
              <td style="border: 1px solid #e2e8f0; padding: 8px 16px;">
                <div style="font-weight: 600;">${item.name}</div>
                <div style="font-size: 10px; color: #64748b;">Raw Price: ₹${rawPrice.toFixed(2)} | GST: ${gstPercent}%</div>
              </td>
              <td style="text-align: center; border: 1px solid #e2e8f0; padding: 8px 16px;">${item.quantity}</td>
              <td style="text-align: right; border: 1px solid #e2e8f0; padding: 8px 16px;">₹${currentPrice.toFixed(2)}</td>
              <td style="text-align: right; border: 1px solid #e2e8f0; padding: 8px 16px;">₹${itemTotal.toFixed(2)}</td>
            </tr>
          `;
        }).join('');

        let gstRowsHtml = Object.keys(gstBrackets).map(percent => {
          const bracket = gstBrackets[percent];
          if (bracket.amount === 0 && Number(percent) === 0) return '';
          return `
            <tr class="total-row">
              <td colspan="3" style="text-align: right;">GST (${percent}%) [${bracket.itemsCount} items in bracket]:</td>
              <td style="text-align: right;">₹${bracket.amount.toFixed(2)}</td>
            </tr>
          `;
        }).join('');

        return `
          <div class="invoice-page-container ${pageBreakClass}">
            <div class="invoice-page">
              <div class="header">
                <h1 class="brand-title">ZUDO</h1>
                <p class="brand-subtitle">${invoiceType === 'purchase' ? 'SELLER PURCHASE INVOICE' : 'CUSTOMER ORDER INVOICE'}</p>
              </div>
              
              <div class="info-grid">
                <div class="info-box">
                  <strong>${invoiceType === 'purchase' ? 'Invoice From:' : 'Invoice To:'}</strong><br/>
                  ${invoiceType === 'purchase' ? 
                    (order.items?.[0]?.seller?.name || 'Seller') : (order.shippingAddress?.name || order.userId?.name || 'Customer')}<br/>
                  ${order.shippingAddress?.phone || order.sellerId?.phone || ''}<br/>
                  ${order.shippingAddress?.address || order.sellerId?.address || ''}<br/>
                  ${invoiceType === 'purchase' && (order.items?.[0]?.seller?.gstNumber || order.sellerId?.gstNumber) ? `<strong>GSTIN:</strong> ${order.items?.[0]?.seller?.gstNumber || order.sellerId?.gstNumber}<br/>` : ''}
                </div>
                <div class="info-box text-right">
                  <strong>Order Ref:</strong> #${order._id.toUpperCase()}<br/>
                  <strong>Date:</strong> ${new Date(order.createdAt).toLocaleDateString()}<br/>
                  <strong>Segment:</strong> ${(order.userId?.role || 'B2C').toUpperCase()}<br/>
                  <strong>Payment:</strong> ${order.paymentMethod}
                </div>
              </div>

              <table class="items-table">
                <thead>
                  <tr>
                    <th style="width: 50%;">Product Details</th>
                    <th style="width: 10%; text-align: center;">Qty</th>
                    <th style="width: 20%; text-align: right;">Unit Price</th>
                    <th style="width: 20%; text-align: right;">Total</th>
                  </tr>
                </thead>
                <tbody>
                  ${itemsHtml}
                  <tr class="total-row">
                    <td colspan="3" style="text-align: right;">Subtotal:</td>
                    <td style="text-align: right;">₹${subtotal.toFixed(2)}</td>
                  </tr>
                  ${gstRowsHtml}
                  <tr class="total-row" style="font-size: 16px; font-weight: 800;">
                    <td colspan="3" style="text-align: right; color: #6366f1;">Grand Total:</td>
                    <td style="text-align: right; color: #6366f1;">₹${grandTotal.toFixed(2)}</td>
                  </tr>
                </tbody>
              </table>
              
              <div class="footer text-center" style="margin-top: 30px; font-size: 10px; color: #64748b;">
                This is a computer-generated invoice and does not require a signature.
              </div>
            </div>
          </div>
        `;
      }).join('');
    }

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Invoices</title>
        <style>
          @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800&display=swap');
          @page {
            size: ${pageSize};
            margin: 10mm;
          }
          body {
            font-family: 'Outfit', 'Inter', sans-serif;
            color: #1e293b;
            background: #e2e8f0;
            margin: 0;
            padding: 20px;
            font-size: ${pageSize === 'A5' ? '10px' : '12px'};
            line-height: 1.4;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
          }
          @media print {
            body { background: #fff; padding: 0; }
            .invoice-page-container { margin: 0; box-shadow: none; border-radius: 0; width: 100%; min-height: auto; }
          }
          .page-break { page-break-before: always; }
          .invoice-page-container {
            background: white;
            width: ${pageSize === 'A4' ? '210mm' : '148mm'};
            min-height: ${pageSize === 'A4' ? '297mm' : '210mm'};
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            padding: 20px;
            margin: 0 auto 20px auto;
            box-sizing: border-box;
          }
          .invoice-page { width: 100%; box-sizing: border-box; }
          .header { margin-bottom: 20px; border-bottom: 2px solid #e2e8f0; padding-bottom: 10px; display: flex; justify-content: space-between; align-items: flex-end; }
          .brand-title { font-size: 28px; font-weight: 800; color: #6366f1; margin: 0; }
          .brand-subtitle { font-size: 12px; color: #64748b; font-weight: 700; letter-spacing: 1px; margin: 0; text-transform: uppercase; }
          .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 20px; }
          .info-box { background: #f8fafc; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0; }
          .text-right { text-align: right; }
          .text-center { text-align: center; }
          .items-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
          .items-table th { background: #f1f5f9; color: #475569; padding: 10px 16px; border: 1px solid #e2e8f0; text-align: left; text-transform: uppercase; font-size: 0.9em; }
          .total-row td { padding: 10px 16px; border: 1px solid #e2e8f0; font-weight: 700; }
        </style>
      </head>
      <body>
        ${pagesHtml}
      </body>
      </html>
    `;
  };

  const handlePrint = () => {
    if (iframeRef.current) {
      const doc = iframeRef.current.contentWindow.document;
      doc.open();
      doc.write(generatePrintHTML());
      doc.close();
      iframeRef.current.contentWindow.focus();
      setTimeout(() => {
        iframeRef.current.contentWindow.print();
      }, 500);
    }
  };

  return (
    <div className="flex flex-col gap-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-extrabold text-[var(--text-main)] m-0">Invoices Hub</h1>
          <p className="text-sm text-[var(--text-dim)] mt-1">Generate and customize print-ready invoices</p>
        </div>
      </div>

      <div className="glass-card" style={{ padding: '24px', borderRadius: '24px' }}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '24px', marginBottom: '24px' }}>
          
          <div>
            <label className="text-xs font-bold text-[var(--text-dim)] uppercase mb-2 block">Invoice Type</label>
            <select className="input-field" value={invoiceType} onChange={e => setInvoiceType(e.target.value)}>
              <option value="order">Order Invoice</option>
              <option value="purchase">Purchase (Seller) Invoice</option>
              <option value="seller_generated">Seller Generated Invoices</option>
            </select>
          </div>

          <div>
            <label className="text-xs font-bold text-[var(--text-dim)] uppercase mb-2 block">Segment</label>
            <select className="input-field" value={segmentType} onChange={e => setSegmentType(e.target.value)}>
              <option value="All">All Segments</option>
              <option value="B2B">B2B Only</option>
              <option value="B2C">B2C Only</option>
            </select>
          </div>

          <div>
            <label className="text-xs font-bold text-[var(--text-dim)] uppercase mb-2 block">Search</label>
            <div className="relative">
              <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--text-dim)]" />
              <input 
                type="text" 
                placeholder="Buyer or Seller Name" 
                className="input-field pl-9" 
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          <div>
            <label className="text-xs font-bold text-[var(--text-dim)] uppercase mb-2 block">Date Range</label>
            <select className="input-field" value={dateFilter} onChange={e => setDateFilter(e.target.value)}>
              <option value="All Time">All Time</option>
              <option value="Today">Today</option>
              <option value="This Week">This Week</option>
              <option value="This Month">This Month</option>
              <option value="Custom">Custom Duration</option>
            </select>
          </div>

          <div>
            <label className="text-xs font-bold text-[var(--text-dim)] uppercase mb-2 block">Collation</label>
            <select className="input-field" value={collation} onChange={e => setCollation(e.target.value)}>
              <option value="All">All</option>
              <option value="Collated">Collated</option>
              <option value="Uncollated">Uncollated</option>
            </select>
          </div>
        </div>

        {dateFilter === 'Custom' && (
          <div style={{ display: 'flex', gap: '24px', marginBottom: '24px', padding: '16px', background: 'var(--glass-bg)', borderRadius: '12px', border: '1px solid var(--glass-border)' }}>
            <div style={{ flex: 1 }}>
              <label className="text-xs font-bold text-[var(--text-dim)] mb-2 block">Start Date</label>
              <input type="date" className="input-field" value={customDate.start} onChange={e => setCustomDate({...customDate, start: e.target.value})} />
            </div>
            <div style={{ flex: 1 }}>
              <label className="text-xs font-bold text-[var(--text-dim)] mb-2 block">End Date</label>
              <input type="date" className="input-field" value={customDate.end} onChange={e => setCustomDate({...customDate, end: e.target.value})} />
            </div>
          </div>
        )}

        <div className="flex justify-between items-center border-t border-[var(--glass-border)] pt-6 mt-2">
          <div className="text-sm font-semibold text-[var(--text-main)]">
            Found {filteredOrders.length} matching records
          </div>
          <button 
            className="btn-primary flex items-center gap-2"
            onClick={() => handlePreview(filteredOrders)}
            disabled={filteredOrders.length === 0 || invoiceType === 'seller_generated'}
            style={{ opacity: invoiceType === 'seller_generated' ? 0.5 : 1 }}
          >
            <FileText size={18} />
            <span>Preview & Generate All ({filteredOrders.length})</span>
          </button>
        </div>
      </div>

      {/* Results Table */}
      <div className="glass-card" style={{ borderRadius: '24px', overflow: 'hidden' }}>
        <div style={{ overflowX: 'auto' }}>
          {invoiceType === 'seller_generated' ? (
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid var(--border-color)', background: 'var(--card-bg)' }}>
                  <th style={{ padding: '20px 24px', color: 'var(--text-dim)', fontSize: '13px', fontWeight: 600 }}>SELLER</th>
                  <th style={{ padding: '20px 24px', color: 'var(--text-dim)', fontSize: '13px', fontWeight: 600 }}>PERIOD</th>
                  <th style={{ padding: '20px 24px', color: 'var(--text-dim)', fontSize: '13px', fontWeight: 600 }}>AMOUNT / ORDERS</th>
                  <th style={{ padding: '20px 24px', color: 'var(--text-dim)', fontSize: '13px', fontWeight: 600 }}>STATUS</th>
                  <th style={{ padding: '20px 24px', color: 'var(--text-dim)', fontSize: '13px', fontWeight: 600 }}>ACTIONS</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan="5" style={{ padding: '40px', textAlign: 'center' }}>
                      <div className="animate-spin" style={{ display: 'inline-block' }}><Receipt size={24} /></div>
                    </td>
                  </tr>
                ) : sellerInvoices.length === 0 ? (
                  <tr>
                    <td colSpan="5" style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
                      No seller invoices generated yet.
                    </td>
                  </tr>
                ) : sellerInvoices.map((inv) => (
                  <tr key={inv._id} style={{ borderBottom: '1px solid var(--glass-border)' }} className="table-row-hover hover-row">
                    <td style={{ padding: '16px 24px' }}>
                      <div style={{ fontWeight: 600, fontSize: '14px', color: 'var(--text-main)' }}>
                        {inv.sellerId?.businessName || inv.sellerId?.name || 'Unknown Seller'}
                      </div>
                      <div style={{ fontSize: '12px', color: 'var(--text-dim)', marginTop: '2px' }}>
                        {inv.sellerId?.email || ''}
                      </div>
                    </td>
                    <td style={{ padding: '16px 24px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: 'var(--text-dim)' }}>
                        <Calendar size={14} />
                        {new Date(inv.startDate).toLocaleDateString()} - {new Date(inv.endDate).toLocaleDateString()}
                      </div>
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)', marginTop: '4px' }}>
                        Generated: {new Date(inv.createdAt).toLocaleDateString()}
                      </div>
                    </td>
                    <td style={{ padding: '16px 24px' }}>
                      <div style={{ fontWeight: 700, color: '#22c55e', fontSize: '15px' }}>₹{inv.totalAmount}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-dim)' }}>{inv.orderCount} Orders</div>
                    </td>
                    <td style={{ padding: '16px 24px' }}>
                      <span style={{ 
                        padding: '6px 12px', 
                        borderRadius: '20px', 
                        fontSize: '11px', 
                        fontWeight: 700,
                        background: inv.status === 'Cleared' ? 'rgba(34, 197, 94, 0.1)' : 'rgba(234, 179, 8, 0.1)',
                        color: inv.status === 'Cleared' ? '#22c55e' : '#eab308'
                      }}>
                        {inv.status}
                      </span>
                    </td>
                    <td style={{ padding: '16px 24px' }}>
                      <div style={{ display: 'flex', gap: '8px' }}>
                        <button 
                          onClick={() => handleDownloadInvoice(inv._id)}
                          className="btn-primary"
                          style={{ padding: '8px', background: 'rgba(99, 102, 241, 0.1)', color: 'var(--primary)', border: 'none' }}
                          title="Download PDF"
                        >
                          <Download size={16} />
                        </button>
                        {inv.status !== 'Cleared' && (
                          <button 
                            onClick={() => handleClearInvoice(inv._id)}
                            className="btn-primary"
                            style={{ padding: '8px', background: 'rgba(34, 197, 94, 0.1)', color: '#22c55e', border: 'none' }}
                            title="Mark as Cleared"
                          >
                            <CheckCircle2 size={16} />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: 'var(--card-bg)' }}>
                  <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-dim)', fontSize: '12px' }}>ORDER ID</th>
                  <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-dim)', fontSize: '12px' }}>CUSTOMER / SELLER</th>
                  <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-dim)', fontSize: '12px' }}>DATE</th>
                  <th style={{ padding: '16px 24px', textAlign: 'left', color: 'var(--text-dim)', fontSize: '12px' }}>AMOUNT</th>
                  <th style={{ padding: '16px 24px', textAlign: 'right', color: 'var(--text-dim)', fontSize: '12px' }}>ACTIONS</th>
                </tr>
              </thead>
              <tbody>
                {filteredOrders.slice(0, 50).map(order => (
                  <tr key={order._id} className="border-b border-[var(--glass-border)] hover:bg-white/5">
                    <td style={{ padding: '16px 24px', fontSize: '13px', fontWeight: 600, color: 'var(--primary)' }}>
                      #{order._id.slice(-8).toUpperCase()}
                      <div style={{ fontSize: '11px', color: 'var(--text-dim)', marginTop: '4px' }}>{order.userId?.role?.toUpperCase() || 'B2C'}</div>
                    </td>
                    <td style={{ padding: '16px 24px' }}>
                      <div style={{ fontSize: '14px', fontWeight: 600, color: 'var(--text-main)' }}>{order.shippingAddress?.name || order.userId?.name || 'Customer'}</div>
                      <div style={{ fontSize: '12px', color: 'var(--text-dim)', marginTop: '2px' }}>Seller: {order.sellerId?.name || 'Zudo Admin'}</div>
                    </td>
                    <td style={{ padding: '16px 24px', fontSize: '13px', color: 'var(--text-dim)' }}>
                      {new Date(order.createdAt).toLocaleDateString()}
                    </td>
                    <td style={{ padding: '16px 24px', fontSize: '14px', fontWeight: 700, color: 'var(--text-main)' }}>
                      ₹{order.totalAmount}
                    </td>
                    <td style={{ padding: '16px 24px', textAlign: 'right' }}>
                      <button 
                        onClick={() => handlePreview([order])}
                        className="btn-primary"
                        style={{ padding: '8px 16px', fontSize: '12px', background: 'rgba(99, 102, 241, 0.1)', color: 'var(--primary)', border: 'none' }}
                      >
                        Preview Single
                      </button>
                    </td>
                  </tr>
                ))}
                {filteredOrders.length > 50 && (
                  <tr>
                    <td colSpan="5" style={{ padding: '16px', textAlign: 'center', color: 'var(--text-dim)', fontSize: '13px' }}>
                      Showing first 50 results. Use filters to narrow down or "Preview All" to print all.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Print Preview Modal */}
      {showPreview && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(10px)', display: 'flex', flexDirection: 'column', zIndex: 9999 }}>
          <div style={{ padding: '20px 32px', borderBottom: '1px solid var(--glass-border)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'var(--card-bg)' }}>
            <div className="flex items-center gap-4">
              <h2 className="text-xl font-bold m-0 flex items-center gap-2" style={{ color: 'var(--text-main)' }}>
                <Printer size={24} style={{ color: 'var(--primary)' }} />
                Invoice Print Preview
              </h2>
              <div className="flex gap-4 ml-8">
                <div className="flex items-center gap-2">
                  <label className="text-xs font-bold uppercase" style={{ color: 'var(--text-dim)' }}>Page Size:</label>
                  <select 
                    className="input-field" 
                    style={{ padding: '6px 12px', minHeight: 'auto', fontSize: '13px', background: 'var(--glass-bg)', color: 'var(--text-main)', border: '1px solid var(--glass-border)' }}
                    value={pageSize}
                    onChange={e => setPageSize(e.target.value)}
                  >
                    <option value="A4">A4 (Standard)</option>
                    <option value="A5">A5 (Half Size)</option>
                  </select>
                </div>
              </div>
            </div>
            <div className="flex gap-4">
              <button 
                onClick={handlePrint}
                className="btn-primary flex items-center gap-2"
                style={{ background: 'linear-gradient(135deg, #10b981, #059669)', boxShadow: '0 4px 15px rgba(16, 185, 129, 0.4)' }}
              >
                <Download size={18} />
                <span>Download / Print PDF</span>
              </button>
              <button onClick={() => setShowPreview(false)} style={{ background: 'none', border: 'none', color: 'var(--text-dim)', cursor: 'pointer', padding: '8px' }}>
                <X size={24} />
              </button>
            </div>
          </div>
          
          <div style={{ flex: 1, overflow: 'auto', padding: '32px', display: 'flex', gap: '32px' }}>
            {/* Editor Sidebar */}
            <div style={{ width: '350px', background: 'var(--card-bg)', borderRadius: '16px', border: '1px solid var(--glass-border)', padding: '20px', display: 'flex', flexDirection: 'column', gap: '16px', overflowY: 'auto' }}>
              <h3 className="text-sm font-bold border-b pb-2 m-0 flex items-center gap-2" style={{ color: 'var(--text-main)', borderColor: 'var(--glass-border)' }}>
                <Edit2 size={16} /> Edit Pricing
              </h3>
              <p className="text-xs" style={{ color: 'var(--text-dim)' }}>Modify the product prices specifically for this invoice printout. This does not change the actual database price.</p>
              
              <div className="flex flex-col gap-6">
                {previewOrders.map(order => (
                  <div key={order._id} className="p-4 rounded-xl border" style={{ background: 'var(--glass-bg)', borderColor: 'var(--glass-border)' }}>
                    <div className="text-xs font-bold mb-3" style={{ color: 'var(--primary)' }}>Order #{order._id.slice(-8).toUpperCase()}</div>
                    <div className="flex flex-col gap-3">
                      {order.items.map((item, index) => {
                        const rawPrice = item.price || 0;
                        const currentPrice = calculateItemPrice(order._id, index, rawPrice);
                        return (
                          <div key={index} className="flex flex-col gap-1">
                            <span className="text-xs truncate" style={{ color: 'var(--text-main)' }}>{item.name}</span>
                            <div className="flex items-center gap-2">
                              <span className="text-xs line-through" style={{ color: 'var(--text-dim)' }}>₹{rawPrice.toFixed(2)}</span>
                              <input 
                                type="number" 
                                className="input-field flex-1"
                                style={{ padding: '6px', fontSize: '13px', minHeight: 'auto' }}
                                value={currentPrice}
                                onChange={e => handlePriceChange(order._id, index, e.target.value)}
                              />
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Preview Document */}
            <div style={{ flex: 1, background: 'var(--glass-bg)', borderRadius: '16px', display: 'flex', flexDirection: 'column', alignItems: 'center', overflowY: 'auto' }}>
              <div 
                style={{ width: '100%' }}
                dangerouslySetInnerHTML={{ __html: generatePrintHTML() }}
              />
            </div>
          </div>
        </div>
      )}

      {/* Hidden Iframe for actual printing */}
      <iframe ref={iframeRef} style={{ display: 'none' }} title="Print Frame" />
    </div>
  );
};

export default Invoices;

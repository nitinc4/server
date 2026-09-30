const fs = require('fs');
const file = 'd:/Office Projects/Zudo-server/server/routes/orders.js';
let content = fs.readFileSync(file, 'utf8');

content = content.replace(/\.populate\('items\.seller\.sellerId', 'name qrCodeDoc qrOption companyName'\)/g, ".populate('items.seller.sellerId', 'name qrCodeDoc qrOption companyName').populate('sellerId', 'name qrCodeDoc qrOption companyName')");

fs.writeFileSync(file, content);

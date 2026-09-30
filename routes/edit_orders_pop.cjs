const fs = require('fs');
const file = 'd:/Office Projects/Zudo-server/server/routes/orders.js';
let content = fs.readFileSync(file, 'utf8');

content = content.replace(/\.populate\('items\.productId'\)/g, ".populate('items.productId').populate('items.seller.sellerId', 'name qrCodeDoc qrOption companyName')");

fs.writeFileSync(file, content);

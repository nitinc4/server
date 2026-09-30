const fs = require('fs');
const file = 'd:/Office Projects/Zudo-server/server/routes/auth.js';
let content = fs.readFileSync(file, 'utf8');

const targetStr = `    } else if (locationId) {
      // 2. Check if the user exists in the tenant's specific database
      const location = await Location.findById(locationId);
      if (location) {
        tenantDbName = \`zudo-\${location.city.toLowerCase().replace(/\\s+/g, '-')}\`;
        const tenantConn = await connectDBByLocation(locationId, tenantDbName);
        const TenantAdmin = tenantConn.models.Admin || tenantConn.model('Admin', Admin.schema);
        admin = await TenantAdmin.findOne({ email: new RegExp(\`^\${emailToSearch}$\`, 'i') });
        logToFile(\`Checked tenant Admin collection. Found: \${!!admin}\`);
        if (!admin) {
          const TenantSales = tenantConn.models.Sales || tenantConn.model('Sales', Admin.schema, 'sales');
          admin = await TenantSales.findOne({ email: new RegExp(\`^\${emailToSearch}$\`, 'i') });
          logToFile(\`Checked tenant Sales collection. Found: \${!!admin}\`);
        }
        if (admin) isTenantAdmin = true;
      }
    }`;

const replaceStr = `    } else if (locationId) {
      // 2. Check if the user exists in the tenant's specific database
      const location = await Location.findById(locationId);
      if (location) {
        tenantDbName = \`zudo-\${location.city.toLowerCase().replace(/\\s+/g, '-')}\`;
        const tenantConn = await connectDBByLocation(locationId, tenantDbName);
        const TenantAdmin = tenantConn.models.Admin || tenantConn.model('Admin', Admin.schema);
        admin = await TenantAdmin.findOne({ email: new RegExp(\`^\${emailToSearch}$\`, 'i') });
        logToFile(\`Checked tenant Admin collection. Found: \${!!admin}\`);
        if (!admin) {
          const TenantSales = tenantConn.models.Sales || tenantConn.model('Sales', Admin.schema, 'sales');
          admin = await TenantSales.findOne({ email: new RegExp(\`^\${emailToSearch}$\`, 'i') });
          logToFile(\`Checked tenant Sales collection. Found: \${!!admin}\`);
        }
        if (admin) isTenantAdmin = true;
      }
    } else if (!admin) {
      // 3. Scan all tenant databases if admin not found globally and no locationId provided
      logToFile(\`Scanning all tenant DBs for user...\`);
      const LocationModel = req.models?.Location || Location;
      const locations = await LocationModel.find({ isActive: true });
      for (const loc of locations) {
        const tempDbName = \`zudo-\${loc.city.toLowerCase().replace(/\\s+/g, '-')}\`;
        const tenantConn = await connectDBByLocation(loc._id.toString(), tempDbName);
        const TenantAdmin = tenantConn.models.Admin || tenantConn.model('Admin', Admin.schema);
        admin = await TenantAdmin.findOne({ email: new RegExp(\`^\${emailToSearch}$\`, 'i') });
        if (!admin) {
          const TenantSales = tenantConn.models.Sales || tenantConn.model('Sales', Admin.schema, 'sales');
          admin = await TenantSales.findOne({ email: new RegExp(\`^\${emailToSearch}$\`, 'i') });
        }
        if (admin) {
          tenantDbName = tempDbName;
          isTenantAdmin = true;
          logToFile(\`Found user in tenant DB during scan: \${tenantDbName}\`);
          break;
        }
      }
    }`;

if(content.includes(targetStr)) {
  content = content.replace(targetStr, replaceStr);
  fs.writeFileSync(file, content);
  console.log('Successfully updated auth.js to scan tenant DBs');
} else {
  console.log('Target string not found');
}

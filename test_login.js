async function test() {
  const res = await fetch('http://localhost:5000/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'zudo.superadmin@gmail.com', password: 'Zudo@12345' })
  });
  const data = await res.json();
  const token = data.token;
  
  const globalRes = await fetch('http://localhost:5000/api/products', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const globalProducts = await globalRes.json();
  console.log(`Global Products:`, globalProducts.length || globalProducts);

  const locRes = await fetch('http://localhost:5000/api/locations', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const locations = await locRes.json();
  
  const blr = locations.find(l => l.city.toLowerCase().includes('bengaluru'));
  if (blr) {
    const prodRes = await fetch('http://localhost:5000/api/products', {
      headers: { 'Authorization': `Bearer ${token}`, 'x-tenant-id': blr._id }
    });
    const products = await prodRes.json();
    console.log(`Products in ${blr.city}:`, products.length || products);
  }
}
test();

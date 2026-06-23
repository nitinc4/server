const axios = require('axios');

async function testOrdersApi() {
  try {
    // 1. Login
    const loginRes = await axios.post('http://localhost:5000/api/sellers/login', {
      email: 'seller@test.com',
      password: 'password123'
    });
    
    const token = loginRes.data.token;
    console.log('Login successful');

    // 2. Fetch Orders
    const ordersRes = await axios.get('http://localhost:5000/api/sellers/orders', {
      headers: { Authorization: `Bearer ${token}` }
    });

    console.log('Orders found via API:', ordersRes.data.length);
    if (ordersRes.data.length > 0) {
      console.log('First Order ID:', ordersRes.data[0]._id);
    } else {
      console.log('API returned empty array');
    }

  } catch (error) {
    console.error('API Test failed:', error.response?.data || error.message);
  }
}

testOrdersApi();

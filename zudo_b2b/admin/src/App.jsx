import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import DashboardLayout from './components/DashboardLayout';
import Dashboard from './pages/Dashboard';
import Products from './pages/Products';
import Categories from './pages/Categories';
import Drivers from './pages/Drivers';
import Admins from './pages/Admins';
import BulkUpload from './pages/BulkUpload';
import B2BVerification from './pages/B2BVerification';
import Users from './pages/Users';
import Orders from './pages/Orders';
import Reviews from './pages/Reviews';
import Deliveries from './pages/Deliveries';
import Sellers from './pages/Sellers';
import Deposits from './pages/Deposits';

const ProtectedRoute = ({ children }) => {
  const token = localStorage.getItem('zudo_admin_token');
  return token ? children : <Navigate to="/login" />;
};

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route
          path="/*"
          element={
            <ProtectedRoute>
              <DashboardLayout>
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/products" element={<Products />} />
                  <Route path="/categories" element={<Categories />} />
                  <Route path="/drivers" element={<Drivers />} />
                  <Route path="/admins" element={<Admins />} />
                  <Route path="/bulk-upload" element={<BulkUpload />} />
                  <Route path="/b2b-verification" element={<B2BVerification />} />
                  <Route path="/users" element={<Users />} />
                  <Route path="/orders" element={<Orders />} />
                  <Route path="/reviews" element={<Reviews />} />
                  <Route path="/deliveries" element={<Deliveries />} />
                  <Route path="/deposits" element={<Deposits />} />
                  <Route path="/sellers" element={<Sellers />} />
                </Routes>
              </DashboardLayout>
            </ProtectedRoute>
          }
        />
      </Routes>
    </Router>
  );
}

export default App;

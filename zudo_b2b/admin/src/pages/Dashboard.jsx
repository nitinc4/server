import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Package, Layers, Truck, Users, TrendingUp, ShoppingBag } from 'lucide-react';

const StatCard = ({ title, value, icon: Icon, color }) => (
  <div className="glass-card" style={{ flex: 1, padding: '24px', borderRadius: '24px', display: 'flex', alignItems: 'center', gap: '20px' }}>
    <div style={{ 
      padding: '16px', 
      background: `${color}15`, 
      color: color, 
      borderRadius: '16px' 
    }}>
      <Icon size={24} />
    </div>
    <div>
      <p style={{ color: '#94a3b8', fontSize: '14px', marginBottom: '4px' }}>{title}</p>
      <h3 style={{ fontSize: '24px', fontWeight: 700 }}>{value}</h3>
    </div>
  </div>
);

const Dashboard = () => {
  const [stats, setStats] = useState({ products: 0, categories: 0, drivers: 0 });

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const [p, c, d] = await Promise.all([
          api.get('/products'),
          api.get('/categories'),
          api.get('/drivers')
        ]);
        setStats({
          products: p.data.length,
          categories: c.data.length,
          drivers: d.data.length
        });
      } catch (err) {
        console.error(err);
      }
    };
    fetchStats();
  }, []);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      <div style={{ display: 'flex', gap: '24px' }}>
        <StatCard title="Total Products" value={stats.products} icon={Package} color="#6366f1" />
        <StatCard title="Categories" value={stats.categories} icon={Layers} color="#ec4899" />
        <StatCard title="Active Drivers" value={stats.drivers} icon={Truck} color="#8b5cf6" />
        <StatCard title="Active Admins" value="1" icon={Users} color="#10b981" />
      </div>

      <div style={{ display: 'flex', gap: '24px' }}>
        <div className="glass-card" style={{ flex: 2, padding: '32px', borderRadius: '24px', minHeight: '300px' }}>
          <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '24px' }}>Inventory Overview</h3>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '200px', color: '#475569', border: '1px dashed rgba(255,255,255,0.05)', borderRadius: '16px' }}>
            Analytics Chart Placeholder
          </div>
        </div>

        <div className="glass-card" style={{ flex: 1, padding: '32px', borderRadius: '24px' }}>
          <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '24px' }}>Quick Actions</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <button className="btn-primary" style={{ background: 'rgba(255,255,255,0.05)', textAlign: 'left', padding: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
              <ShoppingBag size={18} />
              <span>Process New Orders</span>
            </button>
            <button className="btn-primary" style={{ background: 'rgba(255,255,255,0.05)', textAlign: 'left', padding: '16px', display: 'flex', alignItems: 'center', gap: '12px' }}>
              <TrendingUp size={18} />
              <span>View Sales Reports</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;

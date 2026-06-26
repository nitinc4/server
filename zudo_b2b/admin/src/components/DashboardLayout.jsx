import React from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { 
  LayoutDashboard, 
  Package, 
  Layers, 
  Truck, 
  Users, 
  Upload, 
  LogOut,
  ChevronRight,
  ShieldCheck,
  ShoppingBag,
  MessageSquare,
  BarChart3,
  Store,
  Wallet
} from 'lucide-react';

const SidebarItem = ({ to, icon: Icon, label, active }) => (
  <Link 
    to={to} 
    className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-300 ${
      active 
        ? 'bg-gradient-to-r from-indigo-600 to-violet-600 text-white shadow-lg shadow-indigo-500/20' 
        : 'text-slate-400 hover:text-white hover:bg-white/5'
    }`}
    style={{
      textDecoration: 'none',
      marginBottom: '8px',
      display: 'flex',
      alignItems: 'center',
      gap: '12px',
      padding: '12px 16px',
      borderRadius: '12px',
      transition: '0.3s'
    }}
  >
    <Icon size={20} />
    <span style={{ fontWeight: 500 }}>{label}</span>
  </Link>
);

const DashboardLayout = ({ children }) => {
  const location = useLocation();
  const navigate = useNavigate();
  const admin = JSON.parse(localStorage.getItem('zudo_admin_user') || '{}');

  const handleLogout = () => {
    localStorage.removeItem('zudo_admin_token');
    localStorage.removeItem('zudo_admin_user');
    navigate('/login');
  };

  const menuItems = [
    { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
    { to: '/products', icon: Package, label: 'Products' },
    { to: '/categories', icon: Layers, label: 'Categories' },
    { to: '/drivers', icon: Truck, label: 'Drivers' },
    { to: '/admins', icon: Users, label: 'Admins' },
    { to: '/bulk-upload', icon: Upload, label: 'Bulk Upload' },
    { to: '/b2b-verification', icon: ShieldCheck, label: 'B2B Verification' },
    { to: '/users', icon: Users, label: 'Users' },
    { to: '/orders', icon: ShoppingBag, label: 'Orders' },
    { to: '/reviews', icon: MessageSquare, label: 'Reviews' },
    { to: '/deliveries', icon: BarChart3, label: 'Deliveries' },
    { to: '/deposits', icon: Wallet, label: 'Deposits' },
    { to: '/sellers', icon: Store, label: 'Sellers' },
  ];

  return (
    <div style={{ display: 'flex', minHeight: '100vh' }}>
      {/* Sidebar */}
      <aside className="glass" style={{ 
        width: '280px', 
        padding: '32px 16px', 
        margin: '16px', 
        display: 'flex', 
        flexDirection: 'column',
        position: 'fixed',
        height: 'calc(100vh - 32px)',
        zIndex: 10
      }}>
        <div style={{ padding: '0 16px 32px' }}>
          <h1 style={{ 
            fontSize: '28px', 
            fontWeight: 800, 
            background: 'linear-gradient(135deg, #6366f1, #ec4899)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent'
          }}>ZUDO</h1>
          <p style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>Admin Panel v1.0</p>
        </div>

        <nav style={{ flex: 1 }}>
          {menuItems.map((item) => (
            <Link 
              key={item.to}
              to={item.to}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '12px 16px',
                borderRadius: '12px',
                marginBottom: '8px',
                textDecoration: 'none',
                color: location.pathname === item.to ? '#fff' : '#94a3b8',
                background: location.pathname === item.to ? 'linear-gradient(135deg, #6366f1, #8b5cf6)' : 'transparent',
                transition: '0.3s',
                boxShadow: location.pathname === item.to ? '0 4px 15px rgba(99, 102, 241, 0.3)' : 'none'
              }}
            >
              <item.icon size={20} />
              <span style={{ fontWeight: 500 }}>{item.label}</span>
            </Link>
          ))}
        </nav>

        <div className="glass-card" style={{ padding: '16px', borderRadius: '16px', marginTop: 'auto' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
            <div style={{ 
              width: '40px', 
              height: '40px', 
              borderRadius: '10px', 
              background: 'linear-gradient(135deg, #ec4899, #8b5cf6)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: 'bold'
            }}>
              {admin.name?.[0]}
            </div>
            <div>
              <p style={{ fontSize: '14px', fontWeight: 600 }}>{admin.name}</p>
              <p style={{ fontSize: '11px', color: '#94a3b8' }}>{admin.role}</p>
            </div>
          </div>
          <button 
            onClick={handleLogout}
            style={{ 
              width: '100%', 
              padding: '10px', 
              borderRadius: '10px', 
              border: 'none', 
              background: 'rgba(255,255,255,0.05)', 
              color: '#f8fafc',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              gap: '8px',
              cursor: 'pointer'
            }}
          >
            <LogOut size={18} />
            <span>Logout</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main style={{ flex: 1, marginLeft: '312px', padding: '32px' }}>
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '32px' }}>
          <h2 style={{ fontSize: '24px', fontWeight: 700 }}>
            {menuItems.find(i => i.to === location.pathname)?.label || 'Dashboard'}
          </h2>
          <div style={{ display: 'flex', gap: '16px' }}>
            <div style={{ fontSize: '14px', color: '#94a3b8' }}>
              {new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
            </div>
          </div>
        </header>

        <div style={{ position: 'relative' }}>
          {children}
        </div>
      </main>
    </div>
  );
};

export default DashboardLayout;

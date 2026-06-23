import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Truck, Plus, Search, Mail, Phone, Hash, Car, Loader2, CheckCircle2, Trash2 } from 'lucide-react';

const Drivers = () => {
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    email: '',
    password: '',
    licenseNumber: '',
    vehicleDetails: ''
  });
  const [submitting, setSubmitting] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [history, setHistory] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);

  useEffect(() => {
    fetchDrivers();
  }, []);

  const fetchDrivers = async () => {
    try {
      const { data } = await api.get('/drivers');
      setDrivers(data);
    } catch (err) {
      console.error('Failed to fetch drivers', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchDriverHistory = async (driver) => {
    setSelectedDriver(driver);
    setShowHistory(true);
    setLoadingHistory(true);
    try {
      const { data } = await api.get(`/orders/admin/all`);
      const driverOrders = data.filter(order => order.driverId?._id === driver._id);
      setHistory(driverOrders);
    } catch (err) {
      console.error('Failed to fetch history', err);
    } finally {
      setLoadingHistory(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this driver?')) return;
    try {
      await api.delete(`/drivers/${id}`);
      fetchDrivers();
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to delete driver');
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      await api.post('/drivers', formData);
      setShowModal(false);
      setFormData({ name: '', phone: '', email: '', password: '', licenseNumber: '', vehicleDetails: '' });
      fetchDrivers();
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to create driver');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ position: 'relative', width: '300px' }}>
          <Search size={18} style={{ position: 'absolute', left: '12px', top: '10px', color: '#64748b' }} />
          <input type="text" placeholder="Search drivers..." className="input-field" style={{ paddingLeft: '40px', paddingBottom: '10px', paddingTop: '10px' }} />
        </div>
        <button className="btn-primary" onClick={() => setShowModal(true)} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Plus size={20} />
          <span>Add Driver</span>
        </button>
      </div>

      <div className="glass-card" style={{ borderRadius: '24px', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', background: 'rgba(255,255,255,0.02)' }}>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Driver Name</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Contact info</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>License No.</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Vehicle</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Status</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="5" style={{ padding: '48px', textAlign: 'center' }}>
                  <Loader2 className="animate-spin" style={{ margin: '0 auto', color: '#6366f1' }} />
                </td>
              </tr>
            ) : drivers.length === 0 ? (
              <tr>
                <td colSpan="6" style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>No drivers found</td>
              </tr>
            ) : drivers.map((driver) => (
              <tr 
                key={driver._id} 
                style={{ borderBottom: '1px solid rgba(255,255,255,0.03)', cursor: 'pointer' }} 
                className="hover:bg-white/5 transition-colors"
                onClick={() => fetchDriverHistory(driver)}
              >
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                      {driver.name[0]}
                    </div>
                    <span>{driver.name}</span>
                  </div>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', fontSize: '13px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#94a3b8' }}>
                      <Phone size={12} /> {driver.phone}
                    </div>
                    {driver.email && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#94a3b8' }}>
                        <Mail size={12} /> {driver.email}
                      </div>
                    )}
                  </div>
                </td>
                <td style={{ padding: '16px 24px', fontFamily: 'monospace' }}>{driver.licenseNumber}</td>
                <td style={{ padding: '16px 24px' }}>{driver.vehicleDetails}</td>
                <td style={{ padding: '16px 24px' }}>
                  <span style={{ 
                    padding: '4px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 600,
                    background: driver.status === 'active' ? 'rgba(34, 197, 94, 0.1)' : 'rgba(239, 68, 68, 0.1)',
                    color: driver.status === 'active' ? '#22c55e' : '#ef4444'
                  }}>
                    {driver.status.toUpperCase()}
                  </span>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <button 
                    onClick={(e) => {
                      e.stopPropagation();
                      handleDelete(driver._id);
                    }}
                    style={{ 
                      background: 'none', border: 'none', color: '#ef4444', 
                      cursor: 'pointer', padding: '8px', borderRadius: '8px',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      transition: 'background 0.2s'
                    }}
                    onMouseOver={(e) => e.currentTarget.style.background = 'rgba(239, 68, 68, 0.1)'}
                    onMouseOut={(e) => e.currentTarget.style.background = 'none'}
                  >
                    <Trash2 size={18} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Driver History Modal */}
      {showHistory && (
        <div style={{ 
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          background: 'rgba(0,0,0,0.8)', backdropFilter: 'blur(8px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100
        }}>
          <div className="glass" style={{ width: '100%', maxWidth: '800px', padding: '32px', borderRadius: '32px', maxHeight: '85vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <div>
                <h3 style={{ fontSize: '22px', fontWeight: 800 }}>{selectedDriver.name}'s Delivery History</h3>
                <p style={{ color: '#94a3b8', fontSize: '14px' }}>Complete log of assigned shipments</p>
              </div>
              <button onClick={() => setShowHistory(false)} style={{ background: 'rgba(255,255,255,0.05)', border: 'none', color: 'white', padding: '10px', borderRadius: '50%', cursor: 'pointer' }}>
                <XCircle size={20} />
              </button>
            </div>

            {loadingHistory ? (
              <div style={{ padding: '60px', textAlign: 'center' }}>
                <Loader2 className="animate-spin mx-auto text-indigo-500" size={32} />
              </div>
            ) : history.length === 0 ? (
              <div style={{ padding: '60px', textAlign: 'center', color: '#94a3b8' }}>No delivery history found for this driver.</div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                {history.map(order => (
                  <div key={order._id} style={{ padding: '20px', borderRadius: '20px', background: 'rgba(255,255,255,0.02)', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <div>
                      <div style={{ fontWeight: 'bold', fontSize: '15px' }}>Order #{order._id.slice(-8).toUpperCase()}</div>
                      <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>
                        {new Date(order.createdAt).toLocaleDateString()} • {order.items.length} Items • ₹{order.totalAmount}
                      </div>
                    </div>
                    <span style={{ 
                      padding: '4px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 600,
                      background: order.orderStatus === 'Delivered' ? 'rgba(34, 197, 94, 0.1)' : 'rgba(99, 102, 241, 0.1)',
                      color: order.orderStatus === 'Delivered' ? '#22c55e' : '#6366f1'
                    }}>
                      {order.orderStatus.toUpperCase()}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Add Driver Modal */}
      {showModal && (
        <div style={{ 
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100
        }}>
          <div className="glass" style={{ width: '100%', maxWidth: '500px', padding: '32px', borderRadius: '24px' }}>
            <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '24px' }}>Register New Driver</h3>
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <input 
                type="text" placeholder="Full Name" className="input-field" required
                value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})}
              />
              <input 
                type="tel" placeholder="Phone Number" className="input-field" required
                value={formData.phone} onChange={(e) => setFormData({...formData, phone: e.target.value})}
              />
              <input 
                type="email" placeholder="Email Address (Optional)" className="input-field"
                value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value})}
              />
              <input 
                type="password" placeholder="Driver App Password" className="input-field" required
                value={formData.password} onChange={(e) => setFormData({...formData, password: e.target.value})}
              />
              <input 
                type="text" placeholder="License Number" className="input-field" required
                value={formData.licenseNumber} onChange={(e) => setFormData({...formData, licenseNumber: e.target.value})}
              />
              <textarea 
                placeholder="Vehicle Details (Model, Plate No.)" className="input-field" style={{ minHeight: '80px' }} required
                value={formData.vehicleDetails} onChange={(e) => setFormData({...formData, vehicleDetails: e.target.value})}
              />
              <div style={{ display: 'flex', gap: '12px', marginTop: '8px' }}>
                <button type="button" onClick={() => setShowModal(false)} style={{ flex: 1, padding: '12px', borderRadius: '12px', border: 'none', background: 'rgba(255,255,255,0.05)', color: 'white', cursor: 'pointer' }}>Cancel</button>
                <button type="submit" className="btn-primary" style={{ flex: 2 }} disabled={submitting}>
                  {submitting ? <Loader2 className="animate-spin" /> : 'Register Driver'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Drivers;

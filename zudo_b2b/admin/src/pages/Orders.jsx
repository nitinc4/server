import React, { useState, useEffect } from 'react';
import axios from '../utils/api';
import { Package, Truck, CheckCircle, XCircle, Clock, MapPin, Phone, User, Send, Loader2, Search, Filter } from 'lucide-react';

const Orders = () => {
  const [orders, setOrders] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedOrderId, setSelectedOrderId] = useState(null);
  const [showDriverModal, setShowDriverModal] = useState(false);
  const [assigning, setAssigning] = useState(false);
  const [activeTab, setActiveTab] = useState('All');

  const statuses = ['All', 'Pending', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled'];

  useEffect(() => {
    fetchOrders();
    fetchDrivers();
  }, []);

  const fetchOrders = async () => {
    try {
      const { data } = await axios.get('/orders/admin/all');
      setOrders(data);
    } catch (error) {
      console.error('Error fetching orders:', error);
    } finally {
      setLoading(false);
    }
  };

  const fetchDrivers = async () => {
    try {
      const { data } = await axios.get('/drivers');
      setDrivers(data.filter(d => d.status === 'active'));
    } catch (error) {
      console.error('Error fetching drivers:', error);
    }
  };

  const handleShipOrder = async (driverId) => {
    setAssigning(true);
    try {
      await axios.put(`/orders/${selectedOrderId}/ship`, { driverId });
      setShowDriverModal(false);
      fetchOrders();
    } catch (error) {
      alert('Failed to ship order');
    } finally {
      setAssigning(false);
    }
  };

  const handleCancelOrder = async (orderId) => {
    if (!window.confirm('Are you sure you want to cancel this order?')) return;
    try {
      await axios.put(`/orders/${orderId}/cancel`);
      fetchOrders();
    } catch (error) {
      alert('Failed to cancel order');
    }
  };

  const getStatusBadge = (status) => {
    const styles = {
      'Pending': { bg: 'rgba(234, 179, 8, 0.1)', color: '#eab308' },
      'Shipped': { bg: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6' },
      'Out for Delivery': { bg: 'rgba(168, 85, 247, 0.1)', color: '#a855f7' },
      'Delivered': { bg: 'rgba(34, 197, 94, 0.1)', color: '#22c55e' },
      'Cancelled': { bg: 'rgba(239, 68, 68, 0.1)', color: '#ef4444' }
    };
    const style = styles[status] || { bg: 'rgba(148, 163, 184, 0.1)', color: '#94a3b8' };
    return (
      <span style={{ padding: '4px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 700, background: style.bg, color: style.color, textTransform: 'uppercase' }}>
        {status}
      </span>
    );
  };

  const filteredOrders = activeTab === 'All' 
    ? orders 
    : orders.filter(order => order.orderStatus === activeTab);

  if (loading) return (
    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '60vh', gap: '16px' }}>
      <Loader2 className="animate-spin" style={{ color: '#6366f1' }} size={40} />
      <div style={{ color: '#94a3b8', fontWeight: 500 }}>Synchronizing Orders...</div>
    </div>
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '20px' }}>
        <div style={{ display: 'flex', background: 'rgba(255,255,255,0.05)', padding: '4px', borderRadius: '16px', overflowX: 'auto', maxWidth: '100%' }}>
          {statuses.map(status => (
            <button
              key={status}
              onClick={() => setActiveTab(status)}
              style={{
                padding: '10px 20px',
                borderRadius: '12px',
                fontSize: '13px',
                fontWeight: 700,
                border: 'none',
                cursor: 'pointer',
                transition: '0.3s',
                whiteSpace: 'nowrap',
                background: activeTab === status ? '#6366f1' : 'transparent',
                color: activeTab === status ? 'white' : '#94a3b8',
                boxShadow: activeTab === status ? '0 4px 15px rgba(99, 102, 241, 0.3)' : 'none'
              }}
            >
              {status}
            </button>
          ))}
        </div>

        <div className="glass-card" style={{ padding: '8px 16px', borderRadius: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Clock size={16} style={{ color: '#6366f1' }} />
          <span style={{ fontSize: '13px', color: '#94a3b8', fontWeight: 600 }}>Live Feed Active</span>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
        {filteredOrders.map((order) => (
          <div key={order._id} className="glass-card" style={{ borderRadius: '24px', overflow: 'hidden' }}>
            <div style={{ padding: '20px 24px', background: 'rgba(255,255,255,0.02)', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                <div style={{ display: 'flex', flexDirection: 'column' }}>
                  <span style={{ fontSize: '11px', color: '#64748b', fontWeight: 700, textTransform: 'uppercase' }}>Transaction ID</span>
                  <span style={{ fontWeight: 700, fontSize: '14px', fontFamily: 'monospace' }}>#{order._id.slice(-12).toUpperCase()}</span>
                </div>
                <div style={{ width: '1px', height: '24px', background: 'rgba(255,255,255,0.1)' }}></div>
                <div style={{ display: 'flex', flexDirection: 'column' }}>
                  <span style={{ fontSize: '11px', color: '#64748b', fontWeight: 700, textTransform: 'uppercase' }}>Placed On</span>
                  <span style={{ fontWeight: 600, fontSize: '14px' }}>{new Date(order.createdAt).toLocaleDateString()}</span>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '24px' }}>
                <div style={{ textAlign: 'right' }}>
                  <span style={{ fontSize: '11px', color: '#64748b', fontWeight: 700, textTransform: 'uppercase', display: 'block' }}>Total Volume</span>
                  <span style={{ fontWeight: 800, fontSize: '18px', color: '#6366f1' }}>₹{order.totalAmount}</span>
                </div>
                {getStatusBadge(order.orderStatus)}
              </div>
            </div>

            <div style={{ padding: '24px', display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '32px' }}>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#94a3b8', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px' }}>
                  <User size={14} /> Dispatch Intel
                </div>
                <div style={{ padding: '16px', background: 'rgba(255,255,255,0.02)', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.05)' }}>
                  <div style={{ fontWeight: 700, fontSize: '16px', marginBottom: '4px' }}>{order.userId?.name || 'Guest'}</div>
                  <div style={{ fontSize: '13px', color: '#94a3b8', display: 'flex', alignItems: 'center', gap: '6px' }}><Phone size={12} /> +91 {order.shippingAddress.phone}</div>
                </div>
                <div style={{ padding: '16px', background: 'rgba(99, 102, 241, 0.03)', borderRadius: '16px', border: '1px solid rgba(99, 102, 241, 0.1)' }}>
                  <div style={{ fontSize: '10px', color: '#6366f1', fontWeight: 800, textTransform: 'uppercase', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}><MapPin size={10} /> Target Destination</div>
                  <div style={{ fontSize: '13px', color: '#cbd5e1', lineHeight: '1.6' }}>
                    {order.shippingAddress.address}<br />
                    <span style={{ color: '#6366f1', fontWeight: 600 }}>{order.shippingAddress.city}, {order.shippingAddress.state}</span> - {order.shippingAddress.pincode}
                  </div>
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#94a3b8', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px' }}>
                  <Package size={14} /> Manifest Contents
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                  {order.items.map((item, idx) => (
                    <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', background: 'rgba(255,255,255,0.01)', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.03)' }}>
                      <img src={item.image} alt="" style={{ width: '48px', height: '48px', borderRadius: '10px', objectFit: 'cover' }} />
                      <div style={{ flex: 1 }}>
                        <div style={{ fontWeight: 600, fontSize: '14px' }}>{item.name}</div>
                        <div style={{ fontSize: '11px', color: '#64748b' }}>Qty: {item.quantity} × ₹{item.price}</div>
                      </div>
                      <div style={{ fontWeight: 700 }}>₹{item.price * item.quantity}</div>
                    </div>
                  ))}
                </div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#94a3b8', fontSize: '12px', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '1px' }}>
                  <Truck size={14} /> Logistics Control
                </div>
                
                {order.driverId ? (
                  <div style={{ padding: '16px', background: 'rgba(255,255,255,0.02)', borderRadius: '16px', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: '#6366f1', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>{order.driverId?.name?.[0] || 'D'}</div>
                    <div>
                      <div style={{ fontWeight: 700, fontSize: '14px' }}>{order.driverId?.name || 'Assigned Driver'}</div>
                      <div style={{ fontSize: '11px', color: '#64748b' }}>{order.driverId?.phone || 'No phone provided'}</div>
                    </div>
                  </div>
                ) : (
                  <div style={{ padding: '16px', background: 'rgba(255,255,255,0.01)', border: '1px dashed rgba(255,255,255,0.1)', borderRadius: '16px', textAlign: 'center', color: '#475569', fontSize: '13px' }}>
                    No courier assigned
                  </div>
                )}

                <div style={{ display: 'flex', gap: '10px', marginTop: 'auto' }}>
                  <button 
                    onClick={() => handleCancelOrder(order._id)}
                    disabled={['Cancelled', 'Delivered'].includes(order.orderStatus)}
                    className="btn-danger"
                    style={{ 
                      flex: 1, padding: '12px', fontSize: '12px', borderRadius: '12px', border: 'none',
                      background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', fontWeight: 700, cursor: 'pointer',
                      opacity: ['Cancelled', 'Delivered'].includes(order.orderStatus) ? 0.3 : 1 
                    }}
                  >
                    Cancel
                  </button>
                  {order.orderStatus === 'Pending' && (
                    <button 
                      onClick={() => { setSelectedOrderId(order._id); setShowDriverModal(true); }}
                      style={{ 
                        flex: 2, padding: '12px', fontSize: '12px', borderRadius: '12px', border: 'none',
                        background: 'linear-gradient(135deg, #6366f1, #8b5cf6)', color: 'white', fontWeight: 800, 
                        cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px',
                        boxShadow: '0 4px 15px rgba(99, 102, 241, 0.3)'
                      }}
                    >
                      <Send size={14} /> Ship Now
                    </button>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
        {filteredOrders.length === 0 && (
          <div style={{ padding: '80px', textAlign: 'center', color: '#475569' }}>
            <Package size={64} style={{ margin: '0 auto 24px', opacity: 0.1 }} />
            <p style={{ fontSize: '18px', fontWeight: 600 }}>No orders found in this category</p>
          </div>
        )}
      </div>

      {showDriverModal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', backdropFilter: 'blur(10px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100, padding: '24px' }}>
          <div className="glass-card" style={{ width: '100%', maxWidth: '400px', borderRadius: '32px', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.1)' }}>
            <div style={{ padding: '32px', borderBottom: '1px solid rgba(255,255,255,0.05)', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'rgba(255,255,255,0.02)' }}>
              <div>
                <h3 style={{ fontSize: '20px', fontWeight: 800, margin: 0 }}>Select Courier</h3>
                <p style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>Assign driver for shipment</p>
              </div>
              <button onClick={() => setShowDriverModal(false)} style={{ background: 'transparent', border: 'none', color: '#475569', cursor: 'pointer' }}>
                <XCircle size={24} />
              </button>
            </div>
            <div style={{ padding: '24px', maxHeight: '400px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px' }}>
              {drivers.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '40px', color: '#475569' }}>No active drivers available</div>
              ) : drivers.map(driver => (
                <button
                  key={driver._id}
                  disabled={assigning}
                  onClick={() => handleShipOrder(driver._id)}
                  style={{ 
                    display: 'flex', alignItems: 'center', gap: '16px', padding: '16px', borderRadius: '20px', 
                    background: 'rgba(255,255,255,0.03)', border: '1px solid rgba(255,255,255,0.05)', color: 'white', 
                    cursor: 'pointer', textAlign: 'left', transition: '0.3s'
                  }}
                  onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(99, 102, 241, 0.1)'; e.currentTarget.style.borderColor = '#6366f1'; }}
                  onMouseLeave={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.03)'; e.currentTarget.style.borderColor = 'rgba(255,255,255,0.05)'; }}
                >
                  <div style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                    {driver.name?.[0] || 'D'}
                  </div>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontWeight: 700, fontSize: '15px' }}>{driver.name || 'Unnamed Driver'}</div>
                    <div style={{ fontSize: '11px', color: '#64748b' }}>{driver.vehicleDetails || 'No vehicle details'}</div>
                  </div>
                  <Send size={16} style={{ color: '#6366f1' }} />
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Orders;

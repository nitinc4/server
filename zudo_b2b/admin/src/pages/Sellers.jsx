import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Users, UserPlus, Loader2, CheckCircle2, AlertCircle, Mail, User, Shield, ExternalLink } from 'lucide-react';

const Sellers = () => {
  const [sellers, setSellers] = useState([]);
  const [showCreate, setShowCreate] = useState(false);
  const [loading, setLoading] = useState(false);
  const [fetchLoading, setFetchLoading] = useState(true);
  const [status, setStatus] = useState({ type: '', message: '' });

  const [createData, setCreateData] = useState({ name: '', email: '', password: '' });

  const fetchSellers = async () => {
    try {
      const { data } = await api.get('/sellers');
      setSellers(data);
    } catch (err) {
      console.error('Failed to fetch sellers:', err);
    } finally {
      setFetchLoading(false);
    }
  };

  useEffect(() => {
    fetchSellers();
  }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      await api.post('/sellers', createData);
      setStatus({ type: 'success', message: 'New seller account created successfully!' });
      setShowCreate(false);
      setCreateData({ name: '', email: '', password: '' });
      fetchSellers();
    } catch (err) {
      setStatus({ type: 'error', message: err.response?.data?.message || 'Failed to create seller.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      {status.message && (
        <div style={{ 
          background: status.type === 'success' ? 'rgba(34, 197, 94, 0.1)' : 'rgba(239, 68, 68, 0.1)', 
          border: `1px solid ${status.type === 'success' ? 'rgba(34, 197, 94, 0.2)' : 'rgba(239, 68, 68, 0.2)'}`, 
          color: status.type === 'success' ? '#22c55e' : '#ef4444', 
          padding: '16px', borderRadius: '12px', display: 'flex', alignItems: 'center', gap: '12px'
        }}>
          {status.type === 'success' ? <CheckCircle2 size={20} /> : <AlertCircle size={20} />}
          <span style={{ fontSize: '14px' }}>{status.message}</span>
        </div>
      )}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{ padding: '12px', background: 'rgba(99, 102, 241, 0.1)', borderRadius: '12px', color: '#6366f1' }}>
            <Users size={24} />
          </div>
          <div>
            <h3 style={{ fontSize: '18px', fontWeight: 700 }}>Sellers Management</h3>
            <p style={{ fontSize: '12px', color: '#94a3b8' }}>Manage and monitor all platform sellers</p>
          </div>
        </div>
        <button 
          className="btn-primary" 
          style={{ display: 'flex', alignItems: 'center', gap: '8px' }} 
          onClick={() => setShowCreate(!showCreate)}
        >
          <UserPlus size={18} />
          <span>{showCreate ? 'Cancel' : 'Add New Seller'}</span>
        </button>
      </div>

      {showCreate && (
        <div className="glass-card" style={{ padding: '32px', borderRadius: '24px' }}>
          <form onSubmit={handleCreate}>
            <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '24px' }}>Create Seller Account</h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px', marginBottom: '16px' }}>
              <input 
                type="text" 
                placeholder="Seller Name" 
                className="input-field" 
                required 
                value={createData.name} 
                onChange={e => setCreateData({...createData, name: e.target.value})} 
              />
              <input 
                type="email" 
                placeholder="Email Address" 
                className="input-field" 
                required 
                value={createData.email} 
                onChange={e => setCreateData({...createData, email: e.target.value})} 
              />
              <input 
                type="password" 
                placeholder="Initial Password" 
                className="input-field" 
                required 
                value={createData.password} 
                onChange={e => setCreateData({...createData, password: e.target.value})} 
              />
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
              <button type="submit" className="btn-primary" disabled={loading}>
                {loading ? <Loader2 className="animate-spin" /> : 'Create Account'}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="glass-card" style={{ borderRadius: '24px', overflow: 'hidden' }}>
        {fetchLoading ? (
          <div style={{ padding: '64px', display: 'flex', justifyContent: 'center' }}>
            <Loader2 className="animate-spin" size={32} color="#6366f1" />
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
                  <th style={{ padding: '20px 24px', fontSize: '14px', fontWeight: 600, color: '#94a3b8' }}>Seller</th>
                  <th style={{ padding: '20px 24px', fontSize: '14px', fontWeight: 600, color: '#94a3b8' }}>Store Name</th>
                  <th style={{ padding: '20px 24px', fontSize: '14px', fontWeight: 600, color: '#94a3b8' }}>Status</th>
                  <th style={{ padding: '20px 24px', fontSize: '14px', fontWeight: 600, color: '#94a3b8' }}>Phone</th>
                  <th style={{ padding: '20px 24px', fontSize: '14px', fontWeight: 600, color: '#94a3b8' }}>Created At</th>
                </tr>
              </thead>
              <tbody>
                {sellers.length === 0 ? (
                  <tr>
                    <td colSpan="5" style={{ padding: '64px', textAlign: 'center', color: '#94a3b8' }}>
                      No sellers found. Create your first seller account above.
                    </td>
                  </tr>
                ) : (
                  sellers.map((seller) => (
                    <tr key={seller._id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', transition: '0.3s' }} className="hover-row">
                      <td style={{ padding: '20px 24px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                          <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 600 }}>
                            {seller.name[0]}
                          </div>
                          <div>
                            <div style={{ fontWeight: 600 }}>{seller.name}</div>
                            <div style={{ fontSize: '12px', color: '#94a3b8' }}>{seller.email}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ padding: '20px 24px' }}>
                        {seller.storeName || <span style={{ color: '#64748b', fontSize: '12px', fontStyle: 'italic' }}>Not set</span>}
                      </td>
                      <td style={{ padding: '20px 24px' }}>
                        <span style={{ 
                          padding: '4px 12px', 
                          borderRadius: '20px', 
                          fontSize: '11px', 
                          fontWeight: 600,
                          background: seller.isProfileComplete ? 'rgba(34, 197, 94, 0.1)' : 'rgba(245, 158, 11, 0.1)',
                          color: seller.isProfileComplete ? '#22c55e' : '#f59e0b'
                        }}>
                          {seller.isProfileComplete ? 'Completed' : 'Pending Profile'}
                        </span>
                      </td>
                      <td style={{ padding: '20px 24px' }}>{seller.phone || '-'}</td>
                      <td style={{ padding: '20px 24px', fontSize: '13px', color: '#94a3b8' }}>
                        {new Date(seller.createdAt).toLocaleDateString()}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default Sellers;

import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { Wallet, Loader2, Search, CheckCircle, XCircle, Clock } from 'lucide-react';

const Deposits = () => {
  const [deposits, setDeposits] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchDeposits();
  }, []);

  const fetchDeposits = async () => {
    try {
      const { data } = await api.get('/deposits/admin');
      setDeposits(data);
    } catch (err) {
      console.error('Failed to fetch deposits', err);
    } finally {
      setLoading(false);
    }
  };

  const handleStatusUpdate = async (id, status) => {
    if (!window.confirm(`Are you sure you want to ${status.toLowerCase()} this deposit?`)) return;
    try {
      await api.put(`/deposits/${id}/status`, { status });
      fetchDeposits();
    } catch (err) {
      alert(err.response?.data?.message || 'Failed to update status');
    }
  };

  const filteredDeposits = deposits.filter(d => 
    d.driverId?.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.driverId?.phone?.includes(searchTerm)
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ position: 'relative', width: '300px' }}>
          <Search size={18} style={{ position: 'absolute', left: '12px', top: '10px', color: '#64748b' }} />
          <input 
            type="text" 
            placeholder="Search by driver name or phone..." 
            className="input-field" 
            style={{ paddingLeft: '40px', paddingBottom: '10px', paddingTop: '10px' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
      </div>

      <div className="glass-card" style={{ borderRadius: '24px', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', background: 'rgba(255,255,255,0.02)' }}>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Driver</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Amount</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Date</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>OTP (To be entered in App)</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Status</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="6" style={{ padding: '48px', textAlign: 'center' }}>
                  <Loader2 className="animate-spin" style={{ margin: '0 auto', color: '#6366f1' }} />
                </td>
              </tr>
            ) : filteredDeposits.length === 0 ? (
              <tr>
                <td colSpan="6" style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>No deposits found</td>
              </tr>
            ) : filteredDeposits.map((deposit) => (
              <tr key={deposit._id} style={{ borderBottom: '1px solid rgba(255,255,255,0.03)' }}>
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontWeight: 600 }}>{deposit.driverId?.name}</span>
                    <span style={{ fontSize: '12px', color: '#94a3b8' }}>{deposit.driverId?.phone}</span>
                  </div>
                </td>
                <td style={{ padding: '16px 24px', fontWeight: 'bold' }}>₹{deposit.amount}</td>
                <td style={{ padding: '16px 24px', fontSize: '13px', color: '#94a3b8' }}>
                  {new Date(deposit.createdAt).toLocaleString()}
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ 
                    display: 'inline-block', 
                    padding: '8px 16px', 
                    background: 'rgba(99, 102, 241, 0.1)', 
                    color: '#6366f1', 
                    borderRadius: '12px', 
                    fontWeight: 800, 
                    fontSize: '18px',
                    letterSpacing: '2px',
                    border: '1px dashed #6366f1'
                  }}>
                    {deposit.otp}
                  </div>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <span style={{ 
                    padding: '4px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 600,
                    background: deposit.status === 'Approved' ? 'rgba(34, 197, 94, 0.1)' : (deposit.status === 'Pending' ? 'rgba(245, 158, 11, 0.1)' : 'rgba(239, 68, 68, 0.1)'),
                    color: deposit.status === 'Approved' ? '#22c55e' : (deposit.status === 'Pending' ? '#f59e0b' : '#ef4444')
                  }}>
                    {deposit.status.toUpperCase()}
                  </span>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  {deposit.status === 'Pending' && (
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button 
                        onClick={() => handleStatusUpdate(deposit._id, 'Approved')}
                        className="btn-primary" 
                        style={{ padding: '8px', borderRadius: '8px', background: 'rgba(34, 197, 94, 0.1)', color: '#22c55e', border: 'none', cursor: 'pointer' }}
                        title="Manual Approve"
                      >
                        <CheckCircle size={18} />
                      </button>
                      <button 
                        onClick={() => handleStatusUpdate(deposit._id, 'Rejected')}
                        style={{ padding: '8px', borderRadius: '8px', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', border: 'none', cursor: 'pointer' }}
                        title="Reject"
                      >
                        <XCircle size={18} />
                      </button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Deposits;

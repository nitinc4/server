import React, { useState } from 'react';
import api from '../utils/api';
import { Users, UserPlus, Key, Shield, Loader2, CheckCircle2, AlertCircle } from 'lucide-react';

const Admins = () => {
  const [showCreate, setShowCreate] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState({ type: '', message: '' });
  const currentUser = JSON.parse(localStorage.getItem('zudo_admin_user') || '{}');

  const [createData, setCreateData] = useState({ name: '', email: '', password: '', role: 'admin' });
  const [passData, setPassData] = useState({ currentPassword: '', newPassword: '', confirmPassword: '' });

  const handleCreate = async (e) => {
    e.preventDefault();
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      await api.post('/auth/create-admin', createData);
      setStatus({ type: 'success', message: 'New admin account created successfully!' });
      setShowCreate(false);
      setCreateData({ name: '', email: '', password: '', role: 'admin' });
    } catch (err) {
      setStatus({ type: 'error', message: err.response?.data?.message || 'Failed to create admin.' });
    } finally {
      setLoading(false);
    }
  };

  const handleChangePassword = async (e) => {
    e.preventDefault();
    if (passData.newPassword !== passData.confirmPassword) {
      return setStatus({ type: 'error', message: 'Passwords do not match.' });
    }
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      await api.put('/auth/change-password', passData);
      setStatus({ type: 'success', message: 'Password updated successfully!' });
      setShowPassword(false);
      setPassData({ currentPassword: '', newPassword: '', confirmPassword: '' });
    } catch (err) {
      setStatus({ type: 'error', message: err.response?.data?.message || 'Failed to update password.' });
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

      <div style={{ display: 'flex', gap: '24px' }}>
        {/* Security Summary */}
        <div className="glass-card" style={{ flex: 1, padding: '32px', borderRadius: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
            <div style={{ padding: '12px', background: 'rgba(139, 92, 246, 0.1)', borderRadius: '12px', color: '#8b5cf6' }}>
              <Shield size={24} />
            </div>
            <div>
              <h3 style={{ fontSize: '18px', fontWeight: 700 }}>Security Settings</h3>
              <p style={{ fontSize: '12px', color: '#94a3b8' }}>Manage accounts and access</p>
            </div>
          </div>
          <p style={{ color: '#94a3b8', fontSize: '14px', marginBottom: '24px' }}>
            Logged in as <b>{currentUser.name}</b> ({currentUser.role}). 
            Keep your credentials secure and never share your password.
          </p>
          <button className="btn-primary" style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }} onClick={() => { setShowPassword(true); setShowCreate(false); }}>
            <Key size={18} />
            <span>Change My Password</span>
          </button>
        </div>

        {/* Create Admin (Only for Super Admin) */}
        {currentUser.role === 'super_admin' && (
          <div className="glass-card" style={{ flex: 1, padding: '32px', borderRadius: '24px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '24px' }}>
              <div style={{ padding: '12px', background: 'rgba(99, 102, 241, 0.1)', borderRadius: '12px', color: '#6366f1' }}>
                <UserPlus size={24} />
              </div>
              <div>
                <h3 style={{ fontSize: '18px', fontWeight: 700 }}>Add Admin User</h3>
                <p style={{ fontSize: '12px', color: '#94a3b8' }}>Create new administrative accounts</p>
              </div>
            </div>
            <p style={{ color: '#94a3b8', fontSize: '14px', marginBottom: '24px' }}>
              Add a new team member with administrative privileges to manage products and orders.
            </p>
            <button className="btn-primary" style={{ width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }} onClick={() => { setShowCreate(true); setShowPassword(false); }}>
              <UserPlus size={18} />
              <span>Create Admin Account</span>
            </button>
          </div>
        )}
      </div>

      {/* Forms Section */}
      {(showCreate || showPassword) && (
        <div className="glass-card" style={{ padding: '32px', borderRadius: '24px' }}>
          {showCreate ? (
            <form onSubmit={handleCreate}>
              <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '24px' }}>New Admin Account</h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '16px' }}>
                <input type="text" placeholder="Full Name" className="input-field" required value={createData.name} onChange={e => setCreateData({...createData, name: e.target.value})} />
                <input type="email" placeholder="Email Address" className="input-field" required value={createData.email} onChange={e => setCreateData({...createData, email: e.target.value})} />
                <input type="password" placeholder="Initial Password" className="input-field" required value={createData.password} onChange={e => setCreateData({...createData, password: e.target.value})} />
                <select className="input-field" style={{ color: createData.role ? 'white' : '#94a3b8' }} value={createData.role} onChange={e => setCreateData({...createData, role: e.target.value})}>
                  <option value="admin">Admin</option>
                  <option value="super_admin">Super Admin</option>
                </select>
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                <button type="button" className="btn-primary" style={{ background: 'rgba(255,255,255,0.05)' }} onClick={() => setShowCreate(false)}>Cancel</button>
                <button type="submit" className="btn-primary" disabled={loading}>
                  {loading ? <Loader2 className="animate-spin" /> : 'Create Account'}
                </button>
              </div>
            </form>
          ) : (
            <form onSubmit={handleChangePassword}>
              <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '24px' }}>Update Password</h3>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '16px', maxWidth: '400px', marginBottom: '16px' }}>
                <input type="password" placeholder="Current Password" className="input-field" required value={passData.currentPassword} onChange={e => setPassData({...passData, currentPassword: e.target.value})} />
                <input type="password" placeholder="New Password" className="input-field" required value={passData.newPassword} onChange={e => setPassData({...passData, newPassword: e.target.value})} />
                <input type="password" placeholder="Confirm New Password" className="input-field" required value={passData.confirmPassword} onChange={e => setPassData({...passData, confirmPassword: e.target.value})} />
              </div>
              <div style={{ display: 'flex', gap: '12px' }}>
                <button type="button" className="btn-primary" style={{ background: 'rgba(255,255,255,0.05)' }} onClick={() => setShowPassword(false)}>Cancel</button>
                <button type="submit" className="btn-primary" disabled={loading}>
                  {loading ? <Loader2 className="animate-spin" /> : 'Update Password'}
                </button>
              </div>
            </form>
          )}
        </div>
      )}
    </div>
  );
};

export default Admins;

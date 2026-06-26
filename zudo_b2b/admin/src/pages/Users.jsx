import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { getFullUrl } from '../utils/media_utils';
import { User, Mail, Shield, UserCheck, ShieldAlert, FileText, ShoppingBag, MessageSquare, ExternalLink, Search, Loader2, Calendar } from 'lucide-react';

const Users = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('b2c');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      const { data } = await api.get('/auth/users');
      setUsers(data);
    } catch (error) {
      console.error('Error fetching users:', error);
    } finally {
      setLoading(false);
    }
  };

  const viewDocuments = (user) => {

    const gstUrl = getFullUrl(user.gstPdf);
    const panUrl = getFullUrl(user.panPdf);

    if (gstUrl) window.open(gstUrl, '_blank');
    if (panUrl) window.open(panUrl, '_blank');
  };

  const filteredUsers = users.filter(user => 
    user.role === activeTab && 
    (user.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
     user.email.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  if (loading) return (
    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '60vh', gap: '16px' }}>
      <Loader2 className="animate-spin" style={{ color: '#6366f1' }} size={40} />
      <div style={{ color: '#94a3b8', fontWeight: 500 }}>Loading User Directory...</div>
    </div>
  );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
        <div style={{ position: 'relative', width: '300px' }}>
          <Search size={18} style={{ position: 'absolute', left: '12px', top: '10px', color: '#64748b' }} />
          <input 
            type="text" 
            placeholder="Search users..." 
            className="input-field" 
            style={{ paddingLeft: '40px', paddingBottom: '10px', paddingTop: '10px' }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        
        <div style={{ display: 'flex', background: 'rgba(255,255,255,0.05)', padding: '4px', borderRadius: '16px' }}>
          <button 
            onClick={() => setActiveTab('b2c')}
            style={{ 
              padding: '8px 20px', borderRadius: '12px', fontSize: '13px', fontWeight: 700, border: 'none', cursor: 'pointer', transition: '0.3s',
              background: activeTab === 'b2c' ? '#6366f1' : 'transparent',
              color: activeTab === 'b2c' ? 'white' : '#94a3b8'
            }}
          >
            Personal (B2C)
          </button>
          <button 
            onClick={() => setActiveTab('b2b')}
            style={{ 
              padding: '8px 20px', borderRadius: '12px', fontSize: '13px', fontWeight: 700, border: 'none', cursor: 'pointer', transition: '0.3s',
              background: activeTab === 'b2b' ? '#f59e0b' : 'transparent',
              color: activeTab === 'b2b' ? 'white' : '#94a3b8'
            }}
          >
            Business (B2B)
          </button>
        </div>
      </div>

      <div className="glass-card" style={{ borderRadius: '24px', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', background: 'rgba(255,255,255,0.02)' }}>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>User Identity</th>
              {activeTab === 'b2b' && <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Business Info</th>}
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Communication</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Status</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600, textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredUsers.map((user) => (
              <tr key={user._id} style={{ borderBottom: '1px solid rgba(255,255,255,0.03)' }} className="hover-row">
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ 
                      width: '40px', height: '40px', borderRadius: '12px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', 
                      display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', overflow: 'hidden' 
                    }}>
                      {user.profilePicture ? <img src={getFullUrl(user.profilePicture)} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : user.name[0].toUpperCase()}
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column' }}>
                      <span style={{ fontWeight: 600 }}>{user.name}</span>
                      <span style={{ fontSize: '11px', color: '#64748b' }}>Joined {new Date(user.createdAt).toLocaleDateString()}</span>
                    </div>
                  </div>
                </td>
                
                {activeTab === 'b2b' && (
                  <td style={{ padding: '16px 24px' }}>
                    <div style={{ fontWeight: 600, fontSize: '14px' }}>{user.businessName || 'N/A'}</div>
                    <div style={{ fontSize: '11px', color: '#6366f1' }}>GST: {user.gstNumber || 'N/A'}</div>
                  </td>
                )}

                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: '#94a3b8' }}><Mail size={12} /> {user.email}</div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: '#94a3b8' }}>📱 {user.phone || 'N/A'}</div>
                  </div>
                </td>

                <td style={{ padding: '16px 24px' }}>
                  {user.isVerified ? (
                    <span style={{ padding: '4px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 600, background: 'rgba(34, 197, 94, 0.1)', color: '#22c55e' }}>
                      VERIFIED
                    </span>
                  ) : (
                    <span style={{ padding: '4px 12px', borderRadius: '20px', fontSize: '11px', fontWeight: 600, background: 'rgba(148, 163, 184, 0.1)', color: '#94a3b8' }}>
                      PENDING
                    </span>
                  )}
                </td>

                <td style={{ padding: '16px 24px', textAlign: 'right' }}>
                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                    {activeTab === 'b2b' && (
                      <button 
                        onClick={() => viewDocuments(user)}
                        style={{ padding: '8px', borderRadius: '8px', background: 'rgba(245, 158, 11, 0.1)', border: 'none', color: '#f59e0b', cursor: 'pointer' }}
                      >
                        <FileText size={18} />
                      </button>
                    )}
                    <button style={{ padding: '8px', borderRadius: '8px', background: 'rgba(99, 102, 241, 0.1)', border: 'none', color: '#6366f1', cursor: 'pointer' }}>
                      <ShoppingBag size={18} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filteredUsers.length === 0 && (
          <div style={{ padding: '48px', textAlign: 'center', color: '#64748b' }}>
            <User size={48} style={{ margin: '0 auto 16px', opacity: 0.2 }} />
            <p>No records found matching your search</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Users;

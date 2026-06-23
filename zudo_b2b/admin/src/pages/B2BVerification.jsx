import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { getFullUrl } from '../utils/media_utils';
import { 
  Users, 
  FileText, 
  Check, 
  X, 
  Loader2, 
  ExternalLink,
  ShieldCheck,
  Building2,
  Mail,
  Phone,
  Download,
  XCircle
} from 'lucide-react';

const B2BVerification = () => {
  const [pendingUsers, setPendingUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(null);
  const [selectedPdf, setSelectedPdf] = useState(null);

  useEffect(() => {
    fetchPendingUsers();
  }, []);

  const fetchPendingUsers = async () => {
    try {
      const { data } = await api.get('/auth/b2b-pending');
      setPendingUsers(data);
    } catch (err) {
      console.error('Failed to fetch pending B2B users', err);
    } finally {
      setLoading(false);
    }
  };

  const handleVerify = async (id) => {
    if (!window.confirm('Are you sure you want to verify this business?')) return;
    setActionLoading(id);
    try {
      await api.put(`/auth/verify-b2b/${id}`);
      setPendingUsers(pendingUsers.filter(user => user._id !== id));
    } catch (err) {
      alert('Failed to verify user');
    } finally {
      setActionLoading(null);
    }
  };

  const handleReject = async (id) => {
    if (!window.confirm('Are you sure you want to reject this business?')) return;
    setActionLoading(id);
    try {
      await api.put(`/auth/reject-b2b/${id}`);
      setPendingUsers(pendingUsers.filter(user => user._id !== id));
    } catch (err) {
      alert('Failed to reject user');
    } finally {
      setActionLoading(null);
    }
  };


  const openPdfModal = (path) => {
    setSelectedPdf(getFullUrl(path));
  };

  const downloadFile = (url) => {
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', url.split('/').pop());
    link.setAttribute('target', '_blank');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h3 style={{ fontSize: '18px', color: '#94a3b8', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <ShieldCheck size={20} />
            Pending B2B Verifications
          </h3>
        </div>
      </div>

      <div className="glass-card" style={{ borderRadius: '24px', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', background: 'rgba(255,255,255,0.02)' }}>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Business Info</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Documents</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>GST/PAN No.</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Registration Date</th>
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
            ) : pendingUsers.length === 0 ? (
              <tr>
                <td colSpan="5" style={{ padding: '48px', textAlign: 'center', color: '#94a3b8' }}>
                  No pending B2B verifications
                </td>
              </tr>
            ) : pendingUsers.map((user) => (
              <tr key={user._id} style={{ borderBottom: '1px solid rgba(255,255,255,0.03)' }} className="hover:bg-white/2">
                <td style={{ padding: '20px 24px' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, color: '#fff' }}>
                      <Building2 size={16} color="#6366f1" />
                      {user.businessName}
                    </div>
                    <div style={{ fontSize: '13px', color: '#94a3b8' }}>{user.name} (Owner)</div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: '#64748b' }}>
                      <Mail size={12} /> {user.email}
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: '#64748b' }}>
                      <Phone size={12} /> {user.phone}
                    </div>
                  </div>
                </td>
                <td style={{ padding: '20px 24px' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                    {user.gstPdf && (
                      <button 
                        onClick={() => openPdfModal(user.gstPdf)}
                        style={{ 
                          display: 'flex', alignItems: 'center', gap: '6px', 
                          background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1',
                          padding: '4px 10px', borderRadius: '8px', border: 'none',
                          fontSize: '11px', cursor: 'pointer', fontWeight: 600
                        }}
                      >
                        <FileText size={14} /> GST Doc
                      </button>
                    )}
                    {user.panPdf && (
                      <button 
                        onClick={() => openPdfModal(user.panPdf)}
                        style={{ 
                          display: 'flex', alignItems: 'center', gap: '6px', 
                          background: 'rgba(236, 72, 153, 0.1)', color: '#ec4899',
                          padding: '4px 10px', borderRadius: '8px', border: 'none',
                          fontSize: '11px', cursor: 'pointer', fontWeight: 600
                        }}
                      >
                        <FileText size={14} /> PAN Doc
                      </button>
                    )}
                  </div>
                </td>
                <td style={{ padding: '20px 24px' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px', fontSize: '12px' }}>
                    <div style={{ color: '#94a3b8' }}>GST: <span style={{ color: '#f8fafc', fontFamily: 'monospace' }}>{user.gstNumber || 'N/A'}</span></div>
                    <div style={{ color: '#94a3b8' }}>PAN: <span style={{ color: '#f8fafc', fontFamily: 'monospace' }}>{user.panNumber || 'N/A'}</span></div>
                  </div>
                </td>
                <td style={{ padding: '20px 24px', color: '#64748b', fontSize: '13px' }}>
                  {new Date(user.createdAt).toLocaleDateString()}
                </td>
                <td style={{ padding: '20px 24px' }}>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button 
                      onClick={() => handleVerify(user._id)}
                      disabled={actionLoading === user._id}
                      title="Verify"
                      style={{ 
                        width: '36px', height: '36px', borderRadius: '10px', border: 'none',
                        background: '#22c55e', color: '#fff', cursor: 'pointer',
                        display: 'flex', alignItems: 'center', justifyContent: 'center'
                      }}
                    >
                      {actionLoading === user._id ? <Loader2 size={18} className="animate-spin" /> : <Check size={18} />}
                    </button>
                    <button 
                      onClick={() => handleReject(user._id)}
                      disabled={actionLoading === user._id}
                      title="Reject"
                      style={{ 
                        width: '36px', height: '36px', borderRadius: '10px', border: 'none',
                        background: '#ef4444', color: '#fff', cursor: 'pointer',
                        display: 'flex', alignItems: 'center', justifyContent: 'center'
                      }}
                    >
                      {actionLoading === user._id ? <Loader2 size={18} className="animate-spin" /> : <X size={18} />}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* PDF Viewer Modal */}
      {selectedPdf && (
        <div style={{ 
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, 
          background: 'rgba(0,0,0,0.85)', backdropFilter: 'blur(8px)',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', zIndex: 1000,
          padding: '40px'
        }}>
          <div style={{ 
            width: '100%', maxWidth: '1000px', height: '100%', 
            display: 'flex', flexDirection: 'column', gap: '16px'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <h3 style={{ color: '#fff', fontSize: '20px', fontWeight: 600 }}>Document Preview</h3>
              <div style={{ display: 'flex', gap: '12px' }}>
                <button 
                  onClick={() => downloadFile(selectedPdf)}
                  style={{ 
                    padding: '10px 20px', borderRadius: '12px', border: 'none', 
                    background: '#6366f1', color: 'white', cursor: 'pointer',
                    display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 600
                  }}
                >
                  <Download size={18} /> Download
                </button>
                <button 
                  onClick={() => setSelectedPdf(null)}
                  style={{ 
                    padding: '10px', borderRadius: '12px', border: 'none', 
                    background: 'rgba(255,255,255,0.1)', color: 'white', cursor: 'pointer'
                  }}
                >
                  <XCircle size={24} />
                </button>
              </div>
            </div>
            
            <div style={{ flex: 1, background: '#fff', borderRadius: '20px', overflow: 'hidden', position: 'relative' }}>
              <iframe 
                src={selectedPdf} 
                style={{ width: '100%', height: '100%', border: 'none' }}
                title="PDF Viewer"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default B2BVerification;

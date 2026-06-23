import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../utils/api';
import { Lock, Mail, Loader2 } from 'lucide-react';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const { data } = await api.post('/auth/login', { email, password });
      localStorage.setItem('zudo_admin_token', data.token);
      localStorage.setItem('zudo_admin_user', JSON.stringify(data));
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.message || 'Login failed. Please check credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ 
      height: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      padding: '20px'
    }}>
      <div className="glass" style={{ 
        width: '100%', 
        maxWidth: '450px', 
        padding: '48px',
        textAlign: 'center',
        position: 'relative',
        overflow: 'hidden'
      }}>
        {/* Decor */}
        <div style={{ 
          position: 'absolute', 
          top: '-20px', 
          right: '-20px', 
          width: '100px', 
          height: '100px', 
          background: 'var(--primary)', 
          filter: 'blur(60px)', 
          opacity: 0.3 
        }} />
        
        <h1 style={{ 
          fontSize: '36px', 
          fontWeight: 800, 
          marginBottom: '8px',
          background: 'linear-gradient(135deg, #fff, #94a3b8)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent'
        }}>Welcome Back</h1>
        <p style={{ color: '#94a3b8', marginBottom: '40px' }}>Sign in to ZUDO Admin Panel</p>

        {error && (
          <div style={{ 
            background: 'rgba(239, 68, 68, 0.1)', 
            border: '1px solid rgba(239, 68, 68, 0.2)', 
            color: '#ef4444', 
            padding: '12px', 
            borderRadius: '10px', 
            marginBottom: '24px',
            fontSize: '14px'
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ position: 'relative' }}>
            <Mail size={18} style={{ position: 'absolute', left: '16px', top: '14px', color: '#64748b' }} />
            <input
              type="email"
              placeholder="Email Address"
              className="input-field"
              style={{ paddingLeft: '48px' }}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div style={{ position: 'relative' }}>
            <Lock size={18} style={{ position: 'absolute', left: '16px', top: '14px', color: '#64748b' }} />
            <input
              type="password"
              placeholder="Password"
              className="input-field"
              style={{ paddingLeft: '48px' }}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <button 
            type="submit" 
            className="btn-primary" 
            style={{ marginTop: '12px', height: '48px' }}
            disabled={loading}
          >
            {loading ? <Loader2 className="animate-spin" style={{ margin: '0 auto' }} /> : 'Sign In'}
          </button>
        </form>

        <p style={{ marginTop: '32px', fontSize: '13px', color: '#475569' }}>
          By signing in, you agree to Zudo's Security Policies
        </p>
      </div>
    </div>
  );
};

export default Login;

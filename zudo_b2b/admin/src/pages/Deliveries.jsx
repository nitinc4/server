import React, { useState, useEffect } from 'react';
import axios from '../utils/api';
import { Truck, Clock, Star, CheckCircle, TrendingUp, BarChart3, Loader2 } from 'lucide-react';

const Deliveries = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const { data } = await axios.get('/deliveries/stats');
      setStats(data);
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) return (
    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: '60vh', gap: '16px' }}>
      <Loader2 className="animate-spin" style={{ color: '#6366f1' }} size={40} />
      <div style={{ color: '#94a3b8', fontWeight: 500 }}>Initializing Logistics Core...</div>
    </div>
  );

  const statCards = [
    { title: 'Avg. Delivery Time', value: `${stats.avgDeliveryTime}m`, icon: <Clock size={24} />, color: '#3b82f6' },
    { title: 'Success Rate', value: `${Math.round(stats.successRate)}%`, icon: <TrendingUp size={24} />, color: '#22c55e' },
    { title: 'Total Delivered', value: stats.totalDelivered, icon: <CheckCircle size={24} />, color: '#6366f1' },
    { title: 'Avg. Partner Rating', value: stats.avgRating, icon: <Star size={24} />, color: '#f59e0b' },
  ];

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '24px' }}>
        {statCards.map((card, idx) => (
          <div key={idx} className="glass-card" style={{ padding: '24px', borderRadius: '24px', position: 'relative', overflow: 'hidden' }}>
            <div style={{ position: 'absolute', top: 0, right: 0, width: '80px', height: '80px', background: card.color, opacity: 0.05, borderRadius: '0 0 0 100%' }}></div>
            <div style={{ 
              width: '48px', height: '48px', borderRadius: '14px', background: `${card.color}15`, color: card.color, 
              display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '16px' 
            }}>
              {card.icon}
            </div>
            <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '4px' }}>{card.title}</div>
            <div style={{ fontSize: '28px', fontWeight: 800 }}>{card.value}</div>
          </div>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))', gap: '24px' }}>
        <div className="glass-card" style={{ padding: '32px', borderRadius: '32px', flex: 2 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
            <h3 style={{ fontSize: '18px', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '10px' }}>
              <BarChart3 size={20} style={{ color: '#6366f1' }} /> Efficiency Trends
            </h3>
          </div>
          <div style={{ height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'rgba(255,255,255,0.02)', borderRadius: '24px', border: '1px dashed rgba(255,255,255,0.05)' }}>
            <div style={{ color: '#475569', fontSize: '14px', fontWeight: 500 }}>Visualization Engine Synchronizing...</div>
          </div>
        </div>

        <div className="glass-card" style={{ padding: '32px', borderRadius: '32px', background: 'linear-gradient(135deg, rgba(99, 102, 241, 0.1), rgba(139, 92, 246, 0.1))', position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'relative', zIndex: 1 }}>
            <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '16px' }}>Network Health</h3>
            <p style={{ fontSize: '14px', color: '#94a3b8', lineHeight: '1.6', marginBottom: '24px' }}>
              Your delivery network has seen a significant increase in efficiency this month. 
              The average delivery time has improved by 12.4% compared to the previous cycle.
            </p>
            <div style={{ marginTop: '40px' }}>
              <div style={{ fontSize: '40px', fontWeight: 900, color: '#6366f1' }}>+12.4%</div>
              <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '2px' }}>System Performance Index</div>
            </div>
          </div>
          <Truck size={180} style={{ position: 'absolute', bottom: '-40px', right: '-40px', color: '#6366f1', opacity: 0.05, transform: 'rotate(-15deg)' }} />
        </div>
      </div>
    </div>
  );
};

export default Deliveries;

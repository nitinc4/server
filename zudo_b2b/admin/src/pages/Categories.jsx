import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { getFullUrl } from '../utils/media_utils';
import { Layers, ChevronRight, Loader2 } from 'lucide-react';

const Categories = () => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/categories').then(res => {
      setCategories(res.data);
      setLoading(false);
    });
  }, []);

  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '24px' }}>
      {loading ? (
        <div style={{ gridColumn: '1/-1', textAlign: 'center', padding: '48px' }}><Loader2 className="animate-spin" style={{ margin: '0 auto' }} /></div>
      ) : categories.map(cat => (
        <div key={cat._id} className="glass-card" style={{ padding: '24px', borderRadius: '24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px', marginBottom: '20px' }}>
            <img src={getFullUrl(cat.imageUrl)} alt="" style={{ width: '50px', height: '50px', borderRadius: '12px', objectFit: 'cover' }} />
            <h3 style={{ fontSize: '18px', fontWeight: 700 }}>{cat.name}</h3>
          </div>
          
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <p style={{ fontSize: '12px', color: '#94a3b8', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '1px' }}>Subcategories</p>
            {cat.subCategories?.map(sub => (
              <div key={sub._id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px', background: 'rgba(255,255,255,0.03)', borderRadius: '12px' }}>
                <span style={{ fontSize: '14px' }}>{sub.name}</span>
                <ChevronRight size={14} style={{ color: '#475569' }} />
              </div>
            ))}
            {(!cat.subCategories || cat.subCategories.length === 0) && (
              <p style={{ fontSize: '13px', color: '#475569', fontStyle: 'italic' }}>No subcategories</p>
            )}
          </div>
        </div>
      ))}
    </div>
  );
};

export default Categories;

import React, { useState, useEffect } from 'react';
import api from '../utils/api';
import { getFullUrl } from '../utils/media_utils';
import { Package, Search, Tag, Loader2 } from 'lucide-react';

const Products = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/products').then(res => {
      setProducts(res.data);
      setLoading(false);
    });
  }, []);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ position: 'relative', width: '300px' }}>
          <Search size={18} style={{ position: 'absolute', left: '12px', top: '10px', color: '#64748b' }} />
          <input type="text" placeholder="Search products..." className="input-field" style={{ paddingLeft: '40px', paddingBottom: '10px', paddingTop: '10px' }} />
        </div>
      </div>

      <div className="glass-card" style={{ borderRadius: '24px', overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', background: 'rgba(255,255,255,0.02)' }}>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Product</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>Category</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>B2C Price</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>B2B Price</th>
              <th style={{ padding: '16px 24px', color: '#94a3b8', fontWeight: 600 }}>MOQ</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="5" style={{ padding: '48px', textAlign: 'center' }}><Loader2 className="animate-spin" style={{ margin: '0 auto' }} /></td></tr>
            ) : products.map(product => (
              <tr key={product._id} style={{ borderBottom: '1px solid rgba(255,255,255,0.03)' }}>
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <img src={getFullUrl(product.imageUrl)} alt="" style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }} />
                    <span>{product.name}</span>
                  </div>
                </td>
                <td style={{ padding: '16px 24px' }}>
                  <div style={{ display: 'flex', flexDirection: 'column' }}>
                    <span style={{ fontSize: '14px' }}>{product.categoryId?.name}</span>
                    <span style={{ fontSize: '11px', color: '#94a3b8' }}>{product.subCategoryId?.name || 'No Subcategory'}</span>
                  </div>
                </td>
                <td style={{ padding: '16px 24px' }}>₹{product.price}</td>
                <td style={{ padding: '16px 24px' }}>₹{product.b2bPrice}</td>
                <td style={{ padding: '16px 24px' }}>{product.moq} {product.unit}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Products;

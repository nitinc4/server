import React, { useState } from 'react';
import api from '../utils/api';
import * as XLSX from 'xlsx';
import { Upload, Download, FileSpreadsheet, CheckCircle2, AlertCircle, Loader2, Layers } from 'lucide-react';

const BulkUpload = () => {
  const [file, setFile] = useState(null);
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState({ type: '', message: '' });

  const downloadTemplate = (type) => {
    let data = [];
    if (type === 'products') {
      data = [
        {
          Name: 'Example Product',
          Category: 'Pulses',
          SubCategory: 'Lentils',
          Price: 100,
          B2BPrice: 80,
          MOQ: 5,
          Unit: '1kg',
          ImageUrl: 'https://via.placeholder.com/150',
          Rating: 4.5
        }
      ];
    } else {
      data = [
        {
          Category: 'Pulses',
          CategoryImageUrl: 'https://via.placeholder.com/150',
          SubCategory: 'Lentils',
          SubCategoryImageUrl: 'https://via.placeholder.com/150'
        },
        {
          Category: 'Rice',
          CategoryImageUrl: 'https://via.placeholder.com/150',
          SubCategory: '', // Example of blank subcategory
          SubCategoryImageUrl: ''
        }
      ];
    }

    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Template");
    XLSX.writeFile(wb, `Zudo_${type}_template.xlsx`);
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!file) return;

    setLoading(true);
    setStatus({ type: '', message: '' });

    const formData = new FormData();
    formData.append('file', file);

    try {
      await api.post('/products/bulk-upload', formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      setStatus({ type: 'success', message: 'Bulk upload successful! Data has been imported.' });
      setFile(null);
    } catch (err) {
      setStatus({ type: 'error', message: err.response?.data?.message || 'Upload failed. Please check the file format.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '32px' }}>
      <div className="glass-card" style={{ padding: '32px', borderRadius: '24px' }}>
        <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '24px' }}>Download Templates</h3>
        <div style={{ display: 'flex', gap: '20px' }}>
          <div onClick={() => downloadTemplate('products')} className="glass" style={{ 
            flex: 1, padding: '24px', borderRadius: '20px', cursor: 'pointer', transition: '0.3s',
            display: 'flex', alignItems: 'center', gap: '16px', border: '1px solid rgba(255,255,255,0.05)'
          }}>
            <div style={{ padding: '12px', background: 'rgba(99, 102, 241, 0.1)', borderRadius: '12px', color: '#6366f1' }}>
              <FileSpreadsheet size={24} />
            </div>
            <div>
              <p style={{ fontWeight: 600 }}>Products Template</p>
              <p style={{ fontSize: '12px', color: '#94a3b8' }}>For bulk product inventory</p>
            </div>
            <Download size={18} style={{ marginLeft: 'auto', color: '#94a3b8' }} />
          </div>

          <div onClick={() => downloadTemplate('categories')} className="glass" style={{ 
            flex: 1, padding: '24px', borderRadius: '20px', cursor: 'pointer', transition: '0.3s',
            display: 'flex', alignItems: 'center', gap: '16px', border: '1px solid rgba(255,255,255,0.05)'
          }}>
            <div style={{ padding: '12px', background: 'rgba(236, 72, 153, 0.1)', borderRadius: '12px', color: '#ec4899' }}>
              <Layers size={24} />
            </div>
            <div>
              <p style={{ fontWeight: 600 }}>Categories Template</p>
              <p style={{ fontSize: '12px', color: '#94a3b8' }}>For categories & subcategories</p>
            </div>
            <Download size={18} style={{ marginLeft: 'auto', color: '#94a3b8' }} />
          </div>
        </div>
      </div>

      <div className="glass-card" style={{ padding: '32px', borderRadius: '24px' }}>
        <h3 style={{ fontSize: '20px', fontWeight: 700, marginBottom: '24px' }}>Upload File</h3>
        
        {status.message && (
          <div style={{ 
            background: status.type === 'success' ? 'rgba(34, 197, 94, 0.1)' : 'rgba(239, 68, 68, 0.1)', 
            border: `1px solid ${status.type === 'success' ? 'rgba(34, 197, 94, 0.2)' : 'rgba(239, 68, 68, 0.2)'}`, 
            color: status.type === 'success' ? '#22c55e' : '#ef4444', 
            padding: '16px', borderRadius: '12px', marginBottom: '24px', display: 'flex', alignItems: 'center', gap: '12px'
          }}>
            {status.type === 'success' ? <CheckCircle2 size={20} /> : <AlertCircle size={20} />}
            <span style={{ fontSize: '14px' }}>{status.message}</span>
          </div>
        )}

        <form onSubmit={handleUpload}>
          <div style={{ 
            border: '2px dashed rgba(255,255,255,0.1)', 
            borderRadius: '20px', 
            padding: '60px 40px', 
            textAlign: 'center',
            background: 'rgba(255,255,255,0.02)',
            cursor: 'pointer',
            transition: '0.3s'
          }} onDragOver={(e) => e.preventDefault()} onDrop={(e) => { e.preventDefault(); setFile(e.dataTransfer.files[0]); }}>
            <input 
              type="file" 
              id="file-upload" 
              style={{ display: 'none' }} 
              onChange={(e) => setFile(e.target.files[0])}
              accept=".xlsx, .xls"
            />
            <label htmlFor="file-upload" style={{ cursor: 'pointer' }}>
              <div style={{ 
                width: '64px', height: '64px', background: 'rgba(255,255,255,0.05)', 
                borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center',
                margin: '0 auto 16px', color: '#6366f1'
              }}>
                <Upload size={32} />
              </div>
              <h4 style={{ fontSize: '18px', fontWeight: 600, marginBottom: '8px' }}>
                {file ? file.name : 'Click to upload or drag and drop'}
              </h4>
              <p style={{ color: '#94a3b8', fontSize: '14px' }}>Excel files only (.xlsx, .xls)</p>
            </label>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '32px' }}>
            <button 
              type="submit" 
              className="btn-primary" 
              disabled={!file || loading}
              style={{ minWidth: '160px', height: '48px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}
            >
              {loading ? <Loader2 className="animate-spin" /> : (
                <>
                  <CheckCircle2 size={18} />
                  <span>Import Data</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>

      <div className="glass-card" style={{ padding: '24px', borderRadius: '24px', border: '1px solid rgba(255,165,0,0.1)' }}>
        <h4 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '12px', color: '#f59e0b', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <AlertCircle size={18} />
          Important Instructions
        </h4>
        <ul style={{ color: '#94a3b8', fontSize: '13px', lineHeight: '1.6', paddingLeft: '20px' }}>
          <li>Ensure all required columns are present in the Excel file.</li>
          <li>Categories and subcategories will be created automatically if they don't exist.</li>
          <li>Subcategories can be left blank in the template.</li>
          <li>Image URLs should be valid public links.</li>
        </ul>
      </div>
    </div>
  );
};

export default BulkUpload;

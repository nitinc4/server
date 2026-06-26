import axios from 'axios';

export const BASE_URL = window.location.hostname === 'localhost' 
  ? 'http://localhost:5000/api' 
  : 'https://lightgreen-trout-176417.hostingersite.com/api';

export const BASE_DOMAIN = window.location.hostname === 'localhost'
  ? 'http://localhost:5000'
  : 'https://lightgreen-trout-176417.hostingersite.com';

const api = axios.create({
  baseURL: BASE_URL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('zudo_admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  
  const tenantId = localStorage.getItem('zudo_tenant_id');
  if (tenantId) {
    config.headers['x-tenant-id'] = tenantId;
  }
  
  return config;
});

export default api;

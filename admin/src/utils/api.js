import axios from 'axios';

const isLocal = window.location.hostname === 'localhost' || 
                 window.location.hostname === '127.0.0.1' || 
                 window.location.hostname.startsWith('192.168.') || 
                 window.location.hostname.startsWith('10.') || 
                 window.location.hostname.endsWith('.local');

const envProductionDomain = import.meta.env.VITE_PRODUCTION_DOMAIN || window.location.origin;
const PRODUCTION_DOMAIN = envProductionDomain.endsWith('/') ? envProductionDomain.slice(0, -1) : envProductionDomain;
const LOCAL_DOMAIN = 'https://lightgreen-trout-176417.hostingersite.com';

export const BASE_DOMAIN = isLocal ? LOCAL_DOMAIN : PRODUCTION_DOMAIN;
export const BASE_URL = import.meta.env.VITE_API_URL || `${BASE_DOMAIN}/api`;
export const UPLOAD_URL = BASE_URL;
export const IMAGE_BASE_URL = BASE_DOMAIN;

const api = axios.create({
  baseURL: BASE_URL,
});

export const uploadApi = axios.create({
  baseURL: UPLOAD_URL,
});

export const notificationApi = axios.create({
  baseURL: import.meta.env.VITE_NOTIFICATION_API_URL || import.meta.env.VITE_API_URL || 'https://lightgreen-trout-176417.hostingersite.com/api',
});

const setupInterceptors = (instance) => {
  instance.interceptors.request.use((config) => {
    // Admin panel uses admin token
    const token = localStorage.getItem('zudo_admin_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    
    // Check if there is a location header needed
    const location = localStorage.getItem('zudo_admin_location');
    if (location && !config.headers['x-location']) {
      config.headers['x-location'] = location;
    }
    return config;
  });

  instance.interceptors.response.use(
    (response) => response,
    (error) => {
      if (error.response && error.response.status === 401) {
        if (error.response.data && error.response.data.code === 'SESSION_INVALIDATED') {
          alert('Session expired. You have logged in from another device.');
          localStorage.removeItem('zudo_admin_token');
          localStorage.removeItem('zudo_admin_user');
          localStorage.removeItem('zudo_admin_location');
          window.location.href = '/login';
        }
      }
      return Promise.reject(error);
    }
  );
};

setupInterceptors(api);
setupInterceptors(uploadApi);
setupInterceptors(notificationApi);

export const getImageUrl = (url) => {
  if (!url) return 'https://placehold.co/150';

  let finalUrl = url;

  // Dynamically rewrite legacy placeholder URLs to the modern placehold.co service
  if (typeof url === 'string') {
    if (url.includes('via.placeholder.com')) {
      finalUrl = url.replace('via.placeholder.com', 'placehold.co');
    }
    // Fix connection refused for hardcoded localhost URLs saved in DB
    if (url.includes('localhost:5000')) {
      finalUrl = url.replace(/https?:\/\/localhost:5000/, IMAGE_BASE_URL);
    }
  }

  // Ensure the URL uses the production domain for consistency if it's already a full URL
  if (finalUrl.startsWith('http')) {
    if (!isLocal && finalUrl.includes(LOCAL_DOMAIN)) {
      finalUrl = finalUrl.replace(LOCAL_DOMAIN, PRODUCTION_DOMAIN);
    }
  } else {
    // If it's a relative path, prepend IMAGE_BASE_URL
    const cleanUrl = finalUrl.startsWith('/') ? finalUrl : `/${finalUrl}`;
    finalUrl = `${IMAGE_BASE_URL}${cleanUrl}`;
  }

  // Standardize on /uploads/ and clean up double slashes or double /api
  return finalUrl
    .replace('/api/uploads/', '/uploads/')
    .replace('/api/upload/', '/uploads/')
    .replace('//uploads/', '/uploads/')
    .replace('/api/api/', '/api/');
};

export default api;

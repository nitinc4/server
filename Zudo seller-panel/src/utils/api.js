import axios from 'axios';

export const BASE_URL = 'https://lightgreen-trout-176417.hostingersite.com/api';
export const UPLOAD_URL = 'https://lightgreen-trout-176417.hostingersite.com/api';
export const IMAGE_BASE_URL = 'https://lightgreen-trout-176417.hostingersite.com';

const api = axios.create({
  baseURL: BASE_URL,
});

export const uploadApi = axios.create({
  baseURL: UPLOAD_URL,
});

const setupInterceptors = (instance) => {
  instance.interceptors.request.use((config) => {
    const token = localStorage.getItem('zudo_seller_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }

    const location = localStorage.getItem('zudo_seller_location');
    if (location && !config.headers['x-location']) {
      config.headers['x-location'] = location;
    }
    return config;
  });
};

setupInterceptors(api);
setupInterceptors(uploadApi);

export const getImageUrl = (url) => {
  if (!url) return 'https://via.placeholder.com/150';

  // If it's already a full URL but contains localhost, replace it with IMAGE_BASE_URL
  if (url.includes('localhost:5000')) {
    return url.replace('http://localhost:5000/api', IMAGE_BASE_URL)
      .replace('http://localhost:5000', IMAGE_BASE_URL);
  }

  // If it's a full URL (starts with http), return as is
  if (url.startsWith('http')) return url;

  // Otherwise, prepend IMAGE_BASE_URL (ensure no double slashes)
  const cleanUrl = url.startsWith('/') ? url : `/${url}`;
  return `${IMAGE_BASE_URL}${cleanUrl}`;
};

export default api;
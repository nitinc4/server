import { BASE_DOMAIN } from './api';

export const getFullUrl = (path) => {
  if (!path) return '';
  if (path.startsWith('http')) return path;
  return `${BASE_DOMAIN}${path.startsWith('/') ? '' : '/'}${path}`;
};

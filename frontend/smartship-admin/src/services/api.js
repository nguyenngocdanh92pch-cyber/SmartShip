import axios from 'axios';

// Khai báo cổng của API Gateway (Tất cả API đều phải đi qua cổng này)
const api = axios.create({
  baseURL: 'http://localhost:8080', 
});

// Tự động nhét Token vào header (để sau này phân quyền Admin)
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export default api;
import axios from 'axios';

// axiosのベースURLを設定
const API_BASE_URL = (import.meta as any).env?.VITE_API_URL || 'http://localhost:3001';
const baseURL = `${API_BASE_URL}/api`;

// axiosのデフォルト設定
axios.defaults.baseURL = baseURL;
axios.defaults.headers.common['Content-Type'] = 'application/json';

export default axios;

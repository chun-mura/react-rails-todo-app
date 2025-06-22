import axios from 'axios';

// axiosのベースURLを設定
const API_BASE_URL = (import.meta as any).env?.VITE_API_URL || 'http://localhost:3001';

// axiosのデフォルト設定
axios.defaults.baseURL = API_BASE_URL;
axios.defaults.headers.common['Content-Type'] = 'application/json';

export default axios;

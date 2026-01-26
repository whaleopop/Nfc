import axios from 'axios'

// Базовый URL API из environment переменных
// VITE_API_URL должен быть полным URL с протоколом: https://testapi.soldium.ru/api
// Переменная устанавливается при сборке из GitHub Secrets
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'

// Создаем инстанс axios с базовой конфигурацией
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Interceptor для добавления токена авторизации
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Interceptor для обработки ошибок и refresh токена
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config

    // Если 401 и это не повторный запрос
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      try {
        const refreshToken = localStorage.getItem('refresh_token')
        if (!refreshToken) {
          throw new Error('No refresh token')
        }

        // Попытка обновить токен
        const response = await axios.post(`${API_BASE_URL}/auth/token/refresh/`, {
          refresh: refreshToken,
        })

        const { access } = response.data
        localStorage.setItem('access_token', access)

        // Повторить оригинальный запрос с новым токеном
        originalRequest.headers.Authorization = `Bearer ${access}`
        return api(originalRequest)
      } catch (refreshError) {
        // Если refresh не удался - разлогинить
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        window.location.href = '/login'
        return Promise.reject(refreshError)
      }
    }

    return Promise.reject(error)
  }
)

// Auth API
export const authAPI = {
  // Регистрация
  register: (data) => api.post('/auth/register/', data),

  // Вход
  login: (email, password) => api.post('/auth/login/', { email, password }),

  // Выход
  logout: (refreshToken) => api.post('/auth/logout/', { refresh_token: refreshToken }),

  // Получить текущего пользователя
  getCurrentUser: () => api.get('/auth/me/'),

  // Обновить токен
  refreshToken: (refreshToken) => api.post('/auth/token/refresh/', { refresh: refreshToken }),

  // Изменить пароль
  changePassword: (data) => api.post('/auth/change-password/', data),
}

// Profile API
export const profileAPI = {
  // Получить медицинский профиль
  getProfile: () => api.get('/profiles/medical-profile/'),

  // Обновить профиль
  updateProfile: (data) => api.put('/profiles/medical-profile/', data),

  // Получить аллергии
  getAllergies: () => api.get('/profiles/allergies/'),

  // Добавить аллергию
  addAllergy: (data) => api.post('/profiles/allergies/', data),

  // Удалить аллергию
  deleteAllergy: (id) => api.delete(`/profiles/allergies/${id}/`),

  // Получить хронические заболевания
  getDiseases: () => api.get('/profiles/chronic-diseases/'),

  // Добавить заболевание
  addDisease: (data) => api.post('/profiles/chronic-diseases/', data),

  // Удалить заболевание
  deleteDisease: (id) => api.delete(`/profiles/chronic-diseases/${id}/`),

  // Получить лекарства
  getMedications: () => api.get('/profiles/medications/'),

  // Добавить лекарство
  addMedication: (data) => api.post('/profiles/medications/', data),

  // Удалить лекарство
  deleteMedication: (id) => api.delete(`/profiles/medications/${id}/`),

  // Получить экстренные контакты
  getEmergencyContacts: () => api.get('/profiles/emergency-contacts/'),

  // Добавить контакт
  addEmergencyContact: (data) => api.post('/profiles/emergency-contacts/', data),

  // Удалить контакт
  deleteEmergencyContact: (id) => api.delete(`/profiles/emergency-contacts/${id}/`),
}

// NFC API
export const nfcAPI = {
  // Получить все NFC теги пользователя
  getTags: () => api.get('/nfc/tags/'),

  // Получить конкретный тег
  getTag: (id) => api.get(`/nfc/tags/${id}/`),

  // Создать новый тег
  createTag: (data) => api.post('/nfc/tags/', data),

  // Обновить тег
  updateTag: (id, data) => api.put(`/nfc/tags/${id}/`, data),

  // Удалить тег
  deleteTag: (id) => api.delete(`/nfc/tags/${id}/`),

  // Активировать тег
  activateTag: (id) => api.post(`/nfc/tags/${id}/activate/`),

  // Деактивировать тег
  deactivateTag: (id) => api.post(`/nfc/tags/${id}/deactivate/`),

  // Получить публичную информацию по тегу (без авторизации)
  getPublicInfo: (tagUid) => axios.get(`${API_BASE_URL}/nfc/public/${tagUid}/`),

  // Запросить экстренный доступ
  requestEmergencyAccess: (tagUid, data) =>
    axios.post(`${API_BASE_URL}/nfc/emergency-access/request/`, {
      tag_uid: tagUid,
      ...data,
    }),

  // Получить логи доступа
  getAccessLogs: () => api.get('/nfc/access-logs/'),
}

export default api

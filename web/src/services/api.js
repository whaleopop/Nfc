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

// Singleton для refresh - чтобы не делать несколько refresh одновременно
let refreshPromise = null

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

        // Если refresh уже выполняется — ждём его результата
        if (!refreshPromise) {
          refreshPromise = axios
            .post(`${API_BASE_URL}/auth/refresh/`, { refresh: refreshToken })
            .finally(() => {
              refreshPromise = null
            })
        }

        const response = await refreshPromise
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
  logout: (refreshToken) => api.post('/auth/logout/', { refresh: refreshToken }),

  // Получить текущего пользователя
  getCurrentUser: () => api.get('/auth/me/'),

  // Обновить токен
  refreshToken: (refreshToken) => api.post('/auth/refresh/', { refresh: refreshToken }),

  // Изменить пароль
  changePassword: (data) => api.post('/auth/change-password/', data),
}

// Profile API
export const profileAPI = {
  // Получить медицинский профиль
  getProfile: () => api.get('/profiles/'),

  // Создать профиль
  createProfile: (data) => api.post('/profiles/', data),

  // Обновить профиль
  updateProfile: (data) => api.put('/profiles/', data),

  // Получить аллергии
  getAllergies: () => api.get('/profiles/allergies/'),

  // Добавить аллергию
  addAllergy: (data) => api.post('/profiles/allergies/', data),

  // Обновить аллергию
  updateAllergy: (id, data) => api.put(`/profiles/allergies/${id}/`, data),

  // Удалить аллергию
  deleteAllergy: (id) => api.delete(`/profiles/allergies/${id}/`),

  // Получить хронические заболевания
  getChronicDiseases: () => api.get('/profiles/chronic-diseases/'),

  // Добавить заболевание
  addChronicDisease: (data) => api.post('/profiles/chronic-diseases/', data),

  // Обновить заболевание
  updateChronicDisease: (id, data) => api.put(`/profiles/chronic-diseases/${id}/`, data),

  // Удалить заболевание
  deleteChronicDisease: (id) => api.delete(`/profiles/chronic-diseases/${id}/`),

  // Получить лекарства
  getMedications: () => api.get('/profiles/medications/'),

  // Добавить лекарство
  addMedication: (data) => api.post('/profiles/medications/', data),

  // Обновить лекарство
  updateMedication: (id, data) => api.put(`/profiles/medications/${id}/`, data),

  // Удалить лекарство
  deleteMedication: (id) => api.delete(`/profiles/medications/${id}/`),

  // Получить экстренные контакты
  getEmergencyContacts: () => api.get('/profiles/emergency-contacts/'),

  // Добавить контакт
  addEmergencyContact: (data) => api.post('/profiles/emergency-contacts/', data),

  // Обновить контакт
  updateEmergencyContact: (id, data) => api.put(`/profiles/emergency-contacts/${id}/`, data),

  // Удалить контакт
  deleteEmergencyContact: (id) => api.delete(`/profiles/emergency-contacts/${id}/`),
}

// NFC API
export const nfcAPI = {
  // Получить все NFC теги пользователя
  getTags: () => api.get('/nfc/tags/'),

  // Зарегистрировать новый тег
  registerTag: (data) => api.post('/nfc/register/', data),

  // Отозвать тег
  revokeTag: (tagId, reason = '') => api.post('/nfc/revoke/', { tag_id: tagId, reason }),

  // Получить логи доступа
  getAccessLogs: () => api.get('/nfc/access-logs/'),

  // Получить экстренные доступы
  getEmergencyAccesses: () => api.get('/nfc/emergency-accesses/'),

  // Сканировать тег (экстренный доступ - без авторизации)
  scanTag: (tagUid, publicKeyId, checksum, latitude, longitude) =>
    axios.post(`${API_BASE_URL}/nfc/scan/`, {
      tag_uid: tagUid,
      public_key_id: publicKeyId,
      checksum: checksum,
      latitude: latitude,
      longitude: longitude,
    }),

  // Получить данные экстренного доступа по ID тега (для QR кода)
  getEmergencyData: (tagId) => axios.get(`${API_BASE_URL}/nfc/emergency/${tagId}/`),
}

// Audit API
export const auditAPI = {
  // Получить все логи аудита (только для админов)
  getAuditLogs: (params) => api.get('/audit/logs/', { params }),

  // Получить события безопасности (только для админов)
  getSecurityEvents: (params) => api.get('/audit/security-events/', { params }),

  // Получить логи текущего пользователя
  getMyAuditLogs: () => api.get('/audit/my-logs/'),
}

export default api

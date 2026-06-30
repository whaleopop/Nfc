import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api'

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
})

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

let refreshPromise = null

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      try {
        const refreshToken = localStorage.getItem('refresh_token')
        if (!refreshToken) {
          throw new Error('No refresh token')
        }

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

        originalRequest.headers.Authorization = `Bearer ${access}`
        return api(originalRequest)
      } catch (refreshError) {
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        window.location.href = '/login'
        return Promise.reject(refreshError)
      }
    }

    return Promise.reject(error)
  }
)

export const authAPI = {
  register: (data) => api.post('/auth/register/', data),
  login: (email, password) => api.post('/auth/login/', { email, password }),
  logout: (refreshToken) => api.post('/auth/logout/', { refresh: refreshToken }),
  getCurrentUser: () => api.get('/auth/me/'),
  refreshToken: (refreshToken) => api.post('/auth/refresh/', { refresh: refreshToken }),
  changePassword: (data) => api.post('/auth/change-password/', data),
}

export const profileAPI = {
  getProfile: () => api.get('/profiles/'),
  createProfile: (data) => api.post('/profiles/', data),
  updateProfile: (data) => api.put('/profiles/', data),
  getAllergies: () => api.get('/profiles/allergies/'),
  addAllergy: (data) => api.post('/profiles/allergies/', data),
  updateAllergy: (id, data) => api.put(`/profiles/allergies/${id}/`, data),
  deleteAllergy: (id) => api.delete(`/profiles/allergies/${id}/`),
  getChronicDiseases: () => api.get('/profiles/chronic-diseases/'),
  addChronicDisease: (data) => api.post('/profiles/chronic-diseases/', data),
  updateChronicDisease: (id, data) => api.put(`/profiles/chronic-diseases/${id}/`, data),
  deleteChronicDisease: (id) => api.delete(`/profiles/chronic-diseases/${id}/`),
  getMedications: () => api.get('/profiles/medications/'),
  addMedication: (data) => api.post('/profiles/medications/', data),
  updateMedication: (id, data) => api.put(`/profiles/medications/${id}/`, data),
  deleteMedication: (id) => api.delete(`/profiles/medications/${id}/`),
  getEmergencyContacts: () => api.get('/profiles/emergency-contacts/'),
  addEmergencyContact: (data) => api.post('/profiles/emergency-contacts/', data),
  updateEmergencyContact: (id, data) => api.put(`/profiles/emergency-contacts/${id}/`, data),
  deleteEmergencyContact: (id) => api.delete(`/profiles/emergency-contacts/${id}/`),
}

export const nfcAPI = {
  getTags: () => api.get('/nfc/tags/'),
  registerTag: (data) => api.post('/nfc/register/', data),
  revokeTag: (tagId, reason = '') => api.post('/nfc/revoke/', { tag_id: tagId, reason }),
  getAccessLogs: () => api.get('/nfc/access-logs/'),
  getEmergencyAccesses: () => api.get('/nfc/emergency-accesses/'),
  scanTag: (tagUid, publicKeyId, checksum, latitude, longitude) =>
    axios.post(`${API_BASE_URL}/nfc/scan/`, {
      tag_uid: tagUid,
      public_key_id: publicKeyId,
      checksum: checksum,
      latitude: latitude,
      longitude: longitude,
    }),
  getEmergencyData: (tagId) => axios.get(`${API_BASE_URL}/nfc/emergency/${tagId}/`),
}

export const doctorAPI = {
  getPatients: (search = '') =>
    api.get('/profiles/patients/', { params: search ? { search } : {} }),
  getPatientProfile: (userId) => api.get(`/profiles/patients/${userId}/profile/`),
  updatePatientProfile: (userId, data) => api.put(`/profiles/patients/${userId}/profile/`, data),
  getPatientAllergies: (userId) => api.get(`/profiles/patients/${userId}/allergies/`),
  addPatientAllergy: (userId, data) => api.post(`/profiles/patients/${userId}/allergies/`, data),
  updatePatientAllergy: (userId, id, data) => api.put(`/profiles/patients/${userId}/allergies/${id}/`, data),
  deletePatientAllergy: (userId, id) => api.delete(`/profiles/patients/${userId}/allergies/${id}/`),
  getPatientDiseases: (userId) => api.get(`/profiles/patients/${userId}/chronic-diseases/`),
  addPatientDisease: (userId, data) => api.post(`/profiles/patients/${userId}/chronic-diseases/`, data),
  updatePatientDisease: (userId, id, data) => api.put(`/profiles/patients/${userId}/chronic-diseases/${id}/`, data),
  deletePatientDisease: (userId, id) => api.delete(`/profiles/patients/${userId}/chronic-diseases/${id}/`),
  getPatientMedications: (userId) => api.get(`/profiles/patients/${userId}/medications/`),
  addPatientMedication: (userId, data) => api.post(`/profiles/patients/${userId}/medications/`, data),
  updatePatientMedication: (userId, id, data) => api.put(`/profiles/patients/${userId}/medications/${id}/`, data),
  deletePatientMedication: (userId, id) => api.delete(`/profiles/patients/${userId}/medications/${id}/`),
  getPatientContacts: (userId) => api.get(`/profiles/patients/${userId}/emergency-contacts/`),
  addPatientContact: (userId, data) => api.post(`/profiles/patients/${userId}/emergency-contacts/`, data),
  updatePatientContact: (userId, id, data) => api.put(`/profiles/patients/${userId}/emergency-contacts/${id}/`, data),
  deletePatientContact: (userId, id) => api.delete(`/profiles/patients/${userId}/emergency-contacts/${id}/`),
}

export const auditAPI = {
  getAuditLogs: (params) => api.get('/audit/logs/', { params }),
  getSecurityEvents: (params) => api.get('/audit/security-events/', { params }),
  getMyAuditLogs: () => api.get('/audit/my-logs/'),
}

export default api

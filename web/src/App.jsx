import { Routes, Route, Navigate } from 'react-router-dom'
import { Box } from '@mui/material'
import { useAuth } from './contexts/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Login from './pages/Login'
import Register from './pages/Register'
import Dashboard from './pages/Dashboard'
import Profile from './pages/Profile'
import NFCManagement from './pages/NFCManagement'
import AdminPanel from './pages/AdminPanel'
import EmergencyAccess from './pages/EmergencyAccess'
import DoctorDashboard from './pages/DoctorDashboard'
import PatientProfile from './pages/PatientProfile'

function App() {
  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <Dashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/profile"
          element={
            <ProtectedRoute>
              <Profile />
            </ProtectedRoute>
          }
        />
        <Route
          path="/nfc"
          element={
            <ProtectedRoute>
              <NFCManagement />
            </ProtectedRoute>
          }
        />
        <Route
          path="/admin"
          element={
            <ProtectedRoute>
              <AdminPanel />
            </ProtectedRoute>
          }
        />
        {/* Doctor-only routes */}
        <Route
          path="/patients"
          element={
            <ProtectedRoute requireRole={['MEDICAL_WORKER', 'ADMIN', 'SUPER_ADMIN']}>
              <DoctorDashboard />
            </ProtectedRoute>
          }
        />
        <Route
          path="/patients/:userId"
          element={
            <ProtectedRoute requireRole={['MEDICAL_WORKER', 'ADMIN', 'SUPER_ADMIN']}>
              <PatientProfile />
            </ProtectedRoute>
          }
        />
        <Route path="/emergency/:tagId" element={<EmergencyAccess />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Box>
  )
}

function HomePage() {
  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '100vh',
        textAlign: 'center',
        px: 2,
      }}
    >
      <h1>NFC Medical Platform</h1>
      <p>Экстренный доступ к медицинским данным через NFC</p>
      <Box sx={{ mt: 4, display: 'flex', gap: 2 }}>
        <a href="/login" style={{ textDecoration: 'none' }}>
          <button
            style={{
              padding: '12px 24px',
              fontSize: '16px',
              cursor: 'pointer',
              borderRadius: '8px',
              border: 'none',
              background: '#1976d2',
              color: 'white',
            }}
          >
            Войти
          </button>
        </a>
        <a href="/register" style={{ textDecoration: 'none' }}>
          <button
            style={{
              padding: '12px 24px',
              fontSize: '16px',
              cursor: 'pointer',
              borderRadius: '8px',
              border: '1px solid #1976d2',
              background: 'white',
              color: '#1976d2',
            }}
          >
            Регистрация
          </button>
        </a>
      </Box>
    </Box>
  )
}

export default App

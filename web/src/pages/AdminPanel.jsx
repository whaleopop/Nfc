import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Container,
  Paper,
  Typography,
  Box,
  TextField,
  Button,
  Grid,
  AppBar,
  Toolbar,
  IconButton,
  Avatar,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  InputAdornment,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  Divider,
} from '@mui/material'
import {
  ArrowBack as ArrowBackIcon,
  Search as SearchIcon,
  People as PeopleIcon,
  AdminPanelSettings as AdminIcon,
  Assessment as AssessmentIcon,
  LocalHospital as HospitalIcon,
} from '@mui/icons-material'
import { toast } from 'react-toastify'
import { useAuth } from '../contexts/AuthContext'
import { nfcAPI, profileAPI, auditAPI } from '../services/api'

function AdminPanel() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState(0)

  // Check if user has admin/medical worker access
  const hasAccess = user?.role === 'ADMIN' || user?.role === 'MEDICAL_WORKER'

  // Statistics
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalTags: 0,
    totalAccess: 0,
    activeToday: 0,
  })

  // Users list
  const [users, setUsers] = useState([])
  const [searchQuery, setSearchQuery] = useState('')

  // Access logs
  const [accessLogs, setAccessLogs] = useState([])

  // Patient profile dialog
  const [profileDialog, setProfileDialog] = useState(false)
  const [selectedPatient, setSelectedPatient] = useState(null)
  const [patientProfile, setPatientProfile] = useState(null)
  const [profileLoading, setProfileLoading] = useState(false)

  useEffect(() => {
    if (!hasAccess) {
      toast.error('У вас нет доступа к админ панели')
      navigate('/dashboard')
      return
    }
    loadData()
  }, [hasAccess])

  const loadData = async () => {
    try {
      setLoading(true)
      // In real implementation, these would be separate admin endpoints
      const [logsRes] = await Promise.all([nfcAPI.getAccessLogs()])

      setAccessLogs(logsRes.data)

      // Calculate stats from available data
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      const todayLogs = logsRes.data.filter((log) => new Date(log.accessed_at) >= today)

      setStats({
        totalUsers: 0, // Would come from admin API
        totalTags: 0, // Would come from admin API
        totalAccess: logsRes.data.length,
        activeToday: todayLogs.length,
      })
    } catch (error) {
      toast.error('Ошибка загрузки данных')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  const handleViewPatient = async (patient) => {
    setSelectedPatient(patient)
    setProfileDialog(true)
    setProfileLoading(true)

    try {
      // In real implementation, this would be an admin endpoint to view any user's profile
      const response = await profileAPI.getProfile() // Would need patient ID parameter
      setPatientProfile(response.data)
    } catch (error) {
      toast.error('Ошибка загрузки профиля пациента')
      console.error(error)
    } finally {
      setProfileLoading(false)
    }
  }

  const filteredLogs = accessLogs.filter(
    (log) =>
      !searchQuery ||
      log.nfc_tag_uid?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      log.ip_address?.toLowerCase().includes(searchQuery.toLowerCase())
  )

  if (!hasAccess) {
    return null
  }

  if (loading) {
    return (
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          minHeight: '100vh',
        }}
      >
        <CircularProgress />
      </Box>
    )
  }

  return (
    <>
      <AppBar position="static">
        <Toolbar>
          <IconButton edge="start" color="inherit" onClick={() => navigate('/dashboard')}>
            <ArrowBackIcon />
          </IconButton>
          <AdminIcon sx={{ ml: 2, mr: 1 }} />
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            Панель администратора
          </Typography>
          <Chip
            label={user?.role === 'ADMIN' ? 'Администратор' : 'Медработник'}
            color="warning"
            sx={{ mr: 2 }}
          />
          <Avatar sx={{ bgcolor: 'secondary.main' }}>
            {user?.first_name?.[0]?.toUpperCase() || 'A'}
          </Avatar>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        {/* Statistics Cards */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <Card elevation={3}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <PeopleIcon color="primary" sx={{ mr: 1 }} />
                  <Typography variant="h6" color="text.secondary">
                    Пользователи
                  </Typography>
                </Box>
                <Typography variant="h4">{stats.totalUsers}</Typography>
                <Typography variant="caption" color="text.secondary">
                  Всего в системе
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card elevation={3}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <HospitalIcon color="success" sx={{ mr: 1 }} />
                  <Typography variant="h6" color="text.secondary">
                    NFC метки
                  </Typography>
                </Box>
                <Typography variant="h4">{stats.totalTags}</Typography>
                <Typography variant="caption" color="text.secondary">
                  Активных меток
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card elevation={3}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <AssessmentIcon color="info" sx={{ mr: 1 }} />
                  <Typography variant="h6" color="text.secondary">
                    Обращения
                  </Typography>
                </Box>
                <Typography variant="h4">{stats.totalAccess}</Typography>
                <Typography variant="caption" color="text.secondary">
                  Всего обращений
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={6} md={3}>
            <Card elevation={3}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <AssessmentIcon color="warning" sx={{ mr: 1 }} />
                  <Typography variant="h6" color="text.secondary">
                    Сегодня
                  </Typography>
                </Box>
                <Typography variant="h4">{stats.activeToday}</Typography>
                <Typography variant="caption" color="text.secondary">
                  Обращений за сегодня
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Tabs */}
        <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
          <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
            <Tab label="История доступа" />
            <Tab label="Пользователи" />
          </Tabs>
        </Box>

        {/* Tab 1: Access Logs */}
        {activeTab === 0 && (
          <>
            <Box sx={{ mb: 3 }}>
              <TextField
                fullWidth
                placeholder="Поиск по имени метки или IP адресу..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon />
                    </InputAdornment>
                  ),
                }}
              />
            </Box>

            {filteredLogs.length === 0 ? (
              <Alert severity="info">Нет записей</Alert>
            ) : (
              <TableContainer component={Paper} elevation={3}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Дата и время</TableCell>
                      <TableCell>NFC метка</TableCell>
                      <TableCell>Владелец</TableCell>
                      <TableCell>Тип доступа</TableCell>
                      <TableCell>IP адрес</TableCell>
                      <TableCell>Статус</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {filteredLogs.map((log) => (
                      <TableRow key={log.id}>
                        <TableCell>
                          {new Date(log.accessed_at).toLocaleString('ru-RU', {
                            year: 'numeric',
                            month: '2-digit',
                            day: '2-digit',
                            hour: '2-digit',
                            minute: '2-digit',
                            second: '2-digit',
                          })}
                        </TableCell>
                        <TableCell>{log.nfc_tag_uid || log.nfc_tag}</TableCell>
                        <TableCell>{log.accessed_by_name || '—'}</TableCell>
                        <TableCell>
                          <Chip
                            label={
                              log.access_type === 'SCAN'
                                ? 'Сканирование'
                                : log.access_type === 'REGISTER'
                                ? 'Регистрация'
                                : 'Отзыв'
                            }
                            size="small"
                            color={
                              log.access_type === 'SCAN'
                                ? 'primary'
                                : log.access_type === 'REGISTER'
                                ? 'success'
                                : 'warning'
                            }
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                            {log.ip_address || '—'}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={log.status === 'SUCCESS' ? 'Успешно' : 'Отказано'}
                            size="small"
                            color={log.status === 'SUCCESS' ? 'success' : 'error'}
                          />
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            )}
          </>
        )}

        {/* Tab 2: Users */}
        {activeTab === 1 && (
          <>
            <Alert severity="info" sx={{ mb: 3 }}>
              Функционал управления пользователями будет доступен в следующей версии. Сейчас вы
              можете просматривать логи доступа к медицинским данным.
            </Alert>

            <Paper elevation={3} sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Поиск пациентов
              </Typography>
              <TextField
                fullWidth
                placeholder="Введите имя, email или телефон пациента..."
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <SearchIcon />
                    </InputAdornment>
                  ),
                }}
                sx={{ mb: 2 }}
              />
              <Alert severity="info">
                Для поиска пациентов используйте фильтр выше. Будут отображены пациенты,
                зарегистрированные в системе.
              </Alert>
            </Paper>
          </>
        )}
      </Container>

      {/* Patient Profile Dialog */}
      <Dialog
        open={profileDialog}
        onClose={() => setProfileDialog(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          Профиль пациента
          {selectedPatient && ` - ${selectedPatient.name}`}
        </DialogTitle>
        <DialogContent>
          {profileLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : patientProfile ? (
            <Box sx={{ mt: 2 }}>
              <Typography variant="h6" gutterBottom>
                Основная информация
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={6}>
                  <Typography variant="body2" color="text.secondary">
                    Группа крови:
                  </Typography>
                  <Typography variant="body1">{patientProfile.blood_type || '—'}</Typography>
                </Grid>
                <Grid item xs={3}>
                  <Typography variant="body2" color="text.secondary">
                    Рост:
                  </Typography>
                  <Typography variant="body1">
                    {patientProfile.height ? `${patientProfile.height} см` : '—'}
                  </Typography>
                </Grid>
                <Grid item xs={3}>
                  <Typography variant="body2" color="text.secondary">
                    Вес:
                  </Typography>
                  <Typography variant="body1">
                    {patientProfile.weight ? `${patientProfile.weight} кг` : '—'}
                  </Typography>
                </Grid>
              </Grid>

              {patientProfile.emergency_notes && (
                <Box sx={{ mt: 3 }}>
                  <Typography variant="h6" gutterBottom>
                    Экстренные заметки
                  </Typography>
                  <Alert severity="warning">{patientProfile.emergency_notes}</Alert>
                </Box>
              )}
            </Box>
          ) : (
            <Alert severity="error">Не удалось загрузить профиль пациента</Alert>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setProfileDialog(false)}>Закрыть</Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default AdminPanel

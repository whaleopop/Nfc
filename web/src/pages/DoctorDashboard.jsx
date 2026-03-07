import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  Container,
  AppBar,
  Toolbar,
  Typography,
  IconButton,
  Avatar,
  Menu,
  MenuItem,
  TextField,
  InputAdornment,
  Card,
  CardContent,
  CardActions,
  Button,
  Grid,
  Chip,
  CircularProgress,
  Alert,
  Paper,
} from '@mui/material'
import {
  Search as SearchIcon,
  Person as PersonIcon,
  ExitToApp,
  LocalHospital,
  AccountCircle,
} from '@mui/icons-material'
import { useAuth } from '../contexts/AuthContext'
import { doctorAPI } from '../services/api'

function DoctorDashboard() {
  const navigate = useNavigate()
  const { user, logout } = useAuth()
  const [patients, setPatients] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [anchorEl, setAnchorEl] = useState(null)

  const loadPatients = useCallback(async (q = '') => {
    try {
      setLoading(true)
      const res = await doctorAPI.getPatients(q)
      setPatients(Array.isArray(res.data) ? res.data : [])
    } catch {
      setPatients([])
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadPatients()
  }, [loadPatients])

  // Debounced search
  useEffect(() => {
    const t = setTimeout(() => loadPatients(search), 400)
    return () => clearTimeout(t)
  }, [search, loadPatients])

  const handleLogout = async () => {
    setAnchorEl(null)
    await logout()
    navigate('/login')
  }

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      <AppBar position="static">
        <Toolbar>
          <LocalHospital sx={{ mr: 1 }} />
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            NFC Medical — Панель врача
          </Typography>
          <IconButton color="inherit" onClick={(e) => setAnchorEl(e.currentTarget)}>
            <Avatar sx={{ width: 32, height: 32, bgcolor: 'secondary.main' }}>
              {user?.first_name?.[0] || 'D'}
            </Avatar>
          </IconButton>
          <Menu anchorEl={anchorEl} open={Boolean(anchorEl)} onClose={() => setAnchorEl(null)}>
            <MenuItem disabled>
              <Typography variant="body2" color="text.secondary">
                {user?.first_name} {user?.last_name}
              </Typography>
            </MenuItem>
            <MenuItem onClick={() => { setAnchorEl(null); navigate('/profile') }}>
              <AccountCircle sx={{ mr: 1 }} /> Мой профиль
            </MenuItem>
            <MenuItem onClick={handleLogout}>
              <ExitToApp sx={{ mr: 1 }} /> Выйти
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h5" gutterBottom>
            Пациенты
          </Typography>
          <TextField
            fullWidth
            placeholder="Поиск по имени или email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
            sx={{ mt: 1 }}
          />
        </Paper>

        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', mt: 4 }}>
            <CircularProgress />
          </Box>
        ) : patients.length === 0 ? (
          <Alert severity="info">
            {search ? 'Пациенты не найдены по запросу' : 'Нет пациентов в системе'}
          </Alert>
        ) : (
          <Grid container spacing={2}>
            {patients.map((patient) => (
              <Grid item xs={12} sm={6} md={4} key={patient.id}>
                <Card>
                  <CardContent>
                    <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                      <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                        <PersonIcon />
                      </Avatar>
                      <Box>
                        <Typography variant="subtitle1" fontWeight="bold">
                          {patient.last_name} {patient.first_name}
                          {patient.middle_name ? ` ${patient.middle_name}` : ''}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {patient.email}
                        </Typography>
                      </Box>
                    </Box>
                    {patient.phone && (
                      <Typography variant="body2" color="text.secondary">
                        {patient.phone}
                      </Typography>
                    )}
                    <Chip
                      label="Пациент"
                      size="small"
                      color="primary"
                      variant="outlined"
                      sx={{ mt: 1 }}
                    />
                  </CardContent>
                  <CardActions>
                    <Button
                      size="small"
                      variant="contained"
                      onClick={() => navigate(`/patients/${patient.id}`)}
                    >
                      Открыть профиль
                    </Button>
                  </CardActions>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Container>
    </Box>
  )
}

export default DoctorDashboard

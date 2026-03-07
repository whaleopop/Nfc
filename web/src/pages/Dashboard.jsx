import { useEffect, useState, useLayoutEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  Box,
  Container,
  Grid,
  Paper,
  Typography,
  Card,
  CardContent,
  CardActions,
  Button,
  AppBar,
  Toolbar,
  IconButton,
  Avatar,
  Menu,
  MenuItem,
  CircularProgress,
} from '@mui/material'
import {
  AccountCircle,
  Nfc as NfcIcon,
  LocalHospital,
  EmergencyShare,
  ExitToApp,
} from '@mui/icons-material'
import { useAuth } from '../contexts/AuthContext'
import { nfcAPI, profileAPI } from '../services/api'

function Dashboard() {
  const navigate = useNavigate()
  const { user, logout } = useAuth()
  const [anchorEl, setAnchorEl] = useState(null)

  // Doctors/admins go to patient management
  useLayoutEffect(() => {
    if (user && user.role !== 'PATIENT') {
      navigate('/patients', { replace: true })
    }
  }, [user, navigate])
  const [stats, setStats] = useState({
    nfcTags: 0,
    activeAccess: 0,
    profileComplete: false,
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    loadDashboardData()
  }, [])

  const loadDashboardData = async () => {
    try {
      const [tagsResponse, profileResponse] = await Promise.all([
        nfcAPI.getTags(),
        profileAPI.getProfile().catch(() => null),
      ])

      const tags = Array.isArray(tagsResponse?.data) ? tagsResponse.data : []

      setStats({
        nfcTags: tags.length,
        activeAccess: tags.filter((t) => t.is_active).length,
        profileComplete: !!profileResponse?.data,
      })
    } catch (error) {
      console.error('Failed to load dashboard data:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleMenuOpen = (event) => {
    setAnchorEl(event.currentTarget)
  }

  const handleMenuClose = () => {
    setAnchorEl(null)
  }

  const handleLogout = async () => {
    handleMenuClose()
    await logout()
    navigate('/login')
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
    <Box sx={{ minHeight: '100vh', bgcolor: 'background.default' }}>
      {/* Header */}
      <AppBar position="static">
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            NFC Medical
          </Typography>
          <IconButton color="inherit" onClick={handleMenuOpen}>
            <Avatar sx={{ width: 32, height: 32, bgcolor: 'secondary.main' }}>
              {user?.first_name?.[0] || 'U'}
            </Avatar>
          </IconButton>
          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleMenuClose}
          >
            <MenuItem onClick={() => { handleMenuClose(); navigate('/profile'); }}>
              <AccountCircle sx={{ mr: 1 }} /> Профиль
            </MenuItem>
            <MenuItem onClick={handleLogout}>
              <ExitToApp sx={{ mr: 1 }} /> Выйти
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        {/* Welcome Section */}
        <Paper sx={{ p: 3, mb: 3 }}>
          <Typography variant="h4" gutterBottom>
            Добро пожаловать, {user?.first_name}!
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {user?.role === 'PATIENT'
              ? 'Управляйте своими медицинскими данными и NFC тегами'
              : 'Доступ к экстренным медицинским данным пациентов'}
          </Typography>
        </Paper>

        {/* Stats Cards */}
        <Grid container spacing={3} sx={{ mb: 3 }}>
          <Grid item xs={12} sm={4}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <NfcIcon color="primary" sx={{ fontSize: 40, mr: 2 }} />
                  <Box>
                    <Typography variant="h4">{stats.nfcTags}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      NFC тегов
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={4}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <EmergencyShare color="success" sx={{ fontSize: 40, mr: 2 }} />
                  <Box>
                    <Typography variant="h4">{stats.activeAccess}</Typography>
                    <Typography variant="body2" color="text.secondary">
                      Активных
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12} sm={4}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <LocalHospital color="error" sx={{ fontSize: 40, mr: 2 }} />
                  <Box>
                    <Typography variant="h4">
                      {stats.profileComplete ? '✓' : '!'}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Мед. профиль
                    </Typography>
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Quick Actions */}
        <Grid container spacing={3}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Медицинский профиль
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Управляйте своими медицинскими данными, аллергиями и контактами
                </Typography>
              </CardContent>
              <CardActions>
                <Button
                  size="small"
                  variant="contained"
                  onClick={() => navigate('/profile')}
                >
                  Открыть профиль
                </Button>
              </CardActions>
            </Card>
          </Grid>

          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  NFC Теги
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  Управляйте NFC тегами для экстренного доступа к данным
                </Typography>
              </CardContent>
              <CardActions>
                <Button
                  size="small"
                  variant="contained"
                  onClick={() => navigate('/nfc')}
                >
                  Управление тегами
                </Button>
              </CardActions>
            </Card>
          </Grid>
        </Grid>
      </Container>
    </Box>
  )
}

export default Dashboard

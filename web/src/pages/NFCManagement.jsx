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
  CardActions,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Switch,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
} from '@mui/material'
import {
  ArrowBack as ArrowBackIcon,
  Add as AddIcon,
  Nfc as NfcIcon,
  CheckCircle as CheckCircleIcon,
  Cancel as CancelIcon,
  QrCode as QrCodeIcon,
  History as HistoryIcon,
} from '@mui/icons-material'
import { toast } from 'react-toastify'
import QRCode from 'qrcode.react'
import { useAuth } from '../contexts/AuthContext'
import { nfcAPI } from '../services/api'

function NFCManagement() {
  const navigate = useNavigate()
  const { user } = useAuth()
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState(0)

  // NFC Tags
  const [tags, setTags] = useState([])
  const [createDialog, setCreateDialog] = useState(false)
  const [qrDialog, setQrDialog] = useState(false)
  const [selectedTag, setSelectedTag] = useState(null)
  const [newTagUid, setNewTagUid] = useState('')
  const [newTagType, setNewTagType] = useState('NTAG215')

  // Access Logs
  const [accessLogs, setAccessLogs] = useState([])

  useEffect(() => {
    loadData()
  }, [])

  const loadData = async () => {
    try {
      setLoading(true)
      const [tagsRes, logsRes] = await Promise.all([nfcAPI.getTags(), nfcAPI.getAccessLogs()])
      setTags(tagsRes.data)
      setAccessLogs(logsRes.data)
    } catch (error) {
      toast.error('Ошибка загрузки данных')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateTag = async () => {
    if (!newTagUid.trim()) {
      toast.error('Введите UID метки')
      return
    }

    try {
      const response = await nfcAPI.registerTag({
        tag_uid: newTagUid.trim(),
        tag_type: newTagType
      })
      // Response contains both tag and nfc_data
      if (response.data.tag) {
        setTags([...tags, response.data.tag])
      }
      setCreateDialog(false)
      setNewTagUid('')
      toast.success('NFC метка зарегистрирована')
    } catch (error) {
      toast.error(error.response?.data?.error || 'Ошибка регистрации метки')
      console.error(error)
    }
  }

  const handleRevokeTag = async (tag) => {
    if (!confirm('Вы уверены, что хотите отозвать эту метку? Это действие необратимо.')) {
      return
    }

    try {
      await nfcAPI.revokeTag(tag.id, 'Отозвано пользователем')
      // Reload data to get updated tag status
      loadData()
      toast.success('Метка отозвана')
    } catch (error) {
      toast.error('Ошибка отзыва метки')
      console.error(error)
    }
  }

  const handleShowQR = (tag) => {
    setSelectedTag(tag)
    setQrDialog(true)
  }

  const getAccessUrl = (tagUid) => {
    // Frontend URL for emergency access page
    const baseUrl = window.location.origin
    return `${baseUrl}/emergency/${tagUid}`
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
          <Typography variant="h6" sx={{ flexGrow: 1, ml: 2 }}>
            Управление NFC
          </Typography>
          <Avatar sx={{ bgcolor: 'secondary.main' }}>
            {user?.first_name?.[0]?.toUpperCase() || 'U'}
          </Avatar>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
          <Tabs value={activeTab} onChange={(e, newValue) => setActiveTab(newValue)}>
            <Tab label="Мои метки" icon={<NfcIcon />} iconPosition="start" />
            <Tab label="История доступа" icon={<HistoryIcon />} iconPosition="start" />
          </Tabs>
        </Box>

        {/* Tab 1: NFC Tags */}
        {activeTab === 0 && (
          <>
            <Box sx={{ mb: 3, display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="h5">Мои NFC метки</Typography>
              <Button
                variant="contained"
                startIcon={<AddIcon />}
                onClick={() => setCreateDialog(true)}
              >
                Создать метку
              </Button>
            </Box>

            {tags.length === 0 ? (
              <Alert severity="info">
                У вас пока нет NFC меток. Создайте первую метку, чтобы начать использовать систему.
              </Alert>
            ) : (
              <Grid container spacing={3}>
                {tags.map((tag) => (
                  <Grid item xs={12} md={6} key={tag.id}>
                    <Card elevation={3}>
                      <CardContent>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            <NfcIcon color="primary" />
                            <Typography variant="h6">{tag.tag_uid}</Typography>
                          </Box>
                          <Chip
                            label={tag.status === 'ACTIVE' ? 'Активна' : tag.status === 'REVOKED' ? 'Отозвана' : tag.status}
                            color={tag.status === 'ACTIVE' ? 'success' : 'default'}
                            icon={tag.status === 'ACTIVE' ? <CheckCircleIcon /> : <CancelIcon />}
                          />
                        </Box>

                        <Typography variant="body2" color="text.secondary" gutterBottom>
                          Тип: {tag.tag_type}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" gutterBottom>
                          Зарегистрирована:{' '}
                          {new Date(tag.registered_at).toLocaleDateString('ru-RU', {
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                          })}
                        </Typography>
                        {tag.last_scanned_at && (
                          <Typography variant="body2" color="text.secondary">
                            Последнее сканирование:{' '}
                            {new Date(tag.last_scanned_at).toLocaleString('ru-RU')}
                          </Typography>
                        )}

                        <Box sx={{ mt: 2 }}>
                          <Typography variant="body2" fontWeight="bold" gutterBottom>
                            Статистика:
                          </Typography>
                          <Typography variant="body2">
                            Всего сканирований: {tag.scan_count || 0}
                          </Typography>
                        </Box>
                      </CardContent>
                      <CardActions sx={{ justifyContent: 'space-between', px: 2, pb: 2 }}>
                        <Button
                          variant="outlined"
                          color="error"
                          size="small"
                          onClick={() => handleRevokeTag(tag)}
                          disabled={tag.status !== 'ACTIVE'}
                        >
                          Отозвать
                        </Button>
                        <Button
                          variant="outlined"
                          startIcon={<QrCodeIcon />}
                          onClick={() => handleShowQR(tag)}
                        >
                          QR-код
                        </Button>
                      </CardActions>
                    </Card>
                  </Grid>
                ))}
              </Grid>
            )}
          </>
        )}

        {/* Tab 2: Access Logs */}
        {activeTab === 1 && (
          <>
            <Typography variant="h5" gutterBottom>
              История доступа
            </Typography>

            {accessLogs.length === 0 ? (
              <Alert severity="info">История доступа пуста</Alert>
            ) : (
              <TableContainer component={Paper} elevation={3}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Дата и время</TableCell>
                      <TableCell>NFC метка</TableCell>
                      <TableCell>Тип доступа</TableCell>
                      <TableCell>IP адрес</TableCell>
                      <TableCell>Статус</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {accessLogs.map((log) => (
                      <TableRow key={log.id}>
                        <TableCell>
                          {new Date(log.accessed_at).toLocaleString('ru-RU', {
                            year: 'numeric',
                            month: '2-digit',
                            day: '2-digit',
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </TableCell>
                        <TableCell>{log.nfc_tag_uid || log.nfc_tag}</TableCell>
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
                        <TableCell>{log.ip_address || '—'}</TableCell>
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
      </Container>

      {/* Create Tag Dialog */}
      <Dialog open={createDialog} onClose={() => setCreateDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Зарегистрировать NFC метку</DialogTitle>
        <DialogContent>
          <Alert severity="info" sx={{ mt: 1, mb: 2 }}>
            Введите UID метки, который можно получить сканированием физической NFC метки или из приложения для записи NFC.
          </Alert>
          <TextField
            autoFocus
            fullWidth
            label="UID метки"
            placeholder="Например: 04:A3:B2:C1:D4:E5:F6"
            value={newTagUid}
            onChange={(e) => setNewTagUid(e.target.value)}
            helperText="Уникальный идентификатор NFC метки"
            sx={{ mb: 2 }}
          />
          <TextField
            fullWidth
            label="Тип метки"
            value={newTagType}
            onChange={(e) => setNewTagType(e.target.value)}
            helperText="По умолчанию: NTAG215"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialog(false)}>Отмена</Button>
          <Button onClick={handleCreateTag} variant="contained">
            Зарегистрировать
          </Button>
        </DialogActions>
      </Dialog>

      {/* QR Code Dialog */}
      <Dialog open={qrDialog} onClose={() => setQrDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>QR-код для экстренного доступа</DialogTitle>
        <DialogContent>
          {selectedTag && (
            <>
              <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 2 }}>
                <Typography variant="h6" gutterBottom>
                  {selectedTag.tag_uid}
                </Typography>
                <Box
                  sx={{
                    p: 2,
                    bgcolor: 'white',
                    borderRadius: 2,
                    border: '1px solid #ddd',
                    mb: 2,
                  }}
                >
                  <QRCode value={getAccessUrl(selectedTag.tag_uid)} size={256} level="H" />
                </Box>
                <Alert severity="info" sx={{ width: '100%' }}>
                  Отсканируйте этот QR-код для доступа к медицинским данным в экстренных ситуациях. Доступ возможен без авторизации.
                </Alert>
                <Typography
                  variant="caption"
                  color="text.secondary"
                  sx={{ mt: 2, wordBreak: 'break-all', textAlign: 'center' }}
                >
                  {getAccessUrl(selectedTag.tag_uid)}
                </Typography>
              </Box>
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setQrDialog(false)}>Закрыть</Button>
          <Button
            variant="contained"
            onClick={() => {
              const canvas = document.querySelector('canvas')
              const url = canvas.toDataURL('image/png')
              const link = document.createElement('a')
              link.download = `nfc-qr-${selectedTag.tag_uid}.png`
              link.href = url
              link.click()
              toast.success('QR-код сохранен')
            }}
          >
            Скачать QR-код
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default NFCManagement

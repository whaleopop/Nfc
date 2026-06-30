import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import {
  Container,
  Paper,
  Typography,
  Box,
  Grid,
  Card,
  CardContent,
  Chip,
  Alert,
  CircularProgress,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
} from '@mui/material'
import {
  LocalHospital as HospitalIcon,
  Warning as WarningIcon,
  Bloodtype as BloodIcon,
  Phone as PhoneIcon,
  Medication as MedicationIcon,
  Event as EventIcon,
} from '@mui/icons-material'
import { nfcAPI } from '../services/api'

function EmergencyAccess() {
  const { tagId } = useParams()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [data, setData] = useState(null)

  useEffect(() => {
    loadEmergencyData()
  }, [tagId])

  const loadEmergencyData = async () => {
    try {
      setLoading(true)
      setError(null)
      // This endpoint returns public emergency medical data for the NFC tag
      const response = await nfcAPI.getEmergencyData(tagId)
      setData(response.data)
    } catch (err) {
      console.error(err)
      if (err.response?.status === 404) {
        setError('NFC метка не найдена или не активна')
      } else if (err.response?.status === 403) {
        setError('Доступ к этой метке запрещен')
      } else {
        setError('Ошибка загрузки данных. Попробуйте еще раз.')
      }
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return (
      <Box
        sx={{
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'center',
          minHeight: '100vh',
          bgcolor: '#f5f5f5',
        }}
      >
        <CircularProgress size={60} />
        <Typography variant="h6" sx={{ mt: 2 }}>
          Загрузка медицинских данных...
        </Typography>
      </Box>
    )
  }

  if (error) {
    return (
      <Container maxWidth="md" sx={{ mt: 4 }}>
        <Alert severity="error" sx={{ mb: 2 }}>
          <Typography variant="h6">{error}</Typography>
        </Alert>
        <Paper sx={{ p: 3 }}>
          <Typography variant="body1" gutterBottom>
            Возможные причины:
          </Typography>
          <ul>
            <li>NFC метка не активирована владельцем</li>
            <li>Неверный ID метки</li>
            <li>Метка была удалена из системы</li>
          </ul>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 2 }}>
            Если вы медицинский работник и нуждаетесь в срочном доступе к медицинской информации,
            свяжитесь с технической поддержкой или используйте альтернативные методы идентификации
            пациента.
          </Typography>
        </Paper>
      </Container>
    )
  }

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: '#f5f5f5', py: 3 }}>
      <Container maxWidth="lg">
        {/* Emergency Header */}
        <Paper
          elevation={6}
          sx={{
            p: 3,
            mb: 3,
            bgcolor: '#d32f2f',
            color: 'white',
            textAlign: 'center',
          }}
        >
          <HospitalIcon sx={{ fontSize: 60, mb: 1 }} />
          <Typography variant="h3" fontWeight="bold">
            ЭКСТРЕННЫЙ ДОСТУП
          </Typography>
          <Typography variant="h5" sx={{ mt: 1 }}>
            Медицинские данные пациента
          </Typography>
        </Paper>

        {/* Patient Info */}
        <Paper elevation={3} sx={{ p: 3, mb: 3 }}>
          <Typography variant="h5" gutterBottom>
            Пациент
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6}>
              <Typography variant="body2" color="text.secondary">
                Имя:
              </Typography>
              <Typography variant="h6">
                {data?.user?.full_name || `${data?.user?.first_name} ${data?.user?.last_name}`}
              </Typography>
            </Grid>
            <Grid item xs={12} sm={3}>
              <Typography variant="body2" color="text.secondary">
                Возраст:
              </Typography>
              <Typography variant="h6">{data?.user?.age || '—'} лет</Typography>
            </Grid>
            <Grid item xs={12} sm={3}>
              <Typography variant="body2" color="text.secondary">
                Пол:
              </Typography>
              <Typography variant="h6">
                {data?.user?.gender === 'M' ? 'Мужской' : data?.user?.gender === 'F' ? 'Женский' : '—'}
              </Typography>
            </Grid>
          </Grid>
        </Paper>

        <Grid container spacing={3}>
          {/* Critical Info - Blood Type */}
          <Grid item xs={12} md={4}>
            <Card elevation={3} sx={{ bgcolor: '#fff3e0', height: '100%' }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <BloodIcon sx={{ fontSize: 40, color: '#e65100', mr: 1 }} />
                  <Typography variant="h5" fontWeight="bold">
                    Группа крови
                  </Typography>
                </Box>
                <Typography variant="h3" fontWeight="bold" color="#d84315" textAlign="center">
                  {data?.profile?.blood_type || 'Не указана'}
                </Typography>
              </CardContent>
            </Card>
          </Grid>

          {/* Physical Parameters */}
          <Grid item xs={12} md={4}>
            <Card elevation={3} sx={{ height: '100%' }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Физические параметры
                </Typography>
                <Box sx={{ mt: 2 }}>
                  <Typography variant="body1">
                    <strong>Рост:</strong> {data?.profile?.height ? `${data.profile.height} см` : '—'}
                  </Typography>
                  <Typography variant="body1" sx={{ mt: 1 }}>
                    <strong>Вес:</strong> {data?.profile?.weight ? `${data.profile.weight} кг` : '—'}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          {/* Access Info */}
          <Grid item xs={12} md={4}>
            <Card elevation={3} sx={{ height: '100%' }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Информация о доступе
                </Typography>
                <Box sx={{ mt: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Время доступа:
                  </Typography>
                  <Typography variant="body1">{new Date().toLocaleString('ru-RU')}</Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                    NFC метка:
                  </Typography>
                  <Typography variant="body1" sx={{ fontFamily: 'monospace' }}>
                    {data?.tag?.name || tagId}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          {/* Emergency Notes */}
          {data?.profile?.emergency_notes && (
            <Grid item xs={12}>
              <Alert
                severity="error"
                icon={<WarningIcon fontSize="large" />}
                sx={{ fontSize: '1.1rem' }}
              >
                <Typography variant="h6" fontWeight="bold" gutterBottom>
                  ВАЖНАЯ ИНФОРМАЦИЯ
                </Typography>
                <Typography variant="body1">{data.profile.emergency_notes}</Typography>
              </Alert>
            </Grid>
          )}

          {/* Allergies */}
          <Grid item xs={12} md={6}>
            <Card elevation={3} sx={{ bgcolor: '#ffebee' }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <WarningIcon sx={{ color: '#c62828', mr: 1 }} />
                  <Typography variant="h6" fontWeight="bold">
                    АЛЛЕРГИИ
                  </Typography>
                </Box>
                {!data?.allergies || data.allergies.length === 0 ? (
                  <Typography variant="body1" color="text.secondary">
                    Нет данных об аллергиях
                  </Typography>
                ) : (
                  <List>
                    {data.allergies.map((allergy, index) => (
                      <Box key={index}>
                        {index > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={
                              <Typography variant="h6" fontWeight="bold">
                                {allergy.allergen}
                              </Typography>
                            }
                            secondary={
                              <>
                                <Chip
                                  label={
                                    allergy.severity === 'LIFE_THREATENING'
                                      ? 'ОПАСНО ДЛЯ ЖИЗНИ'
                                      : allergy.severity === 'SEVERE'
                                      ? 'Тяжелая'
                                      : allergy.severity === 'MODERATE'
                                      ? 'Средняя'
                                      : 'Легкая'
                                  }
                                  color={
                                    allergy.severity === 'LIFE_THREATENING' || allergy.severity === 'SEVERE'
                                      ? 'error'
                                      : allergy.severity === 'MODERATE'
                                      ? 'warning'
                                      : 'default'
                                  }
                                  size="small"
                                />
                                {allergy.reaction && (
                                  <Typography variant="body2" sx={{ mt: 1 }}>
                                    Реакция: {allergy.reaction}
                                  </Typography>
                                )}
                              </>
                            }
                          />
                        </ListItem>
                      </Box>
                    ))}
                  </List>
                )}
              </CardContent>
            </Card>
          </Grid>

          {/* Chronic Diseases */}
          <Grid item xs={12} md={6}>
            <Card elevation={3}>
              <CardContent>
                <Typography variant="h6" gutterBottom fontWeight="bold">
                  Хронические заболевания
                </Typography>
                {!data?.diseases || data.diseases.length === 0 ? (
                  <Typography variant="body1" color="text.secondary">
                    Нет данных
                  </Typography>
                ) : (
                  <List>
                    {data.diseases.map((disease, index) => (
                      <Box key={index}>
                        {index > 0 && <Divider />}
                        <ListItem>
                          <ListItemIcon>
                            <HospitalIcon color="error" />
                          </ListItemIcon>
                          <ListItemText
                            primary={<Typography fontWeight="bold">{disease.disease_name}</Typography>}
                            secondary={
                              disease.diagnosis_date
                                ? `Диагностировано: ${new Date(
                                    disease.diagnosis_date
                                  ).toLocaleDateString('ru-RU')}`
                                : null
                            }
                          />
                        </ListItem>
                      </Box>
                    ))}
                  </List>
                )}
              </CardContent>
            </Card>
          </Grid>

          {/* Current Medications */}
          <Grid item xs={12}>
            <Card elevation={3}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <MedicationIcon sx={{ mr: 1 }} color="primary" />
                  <Typography variant="h6" fontWeight="bold">
                    Принимаемые препараты
                  </Typography>
                </Box>
                {!data?.medications || data.medications.length === 0 ? (
                  <Typography variant="body1" color="text.secondary">
                    Нет данных о препаратах
                  </Typography>
                ) : (
                  <List>
                    {data.medications.map((med, index) => (
                      <Box key={index}>
                        {index > 0 && <Divider />}
                        <ListItem>
                          <ListItemIcon>
                            <MedicationIcon />
                          </ListItemIcon>
                          <ListItemText
                            primary={<Typography fontWeight="bold">{med.medication_name}</Typography>}
                            secondary={
                              <>
                                <Typography component="span" variant="body2">
                                  Дозировка: {med.dosage}
                                </Typography>
                                <br />
                                <Typography component="span" variant="body2">
                                  Частота: {med.frequency}
                                </Typography>
                                {med.start_date && (
                                  <>
                                    <br />
                                    <Typography component="span" variant="body2">
                                      Начало приема:{' '}
                                      {new Date(med.start_date).toLocaleDateString('ru-RU')}
                                    </Typography>
                                  </>
                                )}
                              </>
                            }
                          />
                        </ListItem>
                      </Box>
                    ))}
                  </List>
                )}
              </CardContent>
            </Card>
          </Grid>

          {/* Emergency Contacts */}
          <Grid item xs={12}>
            <Card elevation={3} sx={{ bgcolor: '#e3f2fd' }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <PhoneIcon sx={{ mr: 1, color: '#1565c0' }} />
                  <Typography variant="h6" fontWeight="bold">
                    Экстренные контакты
                  </Typography>
                </Box>
                {!data?.emergency_contacts || data.emergency_contacts.length === 0 ? (
                  <Alert severity="warning">Нет данных об экстренных контактах</Alert>
                ) : (
                  <Grid container spacing={2}>
                    {data.emergency_contacts.map((contact, index) => (
                      <Grid item xs={12} sm={6} key={index}>
                        <Paper elevation={2} sx={{ p: 2 }}>
                          <Typography variant="h6" fontWeight="bold">
                            {contact.full_name}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {contact.relationship}
                          </Typography>
                          <Typography variant="h5" color="primary" sx={{ mt: 1 }}>
                            {contact.phone}
                          </Typography>
                        </Paper>
                      </Grid>
                    ))}
                  </Grid>
                )}
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Footer */}
        <Paper elevation={3} sx={{ p: 2, mt: 3, textAlign: 'center', bgcolor: '#fafafa' }}>
          <Typography variant="body2" color="text.secondary">
            NFC Medical Platform - Экстренный доступ к медицинским данным
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Данные предоставлены с согласия пациента для использования в экстренных ситуациях
          </Typography>
        </Paper>
      </Container>
    </Box>
  )
}

export default EmergencyAccess

import { useState, useEffect } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
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
  Card,
  CardContent,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Divider,
  Alert,
  CircularProgress,
  Avatar,
} from '@mui/material'
import {
  ArrowBack as ArrowBackIcon,
  Add as AddIcon,
  Delete as DeleteIcon,
  Edit as EditIcon,
  Save as SaveIcon,
  Person as PersonIcon,
} from '@mui/icons-material'
import { toast } from 'react-toastify'
import { doctorAPI } from '../services/api'

function PatientProfile() {
  const navigate = useNavigate()
  const { userId } = useParams()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [patientName, setPatientName] = useState('')

  const [profile, setProfile] = useState({
    blood_type: '',
    height: '',
    weight: '',
    emergency_notes: '',
  })

  const [allergies, setAllergies] = useState([])
  const [diseases, setDiseases] = useState([])
  const [medications, setMedications] = useState([])
  const [emergencyContacts, setEmergencyContacts] = useState([])

  const [allergyDialog, setAllergyDialog] = useState(false)
  const [diseaseDialog, setDiseaseDialog] = useState(false)
  const [medicationDialog, setMedicationDialog] = useState(false)
  const [contactDialog, setContactDialog] = useState(false)

  const [editingAllergy, setEditingAllergy] = useState(null)
  const [editingDisease, setEditingDisease] = useState(null)
  const [editingMedication, setEditingMedication] = useState(null)
  const [editingContact, setEditingContact] = useState(null)

  const [newAllergy, setNewAllergy] = useState({ allergen: '', severity: 'MODERATE', reaction: '' })
  const [newDisease, setNewDisease] = useState({ disease_name: '', diagnosis_date: '', notes: '' })
  const [newMedication, setNewMedication] = useState({ medication_name: '', dosage: '', frequency: 'ONCE_DAILY', start_date: '' })
  const [newContact, setNewContact] = useState({ full_name: '', relationship: 'OTHER', phone: '' })

  useEffect(() => {
    loadData()
  }, [userId])

  const loadData = async () => {
    try {
      setLoading(true)
      const [profileRes, allergiesRes, diseasesRes, medsRes, contactsRes] = await Promise.allSettled([
        doctorAPI.getPatientProfile(userId),
        doctorAPI.getPatientAllergies(userId),
        doctorAPI.getPatientDiseases(userId),
        doctorAPI.getPatientMedications(userId),
        doctorAPI.getPatientContacts(userId),
      ])

      if (profileRes.status === 'fulfilled') {
        const p = profileRes.value.data
        setProfile(p)
        if (p.user_name) setPatientName(p.user_name)
      }
      setAllergies(allergiesRes.status === 'fulfilled' ? (allergiesRes.value.data || []) : [])
      setDiseases(diseasesRes.status === 'fulfilled' ? (diseasesRes.value.data || []) : [])
      setMedications(medsRes.status === 'fulfilled' ? (medsRes.value.data || []) : [])
      setEmergencyContacts(contactsRes.status === 'fulfilled' ? (contactsRes.value.data || []) : [])
    } catch {
      toast.error('Ошибка загрузки данных пациента')
    } finally {
      setLoading(false)
    }
  }

  const handleSaveProfile = async () => {
    try {
      setSaving(true)
      await doctorAPI.updatePatientProfile(userId, profile)
      toast.success('Профиль сохранён')
    } catch {
      toast.error('Ошибка сохранения профиля')
    } finally {
      setSaving(false)
    }
  }

  // ── Allergies ──────────────────────────────────────────────────────────────
  const handleSaveAllergy = async () => {
    try {
      if (editingAllergy) {
        const res = await doctorAPI.updatePatientAllergy(userId, editingAllergy.id, newAllergy)
        setAllergies(allergies.map((a) => (a.id === editingAllergy.id ? res.data : a)))
        toast.success('Аллергия обновлена')
      } else {
        const res = await doctorAPI.addPatientAllergy(userId, newAllergy)
        setAllergies([...allergies, res.data])
        toast.success('Аллергия добавлена')
      }
      closeAllergyDialog()
    } catch { toast.error('Ошибка сохранения аллергии') }
  }
  const closeAllergyDialog = () => {
    setAllergyDialog(false); setEditingAllergy(null)
    setNewAllergy({ allergen: '', severity: 'MODERATE', reaction: '' })
  }
  const handleDeleteAllergy = async (id) => {
    try {
      await doctorAPI.deletePatientAllergy(userId, id)
      setAllergies(allergies.filter((a) => a.id !== id))
      toast.success('Аллергия удалена')
    } catch { toast.error('Ошибка удаления аллергии') }
  }

  // ── Diseases ───────────────────────────────────────────────────────────────
  const handleSaveDisease = async () => {
    try {
      if (editingDisease) {
        const res = await doctorAPI.updatePatientDisease(userId, editingDisease.id, newDisease)
        setDiseases(diseases.map((d) => (d.id === editingDisease.id ? res.data : d)))
        toast.success('Заболевание обновлено')
      } else {
        const res = await doctorAPI.addPatientDisease(userId, newDisease)
        setDiseases([...diseases, res.data])
        toast.success('Заболевание добавлено')
      }
      closeDiseaseDialog()
    } catch { toast.error('Ошибка сохранения заболевания') }
  }
  const closeDiseaseDialog = () => {
    setDiseaseDialog(false); setEditingDisease(null)
    setNewDisease({ disease_name: '', diagnosis_date: '', notes: '' })
  }
  const handleDeleteDisease = async (id) => {
    try {
      await doctorAPI.deletePatientDisease(userId, id)
      setDiseases(diseases.filter((d) => d.id !== id))
      toast.success('Заболевание удалено')
    } catch { toast.error('Ошибка удаления заболевания') }
  }

  // ── Medications ────────────────────────────────────────────────────────────
  const handleSaveMedication = async () => {
    try {
      if (editingMedication) {
        const res = await doctorAPI.updatePatientMedication(userId, editingMedication.id, newMedication)
        setMedications(medications.map((m) => (m.id === editingMedication.id ? res.data : m)))
        toast.success('Препарат обновлён')
      } else {
        const res = await doctorAPI.addPatientMedication(userId, newMedication)
        setMedications([...medications, res.data])
        toast.success('Препарат добавлен')
      }
      closeMedDialog()
    } catch { toast.error('Ошибка сохранения препарата') }
  }
  const closeMedDialog = () => {
    setMedicationDialog(false); setEditingMedication(null)
    setNewMedication({ medication_name: '', dosage: '', frequency: 'ONCE_DAILY', start_date: '' })
  }
  const handleDeleteMedication = async (id) => {
    try {
      await doctorAPI.deletePatientMedication(userId, id)
      setMedications(medications.filter((m) => m.id !== id))
      toast.success('Препарат удалён')
    } catch { toast.error('Ошибка удаления препарата') }
  }

  // ── Contacts ───────────────────────────────────────────────────────────────
  const handleSaveContact = async () => {
    try {
      if (editingContact) {
        const res = await doctorAPI.updatePatientContact(userId, editingContact.id, newContact)
        setEmergencyContacts(emergencyContacts.map((c) => (c.id === editingContact.id ? res.data : c)))
        toast.success('Контакт обновлён')
      } else {
        const res = await doctorAPI.addPatientContact(userId, newContact)
        setEmergencyContacts([...emergencyContacts, res.data])
        toast.success('Контакт добавлен')
      }
      closeContactDialog()
    } catch { toast.error('Ошибка сохранения контакта') }
  }
  const closeContactDialog = () => {
    setContactDialog(false); setEditingContact(null)
    setNewContact({ full_name: '', relationship: 'OTHER', phone: '' })
  }
  const handleDeleteContact = async (id) => {
    try {
      await doctorAPI.deletePatientContact(userId, id)
      setEmergencyContacts(emergencyContacts.filter((c) => c.id !== id))
      toast.success('Контакт удалён')
    } catch { toast.error('Ошибка удаления контакта') }
  }

  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '100vh' }}>
        <CircularProgress />
      </Box>
    )
  }

  return (
    <>
      <AppBar position="static">
        <Toolbar>
          <IconButton edge="start" color="inherit" onClick={() => navigate('/patients')}>
            <ArrowBackIcon />
          </IconButton>
          <Avatar sx={{ bgcolor: 'secondary.main', mx: 1 }}>
            <PersonIcon />
          </Avatar>
          <Typography variant="h6" sx={{ flexGrow: 1 }}>
            {patientName || 'Профиль пациента'}
          </Typography>
        </Toolbar>
      </AppBar>

      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Grid container spacing={3}>

          {/* Basic Medical Info */}
          <Grid item xs={12}>
            <Paper elevation={3} sx={{ p: 3 }}>
              <Typography variant="h5" gutterBottom>
                Основная информация
              </Typography>
              <Grid container spacing={2} sx={{ mt: 1 }}>
                <Grid item xs={12} sm={6}>
                  <FormControl fullWidth>
                    <InputLabel>Группа крови</InputLabel>
                    <Select
                      value={profile.blood_type || ''}
                      label="Группа крови"
                      onChange={(e) => setProfile({ ...profile, blood_type: e.target.value })}
                    >
                      <MenuItem value="I+">I (0) Rh+</MenuItem>
                      <MenuItem value="I-">I (0) Rh-</MenuItem>
                      <MenuItem value="II+">II (A) Rh+</MenuItem>
                      <MenuItem value="II-">II (A) Rh-</MenuItem>
                      <MenuItem value="III+">III (B) Rh+</MenuItem>
                      <MenuItem value="III-">III (B) Rh-</MenuItem>
                      <MenuItem value="IV+">IV (AB) Rh+</MenuItem>
                      <MenuItem value="IV-">IV (AB) Rh-</MenuItem>
                    </Select>
                  </FormControl>
                </Grid>
                <Grid item xs={12} sm={3}>
                  <TextField fullWidth label="Рост (см)" type="number"
                    value={profile.height || ''}
                    onChange={(e) => setProfile({ ...profile, height: e.target.value })} />
                </Grid>
                <Grid item xs={12} sm={3}>
                  <TextField fullWidth label="Вес (кг)" type="number"
                    value={profile.weight || ''}
                    onChange={(e) => setProfile({ ...profile, weight: e.target.value })} />
                </Grid>
                <Grid item xs={12}>
                  <TextField fullWidth multiline rows={3}
                    label="Экстренные заметки"
                    value={profile.emergency_notes || ''}
                    onChange={(e) => setProfile({ ...profile, emergency_notes: e.target.value })} />
                </Grid>
                <Grid item xs={12}>
                  <Button variant="contained" startIcon={<SaveIcon />}
                    onClick={handleSaveProfile} disabled={saving}>
                    {saving ? 'Сохранение...' : 'Сохранить'}
                  </Button>
                </Grid>
              </Grid>
            </Paper>
          </Grid>

          {/* Allergies */}
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                  <Typography variant="h6">Аллергии</Typography>
                  <IconButton color="primary" onClick={() => setAllergyDialog(true)}><AddIcon /></IconButton>
                </Box>
                {allergies.length === 0 ? (
                  <Alert severity="info">Нет данных об аллергиях</Alert>
                ) : (
                  <List>
                    {allergies.map((a, i) => (
                      <Box key={a.id}>
                        {i > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={a.allergen}
                            secondary={
                              <Chip label={
                                a.severity === 'LIFE_THREATENING' ? 'Угроза жизни'
                                  : a.severity === 'SEVERE' ? 'Тяжёлая'
                                  : a.severity === 'MODERATE' ? 'Средняя' : 'Лёгкая'
                              } size="small"
                                color={a.severity === 'LIFE_THREATENING' || a.severity === 'SEVERE' ? 'error'
                                  : a.severity === 'MODERATE' ? 'warning' : 'default'} />
                            }
                          />
                          <ListItemSecondaryAction>
                            <IconButton edge="end" onClick={() => {
                              setEditingAllergy(a)
                              setNewAllergy({ allergen: a.allergen, severity: a.severity, reaction: a.reaction || '' })
                              setAllergyDialog(true)
                            }}><EditIcon /></IconButton>
                            <IconButton edge="end" onClick={() => handleDeleteAllergy(a.id)}><DeleteIcon /></IconButton>
                          </ListItemSecondaryAction>
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
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                  <Typography variant="h6">Хронические заболевания</Typography>
                  <IconButton color="primary" onClick={() => setDiseaseDialog(true)}><AddIcon /></IconButton>
                </Box>
                {diseases.length === 0 ? (
                  <Alert severity="info">Нет данных о заболеваниях</Alert>
                ) : (
                  <List>
                    {diseases.map((d, i) => (
                      <Box key={d.id}>
                        {i > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={d.disease_name}
                            secondary={d.diagnosis_date
                              ? `Диагностировано: ${new Date(d.diagnosis_date).toLocaleDateString('ru-RU')}`
                              : null}
                          />
                          <ListItemSecondaryAction>
                            <IconButton edge="end" onClick={() => {
                              setEditingDisease(d)
                              setNewDisease({ disease_name: d.disease_name, diagnosis_date: d.diagnosis_date || '', notes: d.notes || '' })
                              setDiseaseDialog(true)
                            }}><EditIcon /></IconButton>
                            <IconButton edge="end" onClick={() => handleDeleteDisease(d.id)}><DeleteIcon /></IconButton>
                          </ListItemSecondaryAction>
                        </ListItem>
                      </Box>
                    ))}
                  </List>
                )}
              </CardContent>
            </Card>
          </Grid>

          {/* Medications */}
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                  <Typography variant="h6">Препараты</Typography>
                  <IconButton color="primary" onClick={() => setMedicationDialog(true)}><AddIcon /></IconButton>
                </Box>
                {medications.length === 0 ? (
                  <Alert severity="info">Нет данных о препаратах</Alert>
                ) : (
                  <List>
                    {medications.map((m, i) => (
                      <Box key={m.id}>
                        {i > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={m.medication_name}
                            secondary={`${m.dosage || '—'} · ${m.frequency || '—'}`}
                          />
                          <ListItemSecondaryAction>
                            <IconButton edge="end" onClick={() => {
                              setEditingMedication(m)
                              setNewMedication({ medication_name: m.medication_name, dosage: m.dosage || '', frequency: m.frequency || 'ONCE_DAILY', start_date: m.start_date || '' })
                              setMedicationDialog(true)
                            }}><EditIcon /></IconButton>
                            <IconButton edge="end" onClick={() => handleDeleteMedication(m.id)}><DeleteIcon /></IconButton>
                          </ListItemSecondaryAction>
                        </ListItem>
                      </Box>
                    ))}
                  </List>
                )}
              </CardContent>
            </Card>
          </Grid>

          {/* Emergency Contacts */}
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                  <Typography variant="h6">Экстренные контакты</Typography>
                  <IconButton color="primary" onClick={() => setContactDialog(true)}><AddIcon /></IconButton>
                </Box>
                {emergencyContacts.length === 0 ? (
                  <Alert severity="warning">Нет экстренных контактов</Alert>
                ) : (
                  <List>
                    {emergencyContacts.map((c, i) => (
                      <Box key={c.id}>
                        {i > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={c.full_name}
                            secondary={`${c.relationship} · ${c.phone}`}
                          />
                          <ListItemSecondaryAction>
                            <IconButton edge="end" onClick={() => {
                              setEditingContact(c)
                              setNewContact({ full_name: c.full_name, relationship: c.relationship || 'OTHER', phone: c.phone || '' })
                              setContactDialog(true)
                            }}><EditIcon /></IconButton>
                            <IconButton edge="end" onClick={() => handleDeleteContact(c.id)}><DeleteIcon /></IconButton>
                          </ListItemSecondaryAction>
                        </ListItem>
                      </Box>
                    ))}
                  </List>
                )}
              </CardContent>
            </Card>
          </Grid>

        </Grid>
      </Container>

      {/* Allergy Dialog */}
      <Dialog open={allergyDialog} onClose={closeAllergyDialog} maxWidth="sm" fullWidth>
        <DialogTitle>{editingAllergy ? 'Редактировать аллергию' : 'Добавить аллергию'}</DialogTitle>
        <DialogContent>
          <TextField autoFocus fullWidth label="Аллерген" value={newAllergy.allergen}
            onChange={(e) => setNewAllergy({ ...newAllergy, allergen: e.target.value })}
            sx={{ mt: 2, mb: 2 }} />
          <TextField fullWidth label="Реакция" value={newAllergy.reaction}
            onChange={(e) => setNewAllergy({ ...newAllergy, reaction: e.target.value })}
            sx={{ mb: 2 }} />
          <FormControl fullWidth>
            <InputLabel>Степень тяжести</InputLabel>
            <Select value={newAllergy.severity} label="Степень тяжести"
              onChange={(e) => setNewAllergy({ ...newAllergy, severity: e.target.value })}>
              <MenuItem value="MILD">Лёгкая</MenuItem>
              <MenuItem value="MODERATE">Средняя</MenuItem>
              <MenuItem value="SEVERE">Тяжёлая</MenuItem>
              <MenuItem value="LIFE_THREATENING">Угроза жизни</MenuItem>
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={closeAllergyDialog}>Отмена</Button>
          <Button onClick={handleSaveAllergy} variant="contained">
            {editingAllergy ? 'Сохранить' : 'Добавить'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Disease Dialog */}
      <Dialog open={diseaseDialog} onClose={closeDiseaseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>{editingDisease ? 'Редактировать заболевание' : 'Добавить заболевание'}</DialogTitle>
        <DialogContent>
          <TextField autoFocus fullWidth label="Название заболевания" value={newDisease.disease_name}
            onChange={(e) => setNewDisease({ ...newDisease, disease_name: e.target.value })}
            sx={{ mt: 2, mb: 2 }} />
          <TextField fullWidth label="Дата диагностирования" type="date"
            value={newDisease.diagnosis_date}
            onChange={(e) => setNewDisease({ ...newDisease, diagnosis_date: e.target.value })}
            InputLabelProps={{ shrink: true }} sx={{ mb: 2 }} />
          <TextField fullWidth multiline rows={3} label="Заметки" value={newDisease.notes}
            onChange={(e) => setNewDisease({ ...newDisease, notes: e.target.value })} />
        </DialogContent>
        <DialogActions>
          <Button onClick={closeDiseaseDialog}>Отмена</Button>
          <Button onClick={handleSaveDisease} variant="contained">
            {editingDisease ? 'Сохранить' : 'Добавить'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Medication Dialog */}
      <Dialog open={medicationDialog} onClose={closeMedDialog} maxWidth="sm" fullWidth>
        <DialogTitle>{editingMedication ? 'Редактировать препарат' : 'Добавить препарат'}</DialogTitle>
        <DialogContent>
          <TextField autoFocus fullWidth label="Название препарата" value={newMedication.medication_name}
            onChange={(e) => setNewMedication({ ...newMedication, medication_name: e.target.value })}
            sx={{ mt: 2, mb: 2 }} />
          <TextField fullWidth label="Дозировка" value={newMedication.dosage}
            onChange={(e) => setNewMedication({ ...newMedication, dosage: e.target.value })}
            sx={{ mb: 2 }} />
          <FormControl fullWidth sx={{ mb: 2 }}>
            <InputLabel>Частота приёма</InputLabel>
            <Select value={newMedication.frequency} label="Частота приёма"
              onChange={(e) => setNewMedication({ ...newMedication, frequency: e.target.value })}>
              <MenuItem value="ONCE_DAILY">1 раз в день</MenuItem>
              <MenuItem value="TWICE_DAILY">2 раза в день</MenuItem>
              <MenuItem value="THREE_TIMES_DAILY">3 раза в день</MenuItem>
              <MenuItem value="FOUR_TIMES_DAILY">4 раза в день</MenuItem>
              <MenuItem value="AS_NEEDED">По необходимости</MenuItem>
              <MenuItem value="WEEKLY">Еженедельно</MenuItem>
              <MenuItem value="MONTHLY">Ежемесячно</MenuItem>
            </Select>
          </FormControl>
          <TextField fullWidth label="Дата начала" type="date" value={newMedication.start_date}
            onChange={(e) => setNewMedication({ ...newMedication, start_date: e.target.value })}
            InputLabelProps={{ shrink: true }} />
        </DialogContent>
        <DialogActions>
          <Button onClick={closeMedDialog}>Отмена</Button>
          <Button onClick={handleSaveMedication} variant="contained">
            {editingMedication ? 'Сохранить' : 'Добавить'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Contact Dialog */}
      <Dialog open={contactDialog} onClose={closeContactDialog} maxWidth="sm" fullWidth>
        <DialogTitle>{editingContact ? 'Редактировать контакт' : 'Добавить контакт'}</DialogTitle>
        <DialogContent>
          <TextField autoFocus fullWidth label="ФИО" value={newContact.full_name}
            onChange={(e) => setNewContact({ ...newContact, full_name: e.target.value })}
            sx={{ mt: 2, mb: 2 }} />
          <TextField fullWidth label="Отношение" value={newContact.relationship}
            onChange={(e) => setNewContact({ ...newContact, relationship: e.target.value })}
            sx={{ mb: 2 }} />
          <TextField fullWidth label="Телефон" value={newContact.phone}
            onChange={(e) => setNewContact({ ...newContact, phone: e.target.value })} />
        </DialogContent>
        <DialogActions>
          <Button onClick={closeContactDialog}>Отмена</Button>
          <Button onClick={handleSaveContact} variant="contained">
            {editingContact ? 'Сохранить' : 'Добавить'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default PatientProfile

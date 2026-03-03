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
} from '@mui/material'
import {
  ArrowBack as ArrowBackIcon,
  Add as AddIcon,
  Delete as DeleteIcon,
  Edit as EditIcon,
  Save as SaveIcon,
} from '@mui/icons-material'
import { toast } from 'react-toastify'
import { useAuth } from '../contexts/AuthContext'
import { profileAPI } from '../services/api'

function Profile() {
  const navigate = useNavigate()
  const { user, logout } = useAuth()
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)

  // Profile data
  const [profile, setProfile] = useState({
    blood_type: '',
    height: '',
    weight: '',
    emergency_notes: '',
  })

  // Lists
  const [allergies, setAllergies] = useState([])
  const [diseases, setDiseases] = useState([])
  const [medications, setMedications] = useState([])
  const [emergencyContacts, setEmergencyContacts] = useState([])

  // Dialog states
  const [allergyDialog, setAllergyDialog] = useState(false)
  const [diseaseDialog, setDiseaseDialog] = useState(false)
  const [medicationDialog, setMedicationDialog] = useState(false)
  const [contactDialog, setContactDialog] = useState(false)

  // Editing states (null = adding new, object = editing existing)
  const [editingAllergy, setEditingAllergy] = useState(null)
  const [editingDisease, setEditingDisease] = useState(null)
  const [editingMedication, setEditingMedication] = useState(null)
  const [editingContact, setEditingContact] = useState(null)

  // Form data for dialogs
  const [newAllergy, setNewAllergy] = useState({ allergen: '', severity: 'MODERATE', reaction: '' })
  const [newDisease, setNewDisease] = useState({ disease_name: '', diagnosis_date: '', notes: '' })
  const [newMedication, setNewMedication] = useState({
    medication_name: '',
    dosage: '',
    frequency: 'ONCE_DAILY',
    start_date: '',
  })
  const [newContact, setNewContact] = useState({
    full_name: '',
    relationship: 'OTHER',
    phone: '',
  })

  useEffect(() => {
    loadProfileData()
  }, [])

  const loadProfileData = async () => {
    try {
      setLoading(true)

      // Try to load profile
      let profileData = null
      try {
        const profileRes = await profileAPI.getProfile()
        profileData = profileRes.data
      } catch (error) {
        // If profile doesn't exist (404), that's ok - we'll create it on first save
        if (error.response?.status === 404) {
          console.log('Profile not found, will be created on first save')
          profileData = {
            blood_type: '',
            height: '',
            weight: '',
            emergency_notes: '',
          }
        } else {
          throw error
        }
      }

      const [allergiesRes, diseasesRes, medicationsRes, contactsRes] = await Promise.all([
        profileAPI.getAllergies().catch(() => ({ data: [] })),
        profileAPI.getChronicDiseases().catch(() => ({ data: [] })),
        profileAPI.getMedications().catch(() => ({ data: [] })),
        profileAPI.getEmergencyContacts().catch(() => ({ data: [] })),
      ])

      setProfile(profileData)
      setAllergies(Array.isArray(allergiesRes.data) ? allergiesRes.data : [])
      setDiseases(Array.isArray(diseasesRes.data) ? diseasesRes.data : [])
      setMedications(Array.isArray(medicationsRes.data) ? medicationsRes.data : [])
      setEmergencyContacts(Array.isArray(contactsRes.data) ? contactsRes.data : [])
    } catch (error) {
      toast.error('Ошибка загрузки данных профиля')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  const handleSaveProfile = async () => {
    try {
      setSaving(true)

      // If profile has id, update it; otherwise create it
      let response
      if (profile.id) {
        response = await profileAPI.updateProfile(profile)
        toast.success('Профиль обновлен')
      } else {
        response = await profileAPI.createProfile(profile)
        toast.success('Профиль создан')
      }

      // Update profile with response data (including id for newly created profiles)
      setProfile(response.data)
    } catch (error) {
      toast.error(error.response?.data?.error || 'Ошибка сохранения профиля')
      console.error(error)
    } finally {
      setSaving(false)
    }
  }

  const handleAddAllergy = async () => {
    try {
      if (!profile.id) {
        const profileResponse = await profileAPI.createProfile(profile)
        setProfile(profileResponse.data)
      }
      if (editingAllergy) {
        const response = await profileAPI.updateAllergy(editingAllergy.id, newAllergy)
        setAllergies(allergies.map((a) => (a.id === editingAllergy.id ? response.data : a)))
        toast.success('Аллергия обновлена')
      } else {
        const response = await profileAPI.addAllergy(newAllergy)
        setAllergies([...allergies, response.data])
        toast.success('Аллергия добавлена')
      }
      setAllergyDialog(false)
      setEditingAllergy(null)
      setNewAllergy({ allergen: '', severity: 'MODERATE', reaction: '' })
    } catch (error) {
      toast.error('Ошибка сохранения аллергии')
      console.error(error)
    }
  }

  const handleEditAllergy = (allergy) => {
    setEditingAllergy(allergy)
    setNewAllergy({ allergen: allergy.allergen, severity: allergy.severity, reaction: allergy.reaction || '' })
    setAllergyDialog(true)
  }

  const handleDeleteAllergy = async (id) => {
    try {
      await profileAPI.deleteAllergy(id)
      setAllergies(allergies.filter((a) => a.id !== id))
      toast.success('Аллергия удалена')
    } catch (error) {
      toast.error('Ошибка удаления аллергии')
      console.error(error)
    }
  }

  const handleAddDisease = async () => {
    try {
      if (!profile.id) {
        const profileResponse = await profileAPI.createProfile(profile)
        setProfile(profileResponse.data)
      }
      if (editingDisease) {
        const response = await profileAPI.updateChronicDisease(editingDisease.id, newDisease)
        setDiseases(diseases.map((d) => (d.id === editingDisease.id ? response.data : d)))
        toast.success('Заболевание обновлено')
      } else {
        const response = await profileAPI.addChronicDisease(newDisease)
        setDiseases([...diseases, response.data])
        toast.success('Заболевание добавлено')
      }
      setDiseaseDialog(false)
      setEditingDisease(null)
      setNewDisease({ disease_name: '', diagnosis_date: '', notes: '' })
    } catch (error) {
      toast.error('Ошибка сохранения заболевания')
      console.error(error)
    }
  }

  const handleEditDisease = (disease) => {
    setEditingDisease(disease)
    setNewDisease({ disease_name: disease.disease_name, diagnosis_date: disease.diagnosis_date || '', notes: disease.notes || '' })
    setDiseaseDialog(true)
  }

  const handleDeleteDisease = async (id) => {
    try {
      await profileAPI.deleteChronicDisease(id)
      setDiseases(diseases.filter((d) => d.id !== id))
      toast.success('Заболевание удалено')
    } catch (error) {
      toast.error('Ошибка удаления заболевания')
      console.error(error)
    }
  }

  const handleAddMedication = async () => {
    try {
      if (!profile.id) {
        const profileResponse = await profileAPI.createProfile(profile)
        setProfile(profileResponse.data)
      }
      if (editingMedication) {
        const response = await profileAPI.updateMedication(editingMedication.id, newMedication)
        setMedications(medications.map((m) => (m.id === editingMedication.id ? response.data : m)))
        toast.success('Препарат обновлён')
      } else {
        const response = await profileAPI.addMedication(newMedication)
        setMedications([...medications, response.data])
        toast.success('Препарат добавлен')
      }
      setMedicationDialog(false)
      setEditingMedication(null)
      setNewMedication({ medication_name: '', dosage: '', frequency: 'ONCE_DAILY', start_date: '' })
    } catch (error) {
      toast.error('Ошибка сохранения препарата')
      console.error(error)
    }
  }

  const handleEditMedication = (med) => {
    setEditingMedication(med)
    setNewMedication({ medication_name: med.medication_name, dosage: med.dosage || '', frequency: med.frequency || 'ONCE_DAILY', start_date: med.start_date || '' })
    setMedicationDialog(true)
  }

  const handleDeleteMedication = async (id) => {
    try {
      await profileAPI.deleteMedication(id)
      setMedications(medications.filter((m) => m.id !== id))
      toast.success('Препарат удален')
    } catch (error) {
      toast.error('Ошибка удаления препарата')
      console.error(error)
    }
  }

  const handleAddContact = async () => {
    try {
      if (!profile.id) {
        const profileResponse = await profileAPI.createProfile(profile)
        setProfile(profileResponse.data)
      }
      if (editingContact) {
        const response = await profileAPI.updateEmergencyContact(editingContact.id, newContact)
        setEmergencyContacts(emergencyContacts.map((c) => (c.id === editingContact.id ? response.data : c)))
        toast.success('Контакт обновлён')
      } else {
        const response = await profileAPI.addEmergencyContact(newContact)
        setEmergencyContacts([...emergencyContacts, response.data])
        toast.success('Контакт добавлен')
      }
      setContactDialog(false)
      setEditingContact(null)
      setNewContact({ full_name: '', relationship: 'OTHER', phone: '' })
    } catch (error) {
      toast.error('Ошибка сохранения контакта')
      console.error(error)
    }
  }

  const handleEditContact = (contact) => {
    setEditingContact(contact)
    setNewContact({ full_name: contact.full_name, relationship: contact.relationship || 'OTHER', phone: contact.phone || '' })
    setContactDialog(true)
  }

  const handleDeleteContact = async (id) => {
    try {
      await profileAPI.deleteEmergencyContact(id)
      setEmergencyContacts(emergencyContacts.filter((c) => c.id !== id))
      toast.success('Контакт удален')
    } catch (error) {
      toast.error('Ошибка удаления контакта')
      console.error(error)
    }
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
            Медицинский профиль
          </Typography>
          <Avatar sx={{ bgcolor: 'secondary.main' }}>
            {user?.first_name?.[0]?.toUpperCase() || 'U'}
          </Avatar>
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
                      value={profile.blood_type}
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
                  <TextField
                    fullWidth
                    label="Рост (см)"
                    type="number"
                    value={profile.height}
                    onChange={(e) => setProfile({ ...profile, height: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12} sm={3}>
                  <TextField
                    fullWidth
                    label="Вес (кг)"
                    type="number"
                    value={profile.weight}
                    onChange={(e) => setProfile({ ...profile, weight: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    multiline
                    rows={3}
                    label="Экстренные заметки"
                    placeholder="Важная информация для медиков в экстренной ситуации..."
                    value={profile.emergency_notes}
                    onChange={(e) => setProfile({ ...profile, emergency_notes: e.target.value })}
                  />
                </Grid>
                <Grid item xs={12}>
                  <Button
                    variant="contained"
                    startIcon={<SaveIcon />}
                    onClick={handleSaveProfile}
                    disabled={saving}
                  >
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
                  <IconButton color="primary" onClick={() => setAllergyDialog(true)}>
                    <AddIcon />
                  </IconButton>
                </Box>
                {allergies.length === 0 ? (
                  <Alert severity="info">Нет данных об аллергиях</Alert>
                ) : (
                  <List>
                    {allergies.map((allergy, index) => (
                      <Box key={allergy.id}>
                        {index > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={allergy.allergen}
                            secondary={
                              <Chip
                                label={
                                  allergy.severity === 'LIFE_THREATENING'
                                    ? 'Опасная для жизни'
                                    : allergy.severity === 'SEVERE'
                                    ? 'Тяжелая'
                                    : allergy.severity === 'MODERATE'
                                    ? 'Средняя'
                                    : 'Легкая'
                                }
                                size="small"
                                color={
                                  allergy.severity === 'LIFE_THREATENING' || allergy.severity === 'SEVERE'
                                    ? 'error'
                                    : allergy.severity === 'MODERATE'
                                    ? 'warning'
                                    : 'default'
                                }
                              />
                            }
                          />
                          <ListItemSecondaryAction>
                            <IconButton edge="end" onClick={() => handleEditAllergy(allergy)}>
                              <EditIcon />
                            </IconButton>
                            <IconButton
                              edge="end"
                              onClick={() => handleDeleteAllergy(allergy.id)}
                            >
                              <DeleteIcon />
                            </IconButton>
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
                  <IconButton color="primary" onClick={() => setDiseaseDialog(true)}>
                    <AddIcon />
                  </IconButton>
                </Box>
                {diseases.length === 0 ? (
                  <Alert severity="info">Нет данных о заболеваниях</Alert>
                ) : (
                  <List>
                    {diseases.map((disease, index) => (
                      <Box key={disease.id}>
                        {index > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={disease.disease_name}
                            secondary={
                              disease.diagnosis_date
                                ? `Диагностировано: ${new Date(
                                    disease.diagnosis_date
                                  ).toLocaleDateString('ru-RU')}`
                                : null
                            }
                          />
                          <ListItemSecondaryAction>
                            <IconButton edge="end" onClick={() => handleEditDisease(disease)}>
                              <EditIcon />
                            </IconButton>
                            <IconButton edge="end" onClick={() => handleDeleteDisease(disease.id)}>
                              <DeleteIcon />
                            </IconButton>
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
                  <Typography variant="h6">Принимаемые препараты</Typography>
                  <IconButton color="primary" onClick={() => setMedicationDialog(true)}>
                    <AddIcon />
                  </IconButton>
                </Box>
                {medications.length === 0 ? (
                  <Alert severity="info">Нет данных о препаратах</Alert>
                ) : (
                  <List>
                    {medications.map((med, index) => (
                      <Box key={med.id}>
                        {index > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={med.medication_name}
                            secondary={`${med.dosage} - ${med.frequency}`}
                          />
                          <ListItemSecondaryAction>
                            <IconButton edge="end" onClick={() => handleEditMedication(med)}>
                              <EditIcon />
                            </IconButton>
                            <IconButton edge="end" onClick={() => handleDeleteMedication(med.id)}>
                              <DeleteIcon />
                            </IconButton>
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
                  <IconButton color="primary" onClick={() => setContactDialog(true)}>
                    <AddIcon />
                  </IconButton>
                </Box>
                {emergencyContacts.length === 0 ? (
                  <Alert severity="warning">Добавьте хотя бы один контакт</Alert>
                ) : (
                  <List>
                    {emergencyContacts.map((contact, index) => (
                      <Box key={contact.id}>
                        {index > 0 && <Divider />}
                        <ListItem>
                          <ListItemText
                            primary={contact.full_name}
                            secondary={`${contact.relationship} - ${contact.phone}`}
                          />
                          <ListItemSecondaryAction>
                            <IconButton edge="end" onClick={() => handleEditContact(contact)}>
                              <EditIcon />
                            </IconButton>
                            <IconButton edge="end" onClick={() => handleDeleteContact(contact.id)}>
                              <DeleteIcon />
                            </IconButton>
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

      {/* Add/Edit Allergy Dialog */}
      <Dialog open={allergyDialog} onClose={() => { setAllergyDialog(false); setEditingAllergy(null); setNewAllergy({ allergen: '', severity: 'MODERATE', reaction: '' }) }} maxWidth="sm" fullWidth>
        <DialogTitle>{editingAllergy ? 'Редактировать аллергию' : 'Добавить аллергию'}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            label="Аллерген"
            value={newAllergy.allergen}
            onChange={(e) => setNewAllergy({ ...newAllergy, allergen: e.target.value })}
            placeholder="Например: Пенициллин, Арахис"
            sx={{ mt: 2, mb: 2 }}
          />
          <TextField
            fullWidth
            label="Реакция"
            value={newAllergy.reaction}
            onChange={(e) => setNewAllergy({ ...newAllergy, reaction: e.target.value })}
            placeholder="Описание реакции"
            sx={{ mb: 2 }}
          />
          <FormControl fullWidth>
            <InputLabel>Степень тяжести</InputLabel>
            <Select
              value={newAllergy.severity}
              label="Степень тяжести"
              onChange={(e) => setNewAllergy({ ...newAllergy, severity: e.target.value })}
            >
              <MenuItem value="MILD">Легкая</MenuItem>
              <MenuItem value="MODERATE">Средняя</MenuItem>
              <MenuItem value="SEVERE">Тяжелая</MenuItem>
              <MenuItem value="LIFE_THREATENING">Опасная для жизни</MenuItem>
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setAllergyDialog(false); setEditingAllergy(null); setNewAllergy({ allergen: '', severity: 'MODERATE', reaction: '' }) }}>Отмена</Button>
          <Button onClick={handleAddAllergy} variant="contained">
            {editingAllergy ? 'Сохранить' : 'Добавить'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Add/Edit Disease Dialog */}
      <Dialog open={diseaseDialog} onClose={() => { setDiseaseDialog(false); setEditingDisease(null); setNewDisease({ disease_name: '', diagnosis_date: '', notes: '' }) }} maxWidth="sm" fullWidth>
        <DialogTitle>{editingDisease ? 'Редактировать заболевание' : 'Добавить заболевание'}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            label="Название заболевания"
            value={newDisease.disease_name}
            onChange={(e) => setNewDisease({ ...newDisease, disease_name: e.target.value })}
            placeholder="Например: Гипертония, Диабет 2 типа"
            sx={{ mt: 2, mb: 2 }}
          />
          <TextField
            fullWidth
            label="Дата диагностирования"
            type="date"
            value={newDisease.diagnosis_date}
            onChange={(e) => setNewDisease({ ...newDisease, diagnosis_date: e.target.value })}
            InputLabelProps={{ shrink: true }}
            sx={{ mb: 2 }}
          />
          <TextField
            fullWidth
            multiline
            rows={3}
            label="Заметки"
            value={newDisease.notes}
            onChange={(e) => setNewDisease({ ...newDisease, notes: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setDiseaseDialog(false); setEditingDisease(null); setNewDisease({ disease_name: '', diagnosis_date: '', notes: '' }) }}>Отмена</Button>
          <Button onClick={handleAddDisease} variant="contained">
            {editingDisease ? 'Сохранить' : 'Добавить'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Add/Edit Medication Dialog */}
      <Dialog
        open={medicationDialog}
        onClose={() => { setMedicationDialog(false); setEditingMedication(null); setNewMedication({ medication_name: '', dosage: '', frequency: 'ONCE_DAILY', start_date: '' }) }}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>{editingMedication ? 'Редактировать препарат' : 'Добавить препарат'}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            label="Название препарата"
            value={newMedication.medication_name}
            onChange={(e) => setNewMedication({ ...newMedication, medication_name: e.target.value })}
            placeholder="Например: Амлодипин, Метформин"
            sx={{ mt: 2, mb: 2 }}
          />
          <TextField
            fullWidth
            label="Дозировка"
            value={newMedication.dosage}
            onChange={(e) => setNewMedication({ ...newMedication, dosage: e.target.value })}
            placeholder="Например: 5 мг, 500 мг"
            sx={{ mb: 2 }}
          />
          <FormControl fullWidth sx={{ mb: 2 }}>
            <InputLabel>Частота приема</InputLabel>
            <Select
              value={newMedication.frequency}
              label="Частота приема"
              onChange={(e) => setNewMedication({ ...newMedication, frequency: e.target.value })}
            >
              <MenuItem value="ONCE_DAILY">1 раз в день</MenuItem>
              <MenuItem value="TWICE_DAILY">2 раза в день</MenuItem>
              <MenuItem value="THREE_TIMES_DAILY">3 раза в день</MenuItem>
              <MenuItem value="FOUR_TIMES_DAILY">4 раза в день</MenuItem>
              <MenuItem value="AS_NEEDED">По необходимости</MenuItem>
              <MenuItem value="WEEKLY">Еженедельно</MenuItem>
              <MenuItem value="MONTHLY">Ежемесячно</MenuItem>
            </Select>
          </FormControl>
          <TextField
            fullWidth
            label="Дата начала приема"
            type="date"
            value={newMedication.start_date}
            onChange={(e) => setNewMedication({ ...newMedication, start_date: e.target.value })}
            InputLabelProps={{ shrink: true }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setMedicationDialog(false); setEditingMedication(null); setNewMedication({ medication_name: '', dosage: '', frequency: 'ONCE_DAILY', start_date: '' }) }}>Отмена</Button>
          <Button onClick={handleAddMedication} variant="contained">
            {editingMedication ? 'Сохранить' : 'Добавить'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Add/Edit Contact Dialog */}
      <Dialog open={contactDialog} onClose={() => { setContactDialog(false); setEditingContact(null); setNewContact({ full_name: '', relationship: 'OTHER', phone: '' }) }} maxWidth="sm" fullWidth>
        <DialogTitle>{editingContact ? 'Редактировать контакт' : 'Добавить контакт'}</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            label="ФИО"
            value={newContact.full_name}
            onChange={(e) => setNewContact({ ...newContact, full_name: e.target.value })}
            sx={{ mt: 2, mb: 2 }}
          />
          <TextField
            fullWidth
            label="Отношение"
            placeholder="Например: Супруг/Супруга, Родитель"
            value={newContact.relationship}
            onChange={(e) => setNewContact({ ...newContact, relationship: e.target.value })}
            sx={{ mb: 2 }}
          />
          <TextField
            fullWidth
            label="Телефон"
            value={newContact.phone}
            onChange={(e) => setNewContact({ ...newContact, phone: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setContactDialog(false); setEditingContact(null); setNewContact({ full_name: '', relationship: 'OTHER', phone: '' }) }}>Отмена</Button>
          <Button onClick={handleAddContact} variant="contained">
            {editingContact ? 'Сохранить' : 'Добавить'}
          </Button>
        </DialogActions>
      </Dialog>
    </>
  )
}

export default Profile

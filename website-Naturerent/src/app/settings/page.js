'use client'
import { useState, useEffect } from 'react'
import Sidebar from '@/components/Sidebar'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

const DEFAULT_QRIS_LIST = [
  { id: 'qr-1', name: 'QRIS Utama', merchant: 'NatureRents', qrId: 'QR-2024-001', active: true, image: null },
  { id: 'qr-2', name: 'QRIS Cabang Surabaya', merchant: 'NatureRents SBY', qrId: 'QR-2024-002', active: false, image: null },
]

const DEFAULT_SETTINGS = {
  appName: 'NatureRent',
  description: 'NatureRent is the leading eco-friendly equipment rental platform connecting adventure seekers with premium outdoor gear and sustainable travel resources.',
  theme: 'light',
  accentColor: 'green',
  customAccentHex: '#1f5a3f',
  officialEmail: 'admin@naturerent.com',
  serviceNumber: '+62 21 5550 1234',
  officeAddress: 'The Green Hub, Fl. 12, Sudirman Central Business District, Jakarta 12190, Indonesia',
  paymentLimit: '30 Minutes',
  defaultPaymentMethod: 'QRIS',
  serviceFee: 10,
  currency: 'IDR',
  autoCancel: true,
  qrisList: DEFAULT_QRIS_LIST
}

// Helper for lighten/darken color hexes
function lightenDarkenColor(col, amt) {
  let usePound = false
  if (!col) return '#1f5a3f'
  if (col[0] === "#") {
    col = col.slice(1)
    usePound = true
  }
  let num = parseInt(col, 16)
  let r = (num >> 16) + amt
  if (r > 255) r = 255
  else if (r < 0) r = 0
  let b = ((num >> 8) & 0x00FF) + amt
  if (b > 255) b = 255
  else if (b < 0) b = 0
  let g = (num & 0x0000FF) + amt
  if (g > 255) g = 255
  else if (g < 0) g = 0
  return (usePound ? "#" : "") + (g | (b << 8) | (r << 16)).toString(16).padStart(6, '0')
}

function applyThemeAndAccent(theme, accentColor, customAccentHex) {
  if (typeof window === 'undefined') return
  const root = document.documentElement

  // Theme Variables
  if (theme === 'dark') {
    root.style.setProperty('--bg-primary', '#121214')
    root.style.setProperty('--bg-secondary', '#1a1a1e')
    root.style.setProperty('--bg-card', '#202024')
    root.style.setProperty('--bg-card-hover', '#26262b')
    root.style.setProperty('--text-primary', '#f3f4f6')
    root.style.setProperty('--text-secondary', '#9ca3af')
    root.style.setProperty('--text-muted', '#6b7280')
    root.style.setProperty('--border-color', '#303036')
    root.style.setProperty('--border-color-light', '#26262a')
  } else {
    root.style.setProperty('--bg-primary', '#f7f7f3')
    root.style.setProperty('--bg-secondary', '#f9fafb')
    root.style.setProperty('--bg-card', '#ffffff')
    root.style.setProperty('--bg-card-hover', '#fcfcf9')
    root.style.setProperty('--text-primary', '#1a2e1a')
    root.style.setProperty('--text-secondary', '#6b7280')
    root.style.setProperty('--text-muted', '#9ca3af')
    root.style.setProperty('--border-color', '#e5e7eb')
    root.style.setProperty('--border-color-light', '#f3f4f6')
  }

  // Accent Colors
  let brandGreen = '#1f5a3f'
  let brandGreenLight = '#2d6a4f'
  let brandGreenDark = '#164a30'
  let brandEmerald = '#52b788'
  let brandMint = '#d1f4e8'

  if (accentColor === 'green') {
    brandGreen = '#1f5a3f'
    brandGreenLight = '#2d6a4f'
    brandGreenDark = '#164a30'
    brandEmerald = '#52b788'
    brandMint = '#d1f4e8'
  } else if (accentColor === 'teal') {
    brandGreen = '#0d8c75'
    brandGreenLight = '#0f766e'
    brandGreenDark = '#115e59'
    brandEmerald = '#14b8a6'
    brandMint = '#ccfbf1'
  } else if (accentColor === 'forest') {
    brandGreen = '#14532d'
    brandGreenLight = '#166534'
    brandGreenDark = '#14532d'
    brandEmerald = '#22c55e'
    brandMint = '#dcfce7'
  } else if (accentColor === 'navy') {
    brandGreen = '#1e3a8a'
    brandGreenLight = '#1e40af'
    brandGreenDark = '#172554'
    brandEmerald = '#3b82f6'
    brandMint = '#dbeafe'
  } else if (accentColor === 'custom' && customAccentHex) {
    brandGreen = customAccentHex
    brandGreenLight = lightenDarkenColor(customAccentHex, 20)
    brandGreenDark = lightenDarkenColor(customAccentHex, -20)
    brandEmerald = lightenDarkenColor(customAccentHex, 40)
    brandMint = lightenDarkenColor(customAccentHex, 80)
  }

  root.style.setProperty('--brand-green', brandGreen)
  root.style.setProperty('--brand-green-light', brandGreenLight)
  root.style.setProperty('--brand-green-dark', brandGreenDark)
  root.style.setProperty('--brand-emerald', brandEmerald)
  root.style.setProperty('--brand-mint', brandMint)
  root.style.setProperty('--bg-sidebar', brandGreen)

  // Dynamically compute and inject isolated sidebar styles in full harmony
  var sidebarBg = brandGreen
  var sidebarTxt = '#c2f0dc'
  var sidebarTitleTxt = '#ffffff'
  var sidebarHoverBg = brandGreenLight
  var sidebarHoverTxt = '#ffffff'
  var sidebarActiveBg = 'rgba(255, 255, 255, 0.12)'
  var sidebarActiveTxt = '#ffffff'
  var sidebarActiveBorder = 'rgba(255, 255, 255, 0.2)'
  var sidebarBorder = brandGreenDark

  if (theme === 'dark') {
    sidebarBg = '#121214'
    sidebarTxt = '#9ca3af'
    sidebarTitleTxt = '#f3f4f6'
    sidebarHoverBg = '#1a1a1e'
    sidebarHoverTxt = '#f3f4f6'
    sidebarActiveBg = 'rgba(82, 183, 136, 0.15)'
    sidebarActiveTxt = '#52b788'
    sidebarActiveBorder = 'rgba(82, 183, 136, 0.25)'
    sidebarBorder = '#26262a'
  }

  root.style.setProperty('--sidebar-bg', sidebarBg)
  root.style.setProperty('--sidebar-txt', sidebarTxt)
  root.style.setProperty('--sidebar-title-txt', sidebarTitleTxt)
  root.style.setProperty('--sidebar-hover-bg', sidebarHoverBg)
  root.style.setProperty('--sidebar-hover-txt', sidebarHoverTxt)
  root.style.setProperty('--sidebar-active-bg', sidebarActiveBg)
  root.style.setProperty('--sidebar-active-txt', sidebarActiveTxt)
  root.style.setProperty('--sidebar-active-border', sidebarActiveBorder)
  root.style.setProperty('--sidebar-border', sidebarBorder)
}

export default function SettingsPage() {
  const { toasts, addToast, removeToast } = useToast()
  const [userEmail, setUserEmail] = useState('')
  const [saving, setSaving] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [form, setForm] = useState(DEFAULT_SETTINGS)

  // Dynamic QRIS list from Supabase (rental_profiles)
  const [rentalQrisList, setRentalQrisList] = useState([])
  const [qrisLoading, setQrisLoading] = useState(true)
  // QRIS edit modal state (edit per rental)
  const [qrisModal, setQrisModal] = useState(false)
  const [qrisEditing, setQrisEditing] = useState(null) // rental row being edited
  const [qrisMerchant, setQrisMerchant] = useState('')
  const [qrisImageFile, setQrisImageFile] = useState(null)
  const [qrisImagePreview, setQrisImagePreview] = useState(null)
  const [qrisSaving, setQrisSaving] = useState(false)

  useEffect(() => {
    const init = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      setUserEmail(user?.email || '')

      // Load settings from localStorage
      const savedSettings = localStorage.getItem('naturerent_system_settings')
      if (savedSettings) {
        try {
          const parsed = JSON.parse(savedSettings)
          setForm({ ...DEFAULT_SETTINGS, ...parsed })
        } catch {
          // ignore
        }
      }

      // Fetch QRIS list from Supabase rental_profiles
      fetchRentalQris(supabase)
    }
    init()
  }, [])

  const fetchRentalQris = async (supabaseClient) => {
    setQrisLoading(true)
    const sb = supabaseClient || createClient()
    const { data, error } = await sb
      .from('rental_profiles')
      .select('id, nama_rental, qris_image_url, qris_merchant_name, is_active')
      .order('nama_rental', { ascending: true })
    if (!error && data) {
      setRentalQrisList(data)
    }
    setQrisLoading(false)
  }

  // Open edit QRIS modal for a specific rental
  const openEditQris = (rental) => {
    setQrisEditing(rental)
    setQrisMerchant(rental.qris_merchant_name || '')
    setQrisImagePreview(rental.qris_image_url || null)
    setQrisImageFile(null)
    setQrisModal(true)
  }

  const handleQrisImageChange = (e) => {
    const file = e.target.files[0]
    if (!file) return
    if (file.size > 2 * 1024 * 1024) { addToast('Gambar terlalu besar (maks 2MB)', 'error'); return }
    setQrisImageFile(file)
    setQrisImagePreview(URL.createObjectURL(file))
  }

  const saveQris = async () => {
    if (!qrisEditing) return
    if (!qrisMerchant.trim()) { addToast('Nama merchant wajib diisi!', 'error'); return }
    setQrisSaving(true)
    const supabase = createClient()
    let imageUrl = qrisEditing.qris_image_url || null

    // Upload new image to Supabase Storage if a new file was selected
    if (qrisImageFile) {
      const fileExt = qrisImageFile.name.split('.').pop()
      const filePath = `${qrisEditing.id}/qris.${fileExt}`
      const { error: uploadError } = await supabase.storage
        .from('qris-images')
        .upload(filePath, qrisImageFile, { upsert: true, contentType: qrisImageFile.type })
      if (uploadError) {
        addToast('Gagal upload gambar: ' + uploadError.message, 'error')
        setQrisSaving(false)
        return
      }
      const { data: urlData } = supabase.storage.from('qris-images').getPublicUrl(filePath)
      imageUrl = urlData?.publicUrl || null
    }

    // Save merchant name + image URL to rental_profiles
    const { error: updateError } = await supabase
      .from('rental_profiles')
      .update({ qris_merchant_name: qrisMerchant.trim(), qris_image_url: imageUrl })
      .eq('id', qrisEditing.id)

    setQrisSaving(false)
    if (updateError) {
      addToast('Gagal menyimpan QRIS: ' + updateError.message, 'error')
      return
    }
    addToast('QRIS berhasil diperbarui!', 'success')
    setQrisModal(false)
    fetchRentalQris()
  }

  // Real-time appearance switcher (Preview Mode)
  useEffect(() => {
    applyThemeAndAccent(form.theme, form.accentColor, form.customAccentHex)
  }, [form.theme, form.accentColor, form.customAccentHex])

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    
    // Simulate save delay
    await new Promise(resolve => setTimeout(resolve, 600))
    localStorage.setItem('naturerent_system_settings', JSON.stringify(form))
    
    setSaving(false)
    addToast('Pengaturan sistem berhasil disimpan!', 'success')
    
    // Trigger dynamic Sidebar update instantly
    window.dispatchEvent(new Event('system_settings_updated'))
  }

  const handleReset = () => {
    if (window.confirm('Apakah Anda yakin ingin mengembalikan pengaturan ke setelan default Figma?')) {
      setForm(DEFAULT_SETTINGS)
      localStorage.removeItem('naturerent_system_settings')
      addToast('Pengaturan berhasil direset ke default!', 'info')
      
      // Trigger dynamic Sidebar reset instantly
      window.dispatchEvent(new Event('system_settings_updated'))
    }
  }

  const handleLogoChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      if (file.size > 1024 * 1024) {
        addToast('Ukuran file terlalu besar! Maksimal 1MB.', 'error')
        return
      }
      const reader = new FileReader()
      reader.onload = (event) => {
        setForm(prev => ({ ...prev, logo: event.target.result }))
        addToast('Logo berhasil diunggah!', 'success')
      }
      reader.readAsDataURL(file)
    }
  }

  // Client-side search filters
  const matchesApp = !searchQuery || 'application information app name description appName brand logo'.toLowerCase().includes(searchQuery.toLowerCase())
  const matchesContact = !searchQuery || 'contact information official email service number office address contact'.toLowerCase().includes(searchQuery.toLowerCase())
  const matchesAppearance = !searchQuery || 'appearance default theme light dark brand primary accent color kustom custom color theme'.toLowerCase().includes(searchQuery.toLowerCase())
  const matchesTransaction = !searchQuery || 'transaction settings payment time limit system currency auto cancel reservation bookings'.toLowerCase().includes(searchQuery.toLowerCase())

  return (
    <AuthGuard>
    <div className="dashboard-container">
      <Sidebar userEmail={userEmail} />
      <main className="main-content" style={{ backgroundColor: 'var(--bg-primary)' }}>
        {/* Topbar matching Figma title bar - Removed non-functional profile/notification/setting buttons */}
        <div className="topbar" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 36px', borderBottom: '1px solid var(--border-color)', backgroundColor: 'var(--bg-card)' }}>
          <h1 style={{ color: 'var(--brand-green)', fontSize: '1rem', fontWeight: 800 }}>System Setting</h1>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, color: 'var(--text-muted)', fontSize: 13 }}>
            <div className="settings-search" style={{ display: 'flex', alignItems: 'center', gap: 8, backgroundColor: 'var(--bg-secondary)', padding: '6px 14px', borderRadius: 999 }}>
              <i className="fa-solid fa-magnifying-glass" />
              <input 
                type="text" 
                placeholder="Search settings..." 
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
                style={{ border: 0, outline: 0, background: 'transparent', fontSize: 12, color: 'var(--text-primary)', width: 160 }} 
              />
            </div>
          </div>
        </div>

        <section className="settings-section" style={{ padding: '32px 36px' }}>
          <div className="page-heading" style={{ marginBottom: 28 }}>
            <h2 style={{ color: 'var(--text-primary)', fontSize: '0.98rem', fontWeight: 600, marginBottom: 4 }}>System Setting</h2>
            <p style={{ color: 'var(--text-secondary)', fontSize: '0.86rem' }}>Manage your application global configurations, contact details, and transaction preferences.</p>
          </div>

          <form onSubmit={handleSave}>
            <div className="settings-grid" style={{ display: 'grid', gridTemplateColumns: '1.35fr 0.95fr', gap: 24 }}>
              {/* Left Column */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                {/* Application Information Card */}
                <div className="setting-card" style={{ display: matchesApp ? 'block' : 'none', padding: 28, border: '1px solid var(--border-color)', borderRadius: 12, backgroundColor: 'var(--bg-card)', boxShadow: '0 8px 24px rgba(15, 23, 42, 0.035)' }}>
                  <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
                    <div className="card-icon mint" style={{ width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, backgroundColor: 'var(--brand-mint)', color: 'var(--brand-green)' }}>
                      <i className="fa-solid fa-circle-info" />
                    </div>
                    <h3 style={{ color: 'var(--text-primary)', fontSize: '0.98rem', fontWeight: 700 }}>Application Information</h3>
                  </div>

                  <div className="settings-form" style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>App Name</label>
                      <input
                        type="text"
                        className="form-input"
                        value={form.appName}
                        onChange={e => setForm({ ...form, appName: e.target.value })}
                        required
                        style={{ minHeight: 44, padding: '0 16px', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)', color: 'var(--text-primary)', borderRadius: 6, width: '100%', outline: 0 }}
                      />
                    </div>

                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Brand Logo</label>
                      <div className="logo-upload" style={{ display: 'flex', alignItems: 'center', gap: 22 }}>
                        <div 
                          className="upload-box" 
                          onClick={() => document.getElementById('logo-file-input').click()}
                          style={{ 
                            width: 88, height: 88, 
                            display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6, 
                            border: '1.5px dashed var(--brand-green)', borderRadius: 8, 
                            backgroundColor: 'var(--bg-card)', color: 'var(--brand-green)', fontSize: '0.62rem', fontWeight: 800,
                            cursor: 'pointer', overflow: 'hidden', position: 'relative'
                          }}
                        >
                          {form.logo ? (
                            <>
                              <img src={form.logo} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                              <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, backgroundColor: 'rgba(0,0,0,0.6)', color: 'white', padding: '3px 0', textAlign: 'center', fontSize: '8px', letterSpacing: '0.5px' }}>
                                GANTI
                              </div>
                            </>
                          ) : (
                            <>
                              <i className="fa-solid fa-arrow-up-from-bracket" style={{ fontSize: 18 }} />
                              <span>UNGGAH</span>
                            </>
                          )}
                        </div>
                        <input 
                          type="file" 
                          id="logo-file-input" 
                          accept="image/*" 
                          style={{ display: 'none' }} 
                          onChange={handleLogoChange}
                        />
                        <div className="upload-copy">
                          <p style={{ color: 'var(--text-muted)', fontSize: '0.72rem', lineHeight: 1.45, marginBottom: 8 }}>Recommended size: 512x512px. SVG or PNG with transparent background.</p>
                          {form.logo ? (
                            <a href={form.logo} download={`${form.appName.toLowerCase()}_logo.png`} style={{ color: 'var(--brand-green)', fontSize: '0.72rem', fontWeight: 700, textDecoration: 'none' }}>
                              Download current logo
                            </a>
                          ) : (
                            <span style={{ color: 'var(--text-muted)', fontSize: '0.72rem', fontWeight: 500 }}>No logo uploaded</span>
                          )}
                        </div>
                      </div>
                    </div>

                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Description</label>
                      <textarea
                        className="form-textarea"
                        value={form.description}
                        onChange={e => setForm({ ...form, description: e.target.value })}
                        required
                        style={{ minHeight: 116, padding: '14px 16px', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)', color: 'var(--text-primary)', borderRadius: 6, lineHeight: 1.55, width: '100%', outline: 0 }}
                      />
                    </div>
                  </div>
                </div>

                {/* Contact Information Card */}
                <div className="setting-card" style={{ display: matchesContact ? 'block' : 'none', padding: 28, border: '1px solid var(--border-color)', borderRadius: 12, backgroundColor: 'var(--bg-card)', boxShadow: '0 8px 24px rgba(15, 23, 42, 0.035)' }}>
                  <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
                    <div className="card-icon blue" style={{ width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, backgroundColor: 'rgba(59, 130, 246, 0.15)', color: '#3b82f6' }}>
                      <i className="fa-solid fa-address-book" />
                    </div>
                    <h3 style={{ color: 'var(--text-primary)', fontSize: '0.98rem', fontWeight: 700 }}>Contact Information</h3>
                  </div>

                  <div className="settings-form" style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                    <div className="field-row" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                      <div>
                        <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Official Email</label>
                        <input
                          type="email"
                          className="form-input"
                          value={form.officialEmail}
                          onChange={e => setForm({ ...form, officialEmail: e.target.value })}
                          required
                          style={{ minHeight: 44, padding: '0 16px', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)', color: 'var(--text-primary)', borderRadius: 6, width: '100%', outline: 0 }}
                        />
                      </div>

                      <div>
                        <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Service Number</label>
                        <input
                          type="text"
                          className="form-input"
                          value={form.serviceNumber}
                          onChange={e => setForm({ ...form, serviceNumber: e.target.value })}
                          required
                          style={{ minHeight: 44, padding: '0 16px', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)', color: 'var(--text-primary)', borderRadius: 6, width: '100%', outline: 0 }}
                        />
                      </div>
                    </div>

                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Office Address</label>
                      <textarea
                        className="form-textarea"
                        value={form.officeAddress}
                        onChange={e => setForm({ ...form, officeAddress: e.target.value })}
                        required
                        style={{ minHeight: 88, padding: '14px 16px', backgroundColor: 'var(--bg-secondary)', borderColor: 'var(--border-color)', color: 'var(--text-primary)', borderRadius: 6, lineHeight: 1.55, width: '100%', outline: 0 }}
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Column */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                {/* Appearance Card */}
                <div className="setting-card" style={{ display: matchesAppearance ? 'block' : 'none', padding: 28, border: '1px solid var(--border-color)', borderRadius: 12, backgroundColor: 'var(--bg-card)', boxShadow: '0 8px 24px rgba(15, 23, 42, 0.035)' }}>
                  <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
                    <div className="card-icon mint" style={{ width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, backgroundColor: 'var(--brand-mint)', color: 'var(--brand-green)' }}>
                      <i className="fa-solid fa-palette" />
                    </div>
                    <h3 style={{ color: 'var(--text-primary)', fontSize: '0.98rem', fontWeight: 700 }}>Appearance</h3>
                  </div>

                  <div className="theme-card" style={{ display: 'flex', justifyContent: 'space-between', gap: 14, padding: 18, border: '1px solid var(--border-color)', borderRadius: 10, backgroundColor: 'var(--bg-secondary)', marginBottom: 24 }}>
                    <div>
                      <h4 style={{ color: 'var(--text-primary)', fontSize: '0.88rem', fontWeight: 700, marginBottom: 4 }}>Default Theme</h4>
                      <p style={{ color: 'var(--text-secondary)', fontSize: '0.72rem', lineHeight: 1.35 }}>Choose how the interface looks for admins.</p>
                    </div>
                    <div className="theme-toggle" style={{ display: 'flex', alignItems: 'center', gap: 8, flexShrink: 0 }}>
                      <button
                        type="button"
                        className={`theme-option ${form.theme === 'light' ? 'active' : ''}`}
                        onClick={() => setForm({ ...form, theme: 'light' })}
                        style={{ minHeight: 28, display: 'inline-flex', alignItems: 'center', gap: 6, padding: '0 10px', border: '1px solid transparent', borderRadius: 6, backgroundColor: form.theme === 'light' ? 'var(--brand-green)' : 'transparent', color: form.theme === 'light' ? '#ffffff' : 'var(--text-secondary)', fontSize: '0.72rem', fontWeight: 700 }}
                      >
                        <i className="fa-solid fa-sun" /> Light
                      </button>
                      <button
                        type="button"
                        className={`theme-option ${form.theme === 'dark' ? 'active' : ''}`}
                        onClick={() => setForm({ ...form, theme: 'dark' })}
                        style={{ minHeight: 28, display: 'inline-flex', alignItems: 'center', gap: 6, padding: '0 10px', border: '1px solid transparent', borderRadius: 6, backgroundColor: form.theme === 'dark' ? 'var(--brand-green)' : 'transparent', color: form.theme === 'dark' ? '#ffffff' : 'var(--text-secondary)', fontSize: '0.72rem', fontWeight: 700 }}
                      >
                        <i className="fa-solid fa-moon" /> Dark
                      </button>
                    </div>
                  </div>

                  <div className="accent-section">
                    <p style={{ color: 'var(--text-secondary)', fontSize: '0.85rem', fontWeight: 500, marginBottom: 12 }}>Brand Primary Accent</p>
                    <div className="accent-row" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      {['green', 'teal', 'forest', 'navy'].map(color => {
                        const bgMap = { green: '#1f5a3f', teal: '#0d8c75', forest: '#14532d', navy: '#1e3a8a' }
                        return (
                          <button
                            key={color}
                            type="button"
                            className={`accent-swatch ${form.accentColor === color ? 'selected' : ''}`}
                            onClick={() => setForm({ ...form, accentColor: color })}
                            style={{
                              width: 34,
                              height: 34,
                              border: 0,
                              borderRadius: '50%',
                              backgroundColor: bgMap[color],
                              cursor: 'pointer',
                              outline: form.accentColor === color ? '2px solid var(--brand-green)' : 'none',
                              outlineOffset: form.accentColor === color ? '3px' : '0',
                              transition: 'all 0.2s'
                            }}
                          />
                        )
                      })}
                      {form.accentColor === 'custom' && (
                        <button
                          type="button"
                          className="accent-swatch selected"
                          onClick={() => document.getElementById('custom-accent-picker').click()}
                          style={{
                            width: 34,
                            height: 34,
                            border: 0,
                            borderRadius: '50%',
                            backgroundColor: form.customAccentHex || '#1f5a3f',
                            cursor: 'pointer',
                            outline: '2px solid var(--brand-green)',
                            outlineOffset: '3px',
                            transition: 'all 0.2s'
                          }}
                          title="Custom Color (Klik untuk mengubah)"
                        />
                      )}
                      <a 
                        href="#" 
                        className="custom-color" 
                        onClick={(e) => {
                          e.preventDefault()
                          document.getElementById('custom-accent-picker').click()
                        }}
                        style={{ marginLeft: 'auto', border: 0, background: 'transparent', color: 'var(--brand-green)', fontSize: '0.72rem', fontWeight: 700, textDecoration: 'none' }}
                      >
                        Custom Color
                      </a>
                      <input 
                        type="color" 
                        id="custom-accent-picker" 
                        style={{ display: 'none' }}
                        value={form.customAccentHex || '#1f5a3f'}
                        onChange={(e) => {
                          setForm(prev => ({ ...prev, accentColor: 'custom', customAccentHex: e.target.value }));
                        }}
                      />
                    </div>
                  </div>
                </div>

                {/* Transaction Settings Card */}
                <div className="setting-card" style={{ display: matchesTransaction ? 'block' : 'none', padding: 28, border: '1px solid var(--border-color)', borderRadius: 12, backgroundColor: 'var(--bg-card)', boxShadow: '0 8px 24px rgba(15, 23, 42, 0.035)' }}>
                  <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
                    <div className="card-icon mint" style={{ width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, backgroundColor: 'var(--brand-mint)', color: 'var(--brand-green)' }}>
                      <i className="fa-solid fa-receipt" />
                    </div>
                    <h3 style={{ color: 'var(--text-primary)', fontSize: '0.98rem', fontWeight: 700 }}>Transaction Settings</h3>
                  </div>

                  <div className="settings-form" style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>

                    {/* Row: Payment Time Limit + Default Payment Method */}
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                      <div>
                        <label style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Payment time limit</label>
                        <select
                          value={form.paymentLimit}
                          onChange={e => setForm({ ...form, paymentLimit: e.target.value })}
                          style={{ minHeight: 44, padding: '0 16px', backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-color)', color: 'var(--text-primary)', borderRadius: 8, outline: 0, width: '100%', cursor: 'pointer', fontSize: '0.88rem' }}
                        >
                          <option>15 Minutes</option>
                          <option>30 Minutes</option>
                          <option>1 Hour</option>
                          <option>2 Hours</option>
                        </select>
                      </div>
                      <div>
                        <label style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Default payment method</label>
                        <input
                          type="text"
                          value="QRIS"
                          readOnly
                          style={{ minHeight: 44, padding: '0 16px', backgroundColor: 'var(--border-color-light)', border: '1px solid var(--border-color)', color: 'var(--text-secondary)', borderRadius: 8, outline: 0, width: '100%', fontSize: '0.88rem', boxSizing: 'border-box', cursor: 'not-allowed' }}
                        />
                      </div>
                    </div>

                    {/* QRIS Configuration Section */}
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 3 }}>
                        <p style={{ fontSize: '0.92rem', fontWeight: 700, color: 'var(--text-primary)' }}>QRIS configuration</p>
                        <button type="button" onClick={() => fetchRentalQris()}
                          style={{ background: 'none', border: 'none', color: 'var(--brand-green)', fontSize: '0.78rem', fontWeight: 700, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 5 }}>
                          <i className="fa-solid fa-arrows-rotate" /> Refresh
                        </button>
                      </div>
                      <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)', marginBottom: 14 }}>Setiap rental memiliki QRIS sendiri. Klik edit untuk mengatur QRIS masing-masing rental.</p>

                      {qrisLoading ? (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '14px', color: 'var(--text-muted)', fontSize: '0.82rem' }}>
                          <div className="loading-spinner" style={{ width: 16, height: 16, borderWidth: 2 }} />
                          Memuat data rental...
                        </div>
                      ) : rentalQrisList.length === 0 ? (
                        <div style={{ padding: '14px 16px', borderRadius: 10, backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-color)', color: 'var(--text-muted)', fontSize: '0.82rem', textAlign: 'center' }}>
                          Belum ada rental terdaftar.
                        </div>
                      ) : (
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                          {rentalQrisList.map(rental => (
                            <div key={rental.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 14px', borderRadius: 10, backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-color)' }}>
                              {/* QR Thumbnail */}
                              <div style={{ width: 46, height: 46, borderRadius: 8, backgroundColor: 'var(--bg-card)', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, overflow: 'hidden' }}>
                                {rental.qris_image_url
                                  ? <img src={rental.qris_image_url} alt={rental.nama_rental} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                  : <i className="fa-solid fa-qrcode" style={{ fontSize: 20, color: 'var(--text-muted)' }} />
                                }
                              </div>
                              {/* Info */}
                              <div style={{ flex: 1, minWidth: 0 }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
                                  <span style={{ fontWeight: 700, fontSize: '0.86rem', color: 'var(--text-primary)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{rental.nama_rental}</span>
                                  <span style={{ padding: '2px 8px', borderRadius: 999, fontSize: '0.66rem', fontWeight: 700, flexShrink: 0, backgroundColor: rental.is_active ? 'rgba(82,183,136,0.15)' : 'rgba(156,163,175,0.15)', color: rental.is_active ? 'var(--brand-green)' : 'var(--text-muted)', border: `1px solid ${rental.is_active ? 'rgba(82,183,136,0.3)' : 'rgba(156,163,175,0.2)'}` }}>
                                    {rental.is_active ? 'Aktif' : 'Nonaktif'}
                                  </span>
                                </div>
                                <span style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>
                                  {rental.qris_merchant_name
                                    ? <>Merchant: {rental.qris_merchant_name} · <span style={{ color: rental.qris_image_url ? 'var(--brand-green)' : '#f59e0b', fontWeight: 600 }}>{rental.qris_image_url ? '✓ QRIS tersedia' : '⚠ Belum ada gambar QRIS'}</span></>
                                    : <span style={{ color: '#f59e0b', fontWeight: 600 }}>⚠ QRIS belum dikonfigurasi</span>
                                  }
                                </span>
                              </div>
                              {/* Edit button */}
                              <button type="button" onClick={() => openEditQris(rental)} title="Set QRIS"
                                style={{ width: 32, height: 32, border: '1px solid var(--border-color)', borderRadius: 7, backgroundColor: 'var(--bg-card)', color: 'var(--text-secondary)', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13, flexShrink: 0 }}>
                                <i className="fa-solid fa-pen-to-square" />
                              </button>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>

                    {/* Biaya Layanan Section */}
                    <div>
                      <p style={{ fontSize: '0.92rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: 12 }}>Biaya layanan</p>
                      <div style={{ borderRadius: 10, backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-color)', overflow: 'hidden' }}>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 16px', borderBottom: '1px solid var(--border-color)' }}>
                          <div>
                            <p style={{ fontSize: '0.86rem', fontWeight: 600, color: 'var(--text-primary)', marginBottom: 3 }}>Persentase biaya layanan</p>
                            <p style={{ fontSize: '0.74rem', color: 'var(--text-muted)' }}>Dibebankan ke pengguna di setiap transaksi</p>
                          </div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 6, flexShrink: 0 }}>
                            <input
                              type="number"
                              min="0"
                              max="100"
                              value={form.serviceFee ?? 10}
                              onChange={e => setForm({ ...form, serviceFee: Math.min(100, Math.max(0, Number(e.target.value))) })}
                              style={{ width: 62, height: 36, textAlign: 'center', fontWeight: 700, fontSize: '0.92rem', border: '1px solid var(--border-color)', borderRadius: 7, backgroundColor: 'var(--bg-card)', color: 'var(--text-primary)', outline: 0 }}
                            />
                            <span style={{ fontWeight: 700, color: 'var(--text-secondary)', fontSize: '0.9rem' }}>%</span>
                          </div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px' }}>
                          <span style={{ fontSize: '0.78rem', color: 'var(--text-muted)' }}>Contoh: transaksi Rp 100.000</span>
                          <span style={{ fontSize: '0.78rem', fontWeight: 700, color: 'var(--brand-green)' }}>
                            Biaya layanan = Rp {((form.serviceFee ?? 10) * 1000).toLocaleString('id-ID')}
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Auto Cancel Toggle */}
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '14px 16px', borderRadius: 10, backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-color)' }}>
                      <div style={{ flex: 1 }}>
                        <strong style={{ display: 'block', color: 'var(--text-primary)', fontSize: '0.86rem', marginBottom: 3, fontWeight: 700 }}>Auto cancel pesanan belum bayar</strong>
                        <span style={{ display: 'block', color: 'var(--text-muted)', fontSize: '0.74rem' }}>Batalkan reservasi jika tidak dibayar dalam batas waktu</span>
                      </div>
                      <div
                        onClick={() => setForm({ ...form, autoCancel: !form.autoCancel })}
                        style={{ position: 'relative', width: 46, height: 26, flexShrink: 0, cursor: 'pointer' }}
                      >
                        <span style={{ position: 'absolute', inset: 0, borderRadius: 999, backgroundColor: form.autoCancel ? 'var(--brand-green)' : 'var(--border-color)', transition: 'background-color 0.2s ease' }} />
                        <span style={{ position: 'absolute', width: 20, height: 20, top: 3, left: 3, borderRadius: '50%', backgroundColor: '#ffffff', boxShadow: '0 1px 4px rgba(0,0,0,0.2)', transition: 'transform 0.2s ease', transform: form.autoCancel ? 'translateX(20px)' : 'none' }} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Save & Reset Actions Bar */}
            <div className="settings-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: 16, marginTop: 32, borderTop: '1px solid var(--border-color)', paddingTop: 24 }}>
              <button
                type="button"
                className="btn reset-btn"
                onClick={handleReset}
                style={{ minWidth: 98, minHeight: 42, borderRadius: 7, fontSize: '0.8rem', fontWeight: 800, border: '1px solid var(--border-color)', backgroundColor: 'var(--bg-card)', color: 'var(--text-primary)', cursor: 'pointer' }}
              >
                Reset
              </button>
              <button
                type="submit"
                className="btn save-btn"
                disabled={saving}
                style={{ minWidth: 120, minHeight: 42, borderRadius: 7, fontSize: '0.8rem', fontWeight: 800, border: 0, backgroundColor: 'var(--brand-green)', color: '#ffffff', boxShadow: '0 6px 16px rgba(45, 112, 47, 0.25)', cursor: 'pointer' }}
              >
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </form>
        </section>
      </main>
      <Toast toasts={toasts} onRemove={removeToast} />

      {/* QRIS Edit Modal — per rental */}
      {qrisModal && qrisEditing && (
        <div style={{ position: 'fixed', inset: 0, zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', backgroundColor: 'rgba(0,0,0,0.6)', backdropFilter: 'blur(4px)' }}>
          <div style={{ backgroundColor: 'var(--bg-card)', borderRadius: 16, padding: 28, width: '100%', maxWidth: 440, boxShadow: '0 20px 60px rgba(0,0,0,0.35)', border: '1px solid var(--border-color)' }}>
            {/* Header */}
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
              <div>
                <h3 style={{ color: 'var(--text-primary)', fontSize: '1rem', fontWeight: 800, marginBottom: 2 }}>Atur QRIS Rental</h3>
                <p style={{ color: 'var(--text-muted)', fontSize: '0.76rem' }}>{qrisEditing.nama_rental}</p>
              </div>
              <button type="button" onClick={() => setQrisModal(false)} style={{ border: 0, background: 'none', color: 'var(--text-muted)', fontSize: 18, cursor: 'pointer' }}>
                <i className="fa-solid fa-xmark" />
              </button>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
              {/* QR Image Upload */}
              <div style={{ display: 'flex', gap: 16, alignItems: 'flex-start' }}>
                <div
                  onClick={() => document.getElementById('qris-img-input').click()}
                  style={{ width: 96, height: 96, borderRadius: 10, border: '2px dashed var(--brand-green)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6, cursor: 'pointer', overflow: 'hidden', backgroundColor: 'var(--bg-secondary)', flexShrink: 0 }}
                >
                  {qrisImagePreview
                    ? <img src={qrisImagePreview} alt="QRIS" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    : <>
                        <i className="fa-solid fa-qrcode" style={{ fontSize: 28, color: 'var(--brand-green)' }} />
                        <span style={{ fontSize: '0.62rem', color: 'var(--text-muted)', fontWeight: 700, textAlign: 'center' }}>KLIK UPLOAD<br/>GAMBAR QRIS</span>
                      </>
                  }
                </div>
                <div style={{ flex: 1 }}>
                  <p style={{ fontSize: '0.82rem', fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 6 }}>Gambar Kode QRIS</p>
                  <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', lineHeight: 1.5 }}>Upload gambar QR code dari penyedia QRIS (BCA, Mandiri, GoPay, dll.).<br/>Format: JPG/PNG, maks 2MB</p>
                  {qrisImagePreview && (
                    <button type="button" onClick={() => { setQrisImagePreview(null); setQrisImageFile(null) }}
                      style={{ marginTop: 8, fontSize: '0.72rem', color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 700 }}>
                      <i className="fa-solid fa-trash" /> Hapus gambar
                    </button>
                  )}
                </div>
              </div>
              <input type="file" id="qris-img-input" accept="image/*" style={{ display: 'none' }} onChange={handleQrisImageChange} />

              {/* Merchant Name */}
              <div>
                <label style={{ display: 'block', marginBottom: 6, fontSize: '0.82rem', fontWeight: 600, color: 'var(--text-secondary)' }}>Nama Merchant QRIS *</label>
                <input type="text" value={qrisMerchant} onChange={e => setQrisMerchant(e.target.value)} placeholder="e.g. Pandawa Outdoor, NatureRents SBY"
                  style={{ width: '100%', minHeight: 42, padding: '0 14px', border: '1px solid var(--border-color)', borderRadius: 8, backgroundColor: 'var(--bg-secondary)', color: 'var(--text-primary)', outline: 0, fontSize: '0.86rem', boxSizing: 'border-box' }} />
                <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 4 }}>Nama yang tampil ke pembeli saat pembayaran</p>
              </div>

              {/* Info box */}
              <div style={{ padding: '10px 14px', borderRadius: 9, backgroundColor: 'rgba(82,183,136,0.08)', border: '1px solid rgba(82,183,136,0.2)', fontSize: '0.76rem', color: 'var(--text-secondary)' }}>
                <i className="fa-solid fa-circle-info" style={{ color: 'var(--brand-green)', marginRight: 6 }} />
                Gambar QRIS ini akan ditampilkan kepada pembeli saat melakukan pembayaran untuk transaksi di <strong>{qrisEditing.nama_rental}</strong>.
              </div>
            </div>

            <div style={{ display: 'flex', gap: 10, marginTop: 22 }}>
              <button type="button" onClick={() => setQrisModal(false)}
                style={{ flex: 1, minHeight: 42, borderRadius: 9, border: '1px solid var(--border-color)', backgroundColor: 'var(--bg-secondary)', color: 'var(--text-secondary)', fontWeight: 700, cursor: 'pointer', fontSize: '0.84rem' }}>
                Batal
              </button>
              <button type="button" onClick={saveQris} disabled={qrisSaving}
                style={{ flex: 2, minHeight: 42, borderRadius: 9, border: 0, backgroundColor: 'var(--brand-green)', color: '#fff', fontWeight: 800, cursor: 'pointer', fontSize: '0.84rem', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, opacity: qrisSaving ? 0.75 : 1 }}>
                {qrisSaving ? <><div className="loading-spinner" style={{ width: 14, height: 14, borderWidth: 2, borderTopColor: '#fff' }} /> Menyimpan...</> : <><i className="fa-solid fa-floppy-disk" /> Simpan QRIS</>}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
    </AuthGuard>
  )
}

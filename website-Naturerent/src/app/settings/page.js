'use client'
import { useState, useEffect } from 'react'
import Sidebar from '@/components/Sidebar'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

// Global admin QRIS default
const DEFAULT_GLOBAL_QRIS = { merchantName: '', imageUrl: null }

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
  serviceFee: 2000,
  commissionRate: 12.5,
  currency: 'IDR',
  autoCancel: true,
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

  // Single global admin QRIS state
  const [globalQris, setGlobalQris] = useState(DEFAULT_GLOBAL_QRIS)
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

      // Load commission rate from localStorage (synced with Komisi page)
      const savedRate = localStorage.getItem('naturerent_commission_rate')
      if (savedRate) {
        setForm(prev => ({ ...prev, commissionRate: Number(savedRate) }))
      }

      // Fetch global QRIS from Supabase
      fetchGlobalQris(supabase)
    }
    init()
  }, [])

  const fetchGlobalQris = async (supabaseClient) => {
    const sb = supabaseClient || createClient()
    try {
      const { data, error } = await sb
        .from('wisata_locations')
        .select('deskripsi')
        .eq('nama', '__GLOBAL_QRIS__')
        .eq('kategori', 'QRIS')
        .maybeSingle()

      if (!error && data?.deskripsi) {
        const parsed = typeof data.deskripsi === 'string' ? JSON.parse(data.deskripsi) : data.deskripsi
        setGlobalQris({ merchantName: parsed.merchant_name || '', imageUrl: parsed.image_url || null })
        setQrisImagePreview(parsed.image_url || null)
        if (parsed.biaya_layanan !== undefined) {
          setForm(prev => ({ ...prev, serviceFee: parsed.biaya_layanan }))
        }
      }
    } catch (e) {
      console.error('Fetch error:', e)
    }
  }

  const handleQrisImageChange = (e) => {
    const file = e.target.files[0]
    if (!file) return
    if (file.size > 2 * 1024 * 1024) { addToast('Gambar terlalu besar (maks 2MB)', 'error'); return }
    setQrisImageFile(file)
    setQrisImagePreview(URL.createObjectURL(file))
  }

  const saveGlobalQris = async () => {
    if (!globalQris.merchantName.trim()) { addToast('Nama merchant wajib diisi!', 'error'); return }
    setQrisSaving(true)
    const supabase = createClient()
    let imageUrl = globalQris.imageUrl || null

    // Upload new image to Supabase Storage if a new file was selected
    if (qrisImageFile) {
      const fileExt = qrisImageFile.name.split('.').pop()
      const filePath = `global/qris.${fileExt}`
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

    // Save to wisata_locations table as a system config row
    const payload = { 
      merchant_name: globalQris.merchantName.trim(), 
      image_url: imageUrl,
      biaya_layanan: Number(form.serviceFee ?? 2000)
    }
    
    try {
      // Check if the config row already exists
      const { data: existingRow, error: checkError } = await supabase
        .from('wisata_locations')
        .select('id')
        .eq('nama', '__GLOBAL_QRIS__')
        .eq('kategori', 'QRIS')
        .maybeSingle()

      if (checkError) throw checkError

      let dbError = null
      if (existingRow?.id) {
        // Update existing
        const { error } = await supabase
          .from('wisata_locations')
          .update({ deskripsi: JSON.stringify(payload), foto_url: imageUrl })
          .eq('id', existingRow.id)
        dbError = error
      } else {
        // Insert new
        const { error } = await supabase
          .from('wisata_locations')
          .insert({
            nama: '__GLOBAL_QRIS__',
            kategori: 'QRIS',
            deskripsi: JSON.stringify(payload),
            foto_url: imageUrl,
            lat: 0,
            lng: 0
          })
        dbError = error
      }

      setQrisSaving(false)
      if (dbError) {
        addToast('Gagal menyimpan QRIS: ' + dbError.message, 'error')
        return
      }
      setGlobalQris(prev => ({ ...prev, imageUrl }))
      setQrisImageFile(null)
      addToast('QRIS global berhasil diperbarui!', 'success')
    } catch (e) {
      setQrisSaving(false)
      addToast('Gagal menyimpan QRIS: ' + e.message, 'error')
    }
  }

  // Real-time appearance switcher (Preview Mode)
  useEffect(() => {
    applyThemeAndAccent(form.theme, form.accentColor, form.customAccentHex)
  }, [form.theme, form.accentColor, form.customAccentHex])

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    const supabase = createClient()
    
    // Simulate save delay
    await new Promise(resolve => setTimeout(resolve, 600))
    localStorage.setItem('naturerent_system_settings', JSON.stringify(form))

    // Sync commission rate to dedicated key (read by Komisi page)
    localStorage.setItem('naturerent_commission_rate', String(form.commissionRate ?? 12.5))
    
    // Save serviceFee to database config row
    try {
      const { data: existingRow } = await supabase
        .from('wisata_locations')
        .select('id, deskripsi')
        .eq('nama', '__GLOBAL_QRIS__')
        .eq('kategori', 'QRIS')
        .maybeSingle()

      let currentPayload = { merchant_name: globalQris.merchantName, image_url: globalQris.imageUrl }
      if (existingRow?.deskripsi) {
        try {
          const parsed = typeof existingRow.deskripsi === 'string' ? JSON.parse(existingRow.deskripsi) : existingRow.deskripsi
          currentPayload = { ...currentPayload, ...parsed }
        } catch {
          // ignore
        }
      }
      
      // Update with new service fee
      currentPayload.biaya_layanan = Number(form.serviceFee)

      if (existingRow?.id) {
        await supabase
          .from('wisata_locations')
          .update({ deskripsi: JSON.stringify(currentPayload) })
          .eq('id', existingRow.id)
      } else {
        await supabase
          .from('wisata_locations')
          .insert({
            nama: '__GLOBAL_QRIS__',
            kategori: 'QRIS',
            deskripsi: JSON.stringify(currentPayload),
            foto_url: globalQris.imageUrl,
            lat: 0,
            lng: 0
          })
      }
    } catch (err) {
      console.error('Error saving service fee to DB:', err)
    }

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
                 <div className="setting-card" style={{ display: matchesTransaction ? 'block' : 'none', padding: 32, border: '1px solid var(--border-color)', borderRadius: 16, backgroundColor: 'var(--bg-card)', boxShadow: '0 12px 32px rgba(15, 23, 42, 0.04)', transition: 'all 0.3s ease-in-out' }}>
                   <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 28 }}>
                     <div className="card-icon mint" style={{ width: 38, height: 38, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 10, backgroundColor: 'var(--brand-mint)', color: 'var(--brand-green)', boxShadow: '0 4px 12px rgba(82, 183, 136, 0.15)' }}>
                       <i className="fa-solid fa-receipt" style={{ fontSize: 16 }} />
                     </div>
                     <div>
                       <h3 style={{ color: 'var(--text-primary)', fontSize: '1.05rem', fontWeight: 800, margin: 0 }}>Transaction Settings</h3>
                       <p style={{ color: 'var(--text-secondary)', fontSize: '0.74rem', margin: '2px 0 0 0' }}>Configure checkout limits, admin QRIS, and flat platform fees.</p>
                     </div>
                   </div>

                   <div className="settings-form" style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>

                     {/* Row: Payment Time Limit + Default Payment Method */}
                     <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18 }}>
                       <div>
                         <label style={{ display: 'block', marginBottom: 8, fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Payment time limit</label>
                         <div style={{ position: 'relative' }}>
                           <select
                             value={form.paymentLimit}
                             onChange={e => setForm({ ...form, paymentLimit: e.target.value })}
                             style={{ minHeight: 46, padding: '0 16px', backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-color)', color: 'var(--text-primary)', borderRadius: 10, outline: 0, width: '100%', cursor: 'pointer', fontSize: '0.86rem', fontWeight: 600, transition: 'all 0.2s', appearance: 'none' }}
                           >
                             <option>15 Minutes</option>
                             <option>30 Minutes</option>
                             <option>1 Hour</option>
                             <option>2 Hours</option>
                           </select>
                           <div style={{ position: 'absolute', right: 16, top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none', color: 'var(--text-secondary)', fontSize: 12 }}>
                             <i className="fa-solid fa-chevron-down" />
                           </div>
                         </div>
                       </div>
                       <div>
                         <label style={{ display: 'block', marginBottom: 8, fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Default payment method</label>
                         <div style={{ position: 'relative' }}>
                           <input
                             type="text"
                             value="QRIS (Global Admin)"
                             readOnly
                             style={{ minHeight: 46, padding: '0 16px 0 42px', backgroundColor: 'var(--bg-primary)', border: '1px solid var(--border-color)', color: 'var(--text-secondary)', borderRadius: 10, outline: 0, width: '100%', fontSize: '0.86rem', fontWeight: 600, boxSizing: 'border-box', cursor: 'not-allowed' }}
                           />
                           <div style={{ position: 'absolute', left: 16, top: '50%', transform: 'translateY(-50%)', color: 'var(--brand-green)' }}>
                             <i className="fa-solid fa-qrcode" />
                           </div>
                         </div>
                       </div>
                     </div>

                     {/* QRIS Configuration Section — Single Global Admin QRIS */}
                     <div>
                       <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 6 }}>
                         <p style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>QRIS Configuration</p>
                         <span style={{ padding: '3px 12px', borderRadius: 999, fontSize: '0.62rem', fontWeight: 800, backgroundColor: 'var(--brand-mint)', color: 'var(--brand-green)', border: '1px solid rgba(82,183,136,0.25)', letterSpacing: '0.5px', textTransform: 'uppercase' }}>Global</span>
                       </div>
                       <p style={{ fontSize: '0.74rem', color: 'var(--text-secondary)', margin: '0 0 16px 0', lineHeight: 1.4 }}>Satu QRIS admin yang digunakan untuk memproses pembayaran semua transaksi dari pelanggan.</p>

                       <div style={{ borderRadius: 14, border: '1px solid var(--border-color)', background: 'linear-gradient(180deg, var(--bg-secondary) 0%, var(--bg-card) 100%)', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.015)' }}>
                         {/* Preview + Upload */}
                         <div style={{ display: 'flex', gap: 20, alignItems: 'center', padding: '20px 20px 16px' }}>
                           <div
                             onClick={() => document.getElementById('global-qris-img-input').click()}
                             style={{ 
                               width: 90, height: 90, borderRadius: 12, 
                               border: '2px dashed var(--brand-emerald)', 
                               display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6, 
                               cursor: 'pointer', overflow: 'hidden', backgroundColor: 'var(--bg-card)', 
                               flexShrink: 0, transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                               boxShadow: '0 4px 12px rgba(0,0,0,0.02)'
                             }}
                             onMouseEnter={(e) => { e.currentTarget.style.borderColor = 'var(--brand-green)'; e.currentTarget.style.transform = 'translateY(-2px)' }}
                             onMouseLeave={(e) => { e.currentTarget.style.borderColor = 'var(--brand-emerald)'; e.currentTarget.style.transform = 'translateY(0)' }}
                           >
                             {qrisImagePreview
                               ? <img src={qrisImagePreview} alt="QRIS" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                               : <>
                                   <i className="fa-solid fa-qrcode" style={{ fontSize: 28, color: 'var(--brand-emerald)' }} />
                                   <span style={{ fontSize: '0.58rem', color: 'var(--text-muted)', fontWeight: 800, textAlign: 'center', lineHeight: 1.3, letterSpacing: '0.3px' }}>UPLOAD<br/>IMAGE</span>
                                 </>
                             }
                           </div>
                           <input type="file" id="global-qris-img-input" accept="image/*" style={{ display: 'none' }} onChange={handleQrisImageChange} />
                           <div style={{ flex: 1 }}>
                             <p style={{ fontSize: '0.84rem', fontWeight: 800, color: 'var(--text-primary)', margin: '0 0 4px 0' }}>Gambar Kode QRIS</p>
                             <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', lineHeight: 1.5, margin: 0 }}>Format JPG/PNG · Maks 2MB<br/>Klik kotak di sebelah kiri untuk mengganti gambar.</p>
                             {qrisImagePreview && (
                               <button type="button" onClick={() => { setQrisImagePreview(null); setQrisImageFile(null); setGlobalQris(prev => ({ ...prev, imageUrl: null })) }}
                                 style={{ marginTop: 8, fontSize: '0.72rem', color: '#f43f5e', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 800, padding: 0, display: 'inline-flex', alignItems: 'center', gap: 6, transition: 'color 0.2s' }}
                                 onMouseEnter={(e) => e.currentTarget.style.color = '#e11d48'}
                                 onMouseLeave={(e) => e.currentTarget.style.color = '#f43f5e'}
                               >
                                 <i className="fa-solid fa-trash-can" /> Hapus gambar
                               </button>
                             )}
                           </div>
                         </div>

                         {/* Merchant Name */}
                         <div style={{ padding: '0 20px 16px' }}>
                           <label style={{ display: 'block', marginBottom: 8, fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.3px' }}>Nama Merchant QRIS *</label>
                           <input
                             type="text"
                             value={globalQris.merchantName}
                             onChange={e => setGlobalQris(prev => ({ ...prev, merchantName: e.target.value }))}
                             placeholder="Contoh: NatureRent Indonesia"
                             style={{ width: '100%', minHeight: 44, padding: '0 16px', border: '1px solid var(--border-color)', borderRadius: 10, backgroundColor: 'var(--bg-card)', color: 'var(--text-primary)', outline: 0, fontSize: '0.86rem', fontWeight: 600, boxSizing: 'border-box', transition: 'all 0.2s' }}
                             onFocus={(e) => e.target.style.borderColor = 'var(--brand-emerald)'}
                             onBlur={(e) => e.target.style.borderColor = 'var(--border-color)'}
                           />
                           <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 6, margin: '6px 0 0 0' }}>Nama yang tampil ke pembeli di semua rental saat pembayaran.</p>
                         </div>

                         {/* Status banner */}
                         <div style={{ margin: '0 20px 16px', padding: '10px 14px', borderRadius: 10, backgroundColor: globalQris.imageUrl ? 'rgba(82,183,136,0.06)' : 'rgba(245,158,11,0.06)', border: `1px solid ${globalQris.imageUrl ? 'rgba(82,183,136,0.18)' : 'rgba(245,158,11,0.18)'}`, fontSize: '0.76rem', color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: 10 }}>
                           <i className={`fa-solid ${globalQris.imageUrl ? 'fa-circle-check' : 'fa-circle-exclamation'}`} style={{ fontSize: 14, color: globalQris.imageUrl ? 'var(--brand-green)' : '#f59e0b', flexShrink: 0 }} />
                           {globalQris.imageUrl
                             ? <span><strong style={{ color: 'var(--brand-green)', fontWeight: 800 }}>QRIS Aktif</strong> — Siap digunakan untuk merchant <strong>{globalQris.merchantName || '(belum diisi)'}</strong></span>
                             : <span><strong style={{ color: '#f59e0b', fontWeight: 800 }}>Belum Dikonfigurasi</strong> — Upload gambar QRIS dan isi nama merchant di atas.</span>
                           }
                         </div>

                         {/* Save button */}
                         <div style={{ padding: '0 20px 20px', display: 'flex', justifyContent: 'flex-end', borderTop: '1px solid var(--border-color-light)', paddingTop: 16 }}>
                           <button type="button" onClick={saveGlobalQris} disabled={qrisSaving}
                             style={{ 
                               minHeight: 40, padding: '0 24px', borderRadius: 10, border: 0, 
                               background: 'linear-gradient(135deg, var(--brand-emerald) 0%, var(--brand-green) 100%)', 
                               color: '#fff', fontWeight: 800, cursor: 'pointer', fontSize: '0.84rem', 
                               display: 'flex', alignItems: 'center', gap: 8, transition: 'all 0.2s ease-in-out',
                               boxShadow: '0 4px 12px rgba(31, 90, 63, 0.2)', opacity: qrisSaving ? 0.75 : 1
                             }}
                             onMouseEnter={(e) => { e.currentTarget.style.opacity = '0.92'; e.currentTarget.style.transform = 'translateY(-1px)' }}
                             onMouseLeave={(e) => { e.currentTarget.style.opacity = '1'; e.currentTarget.style.transform = 'translateY(0)' }}
                           >
                             {qrisSaving
                               ? <><div className="loading-spinner" style={{ width: 12, height: 12, borderWidth: 2, borderTopColor: '#fff' }} /> Menyimpan...</>
                               : <><i className="fa-solid fa-circle-check" /> Simpan QRIS</>
                             }
                           </button>
                         </div>
                       </div>
                     </div>

                      {/* Biaya Layanan Section */}
                      <div>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
                          <p style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>Biaya Layanan Platform</p>
                          <span style={{ padding: '3px 12px', borderRadius: 999, fontSize: '0.62rem', fontWeight: 800, backgroundColor: 'rgba(59,130,246,0.08)', color: '#3b82f6', border: '1px solid rgba(59,130,246,0.18)', letterSpacing: '0.5px', textTransform: 'uppercase' }}>Flat Fee</span>
                        </div>

                        {/* Main fee card */}
                        <div style={{ borderRadius: 16, backgroundColor: 'var(--bg-card)', border: '1px solid var(--border-color)', overflow: 'hidden', boxShadow: '0 8px 28px rgba(0,0,0,0.03)' }}>
                          {/* Fee display hero */}
                          <div style={{ background: 'linear-gradient(135deg, var(--brand-green) 0%, var(--brand-emerald) 100%)', padding: '24px 24px 20px', position: 'relative', overflow: 'hidden' }}>
                            <div style={{ position: 'absolute', top: -20, right: -20, width: 100, height: 100, borderRadius: '50%', background: 'rgba(255,255,255,0.06)' }} />
                            <div style={{ position: 'absolute', bottom: -30, right: 30, width: 70, height: 70, borderRadius: '50%', background: 'rgba(255,255,255,0.04)' }} />
                            <p style={{ fontSize: '0.7rem', fontWeight: 700, color: 'rgba(255,255,255,0.65)', margin: '0 0 6px 0', textTransform: 'uppercase', letterSpacing: '1px' }}>Biaya per transaksi</p>
                            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
                              <span style={{ fontSize: '1rem', fontWeight: 800, color: 'rgba(255,255,255,0.75)' }}>Rp</span>
                              <span style={{ fontSize: '2.2rem', fontWeight: 900, color: '#ffffff', lineHeight: 1, letterSpacing: '-1px' }}>
                                {Number(form.serviceFee ?? 2000).toLocaleString('id-ID')}
                              </span>
                            </div>
                            <p style={{ fontSize: '0.72rem', color: 'rgba(255,255,255,0.55)', margin: '8px 0 0 0' }}>Dibebankan kepada pengguna di setiap transaksi checkout</p>
                          </div>

                          {/* Input area */}
                          <div style={{ padding: '20px 24px 16px' }}>
                            <label style={{ display: 'block', marginBottom: 10, fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.4px' }}>Atur Nominal Biaya</label>
                            <div style={{ display: 'flex', alignItems: 'center', border: '1.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', transition: 'border-color 0.2s', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}
                              onFocusCapture={(e) => e.currentTarget.style.borderColor = 'var(--brand-emerald)'}
                              onBlurCapture={(e) => e.currentTarget.style.borderColor = 'var(--border-color)'}
                            >
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '0 16px', height: 48, backgroundColor: 'var(--bg-secondary)', borderRight: '1.5px solid var(--border-color)', flexShrink: 0 }}>
                                <i className="fa-solid fa-coins" style={{ color: 'var(--brand-green)', fontSize: 14 }} />
                                <span style={{ fontWeight: 800, color: 'var(--text-secondary)', fontSize: '0.88rem' }}>Rp</span>
                              </div>
                              <input
                                type="number"
                                min="0"
                                step="500"
                                value={form.serviceFee ?? 2000}
                                onChange={e => setForm({ ...form, serviceFee: Math.max(0, Number(e.target.value)) })}
                                style={{ flex: 1, height: 48, padding: '0 16px', fontWeight: 700, fontSize: '1rem', border: 0, backgroundColor: 'var(--bg-card)', color: 'var(--text-primary)', outline: 0, minWidth: 0 }}
                                placeholder="0"
                              />
                              <span style={{ padding: '0 16px', height: 48, display: 'inline-flex', alignItems: 'center', backgroundColor: 'var(--bg-secondary)', borderLeft: '1.5px solid var(--border-color)', fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', flexShrink: 0, whiteSpace: 'nowrap' }}>
                                {Number(form.serviceFee ?? 2000).toLocaleString('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 })}
                              </span>
                            </div>

                            {/* Quick preset buttons */}
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12, flexWrap: 'wrap' }}>
                              <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 600 }}>Preset:</span>
                              {[1000, 2000, 3000, 5000, 10000].map(preset => (
                                <button
                                  key={preset}
                                  type="button"
                                  onClick={() => setForm({ ...form, serviceFee: preset })}
                                  style={{
                                    padding: '4px 12px', borderRadius: 8, border: `1px solid ${form.serviceFee === preset ? 'var(--brand-green)' : 'var(--border-color)'}`,
                                    backgroundColor: form.serviceFee === preset ? 'var(--brand-mint)' : 'var(--bg-secondary)',
                                    color: form.serviceFee === preset ? 'var(--brand-green)' : 'var(--text-secondary)',
                                    fontSize: '0.74rem', fontWeight: 800, cursor: 'pointer', transition: 'all 0.15s ease'
                                  }}
                                  onMouseEnter={(e) => { if (form.serviceFee !== preset) { e.currentTarget.style.borderColor = 'var(--brand-emerald)'; e.currentTarget.style.color = 'var(--brand-green)' } }}
                                  onMouseLeave={(e) => { if (form.serviceFee !== preset) { e.currentTarget.style.borderColor = 'var(--border-color)'; e.currentTarget.style.color = 'var(--text-secondary)' } }}
                                >
                                  Rp {preset.toLocaleString('id-ID')}
                                </button>
                              ))}
                            </div>
                          </div>

                          {/* Info footer */}
                          <div style={{ margin: '0 24px 20px', padding: '10px 14px', borderRadius: 10, backgroundColor: 'rgba(59,130,246,0.04)', border: '1px solid rgba(59,130,246,0.12)', display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                            <i className="fa-solid fa-circle-info" style={{ color: '#3b82f6', fontSize: 13, marginTop: 2, flexShrink: 0 }} />
                            <p style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', margin: 0, lineHeight: 1.5 }}>
                              Biaya layanan <strong style={{ color: 'var(--text-primary)' }}>Rp {Number(form.serviceFee ?? 2000).toLocaleString('id-ID')}</strong> akan ditambahkan otomatis saat checkout. Perubahan berlaku setelah menekan <em>Save Changes</em>.
                            </p>
                          </div>
                        </div>
                      </div>

                      {/* Biaya Komisi Section */}
                      <div>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
                          <p style={{ fontSize: '0.9rem', fontWeight: 800, color: 'var(--text-primary)', margin: 0 }}>Biaya Komisi Platform</p>
                          <span style={{ padding: '3px 12px', borderRadius: 999, fontSize: '0.62rem', fontWeight: 800, backgroundColor: 'rgba(139,92,246,0.08)', color: '#8b5cf6', border: '1px solid rgba(139,92,246,0.2)', letterSpacing: '0.5px', textTransform: 'uppercase' }}>Persen (%)</span>
                        </div>

                        <div style={{ borderRadius: 16, backgroundColor: 'var(--bg-card)', border: '1px solid var(--border-color)', overflow: 'hidden', boxShadow: '0 8px 28px rgba(0,0,0,0.03)' }}>
                          {/* Komisi hero display */}
                          <div style={{ background: 'linear-gradient(135deg, #7c3aed 0%, #a78bfa 100%)', padding: '24px 24px 20px', position: 'relative', overflow: 'hidden' }}>
                            <div style={{ position: 'absolute', top: -20, right: -20, width: 100, height: 100, borderRadius: '50%', background: 'rgba(255,255,255,0.06)' }} />
                            <div style={{ position: 'absolute', bottom: -30, right: 30, width: 70, height: 70, borderRadius: '50%', background: 'rgba(255,255,255,0.04)' }} />
                            <p style={{ fontSize: '0.7rem', fontWeight: 700, color: 'rgba(255,255,255,0.65)', margin: '0 0 6px 0', textTransform: 'uppercase', letterSpacing: '1px' }}>Komisi per transaksi</p>
                            <div style={{ display: 'flex', alignItems: 'baseline', gap: 4 }}>
                              <span style={{ fontSize: '2.2rem', fontWeight: 900, color: '#ffffff', lineHeight: 1, letterSpacing: '-1px' }}>
                                {Number(form.commissionRate ?? 12.5).toLocaleString('id-ID', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}
                              </span>
                              <span style={{ fontSize: '1.2rem', fontWeight: 800, color: 'rgba(255,255,255,0.75)' }}>%</span>
                            </div>
                            <p style={{ fontSize: '0.72rem', color: 'rgba(255,255,255,0.55)', margin: '8px 0 0 0' }}>Potongan dari total transaksi untuk pendapatan platform</p>
                          </div>

                          {/* Input area */}
                          <div style={{ padding: '20px 24px 16px' }}>
                            <label style={{ display: 'block', marginBottom: 10, fontSize: '0.78rem', fontWeight: 700, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.4px' }}>Atur Persentase Komisi</label>
                            <div style={{ display: 'flex', alignItems: 'center', border: '1.5px solid var(--border-color)', borderRadius: 12, overflow: 'hidden', transition: 'border-color 0.2s', boxShadow: '0 2px 8px rgba(0,0,0,0.02)' }}
                              onFocusCapture={(e) => e.currentTarget.style.borderColor = '#a78bfa'}
                              onBlurCapture={(e) => e.currentTarget.style.borderColor = 'var(--border-color)'}
                            >
                              <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '0 16px', height: 48, backgroundColor: 'var(--bg-secondary)', borderRight: '1.5px solid var(--border-color)', flexShrink: 0 }}>
                                <i className="fa-solid fa-percent" style={{ color: '#8b5cf6', fontSize: 13 }} />
                                <span style={{ fontWeight: 800, color: 'var(--text-secondary)', fontSize: '0.88rem' }}>%</span>
                              </div>
                              <input
                                type="number"
                                min="0"
                                max="100"
                                step="0.5"
                                value={form.commissionRate ?? 12.5}
                                onChange={e => setForm({ ...form, commissionRate: Math.min(100, Math.max(0, Number(e.target.value))) })}
                                style={{ flex: 1, height: 48, padding: '0 16px', fontWeight: 700, fontSize: '1rem', border: 0, backgroundColor: 'var(--bg-card)', color: 'var(--text-primary)', outline: 0, minWidth: 0 }}
                                placeholder="0"
                              />
                              <span style={{ padding: '0 16px', height: 48, display: 'inline-flex', alignItems: 'center', backgroundColor: 'var(--bg-secondary)', borderLeft: '1.5px solid var(--border-color)', fontSize: '0.75rem', fontWeight: 700, color: 'var(--text-muted)', flexShrink: 0, whiteSpace: 'nowrap' }}>
                                {Number(form.commissionRate ?? 12.5).toLocaleString('id-ID', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}% komisi
                              </span>
                            </div>

                            {/* Quick preset buttons */}
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12, flexWrap: 'wrap' }}>
                              <span style={{ fontSize: '0.72rem', color: 'var(--text-muted)', fontWeight: 600 }}>Preset:</span>
                              {[5, 10, 12.5, 15, 20].map(preset => (
                                <button
                                  key={preset}
                                  type="button"
                                  onClick={() => setForm({ ...form, commissionRate: preset })}
                                  style={{
                                    padding: '4px 12px', borderRadius: 8,
                                    border: `1px solid ${form.commissionRate === preset ? '#8b5cf6' : 'var(--border-color)'}`,
                                    backgroundColor: form.commissionRate === preset ? 'rgba(139,92,246,0.08)' : 'var(--bg-secondary)',
                                    color: form.commissionRate === preset ? '#8b5cf6' : 'var(--text-secondary)',
                                    fontSize: '0.74rem', fontWeight: 800, cursor: 'pointer', transition: 'all 0.15s ease'
                                  }}
                                  onMouseEnter={(e) => { if (form.commissionRate !== preset) { e.currentTarget.style.borderColor = '#a78bfa'; e.currentTarget.style.color = '#8b5cf6' } }}
                                  onMouseLeave={(e) => { if (form.commissionRate !== preset) { e.currentTarget.style.borderColor = 'var(--border-color)'; e.currentTarget.style.color = 'var(--text-secondary)' } }}
                                >
                                  {preset}%
                                </button>
                              ))}
                            </div>
                          </div>

                          {/* Info footer with link to Komisi page */}
                          <div style={{ margin: '0 24px 20px', padding: '10px 14px', borderRadius: 10, backgroundColor: 'rgba(139,92,246,0.04)', border: '1px solid rgba(139,92,246,0.14)', display: 'flex', alignItems: 'flex-start', gap: 10 }}>
                            <i className="fa-solid fa-chart-pie" style={{ color: '#8b5cf6', fontSize: 13, marginTop: 2, flexShrink: 0 }} />
                            <p style={{ fontSize: '0.72rem', color: 'var(--text-secondary)', margin: 0, lineHeight: 1.5 }}>
                              Komisi <strong style={{ color: 'var(--text-primary)' }}>{Number(form.commissionRate ?? 12.5).toLocaleString('id-ID', { minimumFractionDigits: 0, maximumFractionDigits: 2 })}%</strong> dari gross transaksi dipotong untuk platform. Lihat detail di halaman{' '}
                              <a href="/komisi" style={{ color: '#8b5cf6', fontWeight: 800, textDecoration: 'none' }}>Kelola Komisi →</a>
                            </p>
                          </div>
                        </div>
                      </div>

                     {/* Auto Cancel Toggle */}
                     <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '18px 20px', borderRadius: 14, backgroundColor: 'var(--bg-secondary)', border: '1px solid var(--border-color)', boxShadow: '0 4px 20px rgba(0,0,0,0.015)' }}>
                       <div style={{ flex: 1 }}>
                         <strong style={{ display: 'block', color: 'var(--text-primary)', fontSize: '0.86rem', marginBottom: 3, fontWeight: 800 }}>Auto cancel pesanan belum bayar</strong>
                         <span style={{ display: 'block', color: 'var(--text-secondary)', fontSize: '0.74rem', lineHeight: 1.45 }}>Batalkan reservasi jika tidak dibayar dalam batas waktu</span>
                       </div>
                       <div
                         onClick={() => setForm({ ...form, autoCancel: !form.autoCancel })}
                         style={{ position: 'relative', width: 48, height: 26, flexShrink: 0, cursor: 'pointer', transition: 'transform 0.1s' }}
                         onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.95)'}
                         onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
                       >
                         <span style={{ position: 'absolute', inset: 0, borderRadius: 999, backgroundColor: form.autoCancel ? 'var(--brand-green)' : 'var(--border-color)', transition: 'background-color 0.25s ease', boxShadow: form.autoCancel ? '0 2px 8px rgba(31, 90, 63, 0.25)' : 'none' }} />
                         <span style={{ position: 'absolute', width: 20, height: 20, top: 3, left: form.autoCancel ? 25 : 3, borderRadius: '50%', backgroundColor: '#ffffff', boxShadow: '0 2px 5px rgba(0,0,0,0.2)', transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)' }} />
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

      {/* No QRIS modal needed — single inline form above */}

    </div>

    </AuthGuard>
  )
}

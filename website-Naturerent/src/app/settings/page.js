'use client'
import { useState, useEffect } from 'react'
import Sidebar from '@/components/Sidebar'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

const DEFAULT_SETTINGS = {
  appName: 'NatureRent',
  description: 'NatureRent is the leading eco-friendly equipment rental platform connecting adventure seekers with premium outdoor gear and sustainable travel resources.',
  theme: 'light',
  accentColor: 'green',
  officialEmail: 'admin@naturerent.com',
  serviceNumber: '+62 21 5550 1234',
  officeAddress: 'The Green Hub, Fl. 12, Sudirman Central Business District, Jakarta 12190, Indonesia',
  paymentLimit: '30 Minutes',
  currency: 'IDR',
  autoCancel: true
}

export default function SettingsPage() {
  const { toasts, addToast, removeToast } = useToast()
  const [userEmail, setUserEmail] = useState('')
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState(DEFAULT_SETTINGS)

  useEffect(() => {
    const init = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      setUserEmail(user?.email || '')

      // Load settings from localStorage
      const savedSettings = localStorage.getItem('naturerent_system_settings')
      if (savedSettings) {
        try {
          setForm(JSON.parse(savedSettings))
        } catch {
          // ignore
        }
      }
    }
    init()
  }, [])

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    
    // Simulate save delay
    await new Promise(resolve => setTimeout(resolve, 600))
    localStorage.setItem('naturerent_system_settings', JSON.stringify(form))
    
    setSaving(false)
    addToast('Pengaturan sistem berhasil disimpan!', 'success')
  }

  const handleReset = () => {
    if (window.confirm('Apakah Anda yakin ingin mengembalikan pengaturan ke setelan default Figma?')) {
      setForm(DEFAULT_SETTINGS)
      localStorage.removeItem('naturerent_system_settings')
      addToast('Pengaturan berhasil direset ke default!', 'info')
    }
  }

  return (
    <AuthGuard>
    <div className="dashboard-container">
      <Sidebar userEmail={userEmail} />
      <main className="main-content" style={{ backgroundColor: '#f6f7fb' }}>
        {/* Topbar matching Figma title bar */}
        <div className="topbar" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '20px 36px', borderBottom: '1px solid #e8ebf2', backgroundColor: '#ffffff' }}>
          <h1 style={{ color: '#064429', fontSize: '1rem', fontWeight: 800 }}>System Setting</h1>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, color: '#9aa7b7', fontSize: 13 }}>
            <div className="settings-search" style={{ display: 'flex', alignItems: 'center', gap: 8, backgroundColor: '#f3f6fa', padding: '6px 14px', borderRadius: 999 }}>
              <i className="fa-solid fa-magnifying-glass" />
              <input type="text" placeholder="Search settings..." style={{ border: 0, outline: 0, background: 'transparent', fontSize: 12 }} />
            </div>
            <button className="icon-btn" style={{ background: 'transparent', border: 0, color: '#60708a' }}><i className="fa-solid fa-bell" /></button>
            <button className="icon-btn" style={{ background: 'transparent', border: 0, color: '#60708a' }}><i className="fa-solid fa-gear" /></button>
            <button className="icon-btn" style={{ background: 'transparent', border: 0, color: '#60708a' }}><i className="fa-solid fa-circle-user" /></button>
          </div>
        </div>

        <section className="settings-section" style={{ padding: '32px 36px' }}>
          <div className="page-heading" style={{ marginBottom: 28 }}>
            <h2 style={{ color: '#1f2937', fontSize: '0.98rem', fontWeight: 600, marginBottom: 4 }}>System Setting</h2>
            <p style={{ color: '#526071', fontSize: '0.86rem' }}>Manage your application global configurations, contact details, and transaction preferences.</p>
          </div>

          <form onSubmit={handleSave}>
            <div className="settings-grid" style={{ display: 'grid', gridTemplateColumns: '1.35fr 0.95fr', gap: 24 }}>
              {/* Left Column */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                {/* Application Information Card */}
                <div className="setting-card" style={{ padding: 28, border: '1px solid #e5eaf2', borderRadius: 12, backgroundColor: '#ffffff', boxShadow: '0 8px 24px rgba(15, 23, 42, 0.035)' }}>
                  <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
                    <div className="card-icon mint" style={{ width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, backgroundColor: '#c9f5da', color: '#087143' }}>
                      <i className="fa-solid fa-circle-info" />
                    </div>
                    <h3 style={{ color: '#253142', fontSize: '0.98rem', fontWeight: 700 }}>Application Information</h3>
                  </div>

                  <div className="settings-form" style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: '#4b5563' }}>App Name</label>
                      <input
                        type="text"
                        className="form-input"
                        value={form.appName}
                        onChange={e => setForm({ ...form, appName: e.target.value })}
                        required
                        style={{ minHeight: 44, padding: '0 16px', backgroundColor: '#eef3ff', borderColor: '#bcc8da', color: '#203047', borderRadius: 6 }}
                      />
                    </div>

                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: '#4b5563' }}>Brand Logo</label>
                      <div className="logo-upload" style={{ display: 'flex', alignItems: 'center', gap: 22 }}>
                        <div className="upload-box" style={{ width: 88, height: 88, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6, border: '1.5px dashed #9ca3af', borderRadius: 8, backgroundColor: '#ffffff', color: '#6b7280', fontSize: '0.62rem', fontWeight: 800 }}>
                          <i className="fa-solid fa-arrow-up-from-bracket" style={{ fontSize: 18 }} />
                          <span>CHANGE</span>
                        </div>
                        <div className="upload-copy">
                          <p style={{ color: '#526071', fontSize: '0.72rem', lineHeight: 1.45, marginBottom: 8 }}>Recommended size: 512x512px. SVG or PNG with transparent background.</p>
                          <a href="#" style={{ color: '#087143', fontSize: '0.72rem', fontWeight: 700, textDecoration: 'none' }}>Download current logo</a>
                        </div>
                      </div>
                    </div>

                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: '#4b5563' }}>Description</label>
                      <textarea
                        className="form-textarea"
                        value={form.description}
                        onChange={e => setForm({ ...form, description: e.target.value })}
                        required
                        style={{ minHeight: 116, padding: '14px 16px', backgroundColor: '#eef3ff', borderColor: '#bcc8da', color: '#203047', borderRadius: 6, lineHeight: 1.55 }}
                      />
                    </div>
                  </div>
                </div>

                {/* Contact Information Card */}
                <div className="setting-card" style={{ padding: 28, border: '1px solid #e5eaf2', borderRadius: 12, backgroundColor: '#ffffff', boxShadow: '0 8px 24px rgba(15, 23, 42, 0.035)' }}>
                  <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
                    <div className="card-icon blue" style={{ width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, backgroundColor: '#dce9ff', color: '#536b91' }}>
                      <i className="fa-solid fa-address-book" />
                    </div>
                    <h3 style={{ color: '#253142', fontSize: '0.98rem', fontWeight: 700 }}>Contact Information</h3>
                  </div>

                  <div className="settings-form" style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                    <div className="field-row" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                      <div>
                        <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: '#4b5563' }}>Official Email</label>
                        <input
                          type="email"
                          className="form-input"
                          value={form.officialEmail}
                          onChange={e => setForm({ ...form, officialEmail: e.target.value })}
                          required
                          style={{ minHeight: 44, padding: '0 16px', backgroundColor: '#eef3ff', borderColor: '#bcc8da', color: '#203047', borderRadius: 6 }}
                        />
                      </div>

                      <div>
                        <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: '#4b5563' }}>Service Number</label>
                        <input
                          type="text"
                          className="form-input"
                          value={form.serviceNumber}
                          onChange={e => setForm({ ...form, serviceNumber: e.target.value })}
                          required
                          style={{ minHeight: 44, padding: '0 16px', backgroundColor: '#eef3ff', borderColor: '#bcc8da', color: '#203047', borderRadius: 6 }}
                        />
                      </div>
                    </div>

                    <div>
                      <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: '#4b5563' }}>Office Address</label>
                      <textarea
                        className="form-textarea"
                        value={form.officeAddress}
                        onChange={e => setForm({ ...form, officeAddress: e.target.value })}
                        required
                        style={{ minHeight: 88, padding: '14px 16px', backgroundColor: '#eef3ff', borderColor: '#bcc8da', color: '#203047', borderRadius: 6, lineHeight: 1.55 }}
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Column */}
              <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                {/* Appearance Card */}
                <div className="setting-card" style={{ padding: 28, border: '1px solid #e5eaf2', borderRadius: 12, backgroundColor: '#ffffff', boxShadow: '0 8px 24px rgba(15, 23, 42, 0.035)' }}>
                  <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
                    <div className="card-icon mint" style={{ width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, backgroundColor: '#c9f5da', color: '#087143' }}>
                      <i className="fa-solid fa-palette" />
                    </div>
                    <h3 style={{ color: '#253142', fontSize: '0.98rem', fontWeight: 700 }}>Appearance</h3>
                  </div>

                  <div className="theme-card" style={{ display: 'flex', justifyContent: 'space-between', gap: 14, padding: 18, border: '1px solid #b8eed0', borderRadius: 10, backgroundColor: '#f7fffb', marginBottom: 24 }}>
                    <div>
                      <h4 style={{ color: '#243246', fontSize: '0.88rem', fontWeight: 700, marginBottom: 4 }}>Default Theme</h4>
                      <p style={{ color: '#526071', fontSize: '0.72rem', lineHeight: 1.35 }}>Choose how the interface looks for admins.</p>
                    </div>
                    <div className="theme-toggle" style={{ display: 'flex', alignItems: 'center', gap: 8, flexShrink: 0 }}>
                      <button
                        type="button"
                        className={`theme-option ${form.theme === 'light' ? 'active' : ''}`}
                        onClick={() => setForm({ ...form, theme: 'light' })}
                        style={{ minHeight: 28, display: 'inline-flex', alignItems: 'center', gap: 6, padding: '0 10px', border: '1px solid transparent', borderRadius: 6, backgroundColor: form.theme === 'light' ? '#2d702f' : 'transparent', color: form.theme === 'light' ? '#ffffff' : '#536174', fontSize: '0.72rem', fontWeight: 700 }}
                      >
                        <i className="fa-solid fa-sun" /> Light
                      </button>
                      <button
                        type="button"
                        className={`theme-option ${form.theme === 'dark' ? 'active' : ''}`}
                        onClick={() => setForm({ ...form, theme: 'dark' })}
                        style={{ minHeight: 28, display: 'inline-flex', alignItems: 'center', gap: 6, padding: '0 10px', border: '1px solid transparent', borderRadius: 6, backgroundColor: form.theme === 'dark' ? '#2d702f' : 'transparent', color: form.theme === 'dark' ? '#ffffff' : '#536174', fontSize: '0.72rem', fontWeight: 700 }}
                      >
                        <i className="fa-solid fa-moon" /> Dark
                      </button>
                    </div>
                  </div>

                  <div className="accent-section">
                    <p style={{ color: '#4b5563', fontSize: '0.85rem', fontWeight: 500, marginBottom: 12 }}>Brand Primary Accent</p>
                    <div className="accent-row" style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      {['green', 'teal', 'forest', 'navy'].map(color => {
                        const bgMap = { green: '#2d702f', teal: '#0d8c75', forest: '#10535d', navy: '#17233f' }
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
                              outline: form.accentColor === color ? '2px solid #2d702f' : 'none',
                              outlineOffset: form.accentColor === color ? '3px' : '0'
                            }}
                          />
                        )
                      })}
                      <a href="#" className="custom-color" style={{ marginLeft: 'auto', border: 0, background: 'transparent', color: '#2d702f', fontSize: '0.72rem', fontWeight: 700, textDecoration: 'none' }}>Custom Color</a>
                    </div>
                  </div>
                </div>

                {/* Transaction Settings Card */}
                <div className="setting-card" style={{ padding: 28, border: '1px solid #e5eaf2', borderRadius: 12, backgroundColor: '#ffffff', boxShadow: '0 8px 24px rgba(15, 23, 42, 0.035)' }}>
                  <div className="card-title" style={{ display: 'flex', alignItems: 'center', gap: 14, marginBottom: 24 }}>
                    <div className="card-icon blue" style={{ width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', borderRadius: 8, backgroundColor: '#dce9ff', color: '#536b91' }}>
                      <i className="fa-solid fa-receipt" />
                    </div>
                    <h3 style={{ color: '#253142', fontSize: '0.98rem', fontWeight: 700 }}>Transaction Settings</h3>
                  </div>

                  <div className="settings-form" style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                    <div className="field-row" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                      <div>
                        <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: '#4b5563' }}>Payment Time Limit</label>
                        <select
                          className="form-select"
                          value={form.paymentLimit}
                          onChange={e => setForm({ ...form, paymentLimit: e.target.value })}
                          style={{ minHeight: 44, padding: '0 16px', backgroundColor: '#eef3ff', borderColor: '#bcc8da', color: '#203047', borderRadius: 6, outline: 0 }}
                        >
                          <option>15 Minutes</option>
                          <option>30 Minutes</option>
                          <option>1 Hour</option>
                          <option>2 Hours</option>
                        </select>
                      </div>

                      <div>
                        <label className="form-label" style={{ display: 'block', marginBottom: 8, fontSize: '0.85rem', fontWeight: 600, color: '#4b5563' }}>System Currency</label>
                        <select
                          className="form-select"
                          value={form.currency}
                          onChange={e => setForm({ ...form, currency: e.target.value })}
                          style={{ minHeight: 44, padding: '0 16px', backgroundColor: '#eef3ff', borderColor: '#bcc8da', color: '#203047', borderRadius: 6, outline: 0 }}
                        >
                          <option value="IDR">Indonesian Rupiah (IDR)</option>
                          <option value="USD">US Dollar (USD)</option>
                        </select>
                      </div>
                    </div>

                    <div className="toggle-panel" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginTop: 10, padding: 18, borderRadius: 10, backgroundColor: '#eef3ff' }}>
                      <div>
                        <strong style={{ display: 'block', color: '#203047', fontSize: '0.86rem', marginBottom: 4, fontWeight: 700 }}>Auto Cancel Unpaid Orders</strong>
                        <span style={{ display: 'block', color: '#526071', fontSize: '0.72rem' }}>Cancel reservations if not paid within limit.</span>
                      </div>
                      <div
                        className="switch"
                        onClick={() => setForm({ ...form, autoCancel: !form.autoCancel })}
                        style={{ position: 'relative', width: 42, height: 24, flexShrink: 0, cursor: 'pointer' }}
                      >
                        <span style={{ position: 'absolute', inset: 0, borderRadius: 999, backgroundColor: form.autoCancel ? '#2d702f' : '#c7d2df', transition: 'background-color 0.2s ease' }} />
                        <span style={{ position: 'absolute', width: 18, height: 18, top: 3, left: 3, borderRadius: '50%', backgroundColor: '#ffffff', transition: 'transform 0.2s ease', transform: form.autoCancel ? 'translateX(18px)' : 'none' }} />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Save & Reset Actions Bar */}
            <div className="settings-actions" style={{ display: 'flex', justifyContent: 'flex-end', gap: 16, marginTop: 32, borderTop: '1px solid #e5eaf2', paddingTop: 24 }}>
              <button
                type="button"
                className="btn reset-btn"
                onClick={handleReset}
                style={{ minWidth: 98, minHeight: 42, borderRadius: 7, fontSize: '0.8rem', fontWeight: 800, border: '1px solid #e2e8f0', backgroundColor: '#ffffff', color: '#334155' }}
              >
                Reset
              </button>
              <button
                type="submit"
                className="btn save-btn"
                disabled={saving}
                style={{ minWidth: 120, minHeight: 42, borderRadius: 7, fontSize: '0.8rem', fontWeight: 800, border: 0, backgroundColor: '#2d702f', color: '#ffffff', boxShadow: '0 6px 16px rgba(45, 112, 47, 0.25)' }}
              >
                {saving ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </form>
        </section>
      </main>
      <Toast toasts={toasts} onRemove={removeToast} />
    </div>
    </AuthGuard>
  )
}

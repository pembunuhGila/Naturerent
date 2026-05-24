'use client'
import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'

export default function EditPenggunaPage() {
  const router = useRouter()
  const params = useParams()
  const { id } = params
  const { toasts, addToast, removeToast } = useToast()

  const [form, setForm] = useState({ name: '', email: '', phone: '', is_active: true })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [errors, setErrors] = useState({})
  const [userEmail, setUserEmail] = useState('')

  useEffect(() => {
    const fetchUser = async () => {
      setLoading(true)
      const supabase = createClient()
      const { data: { user: authUser } } = await supabase.auth.getUser()
      setUserEmail(authUser?.email || '')

      const { data, error } = await supabase.from('users').select('*').eq('id', id).single()
      if (error || !data) {
        addToast('Data pengguna tidak ditemukan.', 'error')
        router.push('/pengguna')
        return
      }
      setForm({
        name: data.nama_lengkap || data.name || '',
        email: data.email || 'customer@naturerent.com',
        phone: data.no_wa || data.phone || '',
        is_active: data.is_active !== false
      })
      setLoading(false)
    }
    fetchUser()
  }, [id])

  const validate = () => {
    const e = {}
    if (!form.name.trim()) e.name = 'Nama wajib diisi.'
    if (!form.email.trim()) e.email = 'Email wajib diisi.'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) e.email = 'Format email tidak valid.'
    return e
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const errs = validate()
    if (Object.keys(errs).length > 0) {
      setErrors(errs)
      addToast('Data tidak valid. Periksa kembali form.', 'error')
      return
    }
    setErrors({})
    setSaving(true)
    const supabase = createClient()
    const { error } = await supabase.from('users').update({
      nama_lengkap: form.name.trim(),
      no_wa: form.phone.trim(),
      is_active: form.is_active,
      updated_at: new Date().toISOString(),
    }).eq('id', id)
    setSaving(false)

    if (error) {
      addToast('Gagal menyimpan perubahan: ' + error.message, 'error')
    } else {
      addToast('Data pengguna berhasil diperbarui!', 'success')
      setTimeout(() => router.push('/pengguna'), 1200)
    }
  }

  if (loading) {
    return (
      <div className="dashboard-container">
        <Sidebar userEmail={userEmail} />
        <main className="main-content">
          <div className="loading-state" style={{ marginTop: 100 }}>
            <div className="loading-spinner" />
            <span>Memuat data...</span>
          </div>
        </main>
      </div>
    )
  }

  return (
    <div className="dashboard-container">
      <Sidebar userEmail={userEmail} />
      <main className="main-content">
        <header className="top-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <button className="btn btn-ghost" onClick={() => router.back()} style={{ padding: '8px 12px' }}>
              <i className="fa-solid fa-arrow-left" />
            </button>
            <div>
              <h1>Edit Data Pengguna</h1>
              <p className="header-subtitle">Perbarui informasi data pengguna.</p>
            </div>
          </div>
        </header>

        <section className="content-section">
          <form className="form-section" onSubmit={handleSubmit}>
            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Nama Lengkap <span style={{ color: 'var(--accent-red)' }}>*</span></label>
                <input
                  className="form-input"
                  type="text"
                  placeholder="Nama lengkap pengguna"
                  value={form.name}
                  onChange={e => setForm({ ...form, name: e.target.value })}
                  style={errors.name ? { borderColor: 'var(--accent-red)' } : {}}
                />
                {errors.name && <p style={{ color: 'var(--accent-red)', fontSize: 12, marginTop: 4 }}>{errors.name}</p>}
              </div>
              <div className="form-group">
                <label className="form-label">Alamat Email <span style={{ color: 'var(--accent-red)' }}>*</span></label>
                <input
                  className="form-input"
                  type="email"
                  placeholder="email@contoh.com"
                  value={form.email}
                  disabled
                  style={{ opacity: 0.6, cursor: 'not-allowed' }}
                />
                <p style={{ color: 'var(--text-muted)', fontSize: 11, marginTop: 4 }}>Email tidak dapat diubah.</p>
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Nomor HP</label>
                <input
                  className="form-input"
                  type="tel"
                  placeholder="08xxxxxxxxxx"
                  value={form.phone}
                  onChange={e => setForm({ ...form, phone: e.target.value })}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Status Akun</label>
                <select
                  className="form-select"
                  value={form.is_active ? 'aktif' : 'nonaktif'}
                  onChange={e => setForm({ ...form, is_active: e.target.value === 'aktif' })}
                >
                  <option value="aktif">Aktif</option>
                  <option value="nonaktif">Nonaktif</option>
                </select>
              </div>
            </div>

            <div className="form-actions">
              <button type="button" className="btn btn-ghost" onClick={() => router.push('/pengguna')}>
                Batal
              </button>
              <button type="submit" className="btn btn-primary" disabled={saving}>
                {saving ? (
                  <><span className="loading-spinner" style={{ width: 14, height: 14, borderWidth: 2 }} /> Menyimpan...</>
                ) : (
                  <><i className="fa-solid fa-floppy-disk" /> Simpan Perubahan</>
                )}
              </button>
            </div>
          </form>
        </section>
      </main>
      <Toast toasts={toasts} onRemove={removeToast} />
    </div>
  )
}

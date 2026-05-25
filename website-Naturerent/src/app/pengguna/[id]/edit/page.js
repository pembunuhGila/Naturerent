'use client'
import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'

export default function EditPenggunaPage() {
  const router = useRouter()
  const { id } = useParams()
  const { toasts, addToast, removeToast } = useToast()

  const [form, setForm] = useState({
    nama_lengkap: '',
    email: '',
    no_wa: '',
  })
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
        nama_lengkap: data.nama_lengkap || data.name || '',
        email: data.email || '',
        no_wa: data.no_wa || data.phone || '',
      })
      setLoading(false)
    }
    fetchUser()
  }, [id])

  const validate = () => {
    const e = {}
    if (!form.nama_lengkap.trim()) e.nama_lengkap = 'Nama wajib diisi.'
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

    try {
      const res = await fetch(`/api/users/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          nama_lengkap: form.nama_lengkap.trim(),
          no_wa: form.no_wa.trim(),
          updated_at: new Date().toISOString(),
        }),
      })
      const json = await res.json()
      if (!res.ok) {
        addToast('Gagal menyimpan perubahan: ' + (json.error || 'Unknown error'), 'error')
      } else {
        addToast('Data pengguna berhasil diperbarui!', 'success')
        setTimeout(() => router.push('/pengguna'), 1200)
      }
    } catch (e) {
      addToast('Gagal menyimpan perubahan: ' + e.message, 'error')
    }
    setSaving(false)
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
          <form className="form-section" onSubmit={handleSubmit} style={{ maxWidth: 640 }}>
            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Nama Lengkap <span style={{ color: 'var(--accent-red)' }}>*</span></label>
                <input
                  className="form-input"
                  type="text"
                  placeholder="Nama lengkap pengguna"
                  value={form.nama_lengkap}
                  onChange={e => setForm({ ...form, nama_lengkap: e.target.value })}
                  style={errors.nama_lengkap ? { borderColor: 'var(--accent-red)' } : {}}
                />
                {errors.nama_lengkap && <p style={{ color: 'var(--accent-red)', fontSize: 12, marginTop: 4 }}>{errors.nama_lengkap}</p>}
              </div>
              <div className="form-group">
                <label className="form-label">Alamat Email</label>
                <input
                  className="form-input"
                  type="email"
                  value={form.email}
                  disabled
                  style={{ opacity: 0.55, cursor: 'not-allowed', background: 'var(--bg-secondary)' }}
                />
                <p style={{ color: 'var(--text-muted)', fontSize: 11, marginTop: 4 }}>Email tidak dapat diubah di sini.</p>
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Nomor HP / WhatsApp</label>
                <input
                  className="form-input"
                  type="tel"
                  placeholder="08xxxxxxxxxx"
                  value={form.no_wa}
                  onChange={e => setForm({ ...form, no_wa: e.target.value })}
                />
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

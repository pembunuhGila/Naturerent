'use client'
import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'

export default function EditPemilikRentalPage() {
  const router = useRouter()
  const { id } = useParams()
  const { toasts, addToast, removeToast } = useToast()

  const [form, setForm] = useState({
    rental_name: '', owner_name: '', location: '', phone: '', email: '',
    description: '', commission_rate: '', is_active: true,
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [errors, setErrors] = useState({})
  const [userEmail, setUserEmail] = useState('')
  const [ownerId, setOwnerId] = useState(null)

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true)
      const supabase = createClient()
      const { data: { user: authUser } } = await supabase.auth.getUser()
      setUserEmail(authUser?.email || '')

      let data, error
      try {
        const { data: row, error: err } = await supabase
          .from('rental_profiles')
          .select('*')
          .eq('id', id)
          .single()
        
        if (err || !row) {
          error = err || new Error('Data tidak ditemukan.')
        } else {
          // Fetch user/owner info separately to avoid PostgREST join limitations
          let userObj = null
          if (row.owner_id) {
            const { data: userData, error: userErr } = await supabase
              .from('users')
              .select('nama_lengkap, email, no_wa')
              .eq('id', row.owner_id)
              .maybeSingle()
            if (!userErr && userData) {
              userObj = userData
            }
          }
          data = {
            ...row,
            users: userObj
          }
        }
      } catch (e) {
        error = e
      }

      if (error || !data) {
        addToast('Data tidak ditemukan.', 'error')
        router.push('/pemilik-rental')
        return
      }

      setOwnerId(data.owner_id || null)
      setForm({
        rental_name: data.nama_rental || data.rental_name || '',
        owner_name: data.users?.nama_lengkap || data.owner_name || '',
        location: data.alamat || data.location || '',
        phone: data.users?.no_wa || data.no_wa || data.phone || '',
        email: data.users?.email || data.email || 'partner@naturerent.com',
        description: data.deskripsi || data.description || '',
        commission_rate: data.commission_rate ?? '',
        is_active: data.is_active !== false,
      })
      setLoading(false)
    }
    fetchData()
  }, [id])

  const validate = () => {
    const e = {}
    if (!form.rental_name.trim()) e.rental_name = 'Nama rental wajib diisi.'
    if (!form.owner_name.trim()) e.owner_name = 'Nama pemilik wajib diisi.'
    if (!form.location.trim()) e.location = 'Lokasi wajib diisi.'
    if (form.commission_rate !== '' && (isNaN(form.commission_rate) || +form.commission_rate < 0 || +form.commission_rate > 100)) {
      e.commission_rate = 'Komisi harus antara 0–100.'
    }
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
    
    // Update rental profile
    const { error } = await supabase.from('rental_profiles').update({
      nama_rental: form.rental_name.trim(),
      alamat: form.location.trim(),
      no_wa: form.phone.trim(),
      deskripsi: form.description.trim(),
      is_active: form.is_active,
      updated_at: new Date().toISOString(),
    }).eq('id', id)

    // Update owner's name in users table if ownerId is found
    if (ownerId) {
      await supabase.from('users').update({
        nama_lengkap: form.owner_name.trim(),
        no_wa: form.phone.trim(),
      }).eq('id', ownerId)
    }

    setSaving(false)

    if (error) {
      addToast('Gagal menyimpan: ' + error.message, 'error')
    } else {
      addToast('Data pemilik rental berhasil diperbarui!', 'success')
      setTimeout(() => router.push('/pemilik-rental'), 1200)
    }
  }

  const field = (key, label, type = 'text', placeholder = '', required = false, err) => (
    <div className="form-group">
      <label className="form-label">{label} {required && <span style={{ color: 'var(--accent-red)' }}>*</span>}</label>
      <input
        className="form-input"
        type={type}
        placeholder={placeholder}
        value={form[key]}
        onChange={e => setForm({ ...form, [key]: e.target.value })}
        style={err ? { borderColor: 'var(--accent-red)' } : {}}
      />
      {err && <p style={{ color: 'var(--accent-red)', fontSize: 12, marginTop: 4 }}>{err}</p>}
    </div>
  )

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
              <h1>Edit Pemilik Rental</h1>
              <p className="header-subtitle">Perbarui informasi pemilik rental.</p>
            </div>
          </div>
        </header>

        <section className="content-section">
          <form className="form-section" onSubmit={handleSubmit} style={{ maxWidth: 720 }}>
            <div className="form-row">
              {field('rental_name', 'Nama Rental', 'text', 'Green Valley Glamping', true, errors.rental_name)}
              {field('owner_name', 'Nama Pemilik', 'text', 'Samsudin Hernanto', true, errors.owner_name)}
            </div>
            <div className="form-row">
              {field('location', 'Lokasi', 'text', 'Bromo, Jawa Timur', true, errors.location)}
              {field('commission_rate', 'Komisi (%)', 'number', '10', false, errors.commission_rate)}
            </div>
            <div className="form-row">
              {field('phone', 'Nomor HP', 'tel', '08xxxxxxxxxx')}
              {field('email', 'Email', 'email', 'pemilik@email.com')}
            </div>

            <div className="form-group">
              <label className="form-label">Deskripsi</label>
              <textarea
                className="form-textarea"
                placeholder="Deskripsi singkat tentang rental..."
                value={form.description}
                onChange={e => setForm({ ...form, description: e.target.value })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Status</label>
              <select
                className="form-select"
                value={form.is_active ? 'aktif' : 'nonaktif'}
                onChange={e => setForm({ ...form, is_active: e.target.value === 'aktif' })}
                style={{ maxWidth: 200 }}
              >
                <option value="aktif">Aktif</option>
                <option value="nonaktif">Nonaktif</option>
              </select>
            </div>

            <div className="form-actions">
              <button type="button" className="btn btn-ghost" onClick={() => router.push('/pemilik-rental')}>
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

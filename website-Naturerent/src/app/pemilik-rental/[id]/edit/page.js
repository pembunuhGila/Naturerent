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
  // QRIS state
  const [qrisMerchant, setQrisMerchant] = useState('')
  const [qrisImageUrl, setQrisImageUrl] = useState(null)
  const [qrisImageFile, setQrisImageFile] = useState(null)
  const [qrisImagePreview, setQrisImagePreview] = useState(null)

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
      // Load existing QRIS
      setQrisMerchant(data.qris_merchant_name || '')
      setQrisImageUrl(data.qris_image_url || null)
      setQrisImagePreview(data.qris_image_url || null)
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

  const handleQrisImageChange = (e) => {
    const file = e.target.files[0]
    if (!file) return
    if (file.size > 2 * 1024 * 1024) {
      addToast('Gambar terlalu besar (maks 2MB)', 'error')
      return
    }
    setQrisImageFile(file)
    setQrisImagePreview(URL.createObjectURL(file))
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

    // Upload QRIS image to Supabase Storage if a new file was selected
    let finalQrisImageUrl = qrisImageUrl
    if (qrisImageFile) {
      const fileExt = qrisImageFile.name.split('.').pop()
      const filePath = `${id}/qris.${fileExt}`
      const { error: uploadError } = await supabase.storage
        .from('qris-images')
        .upload(filePath, qrisImageFile, { upsert: true, contentType: qrisImageFile.type })
      if (uploadError) {
        addToast('Gagal upload gambar QRIS: ' + uploadError.message, 'error')
        setSaving(false)
        return
      }
      const { data: urlData } = supabase.storage.from('qris-images').getPublicUrl(filePath)
      finalQrisImageUrl = urlData?.publicUrl || null
    }
    
    // Update rental profile
    const { error } = await supabase.from('rental_profiles').update({
      nama_rental: form.rental_name.trim(),
      alamat: form.location.trim(),
      no_wa: form.phone.trim(),
      deskripsi: form.description.trim(),
      is_active: form.is_active,
      qris_merchant_name: qrisMerchant.trim() || null,
      qris_image_url: finalQrisImageUrl,
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

            {/* QRIS Configuration Section */}
            <div style={{ marginTop: 8, padding: 20, borderRadius: 12, border: '1px solid var(--border-color)', backgroundColor: 'var(--bg-secondary)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
                <div style={{ width: 28, height: 28, borderRadius: 7, backgroundColor: 'var(--brand-mint)', color: 'var(--brand-green)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 13 }}>
                  <i className="fa-solid fa-qrcode" />
                </div>
                <h4 style={{ fontWeight: 700, fontSize: '0.92rem', color: 'var(--text-primary)' }}>Konfigurasi QRIS Rental</h4>
              </div>
              <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)', marginBottom: 18 }}>Gambar QRIS ini ditampilkan kepada pembeli saat melakukan pembayaran untuk rental ini.</p>

              <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
                {/* QR Image Upload */}
                <div
                  onClick={() => document.getElementById('edit-qris-img').click()}
                  style={{ width: 110, height: 110, borderRadius: 10, border: `2px dashed var(--brand-green)`, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 6, cursor: 'pointer', overflow: 'hidden', backgroundColor: 'var(--bg-card)', flexShrink: 0 }}
                >
                  {qrisImagePreview
                    ? <img src={qrisImagePreview} alt="QRIS" style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                    : <>
                        <i className="fa-solid fa-qrcode" style={{ fontSize: 32, color: 'var(--brand-green)' }} />
                        <span style={{ fontSize: '0.62rem', color: 'var(--text-muted)', fontWeight: 700, textAlign: 'center' }}>KLIK UPLOAD<br />GAMBAR QRIS</span>
                      </>
                  }
                </div>
                <input type="file" id="edit-qris-img" accept="image/*" style={{ display: 'none' }} onChange={handleQrisImageChange} />

                <div style={{ flex: 1 }}>
                  <div className="form-group" style={{ marginBottom: 12 }}>
                    <label className="form-label" style={{ marginBottom: 6 }}>Nama Merchant QRIS</label>
                    <input
                      className="form-input"
                      type="text"
                      placeholder="e.g. Pandawa Outdoor"
                      value={qrisMerchant}
                      onChange={e => setQrisMerchant(e.target.value)}
                    />
                    <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', marginTop: 4 }}>Nama yang tampil ke pembeli saat pembayaran</p>
                  </div>
                  {qrisImagePreview && (
                    <button type="button"
                      onClick={() => { setQrisImagePreview(null); setQrisImageFile(null); setQrisImageUrl(null) }}
                      style={{ fontSize: '0.75rem', color: '#ef4444', background: 'none', border: 'none', cursor: 'pointer', fontWeight: 700, padding: 0 }}>
                      <i className="fa-solid fa-trash" style={{ marginRight: 5 }} />Hapus gambar QRIS
                    </button>
                  )}
                  {!qrisImagePreview && (
                    <p style={{ fontSize: '0.72rem', color: '#f59e0b', fontWeight: 600 }}>
                      <i className="fa-solid fa-triangle-exclamation" style={{ marginRight: 5 }} />
                      Belum ada gambar QRIS. Upload agar pembeli bisa melakukan pembayaran.
                    </p>
                  )}
                </div>
              </div>
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

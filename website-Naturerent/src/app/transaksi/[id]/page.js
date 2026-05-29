'use client'
import { useState, useEffect } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import { createClient } from '@/lib/supabase'

function formatCurrency(amount) {
  if (!amount) return '-'
  return 'Rp ' + Number(amount).toLocaleString('id-ID')
}

function formatDate(dateStr) {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function getFullProofUrl(url) {
  if (!url) return '#'
  if (url.startsWith('data:') || url.startsWith('http://') || url.startsWith('https://')) {
    return url
  }
  const baseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://hctdfnwfigcjycemacif.supabase.co'
  return `${baseUrl.replace(/\/+$/, '')}/${url.replace(/^\/+/, '')}`
}

const statusBadge = (status) => {
  const labelMap = {
    pending: 'Menunggu Verifikasi',
    confirmed: 'ACC',
    processing: 'Diproses',
    rented: 'Aktif',
    returned: 'Dikembalikan',
    completed: 'Selesai',
    cancelled: 'Batal',
    Selesai: 'Selesai',
    Proses: 'Diproses',
    Ditolak: 'Ditolak',
  }
  const colorMap = {
    pending: 'badge-warning',
    confirmed: 'badge-success',
    processing: 'badge-warning',
    rented: 'badge-blue',
    returned: 'badge-blue',
    completed: 'badge-success',
    cancelled: 'badge-danger',
    Selesai: 'badge-success',
    Proses: 'badge-warning',
    Ditolak: 'badge-danger',
  }
  return <span className={`badge ${colorMap[status] || 'badge-blue'}`}>{labelMap[status] || status}</span>
}

export default function TransaksiDetailPage() {
  const router = useRouter()
  const { id } = useParams()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [userEmail, setUserEmail] = useState('')
  const [showProofModal, setShowProofModal] = useState(false)

  useEffect(() => {
    const fetch = async () => {
      setLoading(true)
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      setUserEmail(user?.email || '')
      
      let finalData = null
      try {
        const { data: row } = await supabase
          .from('bookings')
          .select('*, rental_profiles(nama_rental, owner_id, alamat, qris_image_url, qris_merchant_name), deliveries(*)')
          .eq('id', id)
          .single()
        if (row) {
          let userName = 'Pengguna'
          let userEmailStr = '-'
          let userPhoneStr = '-'
          if (row.customer_id) {
            try {
              const { data: userData } = await supabase.from('users').select('nama_lengkap, email, no_wa').eq('id', row.customer_id).single()
              if (userData) {
                userName = userData.nama_lengkap || 'Pengguna'
                userEmailStr = userData.email || '-'
                userPhoneStr = userData.no_wa || '-'
              }
            } catch (_) {}
          }
          finalData = {
            ...row,
            user_name: userName,
            user_email: userEmailStr,
            user_phone: userPhoneStr,
            rental_name: row.rental_profiles?.nama_rental || row.rental_name || 'Peralatan Camping',
            owner_name: row.owner_name || 'Mitra NatureRent',
            total_amount: row.total_bayar || row.total || row.total_amount || row.subtotal || 0,
            payment_method: 'QRIS',
            start_date: row.tgl_mulai || row.start_date || row.created_at,
            end_date: row.tgl_selesai || row.end_date || row.created_at,
            notes: row.catatan || row.notes || '-',
            alamat: row.rental_profiles?.alamat || row.alamat || '-',
            qris_image_url: row.rental_profiles?.qris_image_url || null,
            qris_merchant_name: row.rental_profiles?.qris_merchant_name || null,
            delivery: row.deliveries && row.deliveries.length > 0 ? row.deliveries[0] : null,
          }
        }
      } catch (e) {
        console.error('Database fetch error:', e)
      }

      // Fallback to mock data if database is empty/not found
      if (!finalData) {
        const fallbackTransactions = [
          { id: 'TRX-20250526-001', created_at: '2025-05-26T10:30:00Z', user_name: 'Budi Santoso', user_email: 'budi@gmail.com', user_phone: '081234567890', rental_name: 'Summit Gear Rental', total_amount: 250000, status: 'Selesai', payment_method: 'QRIS', start_date: '2025-05-27T08:00:00Z', end_date: '2025-05-29T17:00:00Z', notes: 'Minta tenda warna hijau' },
          { id: 'TRX-20250526-002', created_at: '2025-05-26T09:15:00Z', user_name: 'Siti Aisyah', user_email: 'siti@gmail.com', user_phone: '081234567891', rental_name: 'Green Valley Glamping', total_amount: 350000, status: 'Selesai', payment_method: 'Transfer Bank', start_date: '2025-05-28T10:00:00Z', end_date: '2025-05-30T12:00:00Z', notes: 'Sewa matras ekstra' },
          { id: 'TRX-20250525-003', created_at: '2025-05-25T16:45:00Z', user_name: 'Rizky Pratama', user_email: 'rizky@gmail.com', user_phone: '081234567892', rental_name: 'Lembah Pinus Outdoor', total_amount: 150000, status: 'Proses', payment_method: 'QRIS', start_date: '2025-05-26T07:00:00Z', end_date: '2025-05-27T18:00:00Z', notes: '-' },
          { id: 'TRX-20250525-004', created_at: '2025-05-25T14:20:00Z', user_name: 'Dewi Lestari', user_email: 'dewi@gmail.com', user_phone: '081234567893', rental_name: 'Summit Gear Rental', total_amount: 450000, status: 'Selesai', payment_method: 'QRIS', start_date: '2025-05-26T09:00:00Z', end_date: '2025-05-29T12:00:00Z', notes: 'Tenda dipastikan bersih' },
          { id: 'TRX-20250524-005', created_at: '2025-05-24T11:05:00Z', user_name: 'Andi Wijaya', user_email: 'andi@gmail.com', user_phone: '081234567894', rental_name: 'Setyawan Martin', total_amount: 300000, status: 'Bermasalah', payment_method: 'Transfer Bank', start_date: '2025-05-25T08:00:00Z', end_date: '2025-05-26T17:00:00Z', notes: 'Kompor lipat tidak nyala' },
          { id: 'TRX-20250524-006', created_at: '2025-05-24T10:12:00Z', user_name: 'Nina Kartika', user_email: 'nina@gmail.com', user_phone: '081234567895', rental_name: 'Ijen Adventure', total_amount: 200000, status: 'Selesai', payment_method: 'QRIS', start_date: '2025-05-25T08:00:00Z', end_date: '2025-05-26T17:00:00Z', notes: '-' },
          { id: 'TRX-20250523-007', created_at: '2025-05-23T17:30:00Z', user_name: 'Fajar Ramadhan', user_email: 'fajar@gmail.com', user_phone: '081234567896', rental_name: 'Lembah Pinus Outdoor', total_amount: 175000, status: 'Proses', payment_method: 'QRIS', start_date: '2025-05-24T08:00:00Z', end_date: '2025-05-26T12:00:00Z', notes: 'Butuh extra nesting' },
          { id: 'TRX-20250523-008', created_at: '2025-05-23T09:45:00Z', user_name: 'Maya Sari', user_email: 'maya@gmail.com', user_phone: '081234567897', rental_name: 'Green Valley Glamping', total_amount: 275000, status: 'Selesai', payment_method: 'QRIS', start_date: '2025-05-24T08:00:00Z', end_date: '2025-05-26T17:00:00Z', notes: '-' }
        ]
        const matched = fallbackTransactions.find(t => t.id === id)
        if (matched) {
          finalData = {
            ...matched,
            owner_name: 'Mitra NatureRent'
          }
        }
      }
      
      setData(finalData)
      setLoading(false)
    }
    fetch()
  }, [id])

  const handleDownloadInvoice = () => {
    if (!data) return
    window.open(`/transaksi/${data.id}/invoice`, '_blank', 'noopener,noreferrer')
  }

  const handleUpdateStatus = async (nextStatus) => {
    if (!data || saving) return
    setSaving(true)
    const supabase = createClient()
    const payload = {
      status: nextStatus,
      updated_at: new Date().toISOString(),
    }

    // Koreksi nilai ENUM agar sesuai dengan definisi database (public.payment_status)
    if (nextStatus === 'confirmed') {
      payload.payment_status = 'dp_confirmed'
    }
    if (nextStatus === 'cancelled') {
      payload.payment_status = 'failed'
    }

    // Cek format UUID untuk mencegah error syntax pada data simulasi (mock)
    const isUUID = (str) => {
      const pattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      return pattern.test(str)
    }

    if (!isUUID(data.id)) {
      // Untuk data simulasi, langsung update state UI tanpa memanggil database
      setSaving(false)
      setData(prev => ({ ...prev, ...payload }))
      return
    }

    const { error } = await supabase
      .from('bookings')
      .update(payload)
      .eq('id', data.id)

    setSaving(false)
    if (error) {
      alert('Gagal update status: ' + error.message)
      return
    }
    setData(prev => ({ ...prev, ...payload }))
  }

  return (
    <div className="dashboard-container">
      <Sidebar userEmail={userEmail} />
      <main className="main-content">
        <header className="top-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <button className="btn btn-ghost" onClick={() => router.push('/transaksi')} style={{ padding: '8px 12px' }}>
              <i className="fa-solid fa-arrow-left" />
            </button>
            <div>
              <h1>Detail Transaksi</h1>
              <p className="header-subtitle">Informasi lengkap transaksi.</p>
            </div>
          </div>
        </header>

        <section className="content-section">
          {loading ? (
            <div className="loading-state"><div className="loading-spinner" /><span>Memuat detail...</span></div>
          ) : !data ? (
            <div className="empty-state">
              <i className="fa-solid fa-receipt empty-icon" />
              <p>Transaksi tidak ditemukan.</p>
              <button className="btn btn-ghost" onClick={() => router.push('/transaksi')}>Kembali</button>
            </div>
          ) : (
            <div className="form-section" style={{ maxWidth: 720 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <div>
                  <p style={{ fontSize: 12, color: 'var(--text-secondary)' }}>ID TRANSAKSI</p>
                  <p style={{ fontFamily: 'monospace', fontSize: 18, fontWeight: 700, color: 'var(--brand-emerald)' }}>{data.id}</p>
                </div>
                {statusBadge(data.status)}
              </div>

                {/* QRIS Payment Card */}
                <div style={{ marginBottom: 24, padding: 20, borderRadius: 12, border: '1.5px solid var(--border-color)', backgroundColor: 'var(--bg-secondary)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
                    <i className="fa-solid fa-qrcode" style={{ color: 'var(--brand-green)', fontSize: 16 }} />
                    <span style={{ fontWeight: 700, fontSize: '0.92rem', color: 'var(--text-primary)' }}>Pembayaran via QRIS</span>
                    <span style={{ padding: '2px 10px', borderRadius: 999, fontSize: '0.68rem', fontWeight: 700, backgroundColor: 'rgba(82,183,136,0.15)', color: 'var(--brand-green)', border: '1px solid rgba(82,183,136,0.3)', marginLeft: 'auto' }}>
                      QRIS Only
                    </span>
                  </div>
                  <div style={{ display: 'flex', gap: 20, alignItems: 'flex-start' }}>
                    <div style={{ width: 120, height: 120, borderRadius: 10, border: '1.5px solid var(--border-color)', backgroundColor: 'var(--bg-card)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', flexShrink: 0, overflow: 'hidden' }}>
                      {data.qris_image_url
                        ? <img src={data.qris_image_url} alt="QRIS" style={{ width: '100%', height: '100%', objectFit: 'contain', padding: 4 }} />
                        : <>
                            <i className="fa-solid fa-qrcode" style={{ fontSize: 36, color: 'var(--text-muted)' }} />
                            <span style={{ fontSize: '0.62rem', color: 'var(--text-muted)', marginTop: 6, textAlign: 'center', padding: '0 8px' }}>Belum ada QRIS</span>
                          </>
                      }
                    </div>
                    <div style={{ flex: 1 }}>
                      <p style={{ fontSize: '0.82rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: 4 }}>{data.rental_name}</p>
                      {data.qris_merchant_name && (
                        <p style={{ fontSize: '0.78rem', color: 'var(--text-secondary)', marginBottom: 8 }}>Merchant: {data.qris_merchant_name}</p>
                      )}
                      <p style={{ fontSize: '0.76rem', color: 'var(--text-muted)', lineHeight: 1.6 }}>
                        Scan kode QR di atas menggunakan aplikasi m-banking atau e-wallet untuk menyelesaikan pembayaran.
                      </p>
                      {!data.qris_image_url && (
                        <p style={{ fontSize: '0.74rem', color: '#f59e0b', fontWeight: 600, marginTop: 8 }}>
                          <i className="fa-solid fa-triangle-exclamation" style={{ marginRight: 5 }} />
                          QRIS belum dikonfigurasi. Hubungi admin untuk mengatur QRIS rental ini.
                        </p>
                      )}
                    </div>
                  </div>
                </div>

                {/* Delivery / Pickup Information Card */}
                <div style={{ marginBottom: 24, padding: 20, borderRadius: 12, border: '1.5px solid var(--border-color)', backgroundColor: 'var(--bg-secondary)' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 14 }}>
                    <i className={data.tipe_pengiriman === 'delivery' ? "fa-solid fa-truck" : "fa-solid fa-store"} style={{ color: 'var(--brand-green)', fontSize: 16 }} />
                    <span style={{ fontWeight: 700, fontSize: '0.92rem', color: 'var(--text-primary)' }}>
                      {data.tipe_pengiriman === 'delivery' ? 'Informasi Pengiriman (Delivery)' : 'Informasi Pengambilan (Self Pickup)'}
                    </span>
                    <span style={{ padding: '2px 10px', borderRadius: 999, fontSize: '0.68rem', fontWeight: 700, backgroundColor: data.tipe_pengiriman === 'delivery' ? 'rgba(59,130,246,0.15)' : 'rgba(16,185,129,0.15)', color: data.tipe_pengiriman === 'delivery' ? '#3b82f6' : 'var(--brand-green)', border: data.tipe_pengiriman === 'delivery' ? '1px solid rgba(59,130,246,0.3)' : '1px solid rgba(16,185,129,0.3)', marginLeft: 'auto', textTransform: 'uppercase' }}>
                      {data.tipe_pengiriman === 'delivery' ? 'Delivery' : 'Self Pickup'}
                    </span>
                  </div>

                  {data.tipe_pengiriman === 'delivery' ? (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                      <div style={{ display: 'grid', gridTemplateColumns: '150px 1fr', gap: 10 }}>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Alamat Pengiriman:</span>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-primary)', fontWeight: 700 }}>{data.delivery?.alamat_kirim || '-'}</span>
                      </div>
                      <div style={{ display: 'grid', gridTemplateColumns: '150px 1fr', gap: 10 }}>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Nama Kurir:</span>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-primary)', fontWeight: 700 }}>{data.delivery?.nama_kurir || 'Belum Ditugaskan'}</span>
                      </div>
                      <div style={{ display: 'grid', gridTemplateColumns: '150px 1fr', gap: 10 }}>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Status Pengiriman:</span>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-primary)', fontWeight: 700 }}>
                          <span className={`badge ${
                            data.delivery?.status === 'delivered' || data.delivery?.status === 'returned' ? 'badge-success' :
                            data.delivery?.status === 'on_the_way' || data.delivery?.status === 'returning' ? 'badge-blue' : 'badge-warning'
                          }`} style={{ textTransform: 'uppercase', fontSize: '0.68rem', fontWeight: 800 }}>
                            {data.delivery?.status || 'Waiting'}
                          </span>
                        </span>
                      </div>
                      {data.delivery?.scheduled_at && (
                        <div style={{ display: 'grid', gridTemplateColumns: '150px 1fr', gap: 10 }}>
                          <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Jadwal Pengiriman:</span>
                          <span style={{ fontSize: '0.8rem', color: 'var(--text-primary)', fontWeight: 700 }}>{formatDate(data.delivery.scheduled_at)}</span>
                        </div>
                      )}
                      {data.delivery?.catatan && (
                        <div style={{ display: 'grid', gridTemplateColumns: '150px 1fr', gap: 10 }}>
                          <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Catatan Kurir:</span>
                          <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)', fontStyle: 'italic' }}>{data.delivery.catatan}</span>
                        </div>
                      )}
                    </div>
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                      <div style={{ display: 'grid', gridTemplateColumns: '150px 1fr', gap: 10 }}>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Metode:</span>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-primary)', fontWeight: 700 }}>Ambil Sendiri ke Toko Rental</span>
                      </div>
                      <div style={{ display: 'grid', gridTemplateColumns: '150px 1fr', gap: 10 }}>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)', fontWeight: 600 }}>Alamat Rental:</span>
                        <span style={{ fontSize: '0.8rem', color: 'var(--text-primary)', fontWeight: 700 }}>{data.alamat || '-'}</span>
                      </div>
                      <p style={{ fontSize: '0.74rem', color: 'var(--text-muted)', margin: '4px 0 0 0', lineHeight: 1.5 }}>
                        Penyewa akan datang langsung ke alamat toko rental di atas untuk mengambil dan mengembalikan peralatan sesuai jadwal sewa.
                      </p>
                    </div>
                  )}
                </div>

              <div className="detail-grid" style={{ marginBottom: 24 }}>
                {[
                  ['Nama User', data.user_name || '-'],
                  ['Email User', data.user_email || '-'],
                  ['Nama Rental', data.rental_name || '-'],
                  ['Pemilik Rental', data.owner_name || '-'],
                  ['Total Pembayaran', formatCurrency(data.total_amount || data.total)],
                  ['Metode Pembayaran', data.payment_method || '-'],
                  ['Status Pembayaran', data.payment_status || '-'],
                  ['Tanggal Transaksi', formatDate(data.created_at || data.transaction_date)],
                  ['Tanggal Sewa Mulai', formatDate(data.start_date)],
                  ['Tanggal Sewa Selesai', formatDate(data.end_date)],
                  ['Catatan', data.notes || '-'],
                ].map(([label, value]) => (
                  <div key={label} className="detail-item">
                    <p className="detail-label">{label}</p>
                    <p className="detail-value">{value}</p>
                  </div>
                ))}
              </div>

              <div style={{ display: 'flex', gap: 10 }}>
                <button className="btn btn-ghost" onClick={() => router.push('/transaksi')}>
                  <i className="fa-solid fa-arrow-left" /> Kembali
                </button>
                {data.payment_proof_url && (
                  <button type="button" className="btn btn-ghost" onClick={() => setShowProofModal(true)}>
                    <i className="fa-solid fa-image" /> Bukti DP
                  </button>
                )}
                {data.status === 'pending' && (
                  <>
                    <button className="btn btn-primary" disabled={saving} onClick={() => handleUpdateStatus('confirmed')}>
                      <i className="fa-solid fa-check" /> ACC
                    </button>
                    <button className="btn btn-danger" disabled={saving} onClick={() => handleUpdateStatus('cancelled')}>
                      <i className="fa-solid fa-xmark" /> Tolak
                    </button>
                  </>
                )}
                <button className="btn btn-primary" onClick={handleDownloadInvoice}>
                  <i className="fa-solid fa-download" /> Download
                </button>
              </div>
            </div>
          )}
        </section>
      </main>

      {/* Bukti DP Modal Overlay */}
      {showProofModal && data?.payment_proof_url && (
        <div className="modal-overlay" onClick={() => setShowProofModal(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.65)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
          <div className="modal-box" onClick={e => e.stopPropagation()} style={{ background: 'var(--bg-card)', borderRadius: 16, padding: 32, width: '100%', maxWidth: 540, border: '1px solid var(--border-color)', boxShadow: '0 20px 60px rgba(0,0,0,0.3)', display: 'flex', flexDirection: 'column', position: 'relative' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
              <h2 style={{ margin: 0, fontSize: 18, fontWeight: 700, color: 'var(--text-primary)' }}>Detail Bukti Transfer DP</h2>
              <button onClick={() => setShowProofModal(false)} style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', fontSize: 22, padding: 4 }}>
                <i className="fa-solid fa-xmark" />
              </button>
            </div>
            <div style={{ width: '100%', borderRadius: 12, overflow: 'hidden', border: '1px solid var(--border-color)', background: '#000', display: 'flex', justifyContent: 'center', alignItems: 'center', maxHeight: '60vh' }}>
              <img src={getFullProofUrl(data.payment_proof_url)} alt="Bukti Transfer DP" style={{ maxWidth: '100%', maxHeight: '60vh', objectFit: 'contain' }} />
            </div>
            <div style={{ display: 'flex', gap: 10, marginTop: 24 }}>
              <button className="btn btn-ghost" onClick={() => setShowProofModal(false)} style={{ flex: 1 }}>Tutup</button>
              <a className="btn btn-primary" href={getFullProofUrl(data.payment_proof_url)} download="bukti-dp.jpg" style={{ flex: 1, textDecoration: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}>
                <i className="fa-solid fa-download" /> Download Asli
              </a>
            </div>
          </div>
        </div>
      )}

    </div>
  )
}

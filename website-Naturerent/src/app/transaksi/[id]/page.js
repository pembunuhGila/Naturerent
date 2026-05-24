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

const statusBadge = (status) => {
  const map = { 'Selesai': 'badge-success', 'Proses': 'badge-warning', 'Ditolak': 'badge-danger' }
  return <span className={`badge ${map[status] || 'badge-blue'}`}>{status}</span>
}

export default function TransaksiDetailPage() {
  const router = useRouter()
  const { id } = useParams()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [userEmail, setUserEmail] = useState('')

  useEffect(() => {
    const fetch = async () => {
      setLoading(true)
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      setUserEmail(user?.email || '')
      const { data: row } = await supabase.from('bookings').select('*').eq('id', id).single()
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
        setData({
          ...row,
          user_name: userName,
          user_email: userEmailStr,
          user_phone: userPhoneStr,
          rental_name: 'Peralatan Camping',
          owner_name: 'Mitra NatureRent',
          total_amount: row.total || row.total_amount || 0,
          payment_method: row.payment_method || 'QRIS',
          start_date: row.start_date || row.created_at,
          end_date: row.end_date || row.created_at,
          notes: row.notes || '-'
        })
      } else {
        setData(null)
      }
      setLoading(false)
    }
    fetch()
  }, [id])

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

              <div className="detail-grid" style={{ marginBottom: 24 }}>
                {[
                  ['Nama User', data.user_name || '-'],
                  ['Email User', data.user_email || '-'],
                  ['Nama Rental', data.rental_name || '-'],
                  ['Pemilik Rental', data.owner_name || '-'],
                  ['Total Pembayaran', formatCurrency(data.total_amount || data.total)],
                  ['Metode Pembayaran', data.payment_method || '-'],
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
                <button className="btn btn-primary" onClick={() => window.print()}>
                  <i className="fa-solid fa-download" /> Download
                </button>
              </div>
            </div>
          )}
        </section>
      </main>
    </div>
  )
}

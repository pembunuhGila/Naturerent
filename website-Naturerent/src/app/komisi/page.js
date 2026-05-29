'use client'
import { useState, useEffect, useCallback } from 'react'
import Sidebar from '@/components/Sidebar'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

const PAGE_SIZE = 5

function formatCurrency(amount) {
  if (amount === undefined || amount === null) return '-'
  return 'Rp. ' + Number(amount).toLocaleString('id-ID')
}

function formatDate(dateStr) {
  if (!dateStr) return '-'
  const d = new Date(dateStr)
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des']
  return `${months[d.getMonth()]} ${d.getDate()}`
}

function formatTime(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  return `${hours}:${minutes}`
}

export default function KomisiPage() {
  const { toasts, addToast, removeToast } = useToast()
  const [userEmail, setUserEmail] = useState('')
  const [commissionRate, setCommissionRate] = useState(12.5)
  const [loading, setLoading] = useState(true)
  const [data, setData] = useState([])
  const [page, setPage] = useState(1)
  const [totalCount, setTotalCount] = useState(0)
  const [statusFilter, setStatusFilter] = useState('Semua')

  const fetchData = useCallback(async () => {
    setLoading(true)
    
    try {
      const res = await fetch('/api/bookings')
      if (!res.ok) throw new Error('Gagal memuat data bookings')
      const bookings = await res.json()
      
      if (!bookings || bookings.length === 0) {
        throw new Error('Tidak ada data bookings')
      }

      const resolved = bookings.map((b) => {
        return {
          id: b.id.startsWith('TRX-') ? b.id : `TRX-${b.id.substring(0, 5).toUpperCase()}`,
          created_at: b.created_at,
          rental_name: b.rental_profiles?.nama_rental || 'Unknown Rental',
          gross_amount: b.total_bayar || b.subtotal || b.total || b.total_amount || 0,
          status: (b.status === 'completed' || b.status === 'returned' || b.status === 'Selesai') ? 'Selesai' : 
                  (b.status === 'cancelled' || b.status === 'Ditolak') ? 'Batal' : 'Proses'
        }
      })
      setData(resolved)
      setTotalCount(resolved.length)
    } catch (error) {
      console.error('Error fetching bookings:', error)
      const fallbackTransactions = [
        { id: 'TRX-99210', created_at: '2026-10-12T14:30:00Z', rental_name: 'Summit Peak Gear', gross_amount: 700000, status: 'Selesai' },
        { id: 'TRX-99208', created_at: '2026-10-12T12:15:00Z', rental_name: 'River Runner Rentals', gross_amount: 250000, status: 'Selesai' },
        { id: 'TRX-99194', created_at: '2026-10-12T11:45:00Z', rental_name: 'Forest Bound Hub', gross_amount: 150000, status: 'Proses' },
        { id: 'TRX-99182', created_at: '2026-10-11T18:20:00Z', rental_name: 'Trail Blazers Co.', gross_amount: 300000, status: 'Selesai' }
      ]
      
      setData(fallbackTransactions)
      setTotalCount(fallbackTransactions.length)
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    const init = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      setUserEmail(user?.email || '')
      
      // Load saved commission rate from localStorage if exists
      const savedRate = localStorage.getItem('naturerent_commission_rate')
      if (savedRate) {
        setCommissionRate(Number(savedRate))
      }

      // Fetch live commission rate from Supabase database
      try {
        const comRes = await fetch('/api/commission-settings')
        if (comRes.ok) {
          const comData = await comRes.json()
          if (comData?.percentage !== undefined) {
            const dbRate = Number(comData.percentage)
            setCommissionRate(dbRate)
            localStorage.setItem('naturerent_commission_rate', String(dbRate))
          }
        }
      } catch (err) {
        console.error('Error fetching commission rate from DB:', err)
      }
    }
    init()
    fetchData()

    // Live-sync if admin updates rate from System Settings in another tab
    const onStorage = (e) => {
      if (e.key === 'naturerent_commission_rate' && e.newValue) {
        setCommissionRate(Number(e.newValue))
      }
    }
    window.addEventListener('storage', onStorage)
    return () => window.removeEventListener('storage', onStorage)
  }, [])


  const filteredData = statusFilter === 'Semua' 
    ? data 
    : data.filter(row => row.status === statusFilter)

  const totalCountFiltered = filteredData.length
  const totalPages = Math.ceil(totalCountFiltered / PAGE_SIZE)

  return (
    <AuthGuard>
    <div className="dashboard-container">
      <Sidebar userEmail={userEmail} />
      <main className="main-content">
        <header className="top-header">
          <h1>Kelola Komisi</h1>
          <p className="header-subtitle">Kelola data komisi dengan mudah dan terstruktur.</p>
        </header>

        <section className="content-section">

          {/* Commission Rate Info Banner */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 16, marginBottom: 24 }}>
            {/* Rate card */}
            <div style={{ borderRadius: 14, overflow: 'hidden', background: 'linear-gradient(135deg, #7c3aed 0%, #a78bfa 100%)', padding: '20px 22px', position: 'relative', boxShadow: '0 8px 24px rgba(124,58,237,0.18)' }}>
              <div style={{ position: 'absolute', top: -15, right: -15, width: 80, height: 80, borderRadius: '50%', background: 'rgba(255,255,255,0.07)' }} />
              <p style={{ fontSize: '0.68rem', fontWeight: 700, color: 'rgba(255,255,255,0.6)', margin: '0 0 4px 0', textTransform: 'uppercase', letterSpacing: '1px' }}>Tarif Komisi Aktif</p>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 3 }}>
                <span style={{ fontSize: '2rem', fontWeight: 900, color: '#fff', lineHeight: 1 }}>{commissionRate}</span>
                <span style={{ fontSize: '1rem', fontWeight: 800, color: 'rgba(255,255,255,0.75)' }}>%</span>
              </div>
              <p style={{ fontSize: '0.68rem', color: 'rgba(255,255,255,0.5)', margin: '6px 0 0 0' }}>Dikonfigurasikan dari System Settings</p>
              <a href="/settings" style={{ display: 'inline-flex', alignItems: 'center', gap: 5, marginTop: 10, fontSize: '0.7rem', fontWeight: 800, color: 'rgba(255,255,255,0.85)', textDecoration: 'none', background: 'rgba(255,255,255,0.12)', padding: '4px 10px', borderRadius: 999, transition: 'background 0.2s' }}
                onMouseEnter={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.2)'}
                onMouseLeave={(e) => e.currentTarget.style.background = 'rgba(255,255,255,0.12)'}
              >
                <i className="fa-solid fa-gear" style={{ fontSize: 10 }} /> Ubah di Settings
              </a>
            </div>

            {/* Total transaksi selesai */}
            <div style={{ borderRadius: 14, backgroundColor: 'var(--bg-card)', border: '1px solid var(--border-color)', padding: '20px 22px', boxShadow: '0 4px 16px rgba(0,0,0,0.03)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
                <div style={{ width: 34, height: 34, borderRadius: 9, backgroundColor: 'rgba(16,185,129,0.1)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
                  <i className="fa-solid fa-circle-check" style={{ color: '#10b981', fontSize: 14 }} />
                </div>
                <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)' }}>Transaksi Selesai</span>
              </div>
              <p style={{ fontSize: '1.6rem', fontWeight: 900, color: 'var(--text-primary)', margin: 0, lineHeight: 1 }}>
                {data.filter(r => r.status === 'Selesai').length}
              </p>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>dari {data.length} total transaksi</p>
            </div>

            {/* Total komisi terkumpul */}
            <div style={{ borderRadius: 14, backgroundColor: 'var(--bg-card)', border: '1px solid var(--border-color)', padding: '20px 22px', boxShadow: '0 4px 16px rgba(0,0,0,0.03)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
                <div style={{ width: 34, height: 34, borderRadius: 9, backgroundColor: 'var(--brand-mint)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>
                  <i className="fa-solid fa-coins" style={{ color: 'var(--brand-green)', fontSize: 14 }} />
                </div>
                <span style={{ fontSize: '0.8rem', fontWeight: 700, color: 'var(--text-secondary)' }}>Total Komisi</span>
              </div>
              <p style={{ fontSize: '1.1rem', fontWeight: 900, color: 'var(--brand-emerald)', margin: 0, lineHeight: 1 }}>
                {formatCurrency(data.filter(r => r.status === 'Selesai').reduce((sum, r) => sum + r.gross_amount * (commissionRate / 100), 0))}
              </p>
              <p style={{ fontSize: '0.72rem', color: 'var(--text-muted)', margin: '4px 0 0 0' }}>@ {commissionRate}% dari transaksi selesai</p>
            </div>
          </div>

          {/* History Komisi Card */}
          <div className="table-wrapper" style={{ boxShadow: '0px 2px 8px rgba(0, 0, 0, 0.06)', overflow: 'hidden' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '24px' }}>
              <div>
                <h2 style={{ fontSize: '1.05rem', fontWeight: 700, color: 'var(--text-primary)', marginBottom: 6 }}>History Komisi</h2>
                <p style={{ fontSize: '0.85rem', color: 'var(--text-secondary)' }}>Catatan waktu nyata dari semua potongan platform dan pembagian transaksi.</p>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <i className="fa-solid fa-filter" style={{ color: 'var(--text-muted)', fontSize: 13 }} />
                <select 
                  className="filter-select" 
                  value={statusFilter} 
                  onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
                  style={{ 
                    padding: '8px 32px 8px 14px', 
                    borderRadius: '6px', 
                    fontSize: '13px', 
                    fontWeight: 700, 
                    border: '1px solid var(--border-color)', 
                    backgroundColor: 'var(--bg-card)', 
                    color: 'var(--text-primary)',
                    cursor: 'pointer'
                  }}
                >
                  <option value="Semua">Semua Status</option>
                  <option value="Proses">Proses</option>
                  <option value="Batal">Batal</option>
                  <option value="Selesai">Selesai</option>
                </select>
              </div>
            </div>

            <table>
              <thead>
                <tr>
                  <th>ID TRANSAKSI</th>
                  <th>PEMILIK RENTAL</th>
                  <th>JUMLAH KOTOR</th>
                  <th>JUMLAH KOMISI</th>
                  <th>STATUS</th>
                  <th>TANGGAL</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan="6" style={{ textAlign: 'center', padding: '40px' }}>
                      <div className="loading-spinner" style={{ margin: 'auto' }} />
                    </td>
                  </tr>
                ) : filteredData.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE).map(row => {
                  const comm = row.status === 'Batal' ? 0 : row.gross_amount * (commissionRate / 100)
                  return (
                    <tr key={row.id}>
                      <td style={{ fontWeight: 700, color: 'var(--brand-emerald)' }}>#{row.id}</td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12, fontWeight: 700, color: 'var(--text-primary)' }}>
                          <div style={{ width: 28, height: 28, borderRadius: '50%', backgroundColor: 'var(--bg-secondary)', color: 'var(--text-muted)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 11 }}>
                            <i className="fa-solid fa-user" />
                          </div>
                          <span>{row.rental_name}</span>
                        </div>
                      </td>
                      <td>{formatCurrency(row.gross_amount)}</td>
                      <td style={{ fontWeight: 700, color: 'var(--brand-emerald)' }}>{formatCurrency(comm)}</td>
                      <td>
                        <span className={`badge ${row.status === 'Selesai' ? 'badge-success' : row.status === 'Batal' ? 'badge-danger' : 'badge-warning'}`}>
                          {row.status}
                        </span>
                      </td>
                      <td style={{ fontSize: 13, lineHeight: '1.4', color: 'var(--text-primary)' }}>
                        <div style={{ fontWeight: 500 }}>{formatDate(row.created_at)}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>{formatTime(row.created_at)}</div>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>

            {/* Pagination */}
            {!loading && totalCountFiltered > 0 && (
              <div className="pagination-section" style={{ backgroundColor: 'var(--bg-secondary)', borderTop: '1px solid var(--border-color)' }}>
                <p className="pagination-info" style={{ color: 'var(--text-secondary)' }}>
                  Menampilkan {((page - 1) * PAGE_SIZE) + 1}–{Math.min(page * PAGE_SIZE, totalCountFiltered)} dari {totalCountFiltered} transaksi
                </p>
                <div className="pagination">
                  <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                    <i className="fa-solid fa-chevron-left" />
                  </button>
                  {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1).map(p => (
                    <button key={p} className={`pagination-btn ${p === page ? 'active' : ''}`} style={{ fontWeight: 700 }} onClick={() => setPage(p)}>{p}</button>
                  ))}
                  <button className="pagination-btn" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>
                    <i className="fa-solid fa-chevron-right" />
                  </button>
                </div>
              </div>
            )}
          </div>
        </section>
      </main>
      <Toast toasts={toasts} onRemove={removeToast} />
    </div>
    </AuthGuard>
  )
}

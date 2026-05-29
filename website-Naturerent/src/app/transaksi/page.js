'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

const STATUS_OPTIONS = [
  { value: 'Semua Status', label: 'Semua Status' },
  { value: 'pending', label: 'Menunggu Verifikasi' },
  { value: 'confirmed', label: 'ACC' },
  { value: 'processing', label: 'Diproses' },
  { value: 'rented', label: 'Aktif' },
  { value: 'returned', label: 'Dikembalikan' },
  { value: 'completed', label: 'Selesai' },
  { value: 'cancelled', label: 'Batal' },
]
const PAGE_SIZE = 8

function formatCurrency(amount) {
  if (amount === undefined || amount === null) return '-'
  return 'Rp ' + Number(amount).toLocaleString('id-ID')
}

function formatDateOnly(dateStr) {
  if (!dateStr) return '-'
  const d = new Date(dateStr)
  const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember']
  return `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`
}

function formatTimeOnly(dateStr) {
  if (!dateStr) return ''
  const d = new Date(dateStr)
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  return `${hours}:${minutes}`
}

function getStatusLabel(status) {
  const map = {
    pending: 'Menunggu Verifikasi',
    confirmed: 'ACC',
    processing: 'Diproses',
    rented: 'Aktif',
    returned: 'Dikembalikan',
    completed: 'Selesai',
    cancelled: 'Batal',
    Selesai: 'Selesai',
    Proses: 'Diproses',
    Bermasalah: 'Bermasalah',
  }
  return map[status] || status || '-'
}

export default function TransaksiPage() {
  const router = useRouter()
  const { toasts, addToast, removeToast } = useToast()
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('Semua Status')
  const [ownerFilter, setOwnerFilter] = useState('Semua Pemilik')
  const [ownerOptions, setOwnerOptions] = useState(['Semua Pemilik'])
  const [userEmail, setUserEmail] = useState('')
  const [commissionRate, setCommissionRate] = useState(12.5)
  const [page, setPage] = useState(1)
  const [totalCount, setTotalCount] = useState(0)

  const fetchData = useCallback(async (q = '', status = 'Semua Status', owner = 'Semua Pemilik', currentPage = 1) => {
    setLoading(true)
    const supabase = createClient()
    const from = (currentPage - 1) * PAGE_SIZE
    const to = from + PAGE_SIZE - 1

    try {
      let query
      if (owner !== 'Semua Pemilik') {
        query = supabase
          .from('bookings')
          .select('*, rental_profiles!inner(nama_rental)', { count: 'exact' })
          .eq('rental_profiles.nama_rental', owner)
      } else {
        query = supabase
          .from('bookings')
          .select('*, rental_profiles(nama_rental)', { count: 'exact' })
      }

      query = query.order('created_at', { ascending: false }).range(from, to)

      if (status !== 'Semua Status') {
        query = query.eq('status', status)
      }
      if (q) {
        query = query.or(`id.ilike.%${q}%,booking_code.ilike.%${q}%`)
      }

      let { data: rows, error, count } = await query
      
      if (error) {
        addToast('Gagal memuat data transaksi: ' + error.message, 'error')
        setData([])
        setTotalCount(0)
      } else {
        const userIds = [...new Set(rows.map(r => r.customer_id).filter(Boolean))]
        const userMap = {}
        if (userIds.length > 0) {
          const { data: users } = await supabase
            .from('users')
            .select('id, nama_lengkap')
            .in('id', userIds)
          if (users) {
            users.forEach(u => {
              userMap[u.id] = u.nama_lengkap
            })
          }
        }

        const resolvedRows = rows.map(r => ({
          ...r,
          user_name: userMap[r.customer_id] || 'Pengguna',
          rental_name: r.rental_profiles?.nama_rental || r.rental_name || '-',
          total_amount: r.total_bayar || r.subtotal || r.total || r.total_amount || 0
        }))

        setData(resolvedRows)
        setTotalCount(count || resolvedRows.length)
      }
    } catch (e) {
      addToast('Gagal memuat data transaksi: ' + e.message, 'error')
    }
    setLoading(false)
  }, [addToast])

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

      // Dynamically load all owners from DB and merge with mock rentals
      try {
        const { data: rentals } = await supabase.from('rental_profiles').select('nama_rental')
        const dbRentals = rentals ? rentals.map(r => r.nama_rental).filter(Boolean) : []
        const uniqueRentals = [...new Set(['Semua Pemilik', ...dbRentals])]
        setOwnerOptions(uniqueRentals)
      } catch (e) {
        console.error('Error fetching dynamic rental owners:', e)
      }
    }
    init()
  }, [])

  useEffect(() => {
    const timer = setTimeout(() => {
      fetchData(search, statusFilter, ownerFilter, page)
    }, 0)
    return () => clearTimeout(timer)
  }, [fetchData, ownerFilter, page, search, statusFilter])

  const handleSearch = (e) => {
    e.preventDefault()
    setPage(1)
    fetchData(search, statusFilter, ownerFilter, 1)
  }

  const handleDownloadInvoice = (trxId) => {
    window.open(`/transaksi/${trxId}/invoice`, '_blank', 'noopener,noreferrer')
  }

  const totalPages = Math.ceil(totalCount / PAGE_SIZE)

  const statusBadge = (status) => {
    const map = { 
      'pending': 'badge-warning',
      'confirmed': 'badge-success',
      'processing': 'badge-warning',
      'rented': 'badge-blue',
      'returned': 'badge-blue',
      'completed': 'badge-success',
      'cancelled': 'badge-danger',
      'Selesai': 'badge-success', 
      'Proses': 'badge-warning', 
      'Bermasalah': 'badge-danger',
      'Ditolak': 'badge-danger' 
    }
    return <span className={`badge ${map[status] || 'badge-blue'}`}>{getStatusLabel(status)}</span>
  }

  return (
    <AuthGuard>
    <div className="dashboard-container">
      <Sidebar userEmail={userEmail} />
      <main className="main-content">
        <header className="top-header">
          <h1>Transaksi</h1>
          <p className="header-subtitle">Kelola dan monitor semua transaksi penyewaan alat camping.</p>
        </header>

        <section className="content-section">
          {/* Filter Bar Figma */}
          <form className="filter-bar" onSubmit={handleSearch}>
            <div className="search-box">
              <i className="fa-solid fa-magnifying-glass search-icon" />
              <input
                type="text"
                placeholder="Cari ID Transaksi, user, atau rental..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
            <div className="filter-controls">
              <select 
                className="filter-select" 
                value={statusFilter} 
                onChange={e => { 
                  setStatusFilter(e.target.value); 
                  setPage(1); 
                  fetchData(search, e.target.value, ownerFilter, 1) 
                }}
              >
                {STATUS_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
              <select 
                className="filter-select"
                value={ownerFilter}
                onChange={e => {
                  setOwnerFilter(e.target.value);
                  setPage(1);
                  fetchData(search, statusFilter, e.target.value, 1);
                }}
              >
                {ownerOptions.map(o => <option key={o}>{o}</option>)}
              </select>
              <button type="submit" className="filter-btn">
                <i className="fa-solid fa-filter" /> Filter
              </button>
            </div>
          </form>

          {/* Table wrapper */}
          <div className="table-wrapper">
            {loading ? (
              <div className="loading-state">
                <div className="loading-spinner" />
                <span>Memuat data transaksi...</span>
              </div>
            ) : data.length === 0 ? (
              <div className="empty-state">
                <i className="fa-solid fa-receipt empty-icon" />
                <p>Tidak ada transaksi ditemukan.</p>
              </div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>ID TRANSAKSI</th>
                    <th>TANGGAL</th>
                    <th>USER</th>
                    <th>PEMILIK RENTAL</th>
                    <th>TOTAL</th>
                    <th>KOMISI</th>
                    <th>STATUS</th>
                    <th>AKSI</th>
                  </tr>
                </thead>
                <tbody>
                  {data.map(row => (
                    <tr key={row.id}>
                      <td className="transaction-id" style={{ fontWeight: 600, color: 'var(--brand-emerald)' }}>{row.booking_code || row.id}</td>
                      <td style={{ fontSize: 13, lineHeight: '1.4' }}>
                        <div style={{ color: 'var(--text-primary)', fontWeight: 500 }}>{formatDateOnly(row.created_at || row.transaction_date)}</div>
                        <div style={{ color: 'var(--text-muted)', fontSize: 11 }}>{formatTimeOnly(row.created_at || row.transaction_date)}</div>
                      </td>
                      <td style={{ fontWeight: 600 }}>{row.user_name || '-'}</td>
                      <td style={{ color: 'var(--text-secondary)' }}>{row.rental_name || '-'}</td>
                      <td style={{ fontWeight: 600 }}>{formatCurrency(row.total_amount || row.total)}</td>
                      <td style={{ fontWeight: 600, color: 'var(--brand-emerald)' }}>{formatCurrency((row.total_amount || row.total) * (commissionRate / 100))}</td>
                      <td>{statusBadge(row.status)}</td>
                      <td>
                        <div className="action-cell">
                          <button 
                            className="action-btn view-btn" 
                            title="Lihat Detail" 
                            onClick={() => router.push(`/transaksi/${row.id}`)}
                          >
                            <i className="fa-solid fa-eye" />
                          </button>
                          <button 
                            className="action-btn download-btn" 
                            title="Unduh Invoice"
                            onClick={() => handleDownloadInvoice(row.id)}
                          >
                            <i className="fa-solid fa-file-invoice" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}

            {/* Pagination */}
            {!loading && totalCount > 0 && (
              <div className="pagination-section">
                <p className="pagination-info">
                  Menampilkan {((page - 1) * PAGE_SIZE) + 1}–{Math.min(page * PAGE_SIZE, totalCount)} dari {totalCount} data
                </p>
                <div className="pagination">
                  <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                    <i className="fa-solid fa-chevron-left" />
                  </button>
                  {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1).map(p => (
                    <button key={p} className={`pagination-btn ${p === page ? 'active' : ''}`} onClick={() => setPage(p)}>{p}</button>
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

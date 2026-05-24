'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import ConfirmModal from '@/components/ConfirmModal'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

function getInitials(name) {
  if (!name) return '?'
  return name.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase()
}

const colorClasses = ['gv', 'tp', 'mb', 'oc']

export default function PemilikRentalPage() {
  const router = useRouter()
  const { toasts, addToast, removeToast } = useToast()
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleteLoading, setDeleteLoading] = useState(false)
  const [page, setPage] = useState(1)
  const [totalCount, setTotalCount] = useState(0)
  const PAGE_SIZE = 10

  const fetchData = useCallback(async (searchTerm = '', currentPage = 1) => {
    setLoading(true)
    const supabase = createClient()
    const from = (currentPage - 1) * PAGE_SIZE
    const to = from + PAGE_SIZE - 1

    try {
      let query = supabase
        .from('rental_profiles')
        .select('*, users:owner_id(nama_lengkap, email, no_wa)', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range(from, to)

      if (searchTerm) {
        query = query.or(`nama_rental.ilike.%${searchTerm}%,alamat.ilike.%${searchTerm}%`)
      }

      const { data: rows, error, count } = await query
      if (error) {
        // Fallback if join relation syntax differs
        let simpleQuery = supabase
          .from('rental_profiles')
          .select('*', { count: 'exact' })
          .order('created_at', { ascending: false })
          .range(from, to)
        if (searchTerm) {
          simpleQuery = simpleQuery.or(`nama_rental.ilike.%${searchTerm}%,alamat.ilike.%${searchTerm}%`)
        }
        const { data: simpleRows, error: simpleError, count: simpleCount } = await simpleQuery
        if (simpleError) {
          addToast('Gagal memuat data: ' + simpleError.message, 'error')
        } else {
          setData(simpleRows || [])
          setTotalCount(simpleCount || 0)
        }
      } else {
        setData(rows || [])
        setTotalCount(count || 0)
      }
    } catch (e) {
      addToast('Gagal memuat data: ' + e.message, 'error')
    }
    setLoading(false)
  }, [])

  useEffect(() => {
    const init = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      setUserEmail(user?.email || '')
    }
    init()
    fetchData(search, page)
  }, [page])

  const handleSearch = (e) => {
    e.preventDefault()
    setPage(1)
    fetchData(search, 1)
  }

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return
    setDeleteLoading(true)
    const supabase = createClient()
    const { error } = await supabase.from('rental_profiles').delete().eq('id', deleteTarget.id)
    setDeleteLoading(false)
    const targetName = deleteTarget.nama_rental || deleteTarget.rental_name || 'Mitra'
    setDeleteTarget(null)
    if (error) {
      addToast('Gagal menghapus data: ' + error.message, 'error')
    } else {
      addToast(`Pemilik rental "${targetName}" berhasil dihapus.`, 'success')
      fetchData(search, page)
    }
  }

  const totalPages = Math.ceil(totalCount / PAGE_SIZE)

  return (
    <AuthGuard>
    <div className="dashboard-container">
      <Sidebar userEmail={userEmail} />
      <main className="main-content">
        <header className="top-header">
          <h1>Kelola Pemilik Rental</h1>
          <p className="header-subtitle">Kelola data pemilik rental dengan mudah dan terstruktur.</p>
        </header>

        <section className="content-section">
          <form className="filter-bar" onSubmit={handleSearch}>
            <div className="search-box">
              <i className="fa-solid fa-magnifying-glass search-icon" />
              <input
                type="text"
                placeholder="Cari nama rental, pemilik, atau lokasi..."
                value={search}
                onChange={e => setSearch(e.target.value)}
              />
            </div>
            <div className="filter-controls">
              <button type="submit" className="filter-btn">
                <i className="fa-solid fa-magnifying-glass" /> Cari
              </button>
            </div>
          </form>

          <div className="table-wrapper">
            {loading ? (
              <div className="loading-state">
                <div className="loading-spinner" />
                <span>Memuat data pemilik rental...</span>
              </div>
            ) : data.length === 0 ? (
              <div className="empty-state">
                <i className="fa-solid fa-person empty-icon" />
                <p>Tidak ada data pemilik rental ditemukan.</p>
              </div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>NAMA RENTAL</th>
                    <th>NAMA PEMILIK</th>
                    <th>LOKASI</th>
                    <th>PRODUK</th>
                    <th>STATUS</th>
                    <th>AKSI</th>
                  </tr>
                </thead>
                <tbody>
                   {data.map((row, idx) => {
                     const rName = row.nama_rental || row.rental_name || '-'
                     const oName = row.users?.nama_lengkap || row.owner_name || '-'
                     const loc = row.alamat || row.location || '-'
                     return (
                       <tr key={row.id}>
                         <td>
                           <div className="rental-name">
                             <div className={`rental-logo ${colorClasses[idx % colorClasses.length]}`}>
                               {getInitials(rName)}
                             </div>
                             <span style={{ fontWeight: 600 }}>{rName}</span>
                           </div>
                         </td>
                         <td>{oName}</td>
                         <td>
                           <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                             <i className="fa-solid fa-location-dot" style={{ color: 'var(--accent-red)', fontSize: 12 }} />
                             {loc}
                           </span>
                         </td>
                         <td style={{ color: 'var(--text-secondary)' }}>{row.product_count ?? 0} Items</td>
                         <td>
                           <span className={`badge ${row.is_active !== false ? 'badge-success' : 'badge-danger'}`}>
                             {row.is_active !== false ? 'Aktif' : 'Nonaktif'}
                           </span>
                         </td>
                      <td>
                        <div className="action-cell">
                          <button
                            className="action-btn edit-btn"
                            title="Edit"
                            onClick={() => router.push(`/pemilik-rental/${row.id}/edit`)}
                          >
                            <i className="fa-solid fa-pen" />
                          </button>
                          <button
                            className="action-btn delete-btn"
                            title="Hapus"
                            onClick={() => setDeleteTarget(row)}
                          >
                            <i className="fa-solid fa-trash" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  )})}
                </tbody>
              </table>
            )}

            {!loading && totalCount > 0 && (
              <div className="pagination-section">
                <p className="pagination-info">
                  Menampilkan {((page - 1) * PAGE_SIZE) + 1}–{Math.min(page * PAGE_SIZE, totalCount)} dari {totalCount} pemilik rental
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

      <ConfirmModal
        isOpen={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={handleDeleteConfirm}
        isLoading={deleteLoading}
        title="Hapus Pemilik Rental"
        description={`Apakah Anda yakin ingin menghapus "${deleteTarget?.nama_rental || deleteTarget?.rental_name}"? Semua data terkait akan ikut terhapus.`}
        confirmLabel="Hapus Pemilik Rental"
      />
      <Toast toasts={toasts} onRemove={removeToast} />
    </div>
    </AuthGuard>
  )
}

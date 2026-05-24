'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Sidebar from '@/components/Sidebar'
import ConfirmModal from '@/components/ConfirmModal'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

export default function PenggunaPage() {
  const router = useRouter()
  const { toasts, addToast, removeToast } = useToast()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleteLoading, setDeleteLoading] = useState(false)
  const [page, setPage] = useState(1)
  const [totalCount, setTotalCount] = useState(0)
  const PAGE_SIZE = 10

  const fetchUsers = useCallback(async (searchTerm = '', currentPage = 1) => {
    setLoading(true)
    const supabase = createClient()
    const from = (currentPage - 1) * PAGE_SIZE
    const to = from + PAGE_SIZE - 1

    let query = supabase
      .from('users')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to)

    if (searchTerm) {
      query = query.or(`nama_lengkap.ilike.%${searchTerm}%,no_wa.ilike.%${searchTerm}%`)
    }

    const { data, error, count } = await query
    if (error) {
      addToast('Gagal memuat data pengguna: ' + error.message, 'error')
    } else {
      setUsers(data || [])
      setTotalCount(count || 0)
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
    fetchUsers(search, page)
  }, [page])

  const handleSearch = (e) => {
    e.preventDefault()
    setPage(1)
    fetchUsers(search, 1)
  }

  const handleDeleteClick = (user) => {
    setDeleteTarget(user)
  }

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return
    setDeleteLoading(true)
    const supabase = createClient()
    const { error } = await supabase.from('users').delete().eq('id', deleteTarget.id)
    setDeleteLoading(false)
    setDeleteTarget(null)
    if (error) {
      addToast('Gagal menghapus data: ' + error.message, 'error')
    } else {
      addToast(`Data pengguna ${deleteTarget.name || deleteTarget.email} berhasil dihapus.`, 'success')
      fetchUsers(search, page)
    }
  }

  const totalPages = Math.ceil(totalCount / PAGE_SIZE)

  return (
    <AuthGuard>
    <div className="dashboard-container">
      <Sidebar userEmail={userEmail} />
      <main className="main-content">
        <header className="top-header">
          <h1>Kelola Data Pengguna</h1>
          <p className="header-subtitle">Lihat, edit, dan hapus data pengguna terdaftar.</p>
        </header>

        <section className="content-section">
          {/* Filter Bar */}
          <form className="filter-bar" onSubmit={handleSearch}>
            <div className="search-box">
              <i className="fa-solid fa-magnifying-glass search-icon" />
              <input
                type="text"
                placeholder="Cari nama atau email pengguna..."
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

          {/* Table */}
          <div className="table-wrapper">
            {loading ? (
              <div className="loading-state">
                <div className="loading-spinner" />
                <span>Memuat data pengguna...</span>
              </div>
            ) : users.length === 0 ? (
              <div className="empty-state">
                <i className="fa-solid fa-users empty-icon" />
                <p>Tidak ada data pengguna ditemukan.</p>
              </div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>NAMA</th>
                    <th>EMAIL</th>
                    <th>NOMOR HP</th>
                    <th>STATUS</th>
                    <th>BERGABUNG</th>
                    <th>AKSI</th>
                  </tr>
                </thead>
                <tbody>
                  {users.map(user => (
                    <tr key={user.id}>
                      <td style={{ fontWeight: 600 }}>{user.nama_lengkap || user.name || '-'}</td>
                      <td style={{ color: 'var(--text-secondary)' }}>{user.email || 'customer@naturerent.com'}</td>
                      <td>{user.no_wa || user.phone || '-'}</td>
                      <td>
                        <span className={`badge ${user.is_active !== false ? 'badge-success' : 'badge-danger'}`}>
                          {user.is_active !== false ? 'Aktif' : 'Nonaktif'}
                        </span>
                      </td>
                      <td style={{ color: 'var(--text-secondary)', fontSize: 13 }}>
                        {user.created_at ? new Date(user.created_at).toLocaleDateString('id-ID') : '-'}
                      </td>
                      <td>
                        <div className="action-cell">
                          <button
                            className="action-btn edit-btn"
                            title="Edit"
                            onClick={() => router.push(`/pengguna/${user.id}/edit`)}
                          >
                            <i className="fa-solid fa-pen" />
                          </button>
                          <button
                            className="action-btn delete-btn"
                            title="Hapus"
                            onClick={() => handleDeleteClick(user)}
                          >
                            <i className="fa-solid fa-trash" />
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
                  Menampilkan {((page - 1) * PAGE_SIZE) + 1}–{Math.min(page * PAGE_SIZE, totalCount)} dari {totalCount} pengguna
                </p>
                <div className="pagination">
                  <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                    <i className="fa-solid fa-chevron-left" />
                  </button>
                  {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1).map(p => (
                    <button key={p} className={`pagination-btn ${p === page ? 'active' : ''}`} onClick={() => setPage(p)}>
                      {p}
                    </button>
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
        title="Hapus Data Pengguna"
        description={`Apakah Anda yakin ingin menghapus pengguna "${deleteTarget?.name || deleteTarget?.email}"? Tindakan ini tidak dapat dibatalkan.`}
        confirmLabel="Hapus Pengguna"
      />

      <Toast toasts={toasts} onRemove={removeToast} />
    </div>
    </AuthGuard>
  )
}

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

const avatarColors = ['#1f5a3f', '#0d8c75', '#1e3a8a', '#7c3aed', '#b45309']

const roleBadge = (role) => {
  const labelMap = {
    admin: 'Admin',
    rental_owner: 'Pemilik Rental',
    customer: 'Penyewa',
  }
  const styleMap = {
    admin: {
      backgroundColor: 'rgba(124, 58, 237, 0.12)',
      color: '#7c3aed',
      border: '1px solid rgba(124, 58, 237, 0.25)',
      padding: '4px 10px',
      borderRadius: '999px',
      fontSize: '11px',
      fontWeight: '700',
      display: 'inline-flex',
      alignItems: 'center',
      gap: '5px'
    },
    rental_owner: {
      backgroundColor: 'rgba(16, 185, 129, 0.12)',
      color: 'var(--brand-green)',
      border: '1px solid rgba(16, 185, 129, 0.25)',
      padding: '4px 10px',
      borderRadius: '999px',
      fontSize: '11px',
      fontWeight: '700',
      display: 'inline-flex',
      alignItems: 'center',
      gap: '5px'
    },
    customer: {
      backgroundColor: 'rgba(59, 130, 246, 0.12)',
      color: '#3b82f6',
      border: '1px solid rgba(59, 130, 246, 0.25)',
      padding: '4px 10px',
      borderRadius: '999px',
      fontSize: '11px',
      fontWeight: '700',
      display: 'inline-flex',
      alignItems: 'center',
      gap: '5px'
    }
  }

  const defaultStyle = {
    backgroundColor: 'var(--bg-secondary)',
    color: 'var(--text-secondary)',
    border: '1px solid var(--border-color)',
    padding: '4px 10px',
    borderRadius: '999px',
    fontSize: '11px',
    fontWeight: '700',
    display: 'inline-flex',
    alignItems: 'center',
    gap: '5px'
  }

  const iconMap = {
    admin: <i className="fa-solid fa-user-shield" style={{ fontSize: '10px' }} />,
    rental_owner: <i className="fa-solid fa-store" style={{ fontSize: '10px' }} />,
    customer: <i className="fa-solid fa-user" style={{ fontSize: '10px' }} />
  }

  const cleanRole = role || 'customer'
  return (
    <span style={styleMap[cleanRole] || defaultStyle}>
      {iconMap[cleanRole]} {labelMap[cleanRole] || cleanRole}
    </span>
  )
}

function KtpModal({ user, onClose }) {
  if (!user) return null
  const name = user.nama_lengkap || user.name || '-'

  return (
    <div
      className="modal-overlay"
      onClick={onClose}
      style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.75)', zIndex: 300, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}
    >
      <div
        className="modal-box"
        onClick={e => e.stopPropagation()}
        style={{ background: 'var(--bg-card)', borderRadius: 20, padding: 28, width: '100%', maxWidth: 600, border: '1px solid var(--border-color)', boxShadow: '0 24px 80px rgba(0,0,0,0.4)', display: 'flex', flexDirection: 'column', gap: 20 }}
      >
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 38, height: 38, borderRadius: 10, background: 'linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <i className="fa-solid fa-id-card" style={{ color: '#fff', fontSize: 16 }} />
            </div>
            <div>
              <h2 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: 'var(--text-primary)' }}>Foto KTP Pengguna</h2>
              <p style={{ margin: 0, fontSize: 12, color: 'var(--text-secondary)' }}>{name}</p>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{ background: 'var(--bg-secondary)', border: '1px solid var(--border-color)', color: 'var(--text-secondary)', cursor: 'pointer', fontSize: 16, padding: '6px 10px', borderRadius: 8, lineHeight: 1 }}
          >
            <i className="fa-solid fa-xmark" />
          </button>
        </div>

        {/* KTP Image Viewer */}
        {user.ktp_url ? (
          <div style={{ borderRadius: 14, overflow: 'hidden', border: '2px solid var(--border-color)', background: '#000', display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 220, maxHeight: '60vh' }}>
            <img
              src={user.ktp_url}
              alt={`KTP ${name}`}
              style={{ width: '100%', maxHeight: '60vh', objectFit: 'contain', display: 'block' }}
              onError={e => { e.target.style.display = 'none'; e.target.nextSibling.style.display = 'flex' }}
            />
            <div style={{ display: 'none', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 10, padding: 40, color: 'var(--text-muted)' }}>
              <i className="fa-solid fa-image-slash" style={{ fontSize: 36 }} />
              <span style={{ fontSize: 13 }}>Gambar KTP tidak dapat dimuat</span>
            </div>
          </div>
        ) : (
          <div style={{ borderRadius: 14, border: '2px dashed var(--border-color)', background: 'var(--bg-secondary)', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 12, padding: 48 }}>
            <div style={{ width: 56, height: 56, borderRadius: '50%', background: 'rgba(59,130,246,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <i className="fa-solid fa-id-card" style={{ fontSize: 24, color: '#3b82f6' }} />
            </div>
            <p style={{ margin: 0, fontWeight: 700, color: 'var(--text-primary)', fontSize: 14 }}>KTP Belum Diunggah</p>
            <p style={{ margin: 0, fontSize: 12, color: 'var(--text-muted)', textAlign: 'center' }}>
              Pengguna ini belum mengunggah foto KTP mereka.
            </p>
          </div>
        )}

        {/* Info Row */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 14px', borderRadius: 10, background: 'rgba(59,130,246,0.06)', border: '1px solid rgba(59,130,246,0.15)' }}>
          <i className="fa-solid fa-shield-halved" style={{ color: '#3b82f6', fontSize: 13 }} />
          <span style={{ fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
            Data KTP bersifat rahasia dan hanya dapat dilihat oleh admin. Jangan bagikan informasi ini kepada pihak luar.
          </span>
        </div>

        {/* Footer */}
        <div style={{ display: 'flex', gap: 10 }}>
          <button className="btn btn-ghost" onClick={onClose} style={{ flex: 1 }}>Tutup</button>
          {user.ktp_url && (
            <a
              href={user.ktp_url}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-primary"
              style={{ flex: 1, textDecoration: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
            >
              <i className="fa-solid fa-arrow-up-right-from-square" /> Buka di Tab Baru
            </a>
          )}
        </div>
      </div>
    </div>
  )
}

function DetailModal({ user, onClose }) {
  if (!user) return null
  const name = user.nama_lengkap || user.name || '-'
  const colorIdx = name.charCodeAt(0) % avatarColors.length

  return (
    <div className="modal-overlay" onClick={onClose} style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.55)', zIndex: 200, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div className="modal-box" onClick={e => e.stopPropagation()} style={{ background: 'var(--bg-card)', borderRadius: 16, padding: 32, width: '100%', maxWidth: 480, border: '1px solid var(--border-color)', boxShadow: '0 20px 60px rgba(0,0,0,0.3)' }}>
        {/* Header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 24 }}>
          <div style={{ width: 56, height: 56, borderRadius: '50%', background: avatarColors[colorIdx], display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 700, fontSize: 20, flexShrink: 0 }}>
            {getInitials(name)}
          </div>
          <div>
            <h2 style={{ margin: 0, fontSize: 18, fontWeight: 700, color: 'var(--text-primary)' }}>{name}</h2>
            <p style={{ margin: 0, fontSize: 13, color: 'var(--text-secondary)' }}>{user.email || '-'}</p>
          </div>
          <button onClick={onClose} style={{ marginLeft: 'auto', background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', fontSize: 20, padding: 4 }}>
            <i className="fa-solid fa-xmark" />
          </button>
        </div>

        {/* Status badge */}
        <div style={{ marginBottom: 20 }}>
          <span className={`badge ${user.is_active !== false ? 'badge-success' : 'badge-danger'}`}>
            <i className={`fa-solid ${user.is_active !== false ? 'fa-circle-check' : 'fa-circle-xmark'}`} style={{ marginRight: 5 }} />
            {user.is_active !== false ? 'Akun Aktif' : 'Akun Nonaktif'}
          </span>
        </div>

        {/* Detail rows */}
        {[
          { icon: 'fa-phone', label: 'Nomor HP', value: user.no_wa || user.phone || '-' },
          { icon: 'fa-user-tag', label: 'Peran (Role)', value: user.role === 'admin' ? 'Admin' : user.role === 'rental_owner' ? 'Pemilik Rental' : 'Penyewa' },
          { icon: 'fa-calendar', label: 'Bergabung', value: user.created_at ? new Date(user.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) : '-' },
          { icon: 'fa-id-card', label: 'ID Pengguna', value: user.id },
        ].map(row => (
          <div key={row.label} style={{ display: 'flex', gap: 12, padding: '10px 0', borderBottom: '1px solid var(--border-color-light)' }}>
            <div style={{ width: 32, display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'var(--brand-emerald)', flexShrink: 0 }}>
              <i className={`fa-solid ${row.icon}`} style={{ fontSize: 14 }} />
            </div>
            <div>
              <p style={{ margin: 0, fontSize: 11, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: 2 }}>{row.label}</p>
              <p style={{ margin: 0, fontSize: 13, color: 'var(--text-primary)', fontWeight: 500, wordBreak: 'break-all' }}>{row.value}</p>
            </div>
          </div>
        ))}

        <div style={{ display: 'flex', gap: 10, marginTop: 24 }}>
          <button className="btn btn-ghost" onClick={onClose} style={{ flex: 1 }}>Tutup</button>
        </div>
      </div>
    </div>
  )
}


export default function PenggunaPage() {
  const router = useRouter()
  const { toasts, addToast, removeToast } = useToast()
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [userEmail, setUserEmail] = useState('')
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleteLoading, setDeleteLoading] = useState(false)
  const [detailTarget, setDetailTarget] = useState(null)
  const [ktpTarget, setKtpTarget] = useState(null)
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
      query = query.or(`nama_lengkap.ilike.%${searchTerm}%,email.ilike.%${searchTerm}%,no_wa.ilike.%${searchTerm}%`)
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

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return
    setDeleteLoading(true)
    const targetName = deleteTarget.nama_lengkap || deleteTarget.email || 'Pengguna'
    try {
      const res = await fetch(`/api/users/${deleteTarget.id}`, { method: 'DELETE' })
      const json = await res.json()
      if (!res.ok) {
        addToast('Gagal menghapus: ' + (json.error || 'Unknown error'), 'error')
      } else {
        addToast(`Pengguna "${targetName}" berhasil dihapus.`, 'success')
        fetchUsers(search, page)
      }
    } catch (e) {
      addToast('Gagal menghapus: ' + e.message, 'error')
    }
    setDeleteLoading(false)
    setDeleteTarget(null)
  }

  const totalPages = Math.ceil(totalCount / PAGE_SIZE)
  const avatarColors2 = ['#1f5a3f', '#0d8c75', '#1e3a8a', '#7c3aed', '#b45309']

  return (
    <AuthGuard>
      <div className="dashboard-container">
        <Sidebar userEmail={userEmail} />
        <main className="main-content">
          <header className="top-header">
            <h1>Kelola Pengguna</h1>
            <p className="header-subtitle">Lihat, edit, dan kelola data pengguna terdaftar di aplikasi NatureRent.</p>
          </header>

          <section className="content-section">
            {/* Filter Bar */}
            <form className="filter-bar" onSubmit={handleSearch}>
              <div className="search-box">
                <i className="fa-solid fa-magnifying-glass search-icon" />
                <input
                  type="text"
                  placeholder="Cari nama, email, atau nomor HP..."
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
                      <th>ROLE</th>
                      <th>BERGABUNG</th>
                      <th>AKSI</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users.map((user, idx) => {
                      const name = user.nama_lengkap || user.name || '-'
                      const colorIdx = (name.charCodeAt(0) || 0) % avatarColors2.length
                      return (
                        <tr key={user.id}>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                              <div style={{ width: 34, height: 34, borderRadius: '50%', background: avatarColors2[colorIdx], display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontWeight: 700, fontSize: 13, flexShrink: 0 }}>
                                {getInitials(name)}
                              </div>
                              <span style={{ fontWeight: 600 }}>{name}</span>
                            </div>
                          </td>
                          <td style={{ color: 'var(--text-secondary)' }}>{user.email || '-'}</td>
                          <td>{user.no_wa || user.phone || '-'}</td>
                          <td>{roleBadge(user.role)}</td>
                          <td style={{ color: 'var(--text-secondary)', fontSize: 13 }}>
                            {user.created_at ? new Date(user.created_at).toLocaleDateString('id-ID') : '-'}
                          </td>
                          <td>
                            <div className="action-cell">
                              <button
                                className="action-btn"
                                title="Lihat Detail"
                                onClick={() => setDetailTarget(user)}
                                style={{ color: 'var(--brand-emerald)' }}
                              >
                                <i className="fa-solid fa-eye" />
                              </button>
                              <button
                                className="action-btn"
                                title="Lihat KTP"
                                onClick={() => setKtpTarget(user)}
                                style={{ color: '#3b82f6' }}
                              >
                                <i className="fa-solid fa-id-card" />
                              </button>
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
                                onClick={() => setDeleteTarget(user)}
                              >
                                <i className="fa-solid fa-trash" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      )
                    })}
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

        {/* Detail Modal */}
        {detailTarget && (
          <DetailModal user={detailTarget} onClose={() => setDetailTarget(null)} />
        )}

        {/* KTP Modal */}
        {ktpTarget && (
          <KtpModal user={ktpTarget} onClose={() => setKtpTarget(null)} />
        )}

        <ConfirmModal
          isOpen={!!deleteTarget}
          onClose={() => setDeleteTarget(null)}
          onConfirm={handleDeleteConfirm}
          isLoading={deleteLoading}
          title="Hapus Data Pengguna"
          description={`Apakah Anda yakin ingin menghapus pengguna "${deleteTarget?.nama_lengkap || deleteTarget?.email}"? Tindakan ini tidak dapat dibatalkan.`}
          confirmLabel="Hapus Pengguna"
        />

        <Toast toasts={toasts} onRemove={removeToast} />
      </div>
    </AuthGuard>
  )
}

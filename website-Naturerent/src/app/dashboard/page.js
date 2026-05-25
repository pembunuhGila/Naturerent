'use client'
import { useState, useEffect, useCallback } from 'react'
import Sidebar from '@/components/Sidebar'
import Link from 'next/link'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

function timeAgo(dateStr) {
  if (!dateStr) return ''
  const diff = Date.now() - new Date(dateStr).getTime()
  const minutes = Math.floor(diff / 60000)
  if (minutes < 1) return 'Baru saja'
  if (minutes < 60) return `${minutes} menit yang lalu`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours} jam yang lalu`
  const days = Math.floor(hours / 24)
  if (days < 30) return `${days} hari yang lalu`
  return new Date(dateStr).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })
}

export default function DashboardPage() {
  const [userEmail, setUserEmail] = useState('')
  const [stats, setStats] = useState({ totalTransaksi: 0, totalPemilik: 0 })
  const [recentActivity, setRecentActivity] = useState([])
  const [loading, setLoading] = useState(true)
  const [, setTick] = useState(0)

  // Re-render every 60s so timeAgo text stays current without full refetch
  useEffect(() => {
    const timer = setInterval(() => setTick(t => t + 1), 60000)
    return () => clearInterval(timer)
  }, [])

  const fetchData = useCallback(async () => {
    const supabase = createClient()
    const { data: { user } } = await supabase.auth.getUser()
    setUserEmail(user?.email || '')

    try {
      const [bookingsRes, pemilikRes, bookRes, rentalRes] = await Promise.all([
        supabase.from('bookings').select('id', { count: 'exact', head: true }),
        supabase.from('rental_profiles').select('id', { count: 'exact', head: true }),
        supabase.from('bookings').select('id, created_at, status, customer_id').order('created_at', { ascending: false }).limit(3),
        supabase.from('rental_profiles').select('id, created_at, nama_rental').order('created_at', { ascending: false }).limit(2),
      ])

      setStats({
        totalTransaksi: bookingsRes.count ?? 0,
        totalPemilik: pemilikRes.count ?? 0,
      })

      const activities = []

      if (bookRes.data && bookRes.data.length > 0) {
        const userIds = [...new Set(bookRes.data.map(d => d.customer_id).filter(Boolean))]
        const userMap = {}
        if (userIds.length > 0) {
          const { data: users } = await supabase.from('users').select('id, nama_lengkap').in('id', userIds)
          if (users) users.forEach(u => { userMap[u.id] = u.nama_lengkap })
        }
        bookRes.data.forEach(row => {
          activities.push({
            id: row.id,
            created_at: row.created_at,
            icon: 'transaction',
            fa: 'fa-receipt',
            title: 'Transaksi Baru',
            desc: `${row.id} dari ${userMap[row.customer_id] || 'Pengguna'}`,
          })
        })
      }

      if (rentalRes.data && rentalRes.data.length > 0) {
        rentalRes.data.forEach(row => {
          activities.push({
            id: `rp-${row.id}`,
            created_at: row.created_at,
            icon: 'rental',
            fa: 'fa-person-circle-plus',
            title: 'Pemilik Rental Baru',
            desc: `${row.nama_rental || 'Mitra'} ditambahkan`,
          })
        })
      }

      activities.sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      setRecentActivity(activities.slice(0, 4))
    } catch (e) {
      console.error('DashboardPage fetchData error:', e)
    }
    setLoading(false)
  }, [])

  useEffect(() => { fetchData() }, [fetchData])

  return (
    <AuthGuard>
      <div className="dashboard-container">
        <Sidebar userEmail={userEmail} />
        <main className="main-content">
          <header className="top-header">
            <h1>Dashboard</h1>
            <p className="header-subtitle">Selamat datang di Operations Portal NatureRent</p>
          </header>

          <section className="content-section">
            {/* Stats Grid */}
            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-icon transactions"><i className="fa-solid fa-receipt" /></div>
                <div className="stat-content">
                  <h3>Transaksi</h3>
                  <p className="stat-value">{stats.totalTransaksi.toLocaleString('id')}</p>
                  <p className="stat-label">Total Transaksi</p>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon rentals"><i className="fa-solid fa-person" /></div>
                <div className="stat-content">
                  <h3>Pemilik Rental</h3>
                  <p className="stat-value">{stats.totalPemilik.toLocaleString('id')}</p>
                  <p className="stat-label">Total Pemilik Rental</p>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon commission"><i className="fa-solid fa-coins" /></div>
                <div className="stat-content">
                  <h3>Komisi</h3>
                  <p className="stat-value">Rp 45.2M</p>
                  <p className="stat-label">Total Komisi Bulan Ini</p>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon revenue"><i className="fa-solid fa-chart-line" /></div>
                <div className="stat-content">
                  <h3>Revenue</h3>
                  <p className="stat-value">Rp 150.8M</p>
                  <p className="stat-label">Total Pendapatan</p>
                </div>
              </div>
            </div>

            {/* Quick Access */}
            <div className="quick-access-section">
              <h2>Akses Cepat</h2>
              <div className="quick-access-grid">
                {[
                  { href: '/transaksi', icon: 'fa-receipt', title: 'Transaksi', desc: 'Kelola dan monitor semua transaksi penyewaan' },
                  { href: '/pemilik-rental', icon: 'fa-person', title: 'Pemilik Rental', desc: 'Kelola data pemilik rental dengan mudah' },
                  { href: '/pengguna', icon: 'fa-users', title: 'Pengguna', desc: 'Kelola data akun pengguna aplikasi' },
                  { href: '/komisi', icon: 'fa-coins', title: 'Komisi', desc: 'Monitor komisi dan pembayaran pemilik rental' },
                  { href: '/settings', icon: 'fa-sliders', title: 'Pengaturan Sistem', desc: 'Kelola konfigurasi dan pengaturan sistem' },
                ].map(item => (
                  <Link key={item.href} href={item.href} className="quick-card">
                    <div className="card-icon"><i className={`fa-solid ${item.icon}`} /></div>
                    <div className="card-content">
                      <h3>{item.title}</h3>
                      <p>{item.desc}</p>
                    </div>
                    <div className="card-arrow"><i className="fa-solid fa-arrow-right" /></div>
                  </Link>
                ))}
              </div>
            </div>

            {/* Recent Activity */}
            <div className="activity-section">
              <h2>Aktivitas Terbaru</h2>
              <div className="activity-list">
                {loading ? (
                  <div className="loading-state" style={{ padding: '32px 0' }}>
                    <div className="loading-spinner" />
                    <span>Memuat aktivitas...</span>
                  </div>
                ) : recentActivity.length > 0 ? recentActivity.map(item => (
                  <div key={item.id} className="activity-item">
                    <div className={`activity-icon ${item.icon}`}><i className={`fa-solid ${item.fa}`} /></div>
                    <div className="activity-content">
                      <p className="activity-title">{item.title}</p>
                      <p className="activity-description">{item.desc}</p>
                      <p className="activity-time">{timeAgo(item.created_at)}</p>
                    </div>
                  </div>
                )) : (
                  <div className="empty-state" style={{ padding: '32px 0' }}>
                    <i className="fa-solid fa-clock-rotate-left empty-icon" />
                    <p>Belum ada aktivitas terbaru.</p>
                  </div>
                )}
              </div>
            </div>
          </section>
        </main>
      </div>
    </AuthGuard>
  )
}

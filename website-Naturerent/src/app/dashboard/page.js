import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import Sidebar from '@/components/Sidebar'
import Link from 'next/link'

async function getStats(supabase) {
  try {
    const [bookings, pemilik] = await Promise.all([
      supabase.from('bookings').select('id', { count: 'exact', head: true }),
      supabase.from('rental_profiles').select('id', { count: 'exact', head: true }),
    ])
    return {
      totalTransaksi: bookings.count ?? 0,
      totalPemilik: pemilik.count ?? 0,
    }
  } catch (e) {
    console.error('Error fetching stats:', e)
    return { totalTransaksi: 0, totalPemilik: 0 }
  }
}

async function getRecentActivity(supabase) {
  try {
    const { data, error } = await supabase
      .from('bookings')
      .select('id, created_at, status, customer_id')
      .order('created_at', { ascending: false })
      .limit(4)
    
    if (error || !data || data.length === 0) return []

    const userIds = [...new Set(data.map(d => d.customer_id).filter(Boolean))]
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

    return data.map(row => ({
      id: row.id,
      created_at: row.created_at,
      status: row.status,
      user_name: userMap[row.customer_id] || 'Pengguna',
      rental_name: 'Peralatan Camping'
    }))
  } catch (err) {
    console.error('Error fetching recent activity:', err)
    return []
  }
}

export default async function DashboardPage() {
  const cookieStore = await cookies()
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: () => {},
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()
  let stats = { totalTransaksi: 0, totalPemilik: 0 }
  let recentActivity = []

  try {
    stats = await getStats(supabase)
    recentActivity = await getRecentActivity(supabase)
  } catch {
    // Tables may not exist yet, use defaults
  }

  function timeAgo(dateStr) {
    if (!dateStr) return ''
    const diff = Date.now() - new Date(dateStr).getTime()
    const minutes = Math.floor(diff / 60000)
    if (minutes < 60) return `${minutes} menit yang lalu`
    const hours = Math.floor(minutes / 60)
    if (hours < 24) return `${hours} jam yang lalu`
    return `${Math.floor(hours / 24)} hari yang lalu`
  }

  return (
    <div className="dashboard-container">
      <Sidebar userEmail={user?.email} />
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
              {recentActivity.length > 0 ? recentActivity.map(item => (
                <div key={item.id} className="activity-item">
                  <div className="activity-icon transaction"><i className="fa-solid fa-receipt" /></div>
                  <div className="activity-content">
                    <p className="activity-title">Transaksi {item.status}</p>
                    <p className="activity-description">{item.id} — {item.user_name || 'Pengguna'}</p>
                    <p className="activity-time">{timeAgo(item.created_at)}</p>
                  </div>
                </div>
              )) : (
                <>
                  {[
                    { icon: 'transaction', fa: 'fa-receipt', title: 'Transaksi Baru', desc: 'TRX-20250526-001 dari Susmini Hernanto', time: '2 jam yang lalu' },
                    { icon: 'rental', fa: 'fa-person-circle-plus', title: 'Pemilik Rental Baru', desc: 'Green Valley Glamping ditambahkan', time: '5 jam yang lalu' },
                    { icon: 'payment', fa: 'fa-money-bill-transfer', title: 'Pembayaran Komisi', desc: 'Pembayaran komisi Bulan Mei telah diproses', time: '1 hari yang lalu' },
                    { icon: 'setting', fa: 'fa-gear', title: 'Pengaturan Sistem', desc: 'Konfigurasi komisi diperbarui', time: '3 hari yang lalu' },
                  ].map((a, i) => (
                    <div key={i} className="activity-item">
                      <div className={`activity-icon ${a.icon}`}><i className={`fa-solid ${a.fa}`} /></div>
                      <div className="activity-content">
                        <p className="activity-title">{a.title}</p>
                        <p className="activity-description">{a.desc}</p>
                        <p className="activity-time">{a.time}</p>
                      </div>
                    </div>
                  ))}
                </>
              )}
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}

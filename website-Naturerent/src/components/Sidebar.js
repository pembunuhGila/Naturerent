'use client'
import { usePathname, useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'

const navItems = [
  { href: '/dashboard',       icon: 'fa-table-cells-large',  label: 'Dashboard' },
  { href: '/komisi',          icon: 'fa-cube',               label: 'Komisi' },
  { href: '/pemilik-rental',  icon: 'fa-user-group',         label: 'Pemilik Rental' },
  { href: '/transaksi',       icon: 'fa-chart-line',         label: 'Transaksi' },
  { href: '/settings',        icon: 'fa-gear',               label: 'System Settings' },
]

export default function Sidebar({ userEmail }) {
  const pathname = usePathname()
  const router = useRouter()

  const handleLogout = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <div className="logo-icon">
          <i className="fa-solid fa-tree" />
        </div>
        <div>
          <span className="header-title">NatureRent</span>
          <span className="header-subtitle">Operations Portal</span>
        </div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map(({ href, icon, label }) => (
          <a
            key={href}
            href={href}
            className={`nav-item ${pathname.startsWith(href) ? 'active' : ''}`}
          >
            <i className={`fa-solid ${icon} nav-icon`} />
            <span>{label}</span>
          </a>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="user-profile">
          <div className="user-avatar">
            <i className="fa-solid fa-user" />
          </div>
          <div className="user-info">
            <span className="user-name">Admin</span>
            <span className="user-role" style={{ fontSize: 10, maxWidth: 120, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', display: 'block' }}>
              {userEmail || 'administrator'}
            </span>
          </div>
          <button className="logout-btn" onClick={handleLogout} title="Keluar">
            <i className="fa-solid fa-right-from-bracket" />
          </button>
        </div>
      </div>
    </aside>
  )
}

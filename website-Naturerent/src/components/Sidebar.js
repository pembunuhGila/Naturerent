'use client'
import { useState, useEffect } from 'react'
import { usePathname, useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'

const navItems = [
  { href: '/dashboard',       icon: 'fa-table-cells-large',  label: 'Dashboard' },
  { href: '/komisi',          icon: 'fa-cube',               label: 'Komisi' },
  { href: '/pemilik-rental',  icon: 'fa-user-group',         label: 'Pemilik Rental' },
  { href: '/transaksi',       icon: 'fa-chart-line',         label: 'Transaksi' },
  { href: '/settings',        icon: 'fa-gear',               label: 'System Settings' },
]

// Helper for lighten/darken color hexes
function lightenDarkenColor(col, amt) {
  let usePound = false
  if (!col) return '#1f5a3f'
  if (col[0] === "#") {
    col = col.slice(1)
    usePound = true
  }
  let num = parseInt(col, 16)
  let r = (num >> 16) + amt
  if (r > 255) r = 255
  else if (r < 0) r = 0
  let b = ((num >> 8) & 0x00FF) + amt
  if (b > 255) b = 255
  else if (b < 0) b = 0
  let g = (num & 0x0000FF) + amt
  if (g > 255) g = 255
  else if (g < 0) g = 0
  return (usePound ? "#" : "") + (g | (b << 8) | (r << 16)).toString(16).padStart(6, '0')
}

function applyThemeAndAccent(theme, accentColor, customAccentHex) {
  if (typeof window === 'undefined') return
  const root = document.documentElement

  // Theme Variables
  if (theme === 'dark') {
    root.style.setProperty('--bg-primary', '#121214')
    root.style.setProperty('--bg-secondary', '#1a1a1e')
    root.style.setProperty('--bg-card', '#202024')
    root.style.setProperty('--bg-card-hover', '#26262b')
    root.style.setProperty('--text-primary', '#f3f4f6')
    root.style.setProperty('--text-secondary', '#9ca3af')
    root.style.setProperty('--text-muted', '#6b7280')
    root.style.setProperty('--border-color', '#303036')
    root.style.setProperty('--border-color-light', '#26262a')
  } else {
    root.style.setProperty('--bg-primary', '#f7f7f3')
    root.style.setProperty('--bg-secondary', '#f9fafb')
    root.style.setProperty('--bg-card', '#ffffff')
    root.style.setProperty('--bg-card-hover', '#fcfcf9')
    root.style.setProperty('--text-primary', '#1a2e1a')
    root.style.setProperty('--text-secondary', '#6b7280')
    root.style.setProperty('--text-muted', '#9ca3af')
    root.style.setProperty('--border-color', '#e5e7eb')
    root.style.setProperty('--border-color-light', '#f3f4f6')
  }

  // Accent Colors
  let brandGreen = '#1f5a3f'
  let brandGreenLight = '#2d6a4f'
  let brandGreenDark = '#164a30'
  let brandEmerald = '#52b788'
  let brandMint = '#d1f4e8'

  if (accentColor === 'green') {
    brandGreen = '#1f5a3f'
    brandGreenLight = '#2d6a4f'
    brandGreenDark = '#164a30'
    brandEmerald = '#52b788'
    brandMint = '#d1f4e8'
  } else if (accentColor === 'teal') {
    brandGreen = '#0d8c75'
    brandGreenLight = '#0f766e'
    brandGreenDark = '#115e59'
    brandEmerald = '#14b8a6'
    brandMint = '#ccfbf1'
  } else if (accentColor === 'forest') {
    brandGreen = '#14532d'
    brandGreenLight = '#166534'
    brandGreenDark = '#14532d'
    brandEmerald = '#22c55e'
    brandMint = '#dcfce7'
  } else if (accentColor === 'navy') {
    brandGreen = '#1e3a8a'
    brandGreenLight = '#1e40af'
    brandGreenDark = '#172554'
    brandEmerald = '#3b82f6'
    brandMint = '#dbeafe'
  } else if (accentColor === 'custom' && customAccentHex) {
    brandGreen = customAccentHex
    brandGreenLight = lightenDarkenColor(customAccentHex, 20)
    brandGreenDark = lightenDarkenColor(customAccentHex, -20)
    brandEmerald = lightenDarkenColor(customAccentHex, 40)
    brandMint = lightenDarkenColor(customAccentHex, 80)
  }

  root.style.setProperty('--brand-green', brandGreen)
  root.style.setProperty('--brand-green-light', brandGreenLight)
  root.style.setProperty('--brand-green-dark', brandGreenDark)
  root.style.setProperty('--brand-emerald', brandEmerald)
  root.style.setProperty('--brand-mint', brandMint)
  root.style.setProperty('--bg-sidebar', brandGreen)

  // Dynamically compute and inject isolated sidebar styles in full harmony
  var sidebarBg = brandGreen
  var sidebarTxt = '#c2f0dc'
  var sidebarTitleTxt = '#ffffff'
  var sidebarHoverBg = brandGreenLight
  var sidebarHoverTxt = '#ffffff'
  var sidebarActiveBg = 'rgba(255, 255, 255, 0.12)'
  var sidebarActiveTxt = '#ffffff'
  var sidebarActiveBorder = 'rgba(255, 255, 255, 0.2)'
  var sidebarBorder = brandGreenDark

  if (theme === 'dark') {
    sidebarBg = '#121214'
    sidebarTxt = '#9ca3af'
    sidebarTitleTxt = '#f3f4f6'
    sidebarHoverBg = '#1a1a1e'
    sidebarHoverTxt = '#f3f4f6'
    sidebarActiveBg = 'rgba(82, 183, 136, 0.15)'
    sidebarActiveTxt = '#52b788'
    sidebarActiveBorder = 'rgba(82, 183, 136, 0.25)'
    sidebarBorder = '#26262a'
  }

  root.style.setProperty('--sidebar-bg', sidebarBg)
  root.style.setProperty('--sidebar-txt', sidebarTxt)
  root.style.setProperty('--sidebar-title-txt', sidebarTitleTxt)
  root.style.setProperty('--sidebar-hover-bg', sidebarHoverBg)
  root.style.setProperty('--sidebar-hover-txt', sidebarHoverTxt)
  root.style.setProperty('--sidebar-active-bg', sidebarActiveBg)
  root.style.setProperty('--sidebar-active-txt', sidebarActiveTxt)
  root.style.setProperty('--sidebar-active-border', sidebarActiveBorder)
  root.style.setProperty('--sidebar-border', sidebarBorder)
}

export default function Sidebar({ userEmail }) {
  const pathname = usePathname()
  const router = useRouter()
  const [appName, setAppName] = useState('NatureRent')
  const [logo, setLogo] = useState(null)
  const [supportEmail, setSupportEmail] = useState('admin@naturerent.com')
  const [supportPhone, setSupportPhone] = useState('+62 21 5550 1234')

  useEffect(() => {
    const loadSettings = () => {
      const saved = localStorage.getItem('naturerent_system_settings')
      if (saved) {
        try {
          const parsed = JSON.parse(saved)
          setAppName(parsed.appName || 'NatureRent')
          setLogo(parsed.logo || null)
          setSupportEmail(parsed.officialEmail || 'admin@naturerent.com')
          setSupportPhone(parsed.serviceNumber || '+62 21 5550 1234')
          applyThemeAndAccent(parsed.theme || 'dark', parsed.accentColor, parsed.customAccentHex)
        } catch (_) {
          applyThemeAndAccent('dark', 'green', '#1f5a3f')
        }
      } else {
        setAppName('NatureRent')
        setLogo(null)
        setSupportEmail('admin@naturerent.com')
        setSupportPhone('+62 21 5550 1234')
        applyThemeAndAccent('dark', 'green', '#1f5a3f')
      }
    }

    loadSettings()
    window.addEventListener('system_settings_updated', loadSettings)
    return () => window.removeEventListener('system_settings_updated', loadSettings)
  }, [])

  const handleLogout = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <div className="logo-icon" style={{ overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {logo ? (
            <img src={logo} alt="Logo" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: 'inherit' }} />
          ) : (
            <i className="fa-solid fa-tree" />
          )}
        </div>
        <div>
          <span className="header-title">{appName}</span>
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
        {/* Dynamic Helpdesk Widget visualizing Official Email and Service Number */}
        <div style={{ padding: '12px 10px', borderBottom: '1px solid var(--sidebar-border)', marginBottom: 12, fontSize: '11px', color: 'var(--sidebar-txt)', lineHeight: '1.45' }}>
          <div style={{ fontWeight: 700, textTransform: 'uppercase', fontSize: '9px', letterSpacing: '0.5px', marginBottom: 6, color: 'var(--sidebar-title-txt)' }}>Layanan Bantuan</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }} title="Telepon Support">
            <i className="fa-solid fa-phone" style={{ width: 12, textAlign: 'center', fontSize: '10px' }} />
            <span>{supportPhone}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }} title="Email Support">
            <i className="fa-solid fa-envelope" style={{ width: 12, textAlign: 'center', fontSize: '10px' }} />
            <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', display: 'block', maxWidth: 145 }}>{supportEmail}</span>
          </div>
        </div>

        <div className="user-profile">
          <div className="user-avatar">
            <i className="fa-solid fa-user" />
          </div>
          <div className="user-info">
            <span className="user-name">Admin</span>
            <span className="user-role" style={{ fontSize: 10, maxWidth: 95, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', display: 'block' }}>
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

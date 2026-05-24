'use client'
import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'

export default function AuthGuard({ children }) {
  const router = useRouter()
  const [checked, setChecked] = useState(false)

  useEffect(() => {
    const checkAuth = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) {
        router.replace('/login')
      } else {
        setChecked(true)
      }
    }
    checkAuth()
  }, [router])

  if (!checked) {
    return (
      <div style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'var(--bg-primary)',
        flexDirection: 'column',
        gap: 14,
        color: 'var(--text-secondary)',
        fontFamily: 'Plus Jakarta Sans, sans-serif'
      }}>
        <div style={{
          width: 40, height: 40,
          border: '3px solid #30363d',
          borderTopColor: '#52b788',
          borderRadius: '50%',
          animation: 'spin 0.8s linear infinite'
        }} />
        <span style={{ fontSize: 14 }}>Memeriksa autentikasi...</span>
        <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
      </div>
    )
  }

  return children
}

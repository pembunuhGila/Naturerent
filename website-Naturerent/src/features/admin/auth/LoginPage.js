'use client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [showPassword, setShowPassword] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')

    if (!email || !password) {
      setError('Silakan isi email dan kata sandi.')
      return
    }

    setLoading(true)
    try {
      const supabase = createClient()
      const { error: authError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      })

      if (authError) {
        setError(authError.message === 'Invalid login credentials'
          ? 'Email atau kata sandi salah.'
          : authError.message)
        return
      }

      router.push('/dashboard')
      router.refresh()
    } catch {
      setError('Terjadi kesalahan. Silakan coba lagi.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-container">
      <div className="login-bg-glow-figma-1" />
      <div className="login-bg-glow-figma-2" />

      <div className="login-logo-centered">
        <i className="fa-solid fa-tree figma-logo-icon" />
        <span className="figma-logo-text">NatureRent</span>
      </div>

      <div className="login-card-figma">
        <h1 className="login-title-figma">Selamat Datang Kembali</h1>
        <p className="login-subtitle-figma">Silakan masuk untuk melanjutkan petualangan Anda.</p>

        {error && (
          <div className="alert-error" role="alert" style={{ marginBottom: 16 }}>
            <i className="fa-solid fa-circle-exclamation" style={{ marginRight: 8 }} />
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="input-group">
            <label className="input-label-figma" htmlFor="email">Alamat Email</label>
            <div className="input-wrapper-figma">
              <input
                id="email"
                type="email"
                className="form-input-login-figma"
                placeholder="nama@email.com"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
                autoComplete="email"
              />
            </div>
          </div>

          <div className="input-group" style={{ marginBottom: 24 }}>
            <div className="label-row-figma">
              <label className="input-label-figma" htmlFor="password">Kata Sandi</label>
            </div>
            <div className="input-wrapper-figma">
              <input
                id="password"
                type={showPassword ? 'text' : 'password'}
                className="form-input-login-figma"
                placeholder="Masukkan kata sandi"
                value={password}
                onChange={e => setPassword(e.target.value)}
                required
                autoComplete="current-password"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="toggle-password-btn-figma"
              >
                <i className={`fa-solid ${showPassword ? 'fa-eye-slash' : 'fa-eye'}`} />
              </button>
            </div>
          </div>

          <button type="submit" className="submit-btn-figma" disabled={loading}>
            {loading ? (
              <>
                <span className="loading-spinner" style={{ width: 16, height: 16, borderWidth: 2, display: 'inline-block', verticalAlign: 'middle', marginRight: 8, borderColor: 'white', borderTopColor: 'transparent' }} />
                Masuk...
              </>
            ) : 'Masuk'}
          </button>
        </form>
      </div>

      <div className="login-footer-credit-figma">
        &copy; 2026 NatureRent. Grounded in nature.
      </div>
    </div>
  )
}

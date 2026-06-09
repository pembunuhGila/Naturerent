'use client'
import { useEffect, useState } from 'react'

export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener('scroll', onScroll)

    // Intersection Observer for fade-in
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(e => { if (e.isIntersecting) e.target.classList.add('visible') })
    }, { threshold: 0.1 })
    document.querySelectorAll('.fade-in').forEach(el => observer.observe(el))

    return () => {
      window.removeEventListener('scroll', onScroll)
      observer.disconnect()
    }
  }, [])

  return (
    <>
      {/* ===== NAVBAR ===== */}
      <nav className={`navbar${scrolled ? ' scrolled' : ''}`}>
        <div className="navbar-inner">
          <a href="#beranda" className="nav-logo">
            <div className="nav-logo-icon"><i className="fas fa-campground"></i></div>
            <span className="nav-logo-text">NatureRent</span>
          </a>
          <ul className={`nav-links${menuOpen ? ' active' : ''}`}>
            <li><a href="#beranda" onClick={() => setMenuOpen(false)}>Beranda</a></li>
            <li><a href="#fitur" onClick={() => setMenuOpen(false)}>Fitur</a></li>
            <li><a href="#cara-kerja" onClick={() => setMenuOpen(false)}>Cara Kerja</a></li>
            <li><a href="#mitra" onClick={() => setMenuOpen(false)}>Mitra Rental</a></li>
            <li><a href="#tentang" onClick={() => setMenuOpen(false)}>Tentang Kami</a></li>
          </ul>
          <a href="#download" className="nav-cta"><i className="fas fa-download"></i> Download App</a>
          <button className="mobile-toggle" onClick={() => setMenuOpen(!menuOpen)}>
            <i className={menuOpen ? 'fas fa-times' : 'fas fa-bars'}></i>
          </button>
        </div>
      </nav>

      {/* ===== HERO ===== */}
      <section className="hero" id="beranda">
        <div className="hero-bg">
          <img src="/landing/hero_bg.png" alt="Pemandangan alam Indonesia" />
        </div>
        <div className="hero-inner">
          <div className="hero-content">
            <h1>Sewa Alat Camping<br/>Jadi <span>Lebih Mudah</span></h1>
            <p>NatureRent membantu kamu menemukan dan menyewa perlengkapan outdoor dari tempat rental terdekat dengan cepat, praktis, dan aman.</p>
            <div className="hero-buttons">
              <a href="#fitur" className="btn-hero-primary">
                <i className="fas fa-search"></i> Cari Rental Sekarang
              </a>
              <a href="#mitra" className="btn-hero-secondary">
                <i className="fas fa-handshake"></i> Daftar Sebagai Mitra
              </a>
            </div>
            <div className="hero-badges">
              <div className="hero-badge">
                <i className="fab fa-google-play" style={{fontSize:22,color:'white'}}></i>
                <span>Google Play</span>
              </div>
              <div className="hero-badge">
                <i className="fab fa-apple" style={{fontSize:22,color:'white'}}></i>
                <span>App Store</span>
              </div>
            </div>
          </div>
          <div className="hero-mockup">
            <img src="/landing/app_mockup.png" alt="Aplikasi NatureRent" />
          </div>
        </div>
      </section>

      {/* ===== MASALAH & SOLUSI ===== */}
      <section className="section problems-section" id="masalah">
        <div className="container">
          <div className="problems-header fade-in">
            <h2>Masih Ribet Cari Alat Camping?</h2>
            <p>Kami hadir untuk membuat pengalaman menyewa alat camping jadi lebih mudah, cepat, dan aman.</p>
          </div>
          <div className="problems-grid fade-in">
            <div className="problem-card">
              <div className="problem-icon"><i className="fas fa-comments"></i></div>
              <h4>Harus Chat Banyak Rental</h4>
              <p>Menghubungi satu per satu rental untuk cek ketersediaan alat sangat memakan waktu.</p>
            </div>
            <div className="problem-card">
              <div className="problem-icon"><i className="fas fa-box-open"></i></div>
              <h4>Stok Tidak Jelas</h4>
              <p>Sulit mengetahui apakah alat yang dibutuhkan masih tersedia atau sudah habis.</p>
            </div>
            <div className="problem-card">
              <div className="problem-icon"><i className="fas fa-money-bill-wave"></i></div>
              <h4>Harga & Lokasi Sulit Dibandingkan</h4>
              <p>Tidak ada platform yang memudahkan membandingkan harga dan jarak rental.</p>
            </div>
            <div className="problem-card">
              <div className="problem-icon"><i className="fas fa-clipboard-list"></i></div>
              <h4>Booking Masih Manual</h4>
              <p>Proses pemesanan lewat chat atau datang langsung ke toko yang tidak praktis.</p>
            </div>
          </div>

          <div className="solution-block fade-in">
            <div className="solution-content">
              <h3>NatureRent Solusinya!</h3>
              <p>Satu aplikasi untuk semua kebutuhan rental alat camping kamu.</p>
              <ul className="solution-list">
                <li><span className="solution-check"><i className="fas fa-check"></i></span> Cari rental terdekat berdasarkan lokasi</li>
                <li><span className="solution-check"><i className="fas fa-check"></i></span> Lihat informasi alat dan stok lengkap</li>
                <li><span className="solution-check"><i className="fas fa-check"></i></span> Informasi lokasi toko rental di peta</li>
                <li><span className="solution-check"><i className="fas fa-check"></i></span> Detail profil pemilik rental</li>
                <li><span className="solution-check"><i className="fas fa-check"></i></span> Proses pemesanan lebih praktis & cepat</li>
              </ul>
            </div>
            <div className="solution-image">
              <img src="/landing/camping_people.png" alt="Camping bersama NatureRent" />
            </div>
          </div>
        </div>
      </section>

      {/* ===== FITUR UTAMA ===== */}
      <section className="section" id="fitur">
        <div className="container">
          <div className="section-header fade-in">
            <div className="section-label"><i className="fas fa-star"></i> FITUR</div>
            <h2 className="section-title">Fitur Utama NatureRent</h2>
            <p className="section-subtitle">Semua yang kamu butuhkan untuk menyewa alat camping dalam satu aplikasi.</p>
          </div>
          <div className="features-grid fade-in">
            <div className="feature-card">
              <div className="feature-icon"><i className="fas fa-map-marker-alt"></i></div>
              <h4>Cari Rental Terdekat</h4>
              <p>Temukan toko rental alat camping terdekat dari lokasimu dengan mudah dan cepat.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon"><i className="fas fa-list-check"></i></div>
              <h4>Detail Alat & Ketersediaan</h4>
              <p>Lihat harga, deskripsi, foto, dan ketersediaan stok alat camping yang diinginkan.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon"><i className="fas fa-store"></i></div>
              <h4>Informasi Lokasi Toko</h4>
              <p>Dapatkan informasi lengkap lokasi toko rental beserta peta dan petunjuk arah.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon"><i className="fas fa-mountain"></i></div>
              <h4>Rekomendasi Destinasi</h4>
              <p>Temukan berbagai destinasi menarik untuk petualanganmu, langsung dari aplikasi.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon"><i className="fas fa-cart-shopping"></i></div>
              <h4>Pemesanan Praktis</h4>
              <p>Pesan alat camping secara mudah langsung melalui aplikasi tanpa perlu datang ke toko.</p>
            </div>
            <div className="feature-card">
              <div className="feature-icon"><i className="fas fa-gear"></i></div>
              <h4>Dashboard Pemilik Rental</h4>
              <p>Kelola toko, peralatan, pesanan, dan pendapatan dengan mudah melalui dashboard khusus.</p>
            </div>
          </div>
        </div>
      </section>

      {/* ===== CARA KERJA ===== */}
      <section className="section howto-section" id="cara-kerja">
        <div className="container">
          <div className="section-header fade-in">
            <div className="section-label"><i className="fas fa-route"></i> LANGKAH</div>
            <h2 className="section-title">Cara Pakai NatureRent</h2>
            <p className="section-subtitle">Hanya 4 langkah mudah untuk memulai petualanganmu.</p>
          </div>
          <div className="howto-grid fade-in">
            <div className="howto-step">
              <div className="step-number">1</div>
              <div className="step-icon"><i className="fas fa-search-location"></i></div>
              <h4>Cari Rental</h4>
              <p>Pilih toko rental atau cari alat camping sesuai lokasi dan kebutuhanmu.</p>
            </div>
            <div className="howto-step">
              <div className="step-number">2</div>
              <div className="step-icon"><i className="fas fa-hand-pointer"></i></div>
              <h4>Pilih Alat Camping</h4>
              <p>Cek detail, harga, dan ketersediaan alat yang ingin kamu sewa.</p>
            </div>
            <div className="howto-step">
              <div className="step-number">3</div>
              <div className="step-icon"><i className="fas fa-credit-card"></i></div>
              <h4>Lakukan Pemesanan</h4>
              <p>Lakukan pemesanan dan pembayaran melalui aplikasi dengan mudah.</p>
            </div>
            <div className="howto-step">
              <div className="step-number">4</div>
              <div className="step-icon"><i className="fas fa-hiking"></i></div>
              <h4>Mulai Petualangan!</h4>
              <p>Ambil alat di toko rental dan mulai petualangan outdoor-mu.</p>
            </div>
          </div>
        </div>
      </section>

      {/* ===== MITRA RENTAL ===== */}
      <section className="section mitra-section" id="mitra">
        <div className="container">
          <div className="mitra-inner fade-in">
            <div className="mitra-content">
              <div className="section-label"><i className="fas fa-handshake"></i> MITRA</div>
              <h3>Untuk Pemilik Rental</h3>
              <p>NatureRent juga membantu pemilik rental outdoor untuk mengembangkan bisnis secara digital dan menjangkau lebih banyak pelanggan.</p>
              <ul className="mitra-features">
                <li>
                  <div className="mitra-feat-icon"><i className="fas fa-store"></i></div>
                  <span>Mengelola profil toko dan informasi bisnis</span>
                </li>
                <li>
                  <div className="mitra-feat-icon"><i className="fas fa-boxes-stacked"></i></div>
                  <span>Mengatur daftar peralatan dan ketersediaan stok</span>
                </li>
                <li>
                  <div className="mitra-feat-icon"><i className="fas fa-clipboard-check"></i></div>
                  <span>Mengelola pesanan masuk dari pelanggan</span>
                </li>
                <li>
                  <div className="mitra-feat-icon"><i className="fas fa-chart-line"></i></div>
                  <span>Melihat laporan pendapatan dan performa toko</span>
                </li>
                <li>
                  <div className="mitra-feat-icon"><i className="fas fa-map-pin"></i></div>
                  <span>Menambahkan lokasi toko dan destinasi terdekat</span>
                </li>
              </ul>
              <a href="#download" className="btn-mitra">
                <i className="fas fa-rocket"></i> Gabung Sebagai Mitra NatureRent
              </a>
            </div>
            <div className="mitra-image">
              <img src="/landing/rental_dashboard.png" alt="Dashboard Mitra NatureRent" />
            </div>
          </div>
        </div>
      </section>

      {/* ===== KEUNGGULAN ===== */}
      <section className="section advantages-section" id="tentang">
        <div className="container">
          <div className="section-header fade-in">
            <div className="section-label"><i className="fas fa-trophy"></i> KEUNGGULAN</div>
            <h2 className="section-title">Kenapa Pilih NatureRent?</h2>
            <p className="section-subtitle">Alasan mengapa NatureRent menjadi pilihan terbaik untuk kebutuhan rental outdoor kamu.</p>
          </div>
          <div className="advantages-grid fade-in">
            <div className="advantage-card">
              <div className="advantage-icon"><i className="fas fa-bolt"></i></div>
              <h4>Praktis</h4>
              <p>Cari, bandingkan, dan pesan alat camping hanya dalam genggaman.</p>
            </div>
            <div className="advantage-card">
              <div className="advantage-icon"><i className="fas fa-location-dot"></i></div>
              <h4>Dekat</h4>
              <p>Temukan rental terdekat dari lokasi kamu saat ini.</p>
            </div>
            <div className="advantage-card">
              <div className="advantage-icon"><i className="fas fa-compass"></i></div>
              <h4>Untuk Traveler</h4>
              <p>Cocok untuk traveler dan pecinta alam yang aktif berpetualang.</p>
            </div>
            <div className="advantage-card">
              <div className="advantage-icon"><i className="fas fa-heart"></i></div>
              <h4>Dukung UMKM</h4>
              <p>Membantu UMKM rental outdoor berkembang secara digital.</p>
            </div>
            <div className="advantage-card">
              <div className="advantage-icon"><i className="fas fa-mobile-screen-button"></i></div>
              <h4>Mudah Digunakan</h4>
              <p>Interface yang intuitif dan mudah dipahami semua kalangan.</p>
            </div>
          </div>
        </div>
      </section>

      {/* ===== CTA FINAL ===== */}
      <section className="cta-final" id="download">
        <div className="container">
          <div className="cta-inner fade-in">
            <h2>Siap Memulai Petualanganmu<br/>Bersama NatureRent?</h2>
            <p>Download aplikasi sekarang dan sewa alat camping dengan lebih praktis.</p>
            <div className="cta-buttons">
              <a href="#" className="btn-cta-white">
                <i className="fas fa-download"></i> Download Aplikasi
              </a>
              <a href="#mitra" className="btn-cta-outline">
                <i className="fas fa-handshake"></i> Daftar Mitra Rental
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* ===== FOOTER ===== */}
      <footer className="footer">
        <div className="container">
          <div className="footer-grid">
            <div className="footer-brand">
              <h3><i className="fas fa-campground"></i> NatureRent</h3>
              <p>Aplikasi penyewaan alat camping dan penemuan destinasi outdoor terbaik untuk petualanganmu. Sewa alat camping, petualangan tanpa batas.</p>
              <div className="footer-socials">
                <a href="#" className="footer-social"><i className="fab fa-instagram"></i></a>
                <a href="#" className="footer-social"><i className="fab fa-tiktok"></i></a>
                <a href="#" className="footer-social"><i className="fab fa-youtube"></i></a>
                <a href="#" className="footer-social"><i className="fab fa-twitter"></i></a>
              </div>
            </div>
            <div className="footer-col">
              <h4>Menu</h4>
              <ul>
                <li><a href="#beranda">Beranda</a></li>
                <li><a href="#fitur">Fitur</a></li>
                <li><a href="#cara-kerja">Cara Kerja</a></li>
                <li><a href="#mitra">Mitra Rental</a></li>
              </ul>
            </div>
            <div className="footer-col">
              <h4>Untuk Pengguna</h4>
              <ul>
                <li><a href="#">Syarat & Ketentuan</a></li>
                <li><a href="#">Kebijakan Privasi</a></li>
                <li><a href="#">Bantuan</a></li>
                <li><a href="#">FAQ</a></li>
              </ul>
            </div>
            <div className="footer-col">
              <h4>Kontak</h4>
              <ul>
                <li><a href="mailto:hello@naturerent.id"><i className="fas fa-envelope"></i> hello@naturerent.id</a></li>
                <li><a href="#"><i className="fas fa-phone"></i> 0812-3456-7890</a></li>
                <li><a href="#"><i className="fas fa-map-marker-alt"></i> Indonesia</a></li>
              </ul>
            </div>
          </div>
          <div className="footer-bottom">
            © 2024 NatureRent. Sewa alat camping, petualangan tanpa batas.
          </div>
        </div>
      </footer>
    </>
  )
}

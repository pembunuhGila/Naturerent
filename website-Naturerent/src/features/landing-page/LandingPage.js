'use client'
import { useEffect, useState } from 'react'

const features = [
  ['fa-location-crosshairs', 'Rental Terdekat', 'Temukan toko rental dari lokasi kamu tanpa bolak-balik chat.'],
  ['fa-boxes-stacked', 'Stok Real-Time', 'Lihat alat yang tersedia, harga, dan detailnya sebelum pesan.'],
  ['fa-map-location-dot', 'Destinasi Outdoor', 'Cari inspirasi gunung, ranu, hutan, dan pantai dalam satu layar.'],
  ['fa-calendar-check', 'Booking Praktis', 'Atur tanggal sewa dan kirim pesanan dengan alur yang jelas.'],
  ['fa-store', 'Profil Rental', 'Kenali pemilik, alamat toko, dan kontak sebelum mengambil alat.'],
  ['fa-receipt', 'Riwayat Aktivitas', 'Pantau pesanan dan transaksi dari awal sampai alat dikembalikan.'],
  ['fa-shield-heart', 'Lebih Aman', 'Data rental, pesanan, dan pembayaran dibuat lebih mudah dilacak.'],
  ['fa-chart-line', 'Panel Mitra', 'Pemilik rental bisa mengelola alat, pesanan, dan performa toko.'],
]

const oldWay = [
  'Chat banyak rental satu per satu',
  'Stok sering baru diketahui di akhir',
  'Harga dan lokasi sulit dibandingkan',
  'Booking manual dan mudah tercecer',
]

const natureRentWay = [
  'Cari rental dan alat dari satu aplikasi',
  'Ketersediaan dan detail alat tampil lebih rapi',
  'Destinasi, toko, dan pesanan saling terhubung',
  'Aktivitas sewa bisa dipantau kapan saja',
]

export default function LandingPage() {
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const [compareMode, setCompareMode] = useState('naturerent')

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 40)
    window.addEventListener('scroll', onScroll)

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(e => { if (e.isIntersecting) e.target.classList.add('visible') })
    }, { threshold: 0.12 })
    document.querySelectorAll('.fade-in').forEach(el => observer.observe(el))

    return () => {
      window.removeEventListener('scroll', onScroll)
      observer.disconnect()
    }
  }, [])

  const comparison = compareMode === 'naturerent' ? natureRentWay : oldWay

  return (
    <>
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
            <li><a href="#mitra" onClick={() => setMenuOpen(false)}>Mitra</a></li>
            <li><a href="#download" onClick={() => setMenuOpen(false)}>Download</a></li>
          </ul>
          <a href="#download" className="nav-cta"><i className="fas fa-download"></i> Download</a>
          <button className="mobile-toggle" type="button" aria-label="Toggle menu" onClick={() => setMenuOpen(!menuOpen)}>
            <i className={menuOpen ? 'fas fa-times' : 'fas fa-bars'}></i>
          </button>
        </div>
      </nav>

      <section className="hero" id="beranda">
        <div className="hero-bg">
          <img src="/landing/hero_bg.png" alt="Pemandangan alam Indonesia" />
        </div>
        <div className="hero-inner">
          <div className="hero-content">
            <div className="hero-kicker"><i className="fas fa-leaf"></i> Rental outdoor lebih tertata</div>
            <h1>Sewa Alat Camping Jadi <span>Lebih Mudah</span></h1>
            <p>NatureRent membantu kamu menemukan perlengkapan outdoor, rental terdekat, dan destinasi wisata dalam satu pengalaman yang praktis.</p>
            <div className="hero-buttons">
              <a href="#fitur" className="btn-hero-primary">
                <i className="fas fa-magnifying-glass"></i> Jelajahi Fitur
              </a>
              <a href="#mitra" className="btn-hero-secondary">
                <i className="fas fa-handshake"></i> Jadi Mitra
              </a>
            </div>
            <div className="hero-stats">
              <div><strong>24/7</strong><span>Akses pencarian</span></div>
              <div><strong>1 app</strong><span>Rental dan destinasi</span></div>
              <div><strong>UMKM</strong><span>Siap go digital</span></div>
            </div>
          </div>

          <div className="phone-stage" aria-label="Preview aplikasi NatureRent">
            <div className="phone-shell">
              <div className="phone-screen">
                <div className="phone-status"><span>9:32</span><span>4G 91%</span></div>
                <div className="phone-head">
                  <div>
                    <h3>Hi, Mochammad</h3>
                    <p>Mau sewa alat apa hari ini?</p>
                  </div>
                  <div className="phone-bell"><i className="far fa-bell"></i><span>6</span></div>
                </div>
                <div className="phone-search"><i className="fas fa-magnifying-glass"></i><span>Cari alat camping</span></div>
                <div className="phone-tabs">
                  <span className="active">Semua</span><span>Gunung</span><span>Ranu</span><span>Hutan</span>
                </div>
                <div className="destination-card main">
                  <img src="/landing/destination_ranu.png" alt="Ranu Regulo" />
                  <span><i className="fas fa-mountain"></i> Ranu</span>
                  <div><small>DESTINASI WISATA</small><strong>Ranu Regulo</strong><p>Danau cantik di kaki Gunung Semeru...</p></div>
                </div>
                <div className="destination-card compact">
                  <img src="/landing/hero.png" alt="Ranu Kumbolo" />
                  <span><i className="fas fa-mountain"></i> Ranu</span>
                  <div><small>DESTINASI WISATA</small><strong>Ranu Kumbolo</strong></div>
                </div>
                <div className="phone-nav">
                  <span className="active"><i className="fas fa-house"></i>Home</span>
                  <span><i className="fas fa-store"></i>Rental</span>
                  <span><i className="far fa-rectangle-list"></i>Aktifitas</span>
                  <span><i className="fas fa-user"></i>Profile</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="section problems-section" id="masalah">
        <div className="container">
          <div className="problems-header fade-in">
            <div className="problem-title-block">
              <div className="section-label"><i className="fas fa-circle-exclamation"></i> MASALAH</div>
              <h2>Masalah yang Kami Pecahkan</h2>
            </div>
            <p>Pengalaman sewa alat outdoor sering terasa ribet karena informasinya tersebar dan prosesnya masih manual.</p>
          </div>
          <div className="problems-grid fade-in">
            <div className="problem-card"><div className="problem-icon"><i className="fas fa-comments"></i></div><h4>Chat Terlalu Banyak</h4><p>Cek alat dan harga ke banyak toko memakan waktu.</p></div>
            <div className="problem-card"><div className="problem-icon"><i className="fas fa-box-open"></i></div><h4>Stok Tidak Jelas</h4><p>Ketersediaan alat sering baru diketahui setelah tanya manual.</p></div>
            <div className="problem-card"><div className="problem-icon"><i className="fas fa-map-pin"></i></div><h4>Lokasi Sulit Dibandingkan</h4><p>Pengguna perlu cek toko, jarak, dan destinasi secara terpisah.</p></div>
            <div className="problem-card"><div className="problem-icon"><i className="fas fa-clipboard-list"></i></div><h4>Booking Tercerai-berai</h4><p>Pesanan mudah hilang di chat dan catatan manual.</p></div>
          </div>
        </div>
      </section>

      <section className="section" id="fitur">
        <div className="container">
          <div className="section-header fade-in">
            <div className="section-label"><i className="fas fa-star"></i> FITUR UNGGULAN</div>
            <h2 className="section-title">Dibuat untuk Penyewa dan Pemilik Rental</h2>
            <p className="section-subtitle">Delapan fitur utama disusun rapi agar tidak ada kartu yang menggantung sendirian.</p>
          </div>
          <div className="features-grid fade-in">
            {features.map(([icon, title, body]) => (
              <div className="feature-card" key={title}>
                <div className="feature-icon"><i className={`fas ${icon}`}></i></div>
                <h4>{title}</h4>
                <p>{body}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="section howto-section" id="cara-kerja">
        <div className="container">
          <div className="section-header fade-in">
            <div className="section-label"><i className="fas fa-route"></i> CARA KERJA</div>
            <h2 className="section-title">Dari Cari Alat sampai Berangkat</h2>
            <p className="section-subtitle">Alurnya dibuat singkat supaya pengguna bisa fokus ke petualangan, bukan administrasi.</p>
          </div>
          <div className="howto-grid fade-in">
            <div className="howto-step"><div className="step-number">1</div><div className="step-icon"><i className="fas fa-search-location"></i></div><h4>Cari Rental</h4><p>Pilih toko atau cari alat sesuai lokasi dan kebutuhan.</p></div>
            <div className="howto-step"><div className="step-number">2</div><div className="step-icon"><i className="fas fa-hand-pointer"></i></div><h4>Pilih Alat</h4><p>Cek detail, harga, dan stok sebelum membuat pesanan.</p></div>
            <div className="howto-step"><div className="step-number">3</div><div className="step-icon"><i className="fas fa-calendar-check"></i></div><h4>Booking</h4><p>Atur tanggal sewa dan simpan aktivitas pesanan.</p></div>
            <div className="howto-step"><div className="step-number">4</div><div className="step-icon"><i className="fas fa-mountain-sun"></i></div><h4>Berangkat</h4><p>Ambil alat di toko dan mulai perjalanan.</p></div>
          </div>

          <div className="comparison-panel fade-in">
            <div className="comparison-copy">
              <div className="section-label"><i className="fas fa-wand-magic-sparkles"></i> PERBANDINGAN</div>
              <h3>Cara Lama vs NatureRent</h3>
              <p>Pilih mode untuk melihat perbedaannya tanpa tabel kaku.</p>
              <div className="compare-toggle">
                <button className={compareMode === 'old' ? 'active' : ''} type="button" onClick={() => setCompareMode('old')}>Cara Lama</button>
                <button className={compareMode === 'naturerent' ? 'active' : ''} type="button" onClick={() => setCompareMode('naturerent')}>NatureRent</button>
              </div>
            </div>
            <div className={`compare-card ${compareMode}`}>
              <div className="compare-card-head">
                <i className={`fas ${compareMode === 'naturerent' ? 'fa-leaf' : 'fa-hourglass-half'}`}></i>
                <strong>{compareMode === 'naturerent' ? 'Dengan NatureRent' : 'Cara Lama'}</strong>
              </div>
              <div className="compare-list">
                {comparison.map((item) => (
                  <div className="compare-item" key={item}>
                    <span><i className={`fas ${compareMode === 'naturerent' ? 'fa-check' : 'fa-minus'}`}></i></span>
                    <p>{item}</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="section mitra-section" id="mitra">
        <div className="container">
          <div className="mitra-inner fade-in">
            <div className="mitra-content">
              <div className="section-label"><i className="fas fa-handshake"></i> MITRA RENTAL</div>
              <h3>Bisnis Rental Outdoor Bisa Terlihat Lebih Profesional</h3>
              <p>NatureRent membantu pemilik rental menyusun profil toko, alat, pesanan, dan performa bisnis dalam dashboard yang lebih rapi.</p>
              <div className="mitra-points">
                <span><i className="fas fa-store"></i> Profil toko</span>
                <span><i className="fas fa-boxes-stacked"></i> Manajemen alat</span>
                <span><i className="fas fa-chart-simple"></i> Ringkasan performa</span>
              </div>
              <a href="#download" className="btn-mitra"><i className="fas fa-rocket"></i> Gabung Sebagai Mitra</a>
            </div>
            <div className="mitra-phone-stage" aria-label="Preview aplikasi mitra NatureRent">
              <div className="phone-shell partner-phone">
                <div className="phone-screen partner-screen">
                  <div className="phone-status"><span>9:32</span><span>4G 91%</span></div>
                  <div className="partner-top">
                    <div>
                      <small>Dashboard Mitra</small>
                      <h3>Outdoor Malang</h3>
                    </div>
                    <span><i className="fas fa-store"></i></span>
                  </div>
                  <div className="partner-summary">
                    <div><strong>128</strong><span>Alat aktif</span></div>
                    <div><strong>34</strong><span>Pesanan</span></div>
                  </div>
                  <div className="partner-card highlight">
                    <div><i className="fas fa-tent"></i></div>
                    <span>
                      <strong>Tenda Dome 4P</strong>
                      <small>12 unit tersedia</small>
                    </span>
                    <b>Rp45K</b>
                  </div>
                  <div className="partner-list">
                    <div><span><i className="fas fa-box"></i></span><p>Carrier 60L</p><strong>8 unit</strong></div>
                    <div><span><i className="fas fa-fire-burner"></i></span><p>Kompor Portable</p><strong>15 unit</strong></div>
                    <div><span><i className="fas fa-receipt"></i></span><p>Booking Baru</p><strong>6 order</strong></div>
                  </div>
                  <div className="partner-chart">
                    <span style={{height: '38%'}}></span>
                    <span style={{height: '64%'}}></span>
                    <span style={{height: '48%'}}></span>
                    <span style={{height: '82%'}}></span>
                    <span style={{height: '70%'}}></span>
                    <span style={{height: '92%'}}></span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="download-section" id="download">
        <div className="container">
          <div className="download-inner fade-in">
            <div>
              <div className="section-label light"><i className="fas fa-campground"></i> MULAI SEKARANG</div>
              <h2>Petualangan Lebih Siap, Rental Lebih Rapi.</h2>
              <p>NatureRent menyatukan alat camping, toko rental, dan destinasi outdoor ke dalam pengalaman yang terasa modern dari awal sampai akhir.</p>
            </div>
            <div className="download-actions">
              <a href="#" className="store-button"><i className="fab fa-google-play"></i><span><small>Download di</small>Google Play</span></a>
              <a href="#" className="store-button"><i className="fab fa-apple"></i><span><small>Segera hadir di</small>App Store</span></a>
            </div>
          </div>
        </div>
      </section>

      <footer className="footer">
        <div className="container">
          <div className="footer-map-rail" aria-hidden="true">
            <span><i className="fas fa-magnifying-glass"></i></span>
            <span><i className="fas fa-plus"></i></span>
            <span><i className="fas fa-list"></i></span>
          </div>
          <div className="footer-profile">
            <p className="footer-company">PT NATURERENT INDONESIA</p>
            <div className="footer-mark">
              <i className="fas fa-campground"></i>
              <strong>NatureRent</strong>
            </div>

            <div className="footer-info">
              <section>
                <h4>Kantor Pusat</h4>
                <p>Jl. Kaliurang Km. 5, Sleman 55281, Daerah Istimewa Yogyakarta</p>
                <p>Telp. <a href="tel:+6281234567890">0812-3456-7890</a></p>
                <p>Email:</p>
                <ul>
                  <li>Hubungan Pengguna: <a href="mailto:hello@naturerent.id">hello@naturerent.id</a></li>
                  <li>Bisnis & Pemasaran: <a href="mailto:mitra@naturerent.id">mitra@naturerent.id</a></li>
                </ul>
              </section>

              <section>
                <h4>Kantor Perwakilan Jakarta</h4>
                <p>Jl. Tebet Barat VIII No. 3, Jakarta Selatan</p>
                <p>Telp. <a href="tel:+622128543771">(021) 28543771</a></p>
                <p>Email: <a href="mailto:jakarta@naturerent.id">jakarta@naturerent.id</a></p>
              </section>

              <section>
                <h4>Layanan Mitra Rental</h4>
                <p>Registrasi toko, pendataan alat outdoor, pengelolaan pesanan, dan informasi destinasi wisata.</p>
              </section>
            </div>
          </div>
          <div className="footer-bottom">
            <span>© 2026 NatureRent. Dibangun untuk petualangan outdoor Indonesia.</span>
            <div className="footer-socials">
              <a href="#" aria-label="Instagram"><i className="fab fa-instagram"></i></a>
              <a href="#" aria-label="TikTok"><i className="fab fa-tiktok"></i></a>
              <a href="#" aria-label="YouTube"><i className="fab fa-youtube"></i></a>
            </div>
          </div>
        </div>
      </footer>
    </>
  )
}

import './landing.css'

export const metadata = {
  title: 'NatureRent - Sewa Alat Camping Jadi Lebih Mudah',
  description: 'NatureRent membantu kamu menemukan dan menyewa perlengkapan outdoor dari tempat rental terdekat dengan cepat, praktis, dan aman.',
}

export default function LandingLayout({ children }) {
  return (
    <div className="landing-body">
      {children}
    </div>
  )
}

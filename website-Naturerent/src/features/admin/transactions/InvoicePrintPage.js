'use client'
import { useState, useEffect } from 'react'
import { useParams } from 'next/navigation'
import { createClient } from '@/lib/supabase'

function formatCurrency(amount) {
  if (!amount) return '-'
  return 'Rp ' + Number(amount).toLocaleString('id-ID')
}

function formatDate(dateStr) {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

export default function InvoicePrintPage() {
  const { id } = useParams()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetch = async () => {
      setLoading(true)
      const supabase = createClient()
      
      let finalData = null
      try {
        const { data: row } = await supabase.from('bookings').select('*').eq('id', id).single()
        if (row) {
          let userName = 'Pengguna'
          let userEmailStr = '-'
          let userPhoneStr = '-'
          if (row.customer_id) {
            try {
              const { data: userData } = await supabase.from('users').select('nama_lengkap, email, no_wa').eq('id', row.customer_id).single()
              if (userData) {
                userName = userData.nama_lengkap || 'Pengguna'
                userEmailStr = userData.email || '-'
                userPhoneStr = userData.no_wa || '-'
              }
            } catch (_) {}
          }
          finalData = {
            ...row,
            user_name: userName,
            user_email: userEmailStr,
            user_phone: userPhoneStr,
            rental_name: row.rental_name || 'Peralatan Camping',
            owner_name: row.owner_name || 'Mitra NatureRent',
            total_amount: row.total || row.total_bayar || row.total_amount || 0,
            payment_method: row.payment_method || 'QRIS',
            start_date: row.tgl_mulai || row.start_date || row.created_at,
            end_date: row.tgl_selesai || row.end_date || row.created_at,
            notes: row.catatan || row.notes || '-'
          }
        }
      } catch (e) {
        console.error('Database fetch error:', e)
      }

      // Fallback to mock data if database is empty/not found
      if (!finalData) {
        const fallbackTransactions = [
          { id: 'TRX-20250526-001', created_at: '2025-05-26T10:30:00Z', user_name: 'Budi Santoso', user_email: 'budi@gmail.com', user_phone: '081234567890', rental_name: 'Summit Gear Rental', total_amount: 250000, status: 'Selesai', payment_method: 'QRIS', start_date: '2025-05-27T08:00:00Z', end_date: '2025-05-29T17:00:00Z', notes: 'Minta tenda warna hijau' },
          { id: 'TRX-20250526-002', created_at: '2025-05-26T09:15:00Z', user_name: 'Siti Aisyah', user_email: 'siti@gmail.com', user_phone: '081234567891', rental_name: 'Green Valley Glamping', total_amount: 350000, status: 'Selesai', payment_method: 'Transfer Bank', start_date: '2025-05-28T10:00:00Z', end_date: '2025-05-30T12:00:00Z', notes: 'Sewa matras ekstra' },
          { id: 'TRX-20250525-003', created_at: '2025-05-25T16:45:00Z', user_name: 'Rizky Pratama', user_email: 'rizky@gmail.com', user_phone: '081234567892', rental_name: 'Lembah Pinus Outdoor', total_amount: 150000, status: 'Proses', payment_method: 'QRIS', start_date: '2025-05-26T07:00:00Z', end_date: '2025-05-27T18:00:00Z', notes: '-' },
          { id: 'TRX-20250525-004', created_at: '2025-05-25T14:20:00Z', user_name: 'Dewi Lestari', user_email: 'dewi@gmail.com', user_phone: '081234567893', rental_name: 'Summit Gear Rental', total_amount: 450000, status: 'Selesai', payment_method: 'QRIS', start_date: '2025-05-26T09:00:00Z', end_date: '2025-05-29T12:00:00Z', notes: 'Tenda dipastikan bersih' },
          { id: 'TRX-20250524-005', created_at: '2025-05-24T11:05:00Z', user_name: 'Andi Wijaya', user_email: 'andi@gmail.com', user_phone: '081234567894', rental_name: 'Setyawan Martin', total_amount: 300000, status: 'Bermasalah', payment_method: 'Transfer Bank', start_date: '2025-05-25T08:00:00Z', end_date: '2025-05-26T17:00:00Z', notes: 'Kompor lipat tidak nyala' },
          { id: 'TRX-20250524-006', created_at: '2025-05-24T10:12:00Z', user_name: 'Nina Kartika', user_email: 'nina@gmail.com', user_phone: '081234567895', rental_name: 'Ijen Adventure', total_amount: 200000, status: 'Selesai', payment_method: 'QRIS', start_date: '2025-05-25T08:00:00Z', end_date: '2025-05-26T17:00:00Z', notes: '-' },
          { id: 'TRX-20250523-007', created_at: '2025-05-23T17:30:00Z', user_name: 'Fajar Ramadhan', user_email: 'fajar@gmail.com', user_phone: '081234567896', rental_name: 'Lembah Pinus Outdoor', total_amount: 175000, status: 'Proses', payment_method: 'QRIS', start_date: '2025-05-24T08:00:00Z', end_date: '2025-05-26T12:00:00Z', notes: 'Butuh extra nesting' },
          { id: 'TRX-20250523-008', created_at: '2025-05-23T09:45:00Z', user_name: 'Maya Sari', user_email: 'maya@gmail.com', user_phone: '081234567897', rental_name: 'Green Valley Glamping', total_amount: 275000, status: 'Selesai', payment_method: 'QRIS', start_date: '2025-05-24T08:00:00Z', end_date: '2025-05-26T17:00:00Z', notes: '-' }
        ]
        const matched = fallbackTransactions.find(t => t.id === id)
        if (matched) {
          finalData = {
            ...matched,
            owner_name: 'Mitra NatureRent'
          }
        }
      }
      
      setData(finalData)
      setLoading(false)
    }
    fetch()
  }, [id])

  useEffect(() => {
    if (data) {
      const timer = setTimeout(() => {
        window.print()
      }, 800)
      return () => clearTimeout(timer)
    }
  }, [data])

  if (loading) {
    return (
      <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', fontFamily: 'system-ui', color: '#64748b' }}>
        <p>Memuat invoice...</p>
      </div>
    )
  }

  if (!data) {
    return (
      <div style={{ display: 'flex', minHeight: '100vh', alignItems: 'center', justifyContent: 'center', fontFamily: 'system-ui', color: '#ef4444' }}>
        <p>Invoice tidak ditemukan.</p>
      </div>
    )
  }

  return (
    <div className="invoice-print-container">
      <style>{`
        body { font-family: 'Segoe UI', system-ui, -apple-system, sans-serif; padding: 40px; color: #1e293b; line-height: 1.5; background: #ffffff; margin: 0; }
        .invoice-card { max-width: 800px; margin: 0 auto; border: 1px solid #e2e8f0; padding: 40px; border-radius: 8px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05); }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #10b981; padding-bottom: 20px; margin-bottom: 30px; }
        .logo { font-size: 24px; font-weight: 800; color: #064429; display: flex; align-items: center; gap: 8px; }
        .title { font-size: 28px; font-weight: 700; color: #0f766e; }
        .meta-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 40px; }
        .meta-section h3 { font-size: 14px; text-transform: uppercase; color: #64748b; margin-bottom: 10px; border-bottom: 1px solid #f1f5f9; padding-bottom: 6px; font-weight: 700; }
        .meta-section p { margin: 4px 0; font-size: 14px; color: #334155; }
        .item-table { width: 100%; border-collapse: collapse; margin-bottom: 30px; }
        .item-table th { background: #f8fafc; border-bottom: 2px solid #cbd5e1; padding: 12px; text-align: left; font-size: 13px; font-weight: 700; color: #475569; }
        .item-table td { border-bottom: 1px solid #e2e8f0; padding: 12px; font-size: 14px; color: #334155; }
        .total-section { display: flex; justify-content: flex-end; font-size: 16px; font-weight: 700; margin-top: 20px; }
        .total-box { border-top: 2px solid #e2e8f0; padding-top: 10px; min-width: 240px; display: flex; justify-content: space-between; }
        .status-badge { display: inline-block; padding: 4px 12px; border-radius: 9999px; font-size: 12px; font-weight: 700; text-transform: uppercase; }
        .status-selesai { background: #dcfce7; color: #15803d; }
        .status-proses { background: #fef9c3; color: #a16207; }
        .status-ditolak { background: #fee2e2; color: #b91c1c; }
        .status-bermasalah { background: #fee2e2; color: #b91c1c; }
        .footer { text-align: center; margin-top: 60px; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; padding-top: 20px; }
        @media print {
          body { padding: 0; background: none; }
          .invoice-card { border: 0; box-shadow: none; padding: 0; max-width: 100%; }
        }
      `}</style>

      <div className="invoice-card">
        <div className="header">
          <div className="logo">🌲 NatureRent</div>
          <div className="title">INVOICE</div>
        </div>
        
        <div className="meta-grid">
          <div className="meta-section">
            <h3>Detail Transaksi</h3>
            <p><strong>ID Invoice:</strong> {data.id}</p>
            <p><strong>Tanggal Transaksi:</strong> {formatDate(data.created_at || data.transaction_date)}</p>
            <p><strong>Metode Pembayaran:</strong> {data.payment_method}</p>
            <p><strong>Status:</strong> <span className={`status-badge status-${(data.status || 'proses').toLowerCase()}`}>{data.status}</span></p>
          </div>
          <div className="meta-section">
            <h3>Informasi Penyewa</h3>
            <p><strong>Nama Penyewa:</strong> {data.user_name}</p>
            <p><strong>Email:</strong> {data.user_email}</p>
            <p><strong>Nomor HP:</strong> {data.user_phone}</p>
          </div>
        </div>

        <div className="meta-grid" style={{ marginBottom: '20px' }}>
          <div className="meta-section">
            <h3>Penyedia Rental</h3>
            <p><strong>Nama Rental:</strong> {data.rental_name}</p>
            <p><strong>Alamat:</strong> {data.alamat || '-'}</p>
          </div>
          <div className="meta-section">
            <h3>Periode Sewa</h3>
            <p><strong>Tanggal Mulai:</strong> {formatDate(data.start_date)}</p>
            <p><strong>Tanggal Selesai:</strong> {formatDate(data.end_date)}</p>
          </div>
        </div>

        <div className="meta-section" style={{ marginBottom: '30px' }}>
          <h3>Rincian Pembayaran</h3>
          <table className="item-table">
            <thead>
              <tr>
                <th>DESKRIPSI SEWA</th>
                <th style={{ textAlign: 'right' }}>TOTAL HARGA</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Sewa Alat Camping ({data.rental_name})<br /><small style={{ color: '#64748b' }}>Catatan: {data.notes}</small></td>
                <td style={{ textAlign: 'right', fontWeight: 600 }}>{formatCurrency(data.total_amount)}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div className="total-section">
          <div className="total-box">
            <span>Total Bayar:</span>
            <span style={{ color: '#0f766e', fontSize: '18px' }}>{formatCurrency(data.total_amount)}</span>
          </div>
        </div>

        <div className="footer">
          <p>Terima kasih telah menyewa peralatan outdoor ramah lingkungan melalui NatureRent.</p>
          <p>&copy; 2026 NatureRent. Grounded in nature.</p>
        </div>
      </div>
    </div>
  )
}

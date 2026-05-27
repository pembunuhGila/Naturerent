'use client'
import { useState, useEffect, useCallback, useRef } from 'react'
import Sidebar from '@/components/Sidebar'
import ConfirmModal from '@/components/ConfirmModal'
import Toast, { useToast } from '@/components/Toast'
import { createClient } from '@/lib/supabase'
import AuthGuard from '@/components/AuthGuard'

const DESTINATION_BUCKET = 'destinasi_wisata'
const PAGE_SIZE = 9
const MAP_ZOOM = 12
const TILE_SIZE = 256
const DEFAULT_MAP_CENTER = { lat: -7.7972, lng: 110.3688 }

function parseOptionalNumber(value) {
  if (value === '' || value === null || value === undefined) return null
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function getSupabaseErrorMessage(error) {
  if (!error) return 'Unknown error'
  return [error.message, error.details, error.hint, error.code]
    .filter(Boolean)
    .join(' | ')
}

function formatDate(value) {
  if (!value) return '-'
  return new Date(value).toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max)
}

function getValidCoordinate(latValue, lngValue) {
  const lat = parseOptionalNumber(latValue)
  const lng = parseOptionalNumber(lngValue)
  if (lat === null || lng === null) return null
  if (lat < -85 || lat > 85 || lng < -180 || lng > 180) return null
  return { lat, lng }
}

function latLngToPixel(lat, lng, zoom = MAP_ZOOM) {
  const scale = TILE_SIZE * (2 ** zoom)
  const clampedLat = clamp(lat, -85, 85)
  const sinLat = Math.sin((clampedLat * Math.PI) / 180)
  return {
    x: ((lng + 180) / 360) * scale,
    y: (0.5 - Math.log((1 + sinLat) / (1 - sinLat)) / (4 * Math.PI)) * scale,
  }
}

function pixelToLatLng(x, y, zoom = MAP_ZOOM) {
  const scale = TILE_SIZE * (2 ** zoom)
  const lng = (x / scale) * 360 - 180
  const n = Math.PI - (2 * Math.PI * y) / scale
  const lat = (180 / Math.PI) * Math.atan(Math.sinh(n))
  return {
    lat: clamp(lat, -85, 85),
    lng: clamp(lng, -180, 180),
  }
}

function SimpleMapPicker({ lat, lng, onPick }) {
  const mapRef = useRef(null)
  const [size, setSize] = useState({ width: 680, height: 260 })
  const selected = getValidCoordinate(lat, lng)
  const center = selected || DEFAULT_MAP_CENTER
  const centerPixel = latLngToPixel(center.lat, center.lng)
  const leftPixel = centerPixel.x - size.width / 2
  const topPixel = centerPixel.y - size.height / 2
  const firstTileX = Math.floor(leftPixel / TILE_SIZE)
  const lastTileX = Math.floor((leftPixel + size.width) / TILE_SIZE)
  const firstTileY = Math.floor(topPixel / TILE_SIZE)
  const lastTileY = Math.floor((topPixel + size.height) / TILE_SIZE)
  const tileCount = 2 ** MAP_ZOOM
  const tiles = []

  for (let x = firstTileX; x <= lastTileX; x += 1) {
    for (let y = firstTileY; y <= lastTileY; y += 1) {
      if (y < 0 || y >= tileCount) continue
      const wrappedX = ((x % tileCount) + tileCount) % tileCount
      tiles.push({
        key: `${x}-${y}`,
        x,
        y,
        url: `https://tile.openstreetmap.org/${MAP_ZOOM}/${wrappedX}/${y}.png`,
      })
    }
  }

  useEffect(() => {
    if (!mapRef.current) return undefined
    const element = mapRef.current
    const updateSize = () => {
      const rect = element.getBoundingClientRect()
      setSize({
        width: rect.width || 680,
        height: rect.height || 260,
      })
    }
    updateSize()
    const observer = new ResizeObserver(updateSize)
    observer.observe(element)
    return () => observer.disconnect()
  }, [])

  const handleClick = (event) => {
    const rect = event.currentTarget.getBoundingClientRect()
    const offsetX = event.clientX - rect.left
    const offsetY = event.clientY - rect.top
    const pickedPixelX = centerPixel.x + offsetX - rect.width / 2
    const pickedPixelY = centerPixel.y + offsetY - rect.height / 2
    const picked = pixelToLatLng(pickedPixelX, pickedPixelY)
    onPick(picked.lat.toFixed(7), picked.lng.toFixed(7))
  }

  const handleKeyDown = (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault()
      onPick(center.lat.toFixed(7), center.lng.toFixed(7))
    }
  }

  return (
    <div>
      <div
        ref={mapRef}
        onClick={handleClick}
        onKeyDown={handleKeyDown}
        role="button"
        tabIndex={0}
        aria-label="Pilih titik destinasi di peta"
        style={{
          position: 'relative',
          height: 260,
          width: '100%',
          overflow: 'hidden',
          borderRadius: 12,
          border: '1px solid var(--border-color)',
          background: 'var(--bg-secondary)',
          cursor: 'crosshair',
        }}
      >
        {tiles.map(tile => (
          <div
            key={tile.key}
            aria-hidden="true"
            style={{
              position: 'absolute',
              width: TILE_SIZE,
              height: TILE_SIZE,
              left: (tile.x * TILE_SIZE) - leftPixel,
              top: (tile.y * TILE_SIZE) - topPixel,
              backgroundImage: `url(${tile.url})`,
              backgroundSize: 'cover',
            }}
          />
        ))}
        <div
          aria-hidden="true"
          style={{
            position: 'absolute',
            inset: 0,
            pointerEvents: 'none',
            background:
              'linear-gradient(rgba(255,255,255,0.06) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.06) 1px, transparent 1px)',
            backgroundSize: '48px 48px',
          }}
        />
        <div
          aria-hidden="true"
          style={{
            position: 'absolute',
            left: '50%',
            top: '50%',
            transform: 'translate(-50%, -100%)',
            color: 'var(--accent-red)',
            fontSize: 34,
            textShadow: '0 2px 10px rgba(0,0,0,0.45)',
            pointerEvents: 'none',
          }}
        >
          <i className="fa-solid fa-location-dot" />
        </div>
        <div
          style={{
            position: 'absolute',
            left: 12,
            bottom: 12,
            padding: '6px 10px',
            borderRadius: 999,
            background: 'rgba(0,0,0,0.58)',
            color: '#fff',
            fontSize: 11,
            pointerEvents: 'none',
          }}
        >
          Klik peta untuk memilih titik
        </div>
      </div>
      <p style={{ marginTop: 7, fontSize: 11, color: 'var(--text-muted)' }}>
        Tiles © OpenStreetMap contributors. Marker berada di tengah peta sesuai lat/lng yang dipilih.
      </p>
    </div>
  )
}

function DestinationFormModal({
  initialData,
  saving,
  onClose,
  onSubmit,
}) {
  const [form, setForm] = useState({
    nama: initialData?.nama || '',
    kategori: initialData?.kategori || '',
    deskripsi: initialData?.deskripsi || '',
    lat: initialData?.lat ?? '',
    lng: initialData?.lng ?? '',
    foto_url: initialData?.foto_url || '',
  })
  const [imageFile, setImageFile] = useState(null)
  const [previewUrl, setPreviewUrl] = useState(initialData?.foto_url || '')
  const [geocoding, setGeocoding] = useState(false)
  const [geocodeResult, setGeocodeResult] = useState('')

  useEffect(() => {
    return () => {
      if (previewUrl?.startsWith('blob:')) URL.revokeObjectURL(previewUrl)
    }
  }, [previewUrl])

  const handleChange = (field, value) => {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  const handleImageChange = (event) => {
    const file = event.target.files?.[0]
    if (!file) return
    if (previewUrl?.startsWith('blob:')) URL.revokeObjectURL(previewUrl)
    setImageFile(file)
    setPreviewUrl(URL.createObjectURL(file))
  }

  const handleMapPick = (lat, lng) => {
    setForm(prev => ({ ...prev, lat, lng }))
    setGeocodeResult('Koordinat diperbarui dari titik peta.')
  }

  const handleFindCoordinates = async () => {
    const keyword = [form.nama, form.kategori, 'Indonesia']
      .map(value => value?.trim())
      .filter(Boolean)
      .join(', ')

    if (!keyword) {
      setGeocodeResult('Isi nama atau kategori destinasi terlebih dahulu.')
      return
    }

    setGeocoding(true)
    setGeocodeResult('')
    try {
      const params = new URLSearchParams({
        q: keyword,
        format: 'jsonv2',
        limit: '1',
        addressdetails: '1',
        countrycodes: 'id',
        'accept-language': 'id',
      })
      const response = await fetch(`https://nominatim.openstreetmap.org/search?${params.toString()}`)
      if (!response.ok) throw new Error('OpenStreetMap tidak merespons.')

      const results = await response.json()
      const first = Array.isArray(results) ? results[0] : null
      if (!first?.lat || !first?.lon) {
        setGeocodeResult('Koordinat tidak ditemukan. Coba masukkan nama destinasi lebih spesifik.')
        return
      }

      setForm(prev => ({
        ...prev,
        lat: Number(first.lat).toFixed(7),
        lng: Number(first.lon).toFixed(7),
      }))
      setGeocodeResult(first.display_name || 'Koordinat berhasil ditemukan.')
    } catch (error) {
      setGeocodeResult('Gagal mengambil koordinat: ' + error.message)
    } finally {
      setGeocoding(false)
    }
  }

  const handleSubmit = (event) => {
    event.preventDefault()
    onSubmit(form, imageFile)
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div
        className="modal-box"
        onClick={e => e.stopPropagation()}
        style={{ maxWidth: 760, maxHeight: '92vh', overflowY: 'auto' }}
      >
        <div className="modal-header">
          <div className="modal-icon warning">
            <i className="fa-solid fa-mountain-sun" />
          </div>
          <div>
            <div className="modal-title">
              {initialData ? 'Edit Destinasi Wisata' : 'Tambah Destinasi Wisata'}
            </div>
            <div className="modal-desc">
              Destinasi ini akan tampil di halaman user NatureRent.
            </div>
          </div>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-row">
            <div className="form-group">
              <label className="form-label">Nama Destinasi</label>
              <input
                className="form-input"
                value={form.nama}
                onChange={e => handleChange('nama', e.target.value)}
                placeholder="Masukkan nama destinasi"
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Kategori</label>
              <input
                className="form-input"
                value={form.kategori}
                onChange={e => handleChange('kategori', e.target.value)}
                placeholder="Masukkan kategori destinasi, misal Gunung atau Pantai"
                required
              />
            </div>
          </div>

          <div className="form-group">
            <button
              type="button"
              className="btn btn-ghost"
              onClick={handleFindCoordinates}
              disabled={geocoding}
            >
              {geocoding ? (
                <>
                  <span className="loading-spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
                  Mencari koordinat...
                </>
              ) : (
                <>
                  <i className="fa-solid fa-location-crosshairs" />
                  Ambil Lat/Lng dari OpenStreetMap
                </>
              )}
            </button>
            <p style={{ marginTop: 8, fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.5 }}>
              Kategori dipakai sebagai label destinasi dan kata kunci bantu saat mengambil koordinat dari OpenStreetMap/Nominatim.
            </p>
            {geocodeResult && (
              <p style={{ marginTop: 6, fontSize: 12, color: 'var(--brand-emerald)', lineHeight: 1.5 }}>
                {geocodeResult}
              </p>
            )}
          </div>

          <div className="form-group">
            <label className="form-label">Gambar</label>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '180px 1fr',
                gap: 16,
                alignItems: 'center',
              }}
            >
              <div
                style={{
                  width: 180,
                  aspectRatio: '16 / 10',
                  borderRadius: 12,
                  overflow: 'hidden',
                  background: 'var(--bg-secondary)',
                  border: '1px solid var(--border-color)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: 'var(--text-muted)',
                }}
              >
                {previewUrl ? (
                  <img
                    src={previewUrl}
                    alt="Preview destinasi"
                    style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                  />
                ) : (
                  <i className="fa-solid fa-image" style={{ fontSize: 28 }} />
                )}
              </div>
              <div>
                <label className="btn btn-ghost" style={{ display: 'inline-flex' }}>
                  <i className="fa-solid fa-upload" />
                  Upload Gambar Destinasi
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleImageChange}
                    style={{ display: 'none' }}
                  />
                </label>
                <p style={{ marginTop: 8, fontSize: 12, color: 'var(--text-secondary)' }}>
                  {imageFile ? imageFile.name : 'Gunakan gambar JPG, PNG, atau WebP.'}
                </p>
              </div>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Deskripsi</label>
            <textarea
              className="form-textarea"
              value={form.deskripsi}
              onChange={e => handleChange('deskripsi', e.target.value)}
              placeholder="Masukkan deskripsi destinasi"
              required
              rows={4}
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label className="form-label">Latitude</label>
              <input
                className="form-input"
                type="number"
                step="any"
                value={form.lat}
                onChange={e => handleChange('lat', e.target.value)}
                placeholder="Otomatis dari OpenStreetMap"
              />
            </div>

            <div className="form-group">
              <label className="form-label">Longitude</label>
              <input
                className="form-input"
                type="number"
                step="any"
                value={form.lng}
                onChange={e => handleChange('lng', e.target.value)}
                placeholder="Otomatis dari OpenStreetMap"
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Pilih Titik di Peta</label>
            <SimpleMapPicker
              lat={form.lat}
              lng={form.lng}
              onPick={handleMapPick}
            />
          </div>

          <p style={{ marginTop: -8, fontSize: 11, color: 'var(--text-muted)', lineHeight: 1.5 }}>
            Latitude/longitude bisa diisi manual, diambil otomatis dari OpenStreetMap, atau dipilih langsung dari peta. Data lokasi dari OpenStreetMap contributors.
          </p>

          <div className="modal-actions">
            <button type="button" className="btn btn-ghost" onClick={onClose} disabled={saving}>
              Batal
            </button>
            <button type="submit" className="btn btn-primary" disabled={saving}>
              {saving ? (
                <>
                  <span className="loading-spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
                  Menyimpan...
                </>
              ) : (
                <>
                  <i className="fa-solid fa-floppy-disk" />
                  Simpan Destinasi
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default function DestinasiWisataPage() {
  const { toasts, addToast, removeToast } = useToast()
  const [userEmail, setUserEmail] = useState('')
  const [destinations, setDestinations] = useState([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')
  const [appliedSearch, setAppliedSearch] = useState('')
  const [page, setPage] = useState(1)
  const [totalCount, setTotalCount] = useState(0)
  const [formTarget, setFormTarget] = useState(null)
  const [isFormOpen, setIsFormOpen] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleteLoading, setDeleteLoading] = useState(false)

  const fetchDestinations = useCallback(async (searchTerm = '', currentPage = 1) => {
    setLoading(true)
    const supabase = createClient()
    const from = (currentPage - 1) * PAGE_SIZE
    const to = from + PAGE_SIZE - 1

    let query = supabase
      .from('wisata_locations')
      .select('id, nama, deskripsi, foto_url, kategori, lat, lng, created_at', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to)

    if (searchTerm) {
      query = query.or(`nama.ilike.%${searchTerm}%,kategori.ilike.%${searchTerm}%,deskripsi.ilike.%${searchTerm}%`)
    }

    const { data, error, count } = await query
    if (error) {
      addToast('Gagal memuat destinasi: ' + error.message, 'error')
    } else {
      setDestinations(data || [])
      setTotalCount(count || 0)
    }
    setLoading(false)
  }, [addToast])

  useEffect(() => {
    const init = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      setUserEmail(user?.email || '')
    }
    init()
  }, [])

  useEffect(() => {
    const timer = setTimeout(() => {
      fetchDestinations(appliedSearch, page)
    }, 0)
    return () => clearTimeout(timer)
  }, [appliedSearch, fetchDestinations, page])

  const openCreateForm = () => {
    setFormTarget(null)
    setIsFormOpen(true)
  }

  const openEditForm = (destination) => {
    setFormTarget(destination)
    setIsFormOpen(true)
  }

  const closeForm = () => {
    if (saving) return
    setIsFormOpen(false)
    setFormTarget(null)
  }

  const uploadImage = async (file) => {
    if (!file) return null
    const supabase = createClient()
    const extension = file.name.split('.').pop()?.toLowerCase() || 'jpg'
    const safeExtension = ['jpg', 'jpeg', 'png', 'webp'].includes(extension) ? extension : 'jpg'
    const path = `destinations/${Date.now()}-${Math.random().toString(36).slice(2)}.${safeExtension}`

    const { error } = await supabase.storage
      .from(DESTINATION_BUCKET)
      .upload(path, file, {
        cacheControl: '3600',
        upsert: false,
        contentType: file.type || 'image/jpeg',
      })

    if (error) {
      throw new Error(`Upload gambar gagal: ${getSupabaseErrorMessage(error)}`)
    }
    const { data } = supabase.storage.from(DESTINATION_BUCKET).getPublicUrl(path)
    return data.publicUrl
  }

  const handleSubmit = async (form, imageFile) => {
    const nama = form.nama.trim()
    const kategori = form.kategori.trim()
    const deskripsi = form.deskripsi.trim()

    if (!nama || !kategori || !deskripsi) {
      addToast('Nama, kategori, dan deskripsi wajib diisi.', 'error')
      return
    }
    if (!formTarget && !imageFile) {
      addToast('Gambar destinasi wajib diupload.', 'error')
      return
    }

    setSaving(true)
    try {
      const supabase = createClient()
      const uploadedUrl = imageFile ? await uploadImage(imageFile) : null
      const payload = {
        nama,
        kategori,
        deskripsi,
        foto_url: uploadedUrl || formTarget?.foto_url || form.foto_url || null,
        lat: parseOptionalNumber(form.lat),
        lng: parseOptionalNumber(form.lng),
      }

      const query = formTarget
        ? supabase
            .from('wisata_locations')
            .update(payload)
            .eq('id', formTarget.id)
            .select('id, nama, deskripsi, foto_url, kategori, lat, lng, created_at')
            .single()
        : supabase
            .from('wisata_locations')
            .insert(payload)
            .select('id, nama, deskripsi, foto_url, kategori, lat, lng, created_at')
            .single()

      const { data: savedDestination, error } = await query
      if (error) {
        throw new Error(`Simpan database gagal: ${getSupabaseErrorMessage(error)}`)
      }

      addToast(formTarget ? 'Destinasi berhasil diperbarui.' : 'Destinasi berhasil ditambahkan.', 'success')
      setIsFormOpen(false)
      setFormTarget(null)
      setDestinations(prev => {
        if (!savedDestination) return prev
        if (formTarget) {
          return prev.map(item =>
            item.id === savedDestination.id ? savedDestination : item
          )
        }
        return [savedDestination, ...prev].slice(0, PAGE_SIZE)
      })
      fetchDestinations(appliedSearch, page)
    } catch (error) {
      console.error('Gagal menyimpan destinasi:', error)
      addToast('Gagal menyimpan destinasi: ' + error.message, 'error')
    } finally {
      setSaving(false)
    }
  }

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return
    setDeleteLoading(true)
    const supabase = createClient()
    const { error } = await supabase
      .from('wisata_locations')
      .delete()
      .eq('id', deleteTarget.id)

    setDeleteLoading(false)
    if (error) {
      addToast('Gagal menghapus destinasi: ' + error.message, 'error')
    } else {
      addToast(`Destinasi "${deleteTarget.nama}" berhasil dihapus.`, 'success')
      setDeleteTarget(null)
      fetchDestinations(appliedSearch, page)
    }
  }

  const handleSearch = (event) => {
    event.preventDefault()
    setPage(1)
    setAppliedSearch(search)
  }

  const handleManualRefresh = () => {
    fetchDestinations(appliedSearch, page)
  }

  const totalPages = Math.ceil(totalCount / PAGE_SIZE)

  return (
    <AuthGuard>
      <div className="dashboard-container">
        <Sidebar userEmail={userEmail} />
        <main className="main-content">
          <header className="top-header">
            <div>
              <h1>Destinasi Wisata</h1>
              <p className="header-subtitle">Kelola destinasi wisata yang tampil di aplikasi user NatureRent.</p>
            </div>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <button className="btn btn-ghost" onClick={handleManualRefresh}>
                <i className="fa-solid fa-rotate-right" />
                Refresh
              </button>
              <button className="btn btn-primary" onClick={openCreateForm}>
                <i className="fa-solid fa-plus" />
                Tambah Destinasi
              </button>
            </div>
          </header>

          <section className="content-section">
            <form className="filter-bar" onSubmit={handleSearch}>
              <div className="search-box">
                <i className="fa-solid fa-magnifying-glass search-icon" />
                <input
                  type="text"
                  placeholder="Cari nama, kategori, atau deskripsi destinasi..."
                  value={search}
                  onChange={e => setSearch(e.target.value)}
                />
              </div>
              <div className="filter-controls">
                <button type="submit" className="filter-btn">
                  <i className="fa-solid fa-magnifying-glass" /> Cari
                </button>
              </div>
            </form>

            {loading ? (
              <div className="table-wrapper">
                <div className="loading-state">
                  <div className="loading-spinner" />
                  <span>Memuat data destinasi...</span>
                </div>
              </div>
            ) : destinations.length === 0 ? (
              <div className="table-wrapper">
                <div className="empty-state">
                  <i className="fa-solid fa-mountain-sun empty-icon" />
                  <p>Tidak ada destinasi wisata ditemukan.</p>
                </div>
              </div>
            ) : (
              <>
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
                    gap: 16,
                  }}
                >
                  {destinations.map(destination => (
                    <article
                      key={destination.id}
                      style={{
                        background: 'var(--bg-card)',
                        border: '1px solid var(--border-color)',
                        borderRadius: 'var(--border-radius)',
                        overflow: 'hidden',
                        display: 'flex',
                        flexDirection: 'column',
                      }}
                    >
                      <div
                        style={{
                          aspectRatio: '16 / 10',
                          background: 'var(--bg-secondary)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: 'var(--text-muted)',
                        }}
                      >
                        {destination.foto_url ? (
                          <img
                            src={destination.foto_url}
                            alt={destination.nama}
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                          />
                        ) : (
                          <i className="fa-solid fa-image" style={{ fontSize: 30 }} />
                        )}
                      </div>
                      <div style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 10, flex: 1 }}>
                        <div>
                          <h3 style={{ fontSize: 16, margin: 0, color: 'var(--text-primary)' }}>
                            {destination.nama}
                          </h3>
                          <p style={{ margin: '4px 0 0', fontSize: 12, color: 'var(--text-secondary)', display: 'flex', alignItems: 'center', gap: 6 }}>
                            <i className="fa-solid fa-location-dot" style={{ color: 'var(--accent-red)' }} />
                            {destination.kategori || '-'}
                          </p>
                        </div>
                        <p
                          style={{
                            margin: 0,
                            color: 'var(--text-secondary)',
                            fontSize: 13,
                            lineHeight: 1.5,
                            display: '-webkit-box',
                            WebkitLineClamp: 3,
                            WebkitBoxOrient: 'vertical',
                            overflow: 'hidden',
                          }}
                        >
                          {destination.deskripsi || '-'}
                        </p>
                        <div
                          style={{
                            display: 'grid',
                            gridTemplateColumns: '1fr 1fr',
                            gap: 8,
                            fontSize: 11,
                            color: 'var(--text-secondary)',
                          }}
                        >
                          <span
                            style={{
                              padding: '7px 8px',
                              borderRadius: 8,
                              background: 'var(--bg-secondary)',
                              border: '1px solid var(--border-color-light)',
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            Lat: {destination.lat ?? '-'}
                          </span>
                          <span
                            style={{
                              padding: '7px 8px',
                              borderRadius: 8,
                              background: 'var(--bg-secondary)',
                              border: '1px solid var(--border-color-light)',
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            Lng: {destination.lng ?? '-'}
                          </span>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, marginTop: 'auto' }}>
                          <span className="badge badge-success">
                            <i className="fa-solid fa-calendar" />
                            {formatDate(destination.created_at)}
                          </span>
                          <div className="action-cell">
                            <button
                              className="action-btn edit-btn"
                              title="Edit"
                              onClick={() => openEditForm(destination)}
                            >
                              <i className="fa-solid fa-pen" />
                            </button>
                            <button
                              className="action-btn delete-btn"
                              title="Hapus"
                              onClick={() => setDeleteTarget(destination)}
                            >
                              <i className="fa-solid fa-trash" />
                            </button>
                          </div>
                        </div>
                      </div>
                    </article>
                  ))}
                </div>

                {totalCount > 0 && (
                  <div className="pagination-section" style={{ background: 'var(--bg-card)', border: '1px solid var(--border-color)', borderRadius: 'var(--border-radius)' }}>
                    <p className="pagination-info">
                      Menampilkan {((page - 1) * PAGE_SIZE) + 1}-{Math.min(page * PAGE_SIZE, totalCount)} dari {totalCount} destinasi
                    </p>
                    <div className="pagination">
                      <button className="pagination-btn" disabled={page <= 1} onClick={() => setPage(p => p - 1)}>
                        <i className="fa-solid fa-chevron-left" />
                      </button>
                      {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i + 1).map(p => (
                        <button key={p} className={`pagination-btn ${p === page ? 'active' : ''}`} onClick={() => setPage(p)}>
                          {p}
                        </button>
                      ))}
                      <button className="pagination-btn" disabled={page >= totalPages} onClick={() => setPage(p => p + 1)}>
                        <i className="fa-solid fa-chevron-right" />
                      </button>
                    </div>
                  </div>
                )}
              </>
            )}
          </section>
        </main>

        {isFormOpen && (
          <DestinationFormModal
            key={formTarget?.id || 'create'}
            initialData={formTarget}
            saving={saving}
            onClose={closeForm}
            onSubmit={handleSubmit}
          />
        )}

        <ConfirmModal
          isOpen={!!deleteTarget}
          onClose={() => setDeleteTarget(null)}
          onConfirm={handleDeleteConfirm}
          isLoading={deleteLoading}
          title="Hapus Destinasi Wisata"
          description={`Apakah Anda yakin ingin menghapus "${deleteTarget?.nama}"? Destinasi ini tidak akan tampil lagi ke user.`}
          confirmLabel="Hapus Destinasi"
        />

        <Toast toasts={toasts} onRemove={removeToast} />
      </div>
    </AuthGuard>
  )
}

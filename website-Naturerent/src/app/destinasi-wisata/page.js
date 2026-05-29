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
const DESTINATION_IMAGE_ASPECT = 3 / 4
const DESTINATION_IMAGE_WIDTH = 900
const DESTINATION_IMAGE_HEIGHT = 1200

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

function loadImageFromFile(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file)
    const image = new Image()
    image.onload = () => {
      URL.revokeObjectURL(url)
      resolve(image)
    }
    image.onerror = () => {
      URL.revokeObjectURL(url)
      reject(new Error('Gambar tidak bisa diproses.'))
    }
    image.src = url
  })
}

async function createCroppedDestinationImage(file, crop) {
  if (!file) return null

  const image = await loadImageFromFile(file)
  const imageAspect = image.naturalWidth / image.naturalHeight
  let sourceWidth
  let sourceHeight

  if (imageAspect > DESTINATION_IMAGE_ASPECT) {
    sourceHeight = image.naturalHeight
    sourceWidth = sourceHeight * DESTINATION_IMAGE_ASPECT
  } else {
    sourceWidth = image.naturalWidth
    sourceHeight = sourceWidth / DESTINATION_IMAGE_ASPECT
  }

  const zoom = clamp(Number(crop.zoom) || 1, 1, 3)
  sourceWidth /= zoom
  sourceHeight /= zoom

  const centerX = image.naturalWidth * (clamp(Number(crop.x) || 50, 0, 100) / 100)
  const centerY = image.naturalHeight * (clamp(Number(crop.y) || 50, 0, 100) / 100)
  const sourceX = clamp(centerX - sourceWidth / 2, 0, image.naturalWidth - sourceWidth)
  const sourceY = clamp(centerY - sourceHeight / 2, 0, image.naturalHeight - sourceHeight)

  const canvas = document.createElement('canvas')
  canvas.width = DESTINATION_IMAGE_WIDTH
  canvas.height = DESTINATION_IMAGE_HEIGHT
  const context = canvas.getContext('2d')
  context.drawImage(
    image,
    sourceX,
    sourceY,
    sourceWidth,
    sourceHeight,
    0,
    0,
    DESTINATION_IMAGE_WIDTH,
    DESTINATION_IMAGE_HEIGHT
  )

  const blob = await new Promise((resolve, reject) => {
    canvas.toBlob(
      result => result ? resolve(result) : reject(new Error('Gagal memangkas gambar.')),
      'image/jpeg',
      0.9
    )
  })

  return new File([blob], file.name.replace(/\.[^.]+$/, '') + '-3x4.jpg', {
    type: 'image/jpeg',
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

function ImageCropper({ previewUrl, crop, onCropChange }) {
  const [dragging, setDragging] = useState(false)
  const dragRef = useRef(null)

  const updateCrop = (nextCrop) => {
    onCropChange({
      zoom: clamp(nextCrop.zoom, 1, 3),
      x: clamp(nextCrop.x, 0, 100),
      y: clamp(nextCrop.y, 0, 100),
    })
  }

  const handlePointerDown = (event) => {
    event.currentTarget.setPointerCapture(event.pointerId)
    dragRef.current = {
      startX: event.clientX,
      startY: event.clientY,
      crop,
    }
    setDragging(true)
  }

  const handlePointerMove = (event) => {
    if (!dragging || !dragRef.current) return
    const rect = event.currentTarget.getBoundingClientRect()
    const deltaX = event.clientX - dragRef.current.startX
    const deltaY = event.clientY - dragRef.current.startY
    const zoom = Math.max(dragRef.current.crop.zoom, 1)
    updateCrop({
      ...dragRef.current.crop,
      x: dragRef.current.crop.x - (deltaX / rect.width) * (100 / zoom),
      y: dragRef.current.crop.y - (deltaY / rect.height) * (100 / zoom),
    })
  }

  const handlePointerUp = () => {
    dragRef.current = null
    setDragging(false)
  }

  const handleKeyDown = (event) => {
    const step = event.shiftKey ? 5 : 1
    if (event.key === 'ArrowLeft') updateCrop({ ...crop, x: crop.x - step })
    if (event.key === 'ArrowRight') updateCrop({ ...crop, x: crop.x + step })
    if (event.key === 'ArrowUp') updateCrop({ ...crop, y: crop.y - step })
    if (event.key === 'ArrowDown') updateCrop({ ...crop, y: crop.y + step })
  }

  return (
    <div
      onPointerDown={handlePointerDown}
      onPointerMove={handlePointerMove}
      onPointerUp={handlePointerUp}
      onPointerCancel={handlePointerUp}
      onKeyDown={handleKeyDown}
      role="button"
      tabIndex={0}
      aria-label="Geser gambar untuk mengatur area pangkas"
      style={{
        width: 190,
        aspectRatio: '3 / 4',
        borderRadius: 12,
        overflow: 'hidden',
        background: 'var(--bg-secondary)',
        border: '1px solid var(--border-color)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: 'var(--text-muted)',
        position: 'relative',
        cursor: dragging ? 'grabbing' : 'grab',
        touchAction: 'none',
        userSelect: 'none',
      }}
    >
      {previewUrl ? (
        <>
          <img
            src={previewUrl}
            alt="Preview destinasi"
            draggable={false}
            style={{
              width: '100%',
              height: '100%',
              objectFit: 'cover',
              objectPosition: `${crop.x}% ${crop.y}%`,
              transform: `scale(${crop.zoom})`,
              transformOrigin: `${crop.x}% ${crop.y}%`,
              pointerEvents: 'none',
            }}
          />
          <div
            aria-hidden="true"
            style={{
              position: 'absolute',
              inset: 10,
              border: '1px solid rgba(255,255,255,0.72)',
              boxShadow: '0 0 0 999px rgba(0,0,0,0.14)',
              pointerEvents: 'none',
            }}
          />
          <div
            style={{
              position: 'absolute',
              left: 10,
              right: 10,
              bottom: 10,
              padding: '6px 8px',
              borderRadius: 8,
              background: 'rgba(0,0,0,0.58)',
              color: '#fff',
              fontSize: 10,
              textAlign: 'center',
              pointerEvents: 'none',
            }}
          >
            Geser foto untuk pangkas
          </div>
        </>
      ) : (
        <i className="fa-solid fa-image" style={{ fontSize: 28 }} />
      )}
    </div>
  )
}

function DestinationFormModal({
  initialData,
  categories,
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
  const [crop, setCrop] = useState({ zoom: 1, x: 50, y: 50 })
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
    setCrop({ zoom: 1, x: 50, y: 50 })
    setPreviewUrl(URL.createObjectURL(file))
  }

  const handleCropChange = (field, value) => {
    setCrop(prev => ({ ...prev, [field]: Number(value) }))
  }

  const handleCropDrag = (nextCrop) => {
    setCrop(nextCrop)
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

  const handleSubmit = async (event) => {
    event.preventDefault()
    try {
      const croppedImage = imageFile
        ? await createCroppedDestinationImage(imageFile, crop)
        : null
      await onSubmit(form, croppedImage)
    } catch (error) {
      setGeocodeResult('Gagal memangkas gambar: ' + error.message)
    }
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
              {categories.length > 0 ? (
                <select
                  className="form-input"
                  value={form.kategori}
                  onChange={e => handleChange('kategori', e.target.value)}
                  required
                  style={{ appearance: 'none', backgroundImage: 'none' }}
                >
                  <option value="">Pilih kategori destinasi</option>
                  {categories.map(kategori => (
                    <option key={kategori} value={kategori}>{kategori}</option>
                  ))}
                  {form.kategori && !categories.includes(form.kategori) && (
                    <option value={form.kategori}>{form.kategori} (dipilih)</option>
                  )}
                </select>
              ) : (
                <input
                  className="form-input"
                  value={form.kategori}
                  onChange={e => handleChange('kategori', e.target.value)}
                  placeholder="Masukkan kategori destinasi, misal Gunung atau Pantai"
                  required
                />
              )}
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
                gridTemplateColumns: '190px 1fr',
                gap: 16,
                alignItems: 'start',
              }}
            >
              <ImageCropper
                previewUrl={previewUrl}
                crop={crop}
                onCropChange={handleCropDrag}
              />
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
                  {imageFile ? imageFile.name : 'Gunakan gambar JPG, PNG, atau WebP. Semua gambar disimpan rasio 3:4.'}
                </p>
                {imageFile && (
                  <div
                    style={{
                      marginTop: 14,
                      display: 'grid',
                      gap: 10,
                      maxWidth: 360,
                    }}
                  >
                    <div>
                      <label className="form-label" style={{ marginBottom: 4 }}>
                        Zoom Pangkas
                      </label>
                      <input
                        type="range"
                        min="1"
                        max="3"
                        step="0.05"
                        value={crop.zoom}
                        onChange={e => handleCropChange('zoom', e.target.value)}
                        style={{ width: '100%' }}
                      />
                    </div>
                    <p style={{ margin: 0, fontSize: 12, color: 'var(--text-secondary)' }}>
                      Geser gambar pada preview untuk menentukan area pangkas.
                    </p>
                  </div>
                )}
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
  const [categories, setCategories] = useState([])
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleteLoading, setDeleteLoading] = useState(false)

  const fetchCategories = useCallback(async () => {
    const supabase = createClient()
    const { data, error } = await supabase
      .from('wisata_locations')
      .select('kategori')
      .neq('kategori', 'QRIS')
      .not('kategori', 'is', null)
      .order('kategori', { ascending: true })

    if (error) {
      addToast('Gagal memuat daftar kategori: ' + error.message, 'error')
      return
    }

    const uniqueCategories = Array.from(
      new Set(
        (data || [])
          .map(item => (item.kategori || '').trim())
          .filter(Boolean)
      )
    )

    setCategories(uniqueCategories)
  }, [addToast])

  const fetchDestinations = useCallback(async (searchTerm = '', currentPage = 1) => {
    setLoading(true)
    const supabase = createClient()
    const from = (currentPage - 1) * PAGE_SIZE
    const to = from + PAGE_SIZE - 1

    let query = supabase
      .from('wisata_locations')
      .select('id, nama, deskripsi, foto_url, kategori, lat, lng, created_at', { count: 'exact' })
      .neq('kategori', 'QRIS')
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
      await fetchCategories()
    }
    init()
  }, [fetchCategories])

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
      await fetchCategories()
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
      <style dangerouslySetInnerHTML={{ __html: `
        .destination-card {
          background: var(--bg-card);
          border: 1px solid var(--border-color);
          border-radius: var(--border-radius);
          overflow: hidden;
          display: flex;
          flex-direction: column;
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          position: relative;
        }
        .destination-card:hover {
          transform: translateY(-6px);
          border-color: var(--brand-green);
          box-shadow: 0 16px 36px rgba(31, 90, 63, 0.08);
        }
        .destination-img-container {
          position: relative;
          aspect-ratio: 16 / 11;
          background: var(--bg-secondary);
          overflow: hidden;
          border-bottom: 1px solid var(--border-color-light);
        }
        .destination-img {
          width: 100%;
          height: 100%;
          object-fit: cover;
          transition: transform 0.5s ease;
        }
        .destination-card:hover .destination-img {
          transform: scale(1.06);
        }
        .destination-category-badge {
          position: absolute;
          top: 12px;
          left: 12px;
          padding: 6px 14px;
          border-radius: 20px;
          background: var(--brand-green);
          color: #ffffff;
          font-size: 11px;
          font-weight: 700;
          box-shadow: 0 4px 12px rgba(0,0,0,0.15);
          display: flex;
          align-items: center;
          gap: 6px;
          z-index: 5;
          letter-spacing: 0.3px;
        }
        .destination-content {
          padding: 20px;
          display: flex;
          flex-direction: column;
          gap: 12px;
          flex: 1;
        }
        .destination-title {
          font-size: 15px;
          font-weight: 700;
          margin: 0;
          color: var(--text-primary);
          line-height: 1.35;
        }
        .destination-desc {
          margin: 0;
          color: var(--text-secondary);
          font-size: 13px;
          line-height: 1.6;
          display: -webkit-box;
          -webkit-line-clamp: 3;
          -webkit-box-orient: vertical;
          overflow: hidden;
          min-height: 3.9rem;
        }
        .destination-meta-row {
          display: flex;
          align-items: center;
          gap: 6px;
          font-size: 12px;
          color: var(--text-secondary);
          background: var(--bg-secondary);
          padding: 8px 12px;
          border-radius: 8px;
          border: 1px solid var(--border-color-light);
        }
        .destination-footer {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 10px;
          margin-top: auto;
          padding-top: 14px;
          border-top: 1px solid var(--border-color-light);
        }
      `}} />

      <div className="dashboard-container">
        <Sidebar userEmail={userEmail} />
        <main className="main-content">
          <header className="top-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 20 }}>
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
                    gridTemplateColumns: 'repeat(auto-fill, minmax(310px, 1fr))',
                    gap: 20,
                  }}
                >
                  {destinations.map(destination => {
                    const isGunung = (destination.kategori || '').toLowerCase().includes('gunung');
                    const isPantai = (destination.kategori || '').toLowerCase().includes('pantai');
                    const categoryIcon = isGunung ? 'fa-mountain' : isPantai ? 'fa-umbrella-beach' : 'fa-map-location-dot';

                    return (
                      <article key={destination.id} className="destination-card">
                        <div className="destination-img-container">
                          <div className="destination-category-badge">
                            <i className={`fa-solid ${categoryIcon}`} />
                            <span>{destination.kategori || 'Wisata'}</span>
                          </div>
                          {destination.foto_url ? (
                            <img
                              src={destination.foto_url}
                              alt={destination.nama}
                              className="destination-img"
                            />
                          ) : (
                            <div style={{ display: 'flex', width: '100%', height: '100%', alignItems: 'center', justifyContent: 'center', color: 'var(--text-muted)' }}>
                              <i className="fa-solid fa-image" style={{ fontSize: 32 }} />
                            </div>
                          )}
                        </div>
                        <div className="destination-content">
                          <div>
                            <h3 className="destination-title">{destination.nama}</h3>
                          </div>
                          <p className="destination-desc">
                            {destination.deskripsi || 'Tidak ada deskripsi.'}
                          </p>

                          <div className="destination-footer">
                            <span className="badge badge-success" style={{ padding: '6px 12px', gap: 6, fontSize: '0.74rem' }}>
                              <i className="fa-solid fa-calendar" />
                              {formatDate(destination.created_at)}
                            </span>
                            <div className="action-cell">
                              <button
                                className="action-btn edit-btn"
                                title="Edit"
                                onClick={() => openEditForm(destination)}
                                style={{ borderRadius: 6 }}
                              >
                                <i className="fa-solid fa-pen" />
                              </button>
                              <button
                                className="action-btn delete-btn"
                                title="Hapus"
                                onClick={() => setDeleteTarget(destination)}
                                style={{ borderRadius: 6 }}
                              >
                                <i className="fa-solid fa-trash" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </article>
                    );
                  })}
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
            categories={categories}
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

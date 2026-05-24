'use client'
import { useEffect } from 'react'

export default function ConfirmModal({ isOpen, onClose, onConfirm, title, description, confirmLabel = 'Hapus', isLoading = false }) {
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = ''
    }
    return () => { document.body.style.overflow = '' }
  }, [isOpen])

  if (!isOpen) return null

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-box" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <div className="modal-icon danger">
            <i className="fa-solid fa-triangle-exclamation" />
          </div>
          <div>
            <div className="modal-title">{title}</div>
            <div className="modal-desc">{description}</div>
          </div>
        </div>

        <div className="modal-actions">
          <button className="btn btn-ghost" onClick={onClose} disabled={isLoading}>
            Batal
          </button>
          <button className="btn btn-danger" onClick={onConfirm} disabled={isLoading}>
            {isLoading ? (
              <>
                <span className="loading-spinner" style={{ width: 14, height: 14, borderWidth: 2 }} />
                Memproses...
              </>
            ) : (
              <>
                <i className="fa-solid fa-trash" />
                {confirmLabel}
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  )
}

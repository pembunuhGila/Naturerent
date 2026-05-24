'use client'
import { useState, useCallback } from 'react'

let toastIdCounter = 0

export function useToast() {
  const [toasts, setToasts] = useState([])

  const addToast = useCallback((message, type = 'success') => {
    const id = ++toastIdCounter
    setToasts(prev => [...prev, { id, message, type }])
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id))
    }, 4000)
  }, [])

  const removeToast = useCallback((id) => {
    setToasts(prev => prev.filter(t => t.id !== id))
  }, [])

  return { toasts, addToast, removeToast }
}

const icons = {
  success: 'fa-circle-check',
  error: 'fa-circle-xmark',
  info: 'fa-circle-info',
}

export default function Toast({ toasts, onRemove }) {
  if (!toasts || toasts.length === 0) return null

  return (
    <div className="toast-container">
      {toasts.map(toast => (
        <div key={toast.id} className={`toast toast-${toast.type}`}>
          <i className={`fa-solid ${icons[toast.type] || icons.info} toast-icon`} />
          <span>{toast.message}</span>
          <button className="toast-close" onClick={() => onRemove(toast.id)}>
            <i className="fa-solid fa-xmark" />
          </button>
        </div>
      ))}
    </div>
  )
}

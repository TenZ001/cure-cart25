import { Button } from './Button'
import { Card } from './Card'
import { X, AlertTriangle, LogOut } from 'lucide-react'

interface ConfirmDialogProps {
  isOpen: boolean
  onClose: () => void
  onConfirm: () => void
  title: string
  message: string
  confirmText?: string
  cancelText?: string
  type?: 'warning' | 'danger' | 'info'
}

export function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Confirm',
  cancelText = 'Cancel',
  type = 'warning'
}: ConfirmDialogProps) {
  if (!isOpen) return null

  const handleConfirm = () => {
    onConfirm()
    onClose()
  }

  const getTypeStyles = () => {
    switch (type) {
      case 'danger':
        return {
          iconColor: 'text-red-500',
          iconBg: 'bg-red-50',
          confirmButton: 'bg-red-600 hover:bg-red-700 text-white',
          borderColor: 'border-red-200'
        }
      case 'info':
        return {
          iconColor: 'text-blue-500',
          iconBg: 'bg-blue-50',
          confirmButton: 'bg-blue-600 hover:bg-blue-700 text-white',
          borderColor: 'border-blue-200'
        }
      default:
        return {
          iconColor: 'text-orange-500',
          iconBg: 'bg-orange-50',
          confirmButton: 'bg-orange-600 hover:bg-orange-700 text-white',
          borderColor: 'border-orange-200'
        }
    }
  }

  const styles = getTypeStyles()

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div 
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
      />
      
      {/* Dialog */}
      <Card className={`relative z-10 w-full max-w-md mx-4 p-0 overflow-hidden border-2 ${styles.borderColor}`}>
        <div className="p-6">
          {/* Header */}
          <div className="flex items-center gap-3 mb-4">
            <div className={`p-3 rounded-full ${styles.iconBg}`}>
              {type === 'danger' ? (
                <LogOut className={`w-6 h-6 ${styles.iconColor}`} />
              ) : (
                <AlertTriangle className={`w-6 h-6 ${styles.iconColor}`} />
              )}
            </div>
            <div>
              <h3 className="text-lg font-semibold text-slate-900">{title}</h3>
              <p className="text-sm text-slate-500">Please confirm your action</p>
            </div>
          </div>
          
          {/* Message */}
          <div className="mb-6">
            <p className="text-slate-700 leading-relaxed">{message}</p>
          </div>
          
          {/* Actions */}
          <div className="flex gap-3 justify-end">
            <Button
              variant="outline"
              onClick={onClose}
              className="px-6 py-2"
            >
              {cancelText}
            </Button>
            <Button
              onClick={handleConfirm}
              className={`px-6 py-2 ${styles.confirmButton} shadow-lg`}
            >
              {confirmText}
            </Button>
          </div>
        </div>
      </Card>
    </div>
  )
}

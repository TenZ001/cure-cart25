import * as Dialog from '@radix-ui/react-dialog'
import { cn } from '../lib/utils'
import { X } from 'lucide-react'
import { ReactNode } from 'react'

export function Modal({ open, onOpenChange, children }: { open: boolean; onOpenChange: (open: boolean) => void; children: ReactNode }) {
  return (
    <Dialog.Root open={open} onOpenChange={onOpenChange}>
      <Dialog.Portal>
        <Dialog.Overlay className="fixed inset-0 bg-black/30 backdrop-blur-sm data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=open]:fade-in-0 data-[state=closed]:fade-out-0" />
        <Dialog.Content className={cn('fixed left-1/2 top-1/2 w-full max-w-md -translate-x-1/2 -translate-y-1/2 rounded-lg border border-slate-200 bg-white p-4 shadow-lg data-[state=open]:animate-in data-[state=open]:zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:zoom-out-95') }>
          {children}
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  )
}

export function ModalHeader({ title, description }: { title: string; description?: string }) {
  return (
    <div className="mb-3">
      <Dialog.Title className="text-lg font-semibold text-slate-900">{title}</Dialog.Title>
      {description && <Dialog.Description className="text-sm text-slate-500">{description}</Dialog.Description>}
    </div>
  )
}

export function ModalCloseButton() {
  return (
    <Dialog.Close aria-label="Close" className="absolute right-3 top-3 rounded-md p-1 text-slate-500 hover:bg-slate-100">
      <X size={16} />
    </Dialog.Close>
  )
}










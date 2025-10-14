import { PropsWithChildren } from 'react'
import { ToastProvider } from './hooks/useToast'

export default function App({ children }: PropsWithChildren) {
  return (
    <ToastProvider>
      <div className="text-slate-800">
        {children}
      </div>
    </ToastProvider>
  )
}



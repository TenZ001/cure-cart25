import React from 'react'
import { AlertTriangle, Home, RefreshCw } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

interface ErrorBoundaryState {
  hasError: boolean
  error?: Error
}

interface ErrorBoundaryProps {
  children: React.ReactNode
}

class ErrorBoundary extends React.Component<ErrorBoundaryProps, ErrorBoundaryState> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback error={this.state.error} />
    }

    return this.props.children
  }
}

function ErrorFallback({ error }: { error?: Error }) {
  const navigate = useNavigate()

  const handleGoHome = () => {
    navigate('/dashboard')
  }

  const handleRefresh = () => {
    window.location.reload()
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50">
      <div className="max-w-md w-full mx-4">
        <div className="bg-white rounded-xl shadow-lg p-8 text-center">
          <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <AlertTriangle className="w-8 h-8 text-red-600" />
          </div>
          
          <h1 className="text-2xl font-bold text-slate-900 mb-2">
            Oops! Something went wrong
          </h1>
          
          <p className="text-slate-600 mb-6">
            We encountered an unexpected error. Don't worry, this has been logged and we'll look into it.
          </p>
          
          {error && (
            <details className="mb-6 text-left">
              <summary className="cursor-pointer text-sm text-slate-500 hover:text-slate-700">
                Error Details
              </summary>
              <pre className="mt-2 p-3 bg-slate-100 rounded text-xs text-slate-600 overflow-auto">
                {error.message}
              </pre>
            </details>
          )}
          
          <div className="flex gap-3">
            <button
              onClick={handleGoHome}
              className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2 bg-slate-900 text-white rounded-lg hover:bg-slate-800 transition-colors"
            >
              <Home className="w-4 h-4" />
              Go Home
            </button>
            
            <button
              onClick={handleRefresh}
              className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors"
            >
              <RefreshCw className="w-4 h-4" />
              Refresh
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default ErrorBoundary

import { create } from 'zustand'
import axios from 'axios'
import { Navigate, useLocation } from 'react-router-dom'
import { PropsWithChildren, useEffect } from 'react'

type User = { id: string; name: string; email: string; role?: string } | null

type AuthState = {
  user: User
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  register: (name: string, email: string, password: string, phone?: string, role?: 'pharmacist'|'admin') => Promise<void>
  logout: () => Promise<void>
  hydrate: () => Promise<void>
}

// Prefer env-configured API base, else infer from current host to reduce CORS/login issues
const inferredBase = (() => {
  try {
    const { protocol, hostname } = window.location;
    // Default API port 4000 on same host
    return `${protocol}//${hostname}:4000`;
  } catch {
    return 'http://localhost:4000';
  }
})();
const apiBase = (import.meta as any).env?.VITE_API_BASE_URL || (window as any).__API_BASE__ || inferredBase

console.log('🔍 [AUTH CONFIG] API Base URL:', apiBase);
console.log('🔍 [AUTH CONFIG] Current location:', window.location.href);

axios.defaults.baseURL = apiBase
axios.defaults.withCredentials = true

// Add request interceptor for debugging
axios.interceptors.request.use(
  (config) => {
    console.log('🔍 [AXIOS] Request:', {
      method: config.method,
      url: config.url,
      baseURL: config.baseURL,
      fullURL: `${config.baseURL}${config.url}`,
      headers: config.headers
    });
    return config;
  },
  (error) => {
    console.error('❌ [AXIOS] Request error:', error);
    return Promise.reject(error);
  }
);

// Add response interceptor for debugging
axios.interceptors.response.use(
  (response) => {
    console.log('✅ [AXIOS] Response:', {
      status: response.status,
      url: response.config.url,
      data: response.data
    });
    return response;
  },
  (error) => {
    console.error('❌ [AXIOS] Response error:', {
      status: error.response?.status,
      url: error.config?.url,
      data: error.response?.data,
      message: error.message
    });
    return Promise.reject(error);
  }
);

export const useAuth = create<AuthState>((set) => ({
  user: null,
  loading: true,
  async hydrate() {
    try {
      const stored = localStorage.getItem('cc_token')
      console.log('🔍 [AUTH STORE] Hydrate:', { hasStoredToken: !!stored })
      
      if (stored && !axios.defaults.headers.common['Authorization']) {
        axios.defaults.headers.common['Authorization'] = `Bearer ${stored}`
        console.log('🔍 [AUTH STORE] Set Authorization header')
      }
      
      const { data } = await axios.get('/api/auth/me')
      console.log('🔍 [AUTH STORE] /me response:', { user: data })
      set({ user: data, loading: false })
    } catch (err) {
      console.error('❌ [AUTH STORE] Hydrate error:', err)
      set({ user: null, loading: false })
    }
  },
  async login(email, password) {
    try {
      console.log('🔍 [AUTH STORE] Login attempt:', { email })
      const { data } = await axios.post('/api/auth/login', { email, password })
      console.log('🔍 [AUTH STORE] Login response:', { hasToken: !!data?.token, user: data?.user })
      
      if (data?.token) {
        localStorage.setItem('cc_token', data.token)
        axios.defaults.headers.common['Authorization'] = `Bearer ${data.token}`
        console.log('🔍 [AUTH STORE] Token stored and header set')
      }
      
      // Set user immediately to avoid race on /auth/me during redirect
      if (data?.user) {
        const user = { id: (data.user.id || data.user._id), name: data.user.name, email: data.user.email, role: data.user.role }
        console.log('🔍 [AUTH STORE] Setting user:', user)
        set({ user, loading: false })
      } else {
        console.log('🔍 [AUTH STORE] No user in response, calling hydrate')
        await useAuth.getState().hydrate()
      }
    } catch (err) {
      console.error('❌ [AUTH STORE] Login error:', err)
      throw err
    }
  },
  async register(name, email, password, phone) {
    await axios.post('/api/auth/register', { name, email, password, phone, role: (arguments as any)[4] })
  },
  async logout() {
    await axios.post('/api/auth/logout')
    localStorage.removeItem('cc_token')
    // Prevent role bleed across tabs/sessions
    sessionStorage.clear()
    delete axios.defaults.headers.common['Authorization']
    set({ user: null })
  },
}))

export function AuthGuard({ children }: PropsWithChildren) {
  const location = useLocation()
  const { user, loading, hydrate } = useAuth()
  useEffect(() => { hydrate() }, [])
  if (loading) return <div className="h-screen flex items-center justify-center text-brand-dark">Loading...</div>
  // If an admin token is present, keep admin within admin area
  if ((user as any)?.role === 'admin' && !location.pathname.startsWith('/admin')) {
    return <Navigate to="/admin/dashboard" replace />
  }
  if (!user) return <Navigate to="/login" state={{ from: location }} replace />
  return <>{children}</>
}

export function AdminGuard({ children }: PropsWithChildren) {
  const location = useLocation()
  const { user, loading, hydrate } = useAuth()
  useEffect(() => { hydrate() }, [])
  if (loading) return <div className="h-screen flex items-center justify-center text-brand-dark">Loading...</div>
  if (!user) return <Navigate to="/login" state={{ from: location }} replace />
  if ((user as any)?.role !== 'admin') return <Navigate to="/dashboard" replace />
  return <>{children}</>
}



import { useState } from 'react'
import { Button } from '../../ui/Button'
import { Card } from '../../ui/Card'
import { Input } from '../../ui/Input'
import { Label } from '../../ui/Label'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../../stores/auth'
import { Eye, EyeOff } from 'lucide-react'

export default function Login() {
  const { login } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()
  const location = useLocation() as any

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    try {
      console.log('🔍 [LOGIN] Attempting login:', { email })
      await login(email, password)
      const role = (useAuth.getState().user as any)?.role
      console.log('🔍 [LOGIN] Login successful, role:', role)
      
      if (role === 'admin') {
        console.log('🔍 [LOGIN] Redirecting to admin dashboard')
        navigate('/admin/dashboard', { replace: true })
      } else {
        console.log('🔍 [LOGIN] Redirecting to app dashboard')
        navigate(location.state?.from?.pathname || '/app/dashboard', { replace: true })
      }
    } catch (e: any) {
      console.error('❌ [LOGIN] Login failed:', e)
      setError(e?.response?.data?.error || 'Login failed')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-gradient-to-br from-blue-100 via-purple-50 to-green-100">
      <Card className="w-full max-w-sm p-8 shadow-xl">
        <form onSubmit={onSubmit} aria-label="Login form">
          {/* CureCart Logo with gradient border */}
          <div className="flex justify-center mb-6">
            <div className="relative">
              <div className="w-24 h-24 rounded-full bg-gradient-to-br from-blue-500 to-green-500 p-1">
                <div className="w-full h-full rounded-full bg-white flex items-center justify-center">
                  <img 
                    src="/curecart_logo.png" 
                    alt="CureCart Logo" 
                    className="w-16 h-16 object-contain"
                  />
                </div>
              </div>
            </div>
          </div>
          
          {/* Welcome text */}
          <h1 className="text-2xl font-bold text-center mb-2 text-slate-800 tracking-wide">
            Welcome to Cure Cart
          </h1>
          <p className="text-slate-600 text-center mb-6">Access your dashboard</p>
          {error && <div role="alert" className="mb-3 text-red-600 text-sm">{error}</div>}
          <div className="space-y-3">
            <div>
              <Label htmlFor="email">Email</Label>
              <Input id="email" value={email} onChange={(e)=>setEmail(e.target.value)} type="email" placeholder="you@example.com" required autoComplete="email"/>
            </div>
            <div>
              <Label htmlFor="password">Password</Label>
              <div className="relative">
                <Input 
                  id="password" 
                  value={password} 
                  onChange={(e)=>setPassword(e.target.value)} 
                  type={showPassword ? "text" : "password"} 
                  placeholder="••••••••" 
                  required 
                  autoComplete="current-password"
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700 focus:outline-none"
                >
                  {showPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              </div>
            </div>
            <Button className="w-full">Sign In</Button>
          </div>
          <div className="text-sm text-slate-500 mt-4">
            <div className="flex justify-between">
              <Link to="/forgot-password" className="text-blue-600 hover:text-blue-800 font-medium">Forgot Password?</Link>
              <Link to="/register" className="text-slate-900 font-medium">Register</Link>
            </div>
          </div>
        </form>
      </Card>
    </div>
  )
}



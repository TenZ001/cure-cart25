import { useState } from 'react'
import { Button } from '../../ui/Button'
import { Card } from '../../ui/Card'
import { Input } from '../../ui/Input'
import { Label } from '../../ui/Label'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../stores/auth'
import { Eye, EyeOff } from 'lucide-react'

export default function Register() {
  const { register } = useAuth()
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)
  const [role, setRole] = useState<'pharmacist' | 'admin'>('pharmacist')
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const navigate = useNavigate()

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    
    if (password !== confirmPassword) {
      setError('Passwords do not match')
      return
    }
    
    try {
      await register(name, email, password, phone, role)
      setSuccess('Registered successfully. You can now sign in.')
      setTimeout(()=> navigate('/login'), 800)
    } catch (e: any) {
      setError(e?.response?.data?.error || 'Registration failed')
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-6">
      <Card className="w-full max-w-sm p-6">
        <form onSubmit={onSubmit} aria-label="Register form">
          <h1 className="text-xl font-semibold mb-1 text-slate-900">Create account</h1>
          <p className="text-slate-500 mb-6">Start managing orders</p>
          {error && <div role="alert" className="mb-3 text-red-600 text-sm">{error}</div>}
          {success && <div className="mb-3 text-emerald-600 text-sm">{success}</div>}
          <div className="space-y-3">
            <div>
              <Label htmlFor="name">Full name</Label>
              <Input id="name" value={name} onChange={(e)=>setName(e.target.value)} placeholder="Jane Doe" required autoComplete="name"/>
            </div>
            <div>
              <Label htmlFor="email">Email</Label>
              <Input id="email" value={email} onChange={(e)=>setEmail(e.target.value)} type="email" placeholder="you@example.com" required autoComplete="email"/>
            </div>
            <div>
              <Label htmlFor="phone">Phone (optional)</Label>
              <Input id="phone" value={phone} onChange={(e)=>setPhone(e.target.value)} placeholder="123 456 7890" autoComplete="tel"/>
            </div>
            <div>
            <Label htmlFor="role">Role</Label>
            <select 
              id="role"
              value={role}
              onChange={(e)=>setRole(e.target.value as any)}
              className="w-full h-10 rounded-md border border-slate-200 bg-white px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-primary focus-visible:ring-offset-2"
            >
              <option value="pharmacist">Pharmacist</option>
              <option value="admin">Admin</option>
            </select>
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
                  autoComplete="new-password"
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
            <div>
              <Label htmlFor="confirmPassword">Confirm Password</Label>
              <div className="relative">
                <Input 
                  id="confirmPassword" 
                  value={confirmPassword} 
                  onChange={(e)=>setConfirmPassword(e.target.value)} 
                  type={showConfirmPassword ? "text" : "password"} 
                  placeholder="••••••••" 
                  required 
                  autoComplete="new-password"
                  className="pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                  className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-500 hover:text-gray-700 focus:outline-none"
                >
                  {showConfirmPassword ? (
                    <EyeOff className="h-4 w-4" />
                  ) : (
                    <Eye className="h-4 w-4" />
                  )}
                </button>
              </div>
            </div>
            <Button className="w-full">Create Account</Button>
          </div>
          <div className="text-sm text-slate-500 mt-4">Already have an account? <Link to="/login" className="text-slate-900 font-medium">Sign in</Link></div>
        </form>
      </Card>
    </div>
  )
}



import { useState, useEffect, useRef } from 'react'
import { Button } from '../../ui/Button'
import { Card } from '../../ui/Card'
import { Input } from '../../ui/Input'
import { Label } from '../../ui/Label'
import { Link, useNavigate } from 'react-router-dom'
import { ArrowLeft, Mail, Shield } from 'lucide-react'

export default function ForgotPassword() {
  const [step, setStep] = useState<'email' | 'otp'>('email')
  const [email, setEmail] = useState('')
  const [otp, setOtp] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)
  const [attemptsRemaining, setAttemptsRemaining] = useState<number | null>(null)
  const [timeRemaining, setTimeRemaining] = useState<number | null>(null)
  const [otpExpiry, setOtpExpiry] = useState<Date | null>(null)
  const [countdown, setCountdown] = useState<number>(0)
  const [resetLoading, setResetLoading] = useState(false)
  const intervalRef = useRef<NodeJS.Timeout | null>(null)
  const navigate = useNavigate()

  // Check OTP status when email changes
  useEffect(() => {
    if (email && email.includes('@')) {
      checkOTPStatus(email)
    }
  }, [email])

  // Countdown timer for OTP expiry
  useEffect(() => {
    if (otpExpiry) {
      const updateCountdown = () => {
        const now = new Date().getTime()
        const expiry = otpExpiry.getTime()
        const remaining = Math.max(0, Math.ceil((expiry - now) / 1000))
        
        setCountdown(remaining)
        
        if (remaining <= 0) {
          setOtpExpiry(null)
          setCountdown(0)
          if (intervalRef.current) {
            clearInterval(intervalRef.current)
            intervalRef.current = null
          }
        }
      }
      
      updateCountdown() // Initial call
      intervalRef.current = setInterval(updateCountdown, 1000)
      
      return () => {
        if (intervalRef.current) {
          clearInterval(intervalRef.current)
          intervalRef.current = null
        }
      }
    }
  }, [otpExpiry])

  // Cleanup interval on unmount
  useEffect(() => {
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
      }
    }
  }, [])

  const checkOTPStatus = async (email: string) => {
    try {
      const response = await fetch('/api/auth/check-otp-status', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      })
      
      const data = await response.json()
      
      if (response.ok) {
        setAttemptsRemaining(data.attemptsRemaining)
        if (data.timeRemaining) {
          setTimeRemaining(data.timeRemaining)
        }
        return data.canRequest
      }
      return true
    } catch (err) {
      return true
    }
  }

  const resetOTPAttempts = async () => {
    setResetLoading(true)
    setError(null)
    
    try {
      const response = await fetch('/api/auth/reset-otp-attempts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      })
      
      const data = await response.json()
      
      if (response.ok) {
        setSuccess('OTP attempts reset! You can now request a new OTP.')
        setAttemptsRemaining(5)
        setTimeRemaining(null)
        // Refresh the status
        await checkOTPStatus(email)
      } else {
        setError(data.error || 'Failed to reset OTP attempts')
      }
    } catch (err) {
      setError('Network error. Please try again.')
    } finally {
      setResetLoading(false)
    }
  }

  const handleSendOTP = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setLoading(true)
    
    try {
      // Check OTP status first
      const canRequest = await checkOTPStatus(email)
      
      if (!canRequest) {
        setError(`Too many OTP attempts. Please wait ${timeRemaining || 60} minutes before trying again.`)
        setLoading(false)
        return
      }
      
      const response = await fetch('/api/auth/forgot-password', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      })
      
      const data = await response.json()
      
      if (response.ok) {
        setSuccess('OTP sent to your email address')
        setStep('otp')
        // Set OTP expiry time (10 minutes from now)
        const expiryTime = new Date(Date.now() + 10 * 60 * 1000)
        setOtpExpiry(expiryTime)
        setCountdown(600) // 10 minutes in seconds
        // Update attempts remaining
        if (attemptsRemaining !== null) {
          setAttemptsRemaining(attemptsRemaining - 1)
        }
      } else {
        setError(data.error || 'Failed to send OTP')
      }
    } catch (err) {
      setError('Network error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  const handleVerifyOTP = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    
    if (newPassword !== confirmPassword) {
      setError('Passwords do not match')
      return
    }
    
    if (newPassword.length < 6) {
      setError('Password must be at least 6 characters long')
      return
    }
    
    setLoading(true)
    
    try {
      const response = await fetch('/api/auth/verify-otp', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, otp, newPassword }),
      })
      
      const data = await response.json()
      
      if (response.ok) {
        setSuccess('Password reset successful! Redirecting to login...')
        setTimeout(() => {
          navigate('/login')
        }, 2000)
      } else {
        setError(data.error || 'Failed to reset password')
      }
    } catch (err) {
      setError('Network error. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-6 bg-gradient-to-br from-blue-100 via-purple-50 to-green-100">
      <Card className="w-full max-w-sm p-8 shadow-xl">
        <form onSubmit={step === 'email' ? handleSendOTP : handleVerifyOTP} aria-label="Forgot password form">
          {/* Header */}
          <div className="flex items-center mb-6">
            <button
              type="button"
              onClick={() => navigate('/login')}
              className="mr-3 p-2 hover:bg-gray-100 rounded-full transition-colors"
            >
              <ArrowLeft className="h-5 w-5 text-gray-600" />
            </button>
            <div>
              <h1 className="text-2xl font-bold text-slate-800 tracking-wide">
                {step === 'email' ? 'Reset Password' : 'Verify OTP'}
              </h1>
              <p className="text-slate-600 text-sm">
                {step === 'email' 
                  ? 'Enter your email to receive a verification code' 
                  : 'Enter the 6-digit code sent to your email'
                }
              </p>
            </div>
          </div>

          {/* CureCart Logo */}
          <div className="flex justify-center mb-6">
            <div className="relative">
              <div className="w-16 h-16 rounded-full bg-gradient-to-br from-blue-500 to-green-500 p-1">
                <div className="w-full h-full rounded-full bg-white flex items-center justify-center">
                  <img 
                    src="/curecart_logo.png" 
                    alt="CureCart Logo" 
                    className="w-12 h-12 object-contain"
                  />
                </div>
              </div>
            </div>
          </div>

          {error && (
            <div role="alert" className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-red-600 text-sm">
              {error}
            </div>
          )}

          {success && (
            <div role="alert" className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-green-600 text-sm">
              {success}
            </div>
          )}

          {attemptsRemaining !== null && attemptsRemaining < 5 && (
            <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg text-blue-600 text-sm">
              <div className="flex items-center justify-between">
                <span>OTP attempts remaining: {attemptsRemaining}</span>
                {timeRemaining && timeRemaining > 0 && (
                  <span className="text-xs">Reset in {timeRemaining} min</span>
                )}
              </div>
              {attemptsRemaining === 0 && (
                <div className="mt-2 pt-2 border-t border-blue-200">
                  <button
                    type="button"
                    onClick={resetOTPAttempts}
                    disabled={resetLoading}
                    className="text-xs bg-blue-600 text-white px-3 py-1 rounded hover:bg-blue-700 disabled:opacity-50"
                  >
                    {resetLoading ? 'Resetting...' : 'Reset Attempts'}
                  </button>
                </div>
              )}
            </div>
          )}

          {step === 'email' ? (
            <div className="space-y-4">
              <div>
                <Label htmlFor="email">Email Address</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <Input 
                    id="email" 
                    value={email} 
                    onChange={(e) => setEmail(e.target.value)} 
                    type="email" 
                    placeholder="you@example.com" 
                    required 
                    autoComplete="email"
                    className="pl-10"
                  />
                </div>
              </div>
              <Button 
                type="submit" 
                className="w-full" 
                disabled={loading || (attemptsRemaining !== null && attemptsRemaining <= 0)}
              >
                {loading ? 'Sending...' : 
                 (attemptsRemaining !== null && attemptsRemaining <= 0) ? 
                 `Wait ${timeRemaining || 60} min` : 'Send OTP'}
              </Button>
            </div>
          ) : (
            <div className="space-y-4">
              <div>
                <Label htmlFor="otp">6-Digit OTP Code</Label>
                <div className="relative">
                  <Shield className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                  <Input 
                    id="otp" 
                    value={otp} 
                    onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))} 
                    type="text" 
                    placeholder="123456" 
                    required 
                    maxLength={6}
                    className="pl-10 text-center text-lg tracking-widest"
                  />
                </div>
                <p className="text-xs text-gray-500 mt-1">
                  Check your email for the 6-digit code
                </p>
                {countdown > 0 && (
                  <div className={`mt-2 p-2 border rounded-lg ${
                    countdown <= 60 
                      ? 'bg-red-50 border-red-200' 
                      : countdown <= 300 
                        ? 'bg-yellow-50 border-yellow-200' 
                        : 'bg-blue-50 border-blue-200'
                  }`}>
                    <div className="flex items-center justify-between text-sm">
                      <span className={`font-medium ${
                        countdown <= 60 
                          ? 'text-red-600' 
                          : countdown <= 300 
                            ? 'text-yellow-600' 
                            : 'text-blue-600'
                      }`}>
                        {countdown <= 60 ? '⚠️ OTP expires soon!' : '⏰ OTP expires in:'}
                      </span>
                      <span className={`font-bold ${
                        countdown <= 60 
                          ? 'text-red-800' 
                          : countdown <= 300 
                            ? 'text-yellow-800' 
                            : 'text-blue-800'
                      }`}>
                        {Math.floor(countdown / 60)}:{(countdown % 60).toString().padStart(2, '0')}
                      </span>
                    </div>
                  </div>
                )}
              </div>
              
              <div>
                <Label htmlFor="newPassword">New Password</Label>
                <Input 
                  id="newPassword" 
                  value={newPassword} 
                  onChange={(e) => setNewPassword(e.target.value)} 
                  type="password" 
                  placeholder="Enter new password" 
                  required 
                  autoComplete="new-password"
                />
              </div>
              
              <div>
                <Label htmlFor="confirmPassword">Confirm New Password</Label>
                <Input 
                  id="confirmPassword" 
                  value={confirmPassword} 
                  onChange={(e) => setConfirmPassword(e.target.value)} 
                  type="password" 
                  placeholder="Confirm new password" 
                  required 
                  autoComplete="new-password"
                />
              </div>
              
              <Button type="submit" className="w-full" disabled={loading}>
                {loading ? 'Resetting...' : 'Reset Password'}
              </Button>
              
              <div className="text-center">
                <button
                  type="button"
                  onClick={() => setStep('email')}
                  className="text-sm text-blue-600 hover:text-blue-800 font-medium"
                >
                  Didn't receive the code? Resend
                </button>
                {countdown > 0 && (
                  <div className="mt-2 text-xs text-gray-500">
                    OTP expires in {Math.floor(countdown / 60)}:{(countdown % 60).toString().padStart(2, '0')}
                  </div>
                )}
              </div>
            </div>
          )}

          <div className="text-sm text-slate-500 mt-6 text-center">
            Remember your password? <Link to="/login" className="text-slate-900 font-medium">Back to Login</Link>
          </div>
        </form>
      </Card>
    </div>
  )
}

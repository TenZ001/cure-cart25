import { useState, useEffect } from 'react'
import axios from 'axios'

interface DashboardSummary {
  pendingPrescriptions: number
  approvedPrescriptions: number
  rejectedPrescriptions: number
  lowStock: number
  activeOrders: number
  deliveredOrders: number
  notifications: {
    unread: number
    urgent: number
    newOrders: number
  }
  unreadChatMessages: number
  recentActivity: {
    lastLoginAt: string | null
    lastTransactionAt: string | null
  }
}

export function useDashboardSummary() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchSummary = async () => {
      try {
        setLoading(true)
        const response = await axios.get('/api/dashboard/summary')
        setSummary(response.data)
        setError(null)
      } catch (err) {
        console.error('Failed to fetch dashboard summary:', err)
        setError('Failed to load dashboard data')
      } finally {
        setLoading(false)
      }
    }

    fetchSummary()
    
    // Refresh every 30 seconds to keep counts updated
    const interval = setInterval(fetchSummary, 30000)
    
    return () => clearInterval(interval)
  }, [])

  return { summary, loading, error }
}

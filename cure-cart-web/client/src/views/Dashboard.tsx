import { useEffect, useState } from 'react'
import axios from 'axios'
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import { Clock, CheckCircle, XCircle, AlertTriangle, Bell, Activity, TrendingUp, Calendar } from 'lucide-react'

export default function Dashboard() {
  const [summary, setSummary] = useState<any>({ pendingPrescriptions: 0, approvedPrescriptions: 0, rejectedPrescriptions: 0, lowStock: 0, notifications: { unread: 0, urgent: 0, newOrders: 0 }, recentActivity: {} })
  const [pharmacy, setPharmacy] = useState<any>(null)
  const [sales, setSales] = useState<{ _id: string, total: number }[]>([])
  const [period, setPeriod] = useState<'daily' | 'weekly' | 'monthly'>('daily')

  useEffect(() => {
    axios.get('/api/dashboard/summary').then(({ data }) => setSummary(data))
    axios.get('/api/pharmacies/me').then(({ data }) => setPharmacy(data))
  }, [])
  useEffect(() => {
    axios.get(`/api/reports/sales?period=${period}`).then(({ data }) => setSales(data))
  }, [period])

  const cards = [
    { 
      title: 'Pending Prescriptions', 
      value: summary.pendingPrescriptions, 
      icon: Clock, 
      color: 'from-amber-500 to-orange-500',
      glow: 'shadow-amber-500/25'
    },
    { 
      title: 'Approved Prescriptions', 
      value: summary.approvedPrescriptions, 
      icon: CheckCircle, 
      color: 'from-emerald-500 to-green-500',
      glow: 'shadow-emerald-500/25'
    },
    { 
      title: 'Rejected Prescriptions', 
      value: summary.rejectedPrescriptions, 
      icon: XCircle, 
      color: 'from-red-500 to-rose-500',
      glow: 'shadow-red-500/25'
    },
    { 
      title: 'Low Stock Alerts', 
      value: summary.lowStock, 
      icon: AlertTriangle, 
      color: 'from-violet-500 to-purple-500',
      glow: 'shadow-violet-500/25'
    },
  ]

  return (
    <div className="space-y-6">
      {pharmacy?.status === 'approved' && (
        <div className="bg-white rounded-xl border border-emerald-200 p-4 shadow-md flex items-center gap-3">
          <div className="p-2 rounded-full bg-emerald-100 text-emerald-700">✅</div>
          <div className="text-slate-800 text-sm">
            <b>{pharmacy.name}</b> is approved and active.
          </div>
        </div>
      )}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {cards.map(({ title, value, icon: Icon, color, glow }) => (
          <div key={title} className={`relative group bg-white rounded-xl border border-slate-200 p-6 shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105 ${glow} hover:shadow-2xl`}>
            <div className="absolute inset-0 bg-gradient-to-br opacity-5 rounded-xl" style={{background: `linear-gradient(135deg, var(--tw-gradient-stops))`}}></div>
            <div className="relative">
              <div className="flex items-center justify-between mb-4">
                <div className={`p-3 rounded-lg bg-gradient-to-br ${color} shadow-lg group-hover:shadow-xl transition-all duration-300`}>
                  <Icon className="w-6 h-6 text-white" />
                </div>
                <div className={`text-xs px-2 py-1 rounded-full bg-gradient-to-r ${color} text-white font-medium`}>
                  {value > 0 ? 'Active' : 'None'}
                </div>
              </div>
              <div className="space-y-1">
                <div className="text-slate-600 text-sm font-medium">{title}</div>
                <div className="text-3xl font-bold text-slate-900">{value}</div>
              </div>
            </div>
          </div>
        ))}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-lg hover:shadow-xl transition-all duration-300 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-blue-500/5 to-purple-500/5 rounded-xl"></div>
          <div className="relative">
            <div className="mb-6 font-semibold text-slate-900 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-lg bg-gradient-to-br from-blue-500 to-purple-500 shadow-lg">
                  <TrendingUp className="w-5 h-5 text-white" />
                </div>
                <span>Sales Analytics</span>
              </div>
              <div className="flex gap-2 text-xs">
                {(['daily','weekly','monthly'] as const).map(p => (
                  <button 
                    key={p} 
                    onClick={()=>setPeriod(p)} 
                    className={`px-3 py-1 rounded-full transition-all duration-200 ${
                      period===p 
                        ? 'bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow-lg' 
                        : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                    }`}
                  >
                    {p}
                  </button>
                ))}
              </div>
            </div>
            <div className="h-60">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={sales} margin={{ top: 10, right: 10, bottom: 0, left: 0 }}>
                  <defs>
                    <linearGradient id="salesGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8}/>
                      <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0.1}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid stroke="#e2e8f0" strokeDasharray="3 3" />
                  <XAxis dataKey="_id" tickLine={false} axisLine={false} />
                  <YAxis tickLine={false} axisLine={false} />
                  <Tooltip 
                    contentStyle={{ 
                      borderRadius: 12, 
                      borderColor: '#e2e8f0',
                      boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)'
                    }} 
                  />
                  <Area type="monotone" dataKey="total" stroke="#3b82f6" strokeWidth={3} fill="url(#salesGradient)" isAnimationActive />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-lg hover:shadow-xl transition-all duration-300 relative overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-500/5 to-teal-500/5 rounded-xl"></div>
          <div className="relative">
            <div className="mb-6 font-semibold text-slate-900 flex items-center gap-3">
              <div className="p-2 rounded-lg bg-gradient-to-br from-emerald-500 to-teal-500 shadow-lg">
                <Activity className="w-5 h-5 text-white" />
              </div>
              <span>Notifications & Activity</span>
            </div>
            <div className="h-60">
              <div className="grid grid-cols-2 gap-6 h-full">
                <div>
                  <div className="text-sm text-slate-600 font-medium mb-4 flex items-center gap-2">
                    <Bell className="w-4 h-4" />
                    Notifications
                  </div>
                  <div className="space-y-3">
                    <div className="bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg p-3 border border-blue-200">
                      <div className="text-xs text-blue-600 font-medium">Unread</div>
                      <div className="text-2xl font-bold text-blue-900">{summary.notifications?.unread || 0}</div>
                    </div>
                    <div className="bg-gradient-to-r from-amber-50 to-orange-100 rounded-lg p-3 border border-amber-200">
                      <div className="text-xs text-amber-600 font-medium">Urgent</div>
                      <div className="text-2xl font-bold text-amber-900">{summary.notifications?.urgent || 0}</div>
                    </div>
                    <div className="bg-gradient-to-r from-emerald-50 to-green-100 rounded-lg p-3 border border-emerald-200">
                      <div className="text-xs text-emerald-600 font-medium">New Orders</div>
                      <div className="text-2xl font-bold text-emerald-900">{summary.notifications?.newOrders || 0}</div>
                    </div>
                  </div>
                </div>
                <div>
                  <div className="text-sm text-slate-600 font-medium mb-4 flex items-center gap-2">
                    <Calendar className="w-4 h-4" />
                    Recent Activity
                  </div>
                  <div className="space-y-3">
                    <div className="bg-slate-50 rounded-lg p-3 border border-slate-200">
                      <div className="text-xs text-slate-600 font-medium">Last Login</div>
                      <div className="text-sm text-slate-900 mt-1">{summary.recentActivity?.lastLoginAt ? new Date(summary.recentActivity.lastLoginAt).toLocaleString() : '-'}</div>
                    </div>
                    <div className="bg-slate-50 rounded-lg p-3 border border-slate-200">
                      <div className="text-xs text-slate-600 font-medium">Last Transaction</div>
                      <div className="text-sm text-slate-900 mt-1">{summary.recentActivity?.lastTransactionAt ? new Date(summary.recentActivity.lastTransactionAt).toLocaleString() : '-'}</div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}



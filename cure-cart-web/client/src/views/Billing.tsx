import { useEffect, useMemo, useState } from 'react'
import axios from 'axios'
import { Card } from '../ui/Card'
import { Input } from '../ui/Input'
import { CreditCard, Search, Download } from 'lucide-react'

type Invoice = { _id: string; createdAt: string; amount: number; paymentMethod: string; status: string; customerId: string }

export default function Billing() {
  const [items, setItems] = useState<Invoice[]>([])
  const [q, setQ] = useState('')
  useEffect(() => { axios.get('/api/invoices').then(({ data }) => setItems(data)) }, [])

  const filtered = useMemo(() => items.filter(i => `${i._id} ${i.paymentMethod} ${i.status}`.toLowerCase().includes(q.toLowerCase())), [items, q])

  const exportCsv = () => {
    const header = 'Invoice ID,Date,Amount,Method,Status\n'
    const rows = filtered.map(i => `${i._id},${new Date(i.createdAt).toISOString()},${i.amount},${i.paymentMethod},${i.status}`).join('\n')
    const blob = new Blob([header + rows], { type: 'text/csv' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'billing.csv'
    a.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-gradient-to-br from-green-500 to-emerald-500 shadow-lg">
            <CreditCard className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900">Billing</h2>
        </div>
        <div className="flex gap-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
            <Input 
              placeholder="Search invoices..." 
              value={q} 
              onChange={(e)=>setQ(e.target.value)}
              className="pl-10 w-80"
            />
          </div>
          <button 
            className="inline-flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-green-500 to-emerald-500 hover:from-green-600 hover:to-emerald-600 text-white rounded-lg font-medium shadow-lg hover:shadow-xl transition-all duration-200"
            onClick={exportCsv}
          >
            <Download className="w-4 h-4" />
            Export CSV
          </button>
        </div>
      </div>
      <Card className="p-0 overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-600 bg-gradient-to-r from-slate-50 to-slate-100">
              <th className="py-3 px-4 font-semibold">Invoice</th>
              <th className="px-3 font-semibold">Date</th>
              <th className="px-3 font-semibold">Customer</th>
              <th className="px-3 font-semibold">Amount</th>
              <th className="px-3 font-semibold">Method</th>
              <th className="px-3 font-semibold">Status</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(i => (
              <tr key={i._id} className="border-t hover:bg-slate-50 transition-colors duration-200">
                <td className="py-3 px-4 font-mono text-slate-900 font-medium">{i._id.slice(-6)}</td>
                <td className="px-3 text-slate-600">{new Date(i.createdAt).toLocaleString()}</td>
                <td className="px-3 text-slate-600">{i.customerId?.toString?.().slice(-6) || '-'}</td>
                <td className="px-3 font-semibold text-green-600">Rs. {(i.amount || 0).toFixed(2)}</td>
                <td className="px-3">
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    {i.paymentMethod}
                  </span>
                </td>
                <td className="px-3">
                  <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                    i.status === 'paid' ? 'bg-green-100 text-green-800' :
                    i.status === 'unpaid' ? 'bg-red-100 text-red-800' :
                    'bg-yellow-100 text-yellow-800'
                  }`}>
                    {i.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  )
}





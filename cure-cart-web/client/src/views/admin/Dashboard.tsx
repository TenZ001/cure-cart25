import { useEffect, useState } from 'react'
import axios from 'axios'

export default function AdminDashboard() {
  const [stats, setStats] = useState<any>({ users: 0, orders: 0, pendingPharmacies: 0, feedback: 0, overview: { users: 0, byStatus: {}, revenue: 0 }, top: [], customers: { repeat: 0, new: 0 }, sales: [] })
  useEffect(() => {
    Promise.all([
      axios.get('/api/admin/users'),
      axios.get('/api/admin/orders'),
      axios.get('/api/admin/pharmacies'),
      axios.get('/api/admin/feedback'),
      axios.get('/api/admin/analytics/overview'),
      axios.get('/api/admin/analytics/top-products'),
      axios.get('/api/admin/analytics/customers'),
      axios.get('/api/admin/analytics/sales?period=daily'),
    ]).then(([u,o,p,f,ov,top,cus,sales])=>{
      setStats({ 
        users: u.data.length, 
        orders: o.data.length, 
        pendingPharmacies: p.data.filter((x:any)=>x.status==='pending').length, 
        feedback: f.data.length,
        overview: ov.data,
        top: top.data,
        customers: cus.data,
        sales: sales.data,
      })
    })
  }, [])
  const cards = [
    { title: 'Users', value: stats.users },
    { title: 'Orders', value: stats.orders },
    { title: 'Revenue', value: `Rs. ${(stats.overview.revenue || 0).toFixed(2)}` },
    { title: 'Pending Pharmacies', value: stats.pendingPharmacies },
  ]
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {cards.map(c => (
          <div key={c.title} className="bg-white border border-slate-200 rounded-lg p-4 shadow-sm">
            <div className="text-slate-500 text-sm">{c.title}</div>
            <div className="text-3xl font-bold text-slate-900">{c.value}</div>
          </div>
        ))}
      </div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white border border-slate-200 rounded-lg p-4">
          <div className="text-slate-900 font-semibold mb-3">Orders by status</div>
          <div className="grid grid-cols-2 gap-3 text-sm">
            {Object.entries(stats.overview.byStatus || {}).map(([k,v]) => (
              <div key={k} className="p-3 rounded border bg-slate-50 flex items-center justify-between"><span className="capitalize">{k}</span><b>{v as any}</b></div>
            ))}
          </div>
        </div>
        <div className="bg-white border border-slate-200 rounded-lg p-4">
          <div className="text-slate-900 font-semibold mb-3">Customers</div>
          <div className="flex gap-3 text-sm">
            <div className="p-3 rounded border bg-slate-50 flex-1"><div className="text-slate-500">Repeat</div><div className="text-2xl font-bold">{stats.customers.repeat || 0}</div></div>
            <div className="p-3 rounded border bg-slate-50 flex-1"><div className="text-slate-500">New</div><div className="text-2xl font-bold">{stats.customers.new || 0}</div></div>
          </div>
        </div>
      </div>
      <div className="bg-white border border-slate-200 rounded-lg p-4">
        <div className="text-slate-900 font-semibold mb-3">Top Products</div>
        <table className="w-full text-sm">
          <thead><tr className="text-left text-slate-600"><th className="py-2">Product</th><th>Qty</th><th>Sales</th></tr></thead>
          <tbody>
            {stats.top.map((r:any) => (
              <tr key={r._id} className="border-t"><td className="py-2 font-mono text-xs">{r._id?.toString?.() || '-'}</td><td>{r.qty}</td><td>Rs. {(r.sales || 0).toFixed(2)}</td></tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}



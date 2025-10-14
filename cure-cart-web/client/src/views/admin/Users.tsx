import { useEffect, useState } from 'react'
import axios from 'axios'

export default function AdminUsers() {
  const [items, setItems] = useState<any[]>([])
  const [q, setQ] = useState('')
  const refresh = () => axios.get('/api/admin/users').then(({ data }) => setItems(data))
  useEffect(() => { refresh() }, [])
  const setRole = async (id: string, role: string) => {
    const { data } = await axios.patch(`/api/admin/users/${id}/role`, { role })
    setItems(prev => prev.map(u => u._id === id ? data : u))
  }
  const setStatus = async (id: string, status: string) => {
    const { data } = await axios.patch(`/api/admin/users/${id}/status`, { status })
    setItems(prev => prev.map(u => u._id === id ? data : u))
  }
  const setKyc = async (id: string, verified: boolean) => {
    const { data } = await axios.patch(`/api/admin/users/${id}/kyc`, { verified })
    setItems(prev => prev.map(u => u._id === id ? data : u))
  }
  const filtered = items.filter(u => `${u.name} ${u.email} ${u.role}`.toLowerCase().includes(q.toLowerCase()))
  return (
    <div className="bg-white border border-slate-200 rounded-lg p-4">
      <div className="flex items-center justify-between mb-3">
        <div className="text-slate-900 font-semibold">Users</div>
        <input className="border rounded px-2 py-1 text-sm" placeholder="Search users..." value={q} onChange={(e)=>setQ(e.target.value)} />
      </div>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-slate-600">
            <th className="py-2">Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Status</th>
            <th>KYC</th>
            <th>Activity</th>
          </tr>
        </thead>
        <tbody>
          {filtered.map(u => (
            <tr key={u._id} className="border-t">
              <td className="py-2">{u.name}</td>
              <td>{u.email}</td>
              <td>{u.role}</td>
              <td>
                <select className="border rounded px-2 py-1" value={u.role} onChange={(e)=>setRole(u._id, e.target.value)}>
                  {['admin','pharmacist','customer','doctor'].map(r => <option key={r} value={r}>{r}</option>)}
                </select>
              </td>
              <td>
                <select className="border rounded px-2 py-1" value={u.status || 'active'} onChange={(e)=>setStatus(u._id, e.target.value)}>
                  {['active','suspended'].map(s => <option key={s} value={s}>{s}</option>)}
                </select>
              </td>
              <td>
                <button onClick={()=>setKyc(u._id, !u?.kyc?.verified)} className={`px-2 py-1 text-xs rounded ${u?.kyc?.verified ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-700'}`}>
                  {u?.kyc?.verified ? 'Verified' : 'Verify'}
                </button>
              </td>
              <td>
                <span className="text-xs text-slate-500">Last login: {u.lastLoginAt ? new Date(u.lastLoginAt).toLocaleString() : '-'}</span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}



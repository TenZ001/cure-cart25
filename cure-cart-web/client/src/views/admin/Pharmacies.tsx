import { useEffect, useState } from 'react'
import axios from 'axios'

export default function AdminPharmacies() {
  const [items, setItems] = useState<any[]>([])
  const [name, setName] = useState('')
  const [ownerId, setOwnerId] = useState('')
  const [address, setAddress] = useState('')
  const [contact, setContact] = useState('')
  const [owners, setOwners] = useState<any[]>([])
  const refresh = () => axios.get('/api/admin/pharmacies').then(({ data }) => setItems(data))
  useEffect(() => { 
    refresh(); 
    axios.get('/api/admin/users').then(({ data }) => setOwners(data.filter((u:any)=>u.role==='pharmacist')))
  }, [])
  const approve = async (id: string) => { await axios.patch(`/api/admin/pharmacies/${id}/approve`); refresh() }
  const reject = async (id: string) => { const reason = prompt('Reason (optional)') || undefined; await axios.patch(`/api/admin/pharmacies/${id}/reject`, { reason }); refresh() }
  const remove = async (id: string) => { if (!confirm('Delete this pharmacy?')) return; await axios.delete(`/api/admin/pharmacies/${id}`); refresh() }
  const create = async () => {
    if (!name.trim()) return
    await axios.post('/api/admin/pharmacies', { name, ownerId: ownerId || undefined, address, contact })
    setName(''); setOwnerId(''); setAddress(''); setContact(''); refresh()
  }
  return (
    <div className="bg-white border border-slate-200 rounded-lg p-4">
      <div className="text-slate-900 font-semibold mb-3">Pharmacies</div>
      <div className="mb-4 grid md:grid-cols-4 gap-2">
        <input className="border rounded px-2 py-1" placeholder="Pharmacy name" value={name} onChange={(e)=>setName(e.target.value)} />
        <select className="border rounded px-2 py-1" value={ownerId} onChange={(e)=>setOwnerId(e.target.value)}>
          <option value="">Select owner (optional)</option>
          {owners.map(o => <option key={o._id} value={o._id}>{o.name} ({o.email})</option>)}
        </select>
        <input className="border rounded px-2 py-1" placeholder="Address" value={address} onChange={(e)=>setAddress(e.target.value)} />
        <div className="flex gap-2">
          <input className="border rounded px-2 py-1 flex-1" placeholder="Contact" value={contact} onChange={(e)=>setContact(e.target.value)} />
          <button onClick={create} className="px-3 py-1 rounded bg-slate-900 text-white">Create</button>
        </div>
      </div>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-slate-600">
            <th className="py-2">Name</th>
            <th>Owner</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {items.map(p => (
            <tr key={p._id} className="border-t">
              <td className="py-2">{p.name}</td>
              <td>{p.ownerId?.name || '-'} ({p.ownerId?.email || '-'})</td>
              <td>
                <span className={`px-2 py-1 text-xs rounded-full ${p.status==='approved'?'bg-green-100 text-green-700':p.status==='pending'?'bg-amber-100 text-amber-700':'bg-red-100 text-red-700'}`}>{p.status}</span>
              </td>
              <td className="space-x-2">
                <button disabled={p.status!=='pending'} onClick={()=>approve(p._id)} className="px-2 py-1 text-xs bg-emerald-100 text-emerald-700 rounded disabled:opacity-50">Approve</button>
                <button disabled={p.status!=='pending'} onClick={()=>reject(p._id)} className="px-2 py-1 text-xs bg-red-100 text-red-700 rounded disabled:opacity-50">Reject</button>
                <button onClick={()=>remove(p._id)} title="Delete" className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700">🗑</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}



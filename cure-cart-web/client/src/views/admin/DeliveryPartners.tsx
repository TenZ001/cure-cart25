import { useEffect, useState } from 'react'
import axios from 'axios'

export default function AdminDeliveryPartners() {
  const [items, setItems] = useState<any[]>([])
  const [name, setName] = useState('')
  const [contact, setContact] = useState('')
  const [vehicleNo, setVehicleNo] = useState('')
  const refresh = () => axios.get('/api/admin/delivery-partners').then(({ data }) => setItems(data))
  useEffect(() => { refresh() }, [])
  const add = async () => {
    if (!name.trim()) return
    await axios.post('/api/admin/delivery-partners', { name, contact, vehicleNo })
    setName(''); setContact(''); setVehicleNo(''); refresh()
  }
  const approve = async (id: string) => { await axios.patch(`/api/admin/delivery-partners/${id}/approve`); refresh() }
  const reject = async (id: string) => { await axios.patch(`/api/admin/delivery-partners/${id}/reject`); refresh() }
  return (
    <div className="space-y-4">
      <div className="bg-white border border-slate-200 rounded-lg p-4">
        <div className="text-slate-900 font-semibold mb-3">Add Partner</div>
        <div className="grid md:grid-cols-3 gap-2">
          <input className="border rounded px-2 py-1" value={name} onChange={(e)=>setName(e.target.value)} placeholder="Name" />
          <input className="border rounded px-2 py-1" value={contact} onChange={(e)=>setContact(e.target.value)} placeholder="Contact" />
          <input className="border rounded px-2 py-1" value={vehicleNo} onChange={(e)=>setVehicleNo(e.target.value)} placeholder="Vehicle No" />
        </div>
        <div className="mt-2"><button onClick={add} className="px-3 py-1 rounded bg-slate-900 text-white">Add</button></div>
      </div>
      <div className="bg-white border border-slate-200 rounded-lg p-4">
        <div className="text-slate-900 font-semibold mb-3">Partners</div>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-600">
              <th className="py-2">Name</th>
              <th>Contact</th>
              <th>Vehicle</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map(p => (
              <tr key={p._id} className="border-t">
                <td className="py-2">{p.name}</td>
                <td>{p.contact || '-'}</td>
                <td>{p.vehicleNo || '-'}</td>
                <td><span className={`px-2 py-1 text-xs rounded-full ${p.status==='approved'?'bg-emerald-100 text-emerald-700':p.status==='pending'?'bg-amber-100 text-amber-700':'bg-red-100 text-red-700'}`}>{p.status || 'approved'}</span></td>
                <td className="space-x-2">
                  <button disabled={p.status==='approved'} onClick={()=>approve(p._id)} className="px-2 py-1 text-xs bg-emerald-100 text-emerald-700 rounded disabled:opacity-50">Approve</button>
                  <button disabled={p.status==='rejected'} onClick={()=>reject(p._id)} className="px-2 py-1 text-xs bg-red-100 text-red-700 rounded disabled:opacity-50">Reject</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}



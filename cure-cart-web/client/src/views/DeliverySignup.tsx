import { useState } from 'react'
import axios from 'axios'

export default function DeliverySignup() {
  const [phone, setPhone] = useState('')
  const [nic, setNic] = useState('')
  const [dl, setDl] = useState('')
  const [vehicles, setVehicles] = useState<string[]>([])
  const toggle = (v: string) => setVehicles(prev => prev.includes(v) ? prev.filter(x=>x!==v) : [...prev, v])
  const submit = async () => {
    if (!/^\d{10}$/.test(phone)) return alert('Enter 10-digit mobile number')
    if (!/^\d{12}$/.test(nic)) return alert('Enter 12-digit NIC number')
    if (!/^\d{8}$/.test(dl)) return alert('Enter 8-digit license number')
    try {
      await axios.post('/api/delivery-partners', { phone, nic, licenseNumber: dl, vehicles })
      alert('Request submitted. Await admin approval.')
      window.location.href = '/admin/delivery-partners'
    } catch (e) {
      alert('Failed to submit')
    }
  }
  return (
    <div className="max-w-xl bg-white rounded-xl border border-slate-200 p-6 shadow">
      <div className="text-xl font-semibold mb-4">Delivery Partner Signup</div>
      <div className="space-y-3">
        <div>
          <label className="text-xs text-slate-600">Mobile Number</label>
          <input className="mt-1 w-full border rounded-lg px-3 py-2" value={phone} onChange={e=>setPhone(e.target.value)} placeholder="07XXXXXXXX" />
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="text-xs text-slate-600">NIC Number (12 digits)</label>
            <input className="mt-1 w-full border rounded-lg px-3 py-2" value={nic} onChange={e=>setNic(e.target.value)} placeholder="200012345678" />
          </div>
          <div>
            <label className="text-xs text-slate-600">Driving License (8 digits)</label>
            <input className="mt-1 w-full border rounded-lg px-3 py-2" value={dl} onChange={e=>setDl(e.target.value)} placeholder="12345678" />
          </div>
        </div>
        <div>
          <label className="text-xs text-slate-600">Vehicles</label>
          <div className="mt-1 grid grid-cols-2 gap-2 text-sm">
            {['bike','car','threewheeler','van'].map(v => (
              <label key={v} className="inline-flex items-center gap-2">
                <input type="checkbox" checked={vehicles.includes(v)} onChange={()=>toggle(v)} /> {v}
              </label>
            ))}
          </div>
        </div>
        <div className="pt-2">
          <button className="px-4 py-2 rounded-lg bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow hover:opacity-95" onClick={submit}>Request approval</button>
        </div>
      </div>
    </div>
  )
}



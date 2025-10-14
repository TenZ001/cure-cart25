import { useEffect, useState } from 'react'
import axios from 'axios'

export default function PharmacyInfo() {
  const [address, setAddress] = useState('')
  const [contact, setContact] = useState('')
  const [hours, setHours] = useState('')
  const [name, setName] = useState('')
  const [status, setStatus] = useState<'pending'|'approved'|'rejected'|null>(null)
  const [rejectionReason, setRejectionReason] = useState<string | null>(null)

  useEffect(() => {
    axios.get('/api/pharmacies/me').then(({ data }) => {
      if (data) {
        setName(data.name || '')
        setAddress(data.address || '')
        setContact(data.contact || '')
        setStatus(data.status)
        setRejectionReason(data.rejectionReason || null)
      }
    })
  }, [])

  const requestApproval = async () => {
    if (!name.trim()) return alert('Enter pharmacy name')
    const { data } = await axios.post('/api/pharmacies', { name, address, contact })
    setStatus(data.status)
    alert('Pharmacy submitted for approval')
  }

  const save = async () => {
    if (status !== 'approved') return
    await axios.patch('/api/pharmacies/me', { name, address, contact })
    alert('Saved')
  }
  return (
    <div className="card max-w-2xl">
      <div className="font-medium mb-4">Pharmacy Information</div>
      {status === 'approved' && (
        <div className="mb-4 p-3 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-800">
          ✅ Your pharmacy is approved.
        </div>
      )}
      {status === 'rejected' && (
        <div className="mb-4 p-3 rounded-lg bg-red-50 border border-red-200 text-red-800">
          ❌ Rejected: {rejectionReason || 'Not specified'}
        </div>
      )}
      {status === 'pending' && (
        <div className="mb-4 p-3 rounded-lg bg-amber-50 border border-amber-200 text-amber-800">
          ⏳ Awaiting admin approval…
        </div>
      )}
      <div className="space-y-3">
        <input value={name} onChange={(e)=>setName(e.target.value)} placeholder="Pharmacy name" className="w-full border rounded-lg px-3 py-2" disabled={status !== 'approved' && !!status}/>
        <input value={address} onChange={(e)=>setAddress(e.target.value)} placeholder="Address" className="w-full border rounded-lg px-3 py-2" disabled={status !== 'approved' && !!status}/>
        <input value={contact} onChange={(e)=>setContact(e.target.value)} placeholder="Contact info" className="w-full border rounded-lg px-3 py-2" disabled={status !== 'approved' && !!status}/>
        <input value={hours} onChange={(e)=>setHours(e.target.value)} placeholder="Operating hours" className="w-full border rounded-lg px-3 py-2" disabled={status !== 'approved' && !!status}/>
        {status === 'approved' && (
          <button onClick={save} className="btn-primary w-fit">Save</button>
        )}
        {status === null && (
          <button onClick={requestApproval} className="btn-primary w-fit">Request Approval</button>
        )}
      </div>
    </div>
  )
}



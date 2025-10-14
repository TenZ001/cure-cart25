import { useEffect, useMemo, useState } from 'react'
import axios from 'axios'
import { Card } from '../ui/Card'
import { Button } from '../ui/Button'
import { FileCheck } from 'lucide-react'
import { io } from 'socket.io-client'

type Prescription = { _id: string; imageUrl?: string; status: string; createdAt: string; patientName?: string; patientId?: string; doctorName?: string; doctorLicense?: string; medicines?: { name: string; dosage: string; duration: string }[]; issuedAt?: string }

export default function Prescriptions() {
  const [items, setItems] = useState<Prescription[]>([])
  const [tab, setTab] = useState<'pending'|'approved'|'rejected'>('pending')
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [editing, setEditing] = useState<any | null>(null)
  const [ordering, setOrdering] = useState<any | null>(null)
  const [partners, setPartners] = useState<any[]>([])
  const [orderPrice, setOrderPrice] = useState<string>('')
  const [orderPartnerId, setOrderPartnerId] = useState<string>('')
  useEffect(() => { 
    console.log('🔍 [WEB] Fetching prescriptions for tab:', tab);
    axios.get(`/api/prescriptions?status=${tab}`)
      .then(({ data }) => {
        console.log('📋 [WEB] Prescriptions received:', data.length);
        console.log('📋 [WEB] Prescription data:', data);
        setItems(data);
      })
      .catch(err => {
        console.error('❌ [WEB] Error fetching prescriptions:', err);
      });
  }, [tab])

  // Realtime subscription
  useEffect(() => {
    const socket = io('/', { path: '/socket.io', transports: ['websocket'] })
    const onNew = (p: Prescription) => {
      if (tab === 'pending' && p.status === 'pending') setItems(prev => [p, ...prev])
    }
    const onUpdated = (p: Prescription) => {
      setItems(prev => prev.map(x => x._id === p._id ? p : x))
    }
    socket.on('prescription:new', onNew)
    socket.on('prescription:updated', onUpdated)
    return () => {
      socket.off('prescription:new', onNew)
      socket.off('prescription:updated', onUpdated)
      socket.close()
    }
  }, [tab])
  const update = async (id: string, status: string) => {
    const { data } = await axios.patch(`/api/prescriptions/${id}`, { status })
    setItems((prev) => prev.map((p) => p._id === id ? data : p))
  }
  const openEdit = (p: any) => {
    const meds = Array.isArray((p as any).medicines) ? (p as any).medicines as any[] : []
    const medicinesText = meds.map(m => `${m.name || ''} | ${m.dosage || ''} | ${m.duration || ''}`.trim()).join('\n')
    setEditing({
      _id: p._id,
      notes: (p as any).notes || '',
      patientName: (p as any).patientName || '',
      patientId: (p as any).patientId || '',
      customerAddress: (p as any).customerAddress || '',
      medicinesText,
    })
  }
  const saveEdit = async () => {
    if (!editing?._id) return
    try {
      const payload: any = {
        notes: editing.notes,
        patientName: editing.patientName,
        patientId: editing.patientId,
        customerAddress: editing.customerAddress,
      }
      if (typeof editing.medicinesText === 'string') {
        const lines = editing.medicinesText.split(/\r?\n/).map((l: string) => l.trim()).filter(Boolean)
        payload.medicines = lines.map((line: string) => {
          const [name = '', dosage = '', duration = ''] = line.split('|').map(s => s.trim())
          return { name, dosage, duration }
        })
      }
      const { data } = await axios.patch(`/api/prescriptions/${editing._id}`, payload)
      setItems(prev => prev.map(x => x._id === editing._id ? data : x))
      setEditing(null)
    } catch (e) {
      alert('Failed to save changes')
    }
  }
  const printItem = (p: Prescription) => {
    const text = [
      `Prescription ${p._id}`,
      `Patient: ${p.patientName || '-'} (${p.patientId || '-'})`,
      `Doctor: ${p.doctorName || '-'} (${p.doctorLicense || '-'})`,
      `Issued: ${p.issuedAt ? new Date(p.issuedAt).toLocaleString() : '-'}`,
      'Medicines:',
      ...(p.medicines?.map(m => `- ${m.name} | ${m.dosage} | ${m.duration}`) || ['-'])
    ].join('\n')
    const w = window.open('', '_blank')
    if (w) {
      w.document.write(`<pre>${text}</pre>`)
      w.document.close()
      w.print()
    }
  }
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-gradient-to-br from-blue-500 to-purple-500 shadow-lg">
            <FileCheck className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900">Prescriptions</h2>
        </div>
        <div className="flex gap-2 text-sm">
          {(['pending','approved','rejected'] as const).map(t => (
            <button 
              key={t} 
              onClick={()=>setTab(t)} 
              className={`px-4 py-2 rounded-full transition-all duration-200 font-medium ${
                tab===t 
                  ? 'bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow-lg' 
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {t.charAt(0).toUpperCase() + t.slice(1)}
            </button>
          ))}
        </div>
      </div>
      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {items.map(p => (
          <Card key={p._id} className={`p-6 shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105 relative overflow-hidden ${
            p.status === 'pending' ? 'shadow-amber-500/25' :
            p.status === 'approved' ? 'shadow-emerald-500/25' :
            'shadow-red-500/25'
          }`}>
            <div className="absolute inset-0 bg-gradient-to-br opacity-5 rounded-xl" style={{
              background: p.status === 'pending' ? 'linear-gradient(135deg, #f59e0b, #ea580c)' :
                          p.status === 'approved' ? 'linear-gradient(135deg, #10b981, #059669)' :
                          'linear-gradient(135deg, #ef4444, #dc2626)'
            }}></div>
            {/* Top-right edit icon */}
            <button
              className="absolute top-2 right-2 z-10 text-slate-600 hover:text-slate-900 bg-white/80 backdrop-blur rounded-full w-8 h-8 flex items-center justify-center shadow"
              title="Edit details"
              aria-label="Edit details"
              onClick={()=>openEdit(p as any)}
            >
              ✏️
            </button>
            <div className="relative">
              <div className="flex items-center justify-between mb-3">
                <div className="text-xs text-slate-500 font-medium">{new Date(p.createdAt).toLocaleString()}</div>
                <div className={`px-2 py-1 rounded-full text-xs font-medium ${
                  p.status === 'pending' ? 'bg-amber-100 text-amber-800' :
                  p.status === 'approved' ? 'bg-emerald-100 text-emerald-800' :
                  'bg-red-100 text-red-800'
                }`}>
                  {p.status}
                </div>
              </div>
              <div className="mt-2 h-40 bg-gradient-to-br from-slate-100 to-slate-200 rounded-lg flex items-center justify-center text-slate-500 border-2 border-dashed border-slate-300 overflow-hidden">
                {p.imageUrl ? (
                  <img
                    src={p.imageUrl}
                    alt="Prescription"
                    className="h-full max-w-full object-contain cursor-zoom-in"
                    onClick={() => setPreviewUrl(p.imageUrl!)}
                  />
                ) : (
                  <div className="text-center">
                    <div className="w-12 h-12 bg-slate-300 rounded-lg flex items-center justify-center mx-auto mb-2">
                      <FileCheck className="w-6 h-6 text-slate-500" />
                    </div>
                    <span className="text-sm">No image</span>
                  </div>
                )}
              </div>
              <div className="mt-3 text-sm text-slate-700 space-y-1">
                <div><b>ID:</b> {p._id.slice(-6)}</div>
                <div><b>Patient:</b> {p.patientName || '-'} ({p.patientId || '-'})</div>
                <div><b>Doctor:</b> {p.doctorName || '-'} (Lic: {p.doctorLicense || '-'})</div>
                <div><b>Customer Address:</b> { (p as any).customerAddress || '-' }</div>
                <div><b>Customer Contact:</b> { (p as any).customerPhone || '-' }</div>
                <div><b>Age/Gender:</b> {(p as any).customerAge || '-'} / {(p as any).customerGender || '-'}</div>
                <div>
                  <b>Medicines:</b>
                  <ul className="list-disc pl-5">
                    {p.medicines?.length ? p.medicines.map((m,i)=>(<li key={i}>{m.name} — {m.dosage}, {m.duration}</li>)) : <li>-</li>}
                  </ul>
                </div>
                <div><b>Status:</b> {p.status}</div>
                <div><b>Issued:</b> {p.issuedAt ? new Date(p.issuedAt).toLocaleString() : '-'}</div>
              </div>
              <div className="mt-3 flex items-center justify-between">
                <div />
                <div className="flex gap-2">
                  {p.status === 'approved' && (
                    <Button size="sm" onClick={async ()=>{
                      try {
                        const { data } = await axios.get('/api/delivery-partners/approved')
                        setPartners(data || [])
                        setOrderPartnerId((data?.[0]?._id) || '')
                        setOrderPrice('')
                        setOrdering({ _id: (p as any)._id, paymentMethod: (p as any).paymentMethod || 'cod', customerAddress: (p as any).customerAddress || '-', customerPhone: (p as any).customerPhone || '-' })
                      } catch {
                        alert('Failed to load delivery partners')
                      }
                    }}>Process the order</Button>
                  )}
                  <Button size="sm" onClick={()=>update(p._id,'approved')}>Approve</Button>
                  <Button size="sm" variant="secondary" onClick={()=>update(p._id,'rejected')}>Reject</Button>
                  <Button size="sm" variant="ghost" onClick={()=>printItem(p)}>Print</Button>
                </div>
              </div>
            </div>
          </Card>
        ))}
      </div>
      {/* Image preview modal */}
      {previewUrl && (
        <div
          className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4"
          onClick={() => setPreviewUrl(null)}
        >
          <div className="relative max-w-5xl w-full" onClick={(e) => e.stopPropagation()}>
            <button
              className="absolute -top-2 -right-2 bg-white text-slate-700 rounded-full w-8 h-8 shadow hover:bg-slate-100"
              onClick={() => setPreviewUrl(null)}
              aria-label="Close"
            >
              ✕
            </button>
            <img src={previewUrl} alt="Prescription" className="w-full max-h-[80vh] object-contain rounded" />
          </div>
        </div>
      )}
      {/* Edit details modal */}
      {editing && (
        <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4" onClick={()=>setEditing(null)}>
          <div className="relative max-w-2xl w-full bg-white rounded-xl" onClick={(e)=>e.stopPropagation()}>
            <div className="px-5 py-4 border-b flex items-center justify-between">
              <div className="font-semibold text-slate-900">Edit Prescription Details</div>
              <button className="text-slate-500 hover:text-slate-700" onClick={()=>setEditing(null)} aria-label="Close">✕</button>
            </div>
            <div className="p-5 grid grid-cols-1 gap-4">
              <div>
                <label className="text-xs text-slate-600">Notes</label>
                <textarea className="mt-1 w-full border rounded-lg px-3 py-2" rows={3} value={editing.notes} onChange={e=>setEditing({ ...editing, notes: e.target.value })} />
              </div>
              <div className="grid sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-xs text-slate-600">Patient Name</label>
                  <input className="mt-1 w-full border rounded-lg px-3 py-2" value={editing.patientName} onChange={e=>setEditing({ ...editing, patientName: e.target.value })} />
                </div>
                <div>
                  <label className="text-xs text-slate-600">Patient ID</label>
                  <input className="mt-1 w-full border rounded-lg px-3 py-2" value={editing.patientId} onChange={e=>setEditing({ ...editing, patientId: e.target.value })} />
                </div>
              </div>
              <div>
                <label className="text-xs text-slate-600">Customer Address</label>
                <input className="mt-1 w-full border rounded-lg px-3 py-2" value={editing.customerAddress} onChange={e=>setEditing({ ...editing, customerAddress: e.target.value })} />
              </div>
              <div>
                <label className="text-xs text-slate-600">Medicines (one per line: name | dosage | duration)</label>
                <textarea className="mt-1 w-full border rounded-lg px-3 py-2" rows={4} value={editing.medicinesText || ''} onChange={e=>setEditing({ ...editing, medicinesText: e.target.value })} />
              </div>
            </div>
            <div className="px-5 py-4 border-t flex items-center justify-end gap-2">
              <button className="px-4 py-2 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200" onClick={()=>setEditing(null)}>Cancel</button>
              <button className="px-4 py-2 rounded-lg bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow hover:opacity-95" onClick={saveEdit}>Save</button>
            </div>
          </div>
        </div>
      )}

      {/* Order processing modal */}
      {ordering && (
        <div className="fixed inset-0 z-50 bg-black/70 flex items-center justify-center p-4" onClick={()=>setOrdering(null)}>
          <div className="relative max-w-lg w-full bg-white rounded-xl" onClick={(e)=>e.stopPropagation()}>
            <div className="px-5 py-4 border-b flex items-center justify-between">
              <div className="font-semibold text-slate-900">Process Order</div>
              <button className="text-slate-500 hover:text-slate-700" onClick={()=>setOrdering(null)} aria-label="Close">✕</button>
            </div>
            <div className="p-5 grid grid-cols-1 gap-4">
              <div>
                <label className="text-xs text-slate-600">Delivery Partner</label>
                <select className="mt-1 w-full border rounded-lg px-3 py-2" value={orderPartnerId} onChange={e=>setOrderPartnerId(e.target.value)}>
                  {partners.map(p => (<option key={p._id} value={p._id}>{p.name} — {p.contact || ''}</option>))}
                </select>
              </div>
              <div>
                <label className="text-xs text-slate-600">Total Price (Rs)</label>
                <input className="mt-1 w-full border rounded-lg px-3 py-2" value={orderPrice} onChange={e=>setOrderPrice(e.target.value)} placeholder="0" />
              </div>
              <div className="text-sm text-slate-700">
                <div><b>Payment:</b> {ordering.paymentMethod || 'cod'}</div>
                <div><b>Customer Address:</b> {ordering.customerAddress}</div>
                <div><b>Customer Phone:</b> {ordering.customerPhone}</div>
              </div>
            </div>
            <div className="px-5 py-4 border-t flex items-center justify-end gap-2">
              <button className="px-4 py-2 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200" onClick={()=>setOrdering(null)}>Cancel</button>
              <button className="px-4 py-2 rounded-lg bg-gradient-to-r from-blue-500 to-purple-500 text-white shadow hover:opacity-95" onClick={async ()=>{
                try {
                  const total = Number(orderPrice || '0')
                  const { data } = await axios.post('/api/orders/from-prescription', {
                    prescriptionId: ordering._id,
                    deliveryPartnerId: orderPartnerId,
                    total,
                    paymentMethod: ordering.paymentMethod,
                  })
                  setOrdering(null)
                  alert('Order created')
                  // Refresh list
                  const { data: refreshed } = await axios.get(`/api/prescriptions?status=${tab}`)
                  setItems(refreshed)
                } catch (error: any) {
                  console.error('Order creation failed:', error);
                  const errorMessage = error.response?.data?.error || error.message || 'Failed to create order';
                  alert(`Failed to create order: ${errorMessage}`);
                }
              }}>Confirm</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}



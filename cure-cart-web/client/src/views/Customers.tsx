import { useEffect, useState } from 'react'
import axios from 'axios'
import { Card } from '../ui/Card'
import { Button } from '../ui/Button'
import { Input } from '../ui/Input'
import { Modal, ModalHeader, ModalCloseButton } from '../ui/Modal'
import { Label } from '../ui/Label'
import { Users, Search } from 'lucide-react'

type Customer = { _id: string; name: string; email: string; phone?: string; address?: string; age?: number; gender?: string; rewardPoints?: number; dues?: number }

export default function Customers() {
  const [items, setItems] = useState<Customer[]>([])
  const [q, setQ] = useState('')
  const [editing, setEditing] = useState<Customer | null>(null)
  const [approvedOpen, setApprovedOpen] = useState(false)
  const [approvedFor, setApprovedFor] = useState<string>('')
  const [approvedItems, setApprovedItems] = useState<any[]>([])

  useEffect(() => { axios.get('/api/customers').then(({ data }) => setItems(data)) }, [])

  const filtered = items.filter(i => [i.name, i.email, i.phone].filter(Boolean).join(' ').toLowerCase().includes(q.toLowerCase()))

  const remind = async (id: string) => {
    await axios.post(`/api/customers/${id}/reminders`, { title: 'Refill reminder', body: 'Your refill might be due soon.' })
    alert('Reminder sent')
  }

  const openEdit = (c: Customer) => setEditing(c)
  const saveEdit = async () => {
    if (!editing) return
    const { _id, name, phone, address, age, gender, rewardPoints, dues } = editing
    const { data } = await axios.patch(`/api/customers/${_id}`, { name, phone, address, age, gender, rewardPoints, dues })
    setItems(prev => prev.map(it => it._id === _id ? data : it))
    setEditing(null)
  }

  const openApproved = async (c: Customer) => {
    try {
      const { data } = await axios.get(`/api/customers/${c._id}`)
      const list = (data?.prescriptions || []).filter((p: any) => p.status === 'approved')
      const customerName = data?.customer?.name || c.name
      const withFallbacks = list.map((p: any) => ({
        ...p,
        patientName: p.patientName || customerName,
        customerAddress: p.customerAddress || data?.customer?.address || '',
        customerPhone: p.customerPhone || data?.customer?.phone || '',
      }))
      setApprovedItems(withFallbacks)
      setApprovedFor(c.name)
      setApprovedOpen(true)
    } catch {
      alert('Failed to load approved prescriptions')
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-500 shadow-lg">
            <Users className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900">Customers</h2>
        </div>
        <div className="relative w-80">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-slate-400" />
          <Input 
            placeholder="Search customers..." 
            value={q} 
            onChange={(e)=>setQ(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>
      <Card className="p-0 overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-600 bg-gradient-to-r from-slate-50 to-slate-100">
              <th className="py-3 px-4 font-semibold">Name</th>
              <th className="px-3 font-semibold">Contact</th>
              <th className="px-3 font-semibold">Address</th>
              <th className="px-3 font-semibold">Age/Gender</th>
              <th className="px-3 font-semibold">Points</th>
              <th className="px-3 font-semibold">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(c => (
              <tr key={c._id} className="border-t hover:bg-slate-50 transition-colors duration-200">
                <td className="py-3 px-4 font-medium text-slate-900">{c.name}</td>
                <td className="px-3 text-slate-600">{c.email}{c.phone ? ` · ${c.phone}` : ''}</td>
                <td className="px-3 text-slate-600">{c.address || '-'}</td>
                <td className="px-3 text-slate-600">{c.age || '-'} / {c.gender || '-'}</td>
                <td className="px-3">
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">
                    {c.rewardPoints || 0}
                  </span>
                </td>
                <td className="px-3 space-x-2">
                  <Button 
                    size="sm" 
                    onClick={()=>openEdit(c)}
                    className="bg-gradient-to-r from-blue-500 to-indigo-500 hover:from-blue-600 hover:to-indigo-600 shadow-md"
                  >
                    Edit
                  </Button>
                  <Button 
                    size="sm" 
                    onClick={()=>openApproved(c)}
                    className="bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 shadow-md"
                  >
                    Approved Prescriptions
                  </Button>
                  <button
                    title="Delete customer"
                    onClick={async ()=>{ if (!confirm('Delete this customer?')) return; await axios.delete(`/api/customers/${c._id}`); setItems(prev=>prev.filter(it=>it._id!==c._id)) }}
                    className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-red-600 hover:bg-red-700 text-white align-middle"
                  >
                    🗑
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>

      <Modal open={!!editing} onOpenChange={()=>setEditing(null)}>
        <ModalCloseButton />
        <ModalHeader title="Edit customer" />
        {editing && (
          <div className="grid grid-cols-2 gap-3">
            <div className="col-span-2"><Label>Name</Label><Input value={editing.name} onChange={(e)=>setEditing({ ...editing, name: e.target.value })} /></div>
            <div><Label>Phone</Label><Input value={editing.phone || ''} onChange={(e)=>setEditing({ ...editing, phone: e.target.value })} /></div>
            <div><Label>Address</Label><Input value={editing.address || ''} onChange={(e)=>setEditing({ ...editing, address: e.target.value })} /></div>
            <div><Label>Age</Label><Input type="number" value={editing.age || 0 as any} onChange={(e)=>setEditing({ ...editing, age: Number(e.target.value) as any })} /></div>
            <div><Label>Gender</Label><Input value={editing.gender || ''} onChange={(e)=>setEditing({ ...editing, gender: e.target.value })} /></div>
            <div><Label>Reward points</Label><Input type="number" value={editing.rewardPoints || 0 as any} onChange={(e)=>setEditing({ ...editing, rewardPoints: Number(e.target.value) as any })} /></div>
            <div><Label>Dues</Label><Input type="number" value={editing.dues || 0 as any} onChange={(e)=>setEditing({ ...editing, dues: Number(e.target.value) as any })} /></div>
            <div className="col-span-2 flex justify-end gap-2">
              <Button variant="secondary" type="button" onClick={()=>setEditing(null)}>Cancel</Button>
              <Button type="button" onClick={saveEdit}>Save</Button>
            </div>
          </div>
        )}
      </Modal>
      <Modal open={approvedOpen} onOpenChange={()=>setApprovedOpen(false)}>
        <ModalCloseButton />
        <ModalHeader title={`Approved prescriptions — ${approvedFor || ''}`} />
        <div className="grid gap-3">
          {approvedItems.length === 0 ? (
            <div className="text-slate-500 text-sm">No approved prescriptions.</div>
          ) : (
            approvedItems.map((p: any) => (
              <Card key={p._id} className="p-3">
                <div className="text-sm"><b>Patient:</b> {p.patientName || '-'}</div>
                <div className="text-sm"><b>Address:</b> {p.customerAddress || '-'}</div>
                <div className="text-sm"><b>Contact:</b> {p.customerPhone || '-'}</div>
                <div className="text-xs text-slate-500 mt-1">{new Date(p.createdAt).toLocaleString()}</div>
              </Card>
            ))
          )}
        </div>
      </Modal>
    </div>
  )
}



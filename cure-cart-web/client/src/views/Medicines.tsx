import { useEffect, useMemo, useState } from 'react'
import axios from 'axios'
import { Card } from '../ui/Card'
import { Button } from '../ui/Button'
import { Input } from '../ui/Input'
import { Label } from '../ui/Label'
import { Modal, ModalHeader, ModalCloseButton } from '../ui/Modal'
import { Trash2, ClipboardList } from 'lucide-react'
import { useToast } from '../hooks/useToast'

type Item = { _id: string; medicineId?: string; name: string; sku?: string; batchNo?: string; category?: string; stock: number; lowStockThreshold?: number; expiryDate?: string; supplierName?: string; supplierContact?: string; purchasePrice?: number; sellingPrice?: number; discount?: number }

const MEDICINE_CATEGORIES = [
  'Pain Relief',
  'Antibiotics', 
  'Cardiovascular',
  'Diabetes',
  'Respiratory',
  'Digestive',
  'Vitamins',
  'Skin Care',
  'Eye Care',
  'Other'
]

export default function Medicines() {
  const { success, error: showError } = useToast()
  const [items, setItems] = useState<Item[]>([])
  const [query, setQuery] = useState('')
  const [open, setOpen] = useState(false)
  const [editing, setEditing] = useState<Item | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [form, setForm] = useState<Partial<Item>>({ 
    name: '', 
    stock: 0, 
    sellingPrice: 0, 
    category: 'Other',
    lowStockThreshold: 5
  })

  const refresh = async () => {
    try {
      // First try to migrate any existing items without medicine IDs
      await axios.post('/api/inventory/migrate-ids')
      // Then fetch the updated inventory
      const { data } = await axios.get('/api/inventory')
      setItems(data)
    } catch (error) {
      // If migration fails, just fetch normally
      const { data } = await axios.get('/api/inventory')
      setItems(data)
    }
  }
  useEffect(() => { refresh() }, [])

  const filtered = useMemo(() => items.filter(i => 
    `${i.name} ${i.medicineId || ''} ${i.sku || ''} ${i.batchNo || ''} ${i.category || ''} ${i.supplierName || ''}`.toLowerCase().includes(query.toLowerCase())
  ), [items, query])

  const resetForm = () => {
    setForm({ 
      name: '', 
      stock: 0, 
      sellingPrice: 0, 
      category: 'Other',
      lowStockThreshold: 5
    })
    setEditing(null)
    setError(null)
  }

  const openModal = (item?: Item) => {
    if (item) {
      setEditing(item)
      setForm({
        name: item.name,
        sku: item.sku,
        batchNo: item.batchNo,
        category: item.category || 'Other',
        stock: item.stock,
        lowStockThreshold: item.lowStockThreshold || 5,
        expiryDate: item.expiryDate,
        supplierName: item.supplierName,
        supplierContact: item.supplierContact,
        purchasePrice: item.purchasePrice,
        sellingPrice: item.sellingPrice,
        discount: item.discount
      })
    } else {
      resetForm()
    }
    setOpen(true)
  }

  const save = async () => {
    try {
      setError(null)
      if (!form.name?.trim()) {
        setError('Medicine name is required')
        return
      }
      
      if (editing) {
        await axios.patch(`/api/inventory/${editing._id}`, form)
        success('Medicine Updated', 'Medicine information has been updated successfully')
      } else {
        await axios.post('/api/inventory', form)
        success('Medicine Added', 'New medicine has been added to inventory')
      }
      
      setOpen(false)
      resetForm()
      refresh()
    } catch (err: any) {
      const errorMessage = err?.response?.data?.error || 'Failed to save medicine'
      setError(errorMessage)
      showError('Save Failed', errorMessage)
    }
  }

  const deleteMedicine = async (id: string) => {
    if (confirm('Are you sure you want to delete this medicine?')) {
      try {
        await axios.delete(`/api/inventory/${id}`)
        success('Medicine Deleted', 'Medicine has been removed from inventory')
        refresh()
      } catch (err: any) {
        const errorMessage = err?.response?.data?.error || 'Failed to delete medicine'
        showError('Delete Failed', errorMessage)
      }
    }
  }

  const status = (i: Item) => i.stock <= (i.lowStockThreshold || 5) ? 'Low' : (i.stock === 0 ? 'Out' : 'OK')
  const isNearExpiry = (i: Item) => i.expiryDate ? (new Date(i.expiryDate).getTime() - Date.now()) < 1000*60*60*24*30 : false
  const isExpired = (i: Item) => i.expiryDate ? new Date(i.expiryDate) < new Date() : false

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-gradient-to-br from-emerald-500 to-teal-500 shadow-lg">
            <ClipboardList className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900">Medicines</h2>
        </div>
        <div className="flex gap-3">
          <Input 
            placeholder="Search medicines, ID, category, supplier..." 
            value={query} 
            onChange={(e)=>setQuery(e.target.value)}
            className="w-80"
          />
          <Button 
            onClick={()=>openModal()}
            className="bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600 shadow-lg"
          >
            Add Medicine
          </Button>
        </div>
      </div>
      <Card className="p-0 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-600 bg-slate-50">
              <th className="py-2 px-4">Medicine ID</th>
              <th className="px-2">Name</th>
              <th className="px-2">Category</th>
              <th className="px-2">Batch</th>
              <th className="px-2">Expiry</th>
              <th className="px-2">Stock</th>
              <th className="px-2">Supplier</th>
              <th className="px-2">Price</th>
              <th className="px-2">Alerts</th>
              <th className="px-2">Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map(i => (
              <tr key={i._id} className="border-t">
                <td className="py-2 px-4 font-mono text-xs text-slate-500">{i.medicineId || '-'}</td>
                <td className="px-2 font-medium">{i.name}</td>
                <td className="px-2">{i.category || '-'}</td>
                <td className="px-2">{i.batchNo || '-'}</td>
                <td className="px-2">{i.expiryDate ? new Date(i.expiryDate).toLocaleDateString() : '-'}</td>
                <td className="px-2">{i.stock} <span className="text-slate-500">({status(i)})</span></td>
                <td className="px-2">{i.supplierName || '-'}{i.supplierContact ? ` · ${i.supplierContact}` : ''}</td>
                <td className="px-2">Rs. {(i.sellingPrice || 0).toFixed(2)}</td>
                <td className="px-2 text-sm">
                  {isExpired(i) ? <span className="text-red-600">Expired</span> : isNearExpiry(i) ? <span className="text-amber-600">Near Expiry</span> : '-'}
                </td>
                <td className="px-2">
                  <div className="flex gap-2">
                    <Button size="sm" variant="secondary" onClick={()=>openModal(i)}>Update</Button>
                    <button 
                      onClick={()=>deleteMedicine(i._id)}
                      className="p-1 text-red-600 hover:bg-red-50 rounded transition-colors"
                      title="Delete medicine"
                    >
                      <Trash2 size={16} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>

      <Modal open={open} onOpenChange={(open) => { setOpen(open); if (!open) resetForm() }}>
        <ModalCloseButton />
        <ModalHeader 
          title={editing ? "Update medicine" : "Add medicine"} 
          description={editing ? "Update medicine information" : "Create a new medicine record"} 
        />
        {error && <div className="mb-3 p-2 bg-red-50 border border-red-200 rounded text-red-600 text-sm">{error}</div>}
        <div className="grid grid-cols-2 gap-3">
          <div className="col-span-2">
            <Label>Medicine Name *</Label>
            <Input 
              value={form.name || ''} 
              onChange={(e)=>setForm(f=>({ ...f, name: e.target.value }))} 
              placeholder="Enter medicine name"
            />
          </div>
          <div>
            <Label>SKU</Label>
            <Input 
              value={form.sku || ''} 
              onChange={(e)=>setForm(f=>({ ...f, sku: e.target.value }))} 
              placeholder="Product SKU"
            />
          </div>
          <div>
            <Label>Category</Label>
            <select 
              value={form.category || 'Other'} 
              onChange={(e)=>setForm(f=>({ ...f, category: e.target.value }))}
              className="w-full h-10 rounded-md border border-slate-200 bg-white px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-primary focus-visible:ring-offset-2"
            >
              {MEDICINE_CATEGORIES.map(cat => (
                <option key={cat} value={cat}>{cat}</option>
              ))}
            </select>
          </div>
          <div>
            <Label>Batch No.</Label>
            <Input 
              value={form.batchNo || ''} 
              onChange={(e)=>setForm(f=>({ ...f, batchNo: e.target.value }))} 
              placeholder="Batch number"
            />
          </div>
          <div>
            <Label>Stock</Label>
            <Input 
              type="number" 
              value={form.stock || 0} 
              onChange={(e)=>setForm(f=>({ ...f, stock: Number(e.target.value) }))} 
              min="0"
            />
          </div>
          <div>
            <Label>Low Stock Threshold</Label>
            <Input 
              type="number" 
              value={form.lowStockThreshold || 5} 
              onChange={(e)=>setForm(f=>({ ...f, lowStockThreshold: Number(e.target.value) }))} 
              min="0"
            />
          </div>
          <div>
            <Label>Expiry Date</Label>
            <Input 
              type="date" 
              value={form.expiryDate as any || ''} 
              onChange={(e)=>setForm(f=>({ ...f, expiryDate: e.target.value }))} 
            />
          </div>
          <div>
            <Label>Supplier Name</Label>
            <Input 
              value={form.supplierName || ''} 
              onChange={(e)=>setForm(f=>({ ...f, supplierName: e.target.value }))} 
              placeholder="Supplier company"
            />
          </div>
          <div>
            <Label>Supplier Contact</Label>
            <Input 
              value={form.supplierContact || ''} 
              onChange={(e)=>setForm(f=>({ ...f, supplierContact: e.target.value }))} 
              placeholder="Phone/Email"
            />
          </div>
          <div>
            <Label>Purchase Price (Rs.)</Label>
            <Input 
              type="text" 
              value={form.purchasePrice || ''} 
              onChange={(e)=>setForm(f=>({ ...f, purchasePrice: parseFloat(e.target.value) || 0 }))} 
              placeholder="0.00"
            />
          </div>
          <div>
            <Label>Selling Price (Rs.)</Label>
            <Input 
              type="text" 
              value={form.sellingPrice || ''} 
              onChange={(e)=>setForm(f=>({ ...f, sellingPrice: parseFloat(e.target.value) || 0 }))} 
              placeholder="0.00"
            />
          </div>
          <div className="col-span-2 flex justify-end gap-2">
            <Button variant="secondary" type="button" onClick={()=>setOpen(false)}>Cancel</Button>
            <Button type="button" onClick={save}>{editing ? 'Update' : 'Add'} Medicine</Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}





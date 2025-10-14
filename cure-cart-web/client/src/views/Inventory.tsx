import { useEffect, useState } from 'react'
import axios from 'axios'
import { Button } from '../ui/Button'
import { Card } from '../ui/Card'
import { Input } from '../ui/Input'
import { Label } from '../ui/Label'
import { Modal, ModalHeader, ModalCloseButton } from '../ui/Modal'
import { Boxes, Plus } from 'lucide-react'

type Item = { _id: string; sku?: string; name: string; stock: number; expiryDate?: string; price: number; available: boolean }

export default function Inventory() {
  const [items, setItems] = useState<Item[]>([])
  const [name, setName] = useState('')
  const [price, setPrice] = useState(0)
  const [open, setOpen] = useState(false)

  const refresh = () => axios.get('/api/inventory').then(({ data }) => setItems(data))
  useEffect(() => { refresh() }, [])

  const add = async () => {
    if (!name.trim()) return
    await axios.post('/api/inventory', { name, price, stock: 0, available: true })
    setName(''); setPrice(0); setOpen(false); refresh()
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-gradient-to-br from-cyan-500 to-blue-500 shadow-lg">
            <Boxes className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900">Inventory</h2>
        </div>
        <Button 
          onClick={() => setOpen(true)}
          className="bg-gradient-to-r from-cyan-500 to-blue-500 hover:from-cyan-600 hover:to-blue-600 shadow-lg inline-flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Add Item
        </Button>
      </div>
      <Card className="p-0 overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-600 bg-gradient-to-r from-slate-50 to-slate-100">
              <th className="py-3 px-4 font-semibold">Name</th>
              <th className="px-3 font-semibold">Stock</th>
              <th className="px-3 font-semibold">Price</th>
              <th className="px-3 font-semibold">Available</th>
            </tr>
          </thead>
          <tbody>
            {items.map(i => (
              <tr key={i._id} className="border-t hover:bg-slate-50 transition-colors duration-200">
                <td className="py-3 px-4 font-medium text-slate-900">{i.name}</td>
                <td className="px-3">
                  <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                    i.stock === 0 ? 'bg-red-100 text-red-800' :
                    i.stock <= 5 ? 'bg-yellow-100 text-yellow-800' :
                    'bg-green-100 text-green-800'
                  }`}>
                    {i.stock}
                  </span>
                </td>
                <td className="px-3 font-semibold text-green-600">Rs. {i.price?.toFixed(2) || '0.00'}</td>
                <td className="px-3">
                  <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                    i.available ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {i.available ? 'Yes' : 'No'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>

      <Modal open={open} onOpenChange={setOpen}>
        <ModalCloseButton />
        <ModalHeader title="Add inventory item" description="Create a new item in your catalog" />
        <div className="space-y-3">
          <div>
            <Label htmlFor="name">Name</Label>
            <Input id="name" value={name} onChange={(e)=>setName(e.target.value)} placeholder="Item name" />
          </div>
          <div>
            <Label htmlFor="price">Price</Label>
            <Input id="price" value={price} onChange={(e)=>setPrice(Number(e.target.value))} type="number" placeholder="0.00" />
          </div>
          <div className="flex justify-end gap-2 pt-1">
            <Button variant="secondary" onClick={() => setOpen(false)} type="button">Cancel</Button>
            <Button onClick={add} type="button">Add</Button>
          </div>
        </div>
      </Modal>
    </div>
  )
}



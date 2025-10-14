import { useEffect, useState } from 'react'
import axios from 'axios'
import { Card } from '../ui/Card'
import { Button } from '../ui/Button'
import { Bell, CheckCircle, Trash2 } from 'lucide-react'

type Notification = { _id: string; type: string; title: string; body?: string; read: boolean; createdAt: string }

export default function Notifications() {
  const [items, setItems] = useState<Notification[]>([])
  const refresh = () => axios.get('/api/notifications').then(({ data }) => setItems(data))
  useEffect(() => { refresh() }, [])

  const markAll = async () => { await axios.post('/api/notifications/mark-all-read'); refresh() }
  const clearAll = async () => { await axios.delete('/api/notifications'); refresh() }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-gradient-to-br from-yellow-500 to-orange-500 shadow-lg">
            <Bell className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900">Notifications</h2>
        </div>
        <div className="flex gap-3">
          <Button 
            variant="secondary" 
            onClick={markAll}
            className="inline-flex items-center gap-2 bg-gradient-to-r from-blue-500 to-indigo-500 hover:from-blue-600 hover:to-indigo-600 text-white"
          >
            <CheckCircle className="w-4 h-4" />
            Mark all read
          </Button>
          <Button 
            onClick={clearAll}
            className="inline-flex items-center gap-2 bg-gradient-to-r from-red-500 to-rose-500 hover:from-red-600 hover:to-rose-600"
          >
            <Trash2 className="w-4 h-4" />
            Clear all
          </Button>
        </div>
      </div>
      <div className="grid gap-4">
        {items.map(n => (
          <Card key={n._id} className={`p-4 shadow-lg hover:shadow-xl transition-all duration-300 relative overflow-hidden ${
            n.read ? 'shadow-slate-200' : 'shadow-amber-500/25 border-amber-200'
          }`}>
            <div className={`absolute inset-0 bg-gradient-to-br opacity-5 rounded-lg ${
              n.read ? 'from-slate-400 to-slate-500' : 'from-amber-400 to-orange-500'
            }`}></div>
            <div className="relative">
              <div className="flex items-start justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className={`p-1 rounded-full ${
                    n.read ? 'bg-slate-100' : 'bg-amber-100'
                  }`}>
                    <Bell className={`w-3 h-3 ${
                      n.read ? 'text-slate-500' : 'text-amber-600'
                    }`} />
                  </div>
                  <div className="text-xs text-slate-500 font-medium">
                    {new Date(n.createdAt).toLocaleString()}
                  </div>
                </div>
                <span className={`px-2 py-1 rounded-full text-xs font-medium ${
                  n.type === 'urgent' ? 'bg-red-100 text-red-800' :
                  n.type === 'low_stock' ? 'bg-yellow-100 text-yellow-800' :
                  n.type === 'new_order' ? 'bg-green-100 text-green-800' :
                  'bg-blue-100 text-blue-800'
                }`}>
                  {n.type.replace('_', ' ')}
                </span>
              </div>
              <div className="font-semibold text-slate-900 mb-1">{n.title}</div>
              {n.body && <div className="text-slate-600 text-sm">{n.body}</div>}
            </div>
          </Card>
        ))}
      </div>
    </div>
  )
}





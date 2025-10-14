import { useEffect, useState } from 'react'
import axios from 'axios'

export default function AdminSupport() {
  const [items, setItems] = useState<any[]>([])
  const refresh = () => axios.get('/api/admin/support').then(({ data }) => setItems(data))
  useEffect(() => { refresh() }, [])
  const update = async (id: string, update: any) => {
    await axios.patch(`/api/admin/support/${id}`, update)
    refresh()
  }
  return (
    <div className="bg-white border border-slate-200 rounded-lg p-4">
      <div className="text-slate-900 font-semibold mb-3">Support Tickets</div>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-slate-600">
            <th className="py-2">Subject</th>
            <th>Status</th>
            <th>Priority</th>
            <th>Created</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {items.map(t => (
            <tr key={t._id} className="border-t">
              <td className="py-2">{t.subject}</td>
              <td>{t.status}</td>
              <td>{t.priority}</td>
              <td>{new Date(t.createdAt).toLocaleString()}</td>
              <td className="space-x-1">
                <button onClick={()=>update(t._id,{ status:'in_progress' })} className="px-2 py-1 text-xs bg-slate-100 rounded">In progress</button>
                <button onClick={()=>update(t._id,{ status:'closed' })} className="px-2 py-1 text-xs bg-slate-100 rounded">Close</button>
                <button onClick={()=>update(t._id,{ priority:'high' })} className="px-2 py-1 text-xs bg-slate-100 rounded">High</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}



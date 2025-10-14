import { useEffect, useState } from 'react'
import axios from 'axios'

export default function AdminFeedback() {
  const [items, setItems] = useState<any[]>([])
  const refresh = () => axios.get('/api/admin/feedback').then(({ data }) => setItems(data))
  useEffect(() => { refresh() }, [])
  const toggle = async (id: string, hidden: boolean) => {
    await axios.patch(`/api/admin/feedback/${id}/${hidden ? 'show' : 'hide'}`)
    refresh()
  }
  return (
    <div className="bg-white border border-slate-200 rounded-lg p-4">
      <div className="text-slate-900 font-semibold mb-3">Feedback Moderation</div>
      <div className="grid md:grid-cols-2 gap-4">
        {items.map(f => (
          <div key={f._id} className={`border rounded p-3 ${f.hidden ? 'opacity-50' : ''}`}>
            <div className="text-xs text-slate-500 mb-1">{new Date(f.createdAt).toLocaleString()}</div>
            <div className="mb-2">Rating: {f.rating} / 5</div>
            <div className="text-sm text-slate-700">{f.comment || 'No comment'}</div>
            <div className="mt-2">
              <button onClick={()=>toggle(f._id, !!f.hidden)} className="px-2 py-1 text-xs rounded bg-slate-100 hover:bg-slate-200">
                {f.hidden ? 'Show' : 'Hide'}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}



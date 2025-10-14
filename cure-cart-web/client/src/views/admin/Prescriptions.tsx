import React, { useEffect, useMemo, useState } from 'react'
import axios from 'axios'
import { Card } from '../../ui/Card'
import { Button } from '../../ui/Button'
import { FileCheck } from 'lucide-react'
import { io } from 'socket.io-client'

type Prescription = { 
  _id: string; 
  imageUrl?: string; 
  status: string; 
  createdAt: string; 
  patientName?: string; 
  patientId?: string; 
  doctorName?: string; 
  doctorLicense?: string; 
  medicines?: { name: string; dosage: string; duration: string }[]; 
  issuedAt?: string;
  customerAddress?: string;
  customerPhone?: string;
  customerAge?: string;
  customerGender?: string;
  notes?: string;
}

export default function Prescriptions() {
  const [items, setItems] = useState<Prescription[]>([])
  const [tab, setTab] = useState<'pending'|'approved'|'rejected'>('pending')
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)
  const [editing, setEditing] = useState<any | null>(null)
  const [ordering, setOrdering] = useState<any | null>(null)
  const [partners, setPartners] = useState<any[]>([])
  const [orderPrice, setOrderPrice] = useState<string>('')
  const [orderPartnerId, setOrderPartnerId] = useState<string>('')
  const [loading, setLoading] = useState(false)
  const [showOrderModal, setShowOrderModal] = useState(false)

  useEffect(() => { 
    setLoading(true)
    axios.get(`/api/prescriptions?status=${tab}`).then(({ data }) => {
      setItems(data)
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [tab])

  // realtime updates - DISABLED for testing
  // useEffect(() => {
  //   const socket = io('/', { path: '/socket.io', transports: ['websocket'] })
  //   const onNew = (p: Prescription) => {
  //     if (tab === 'pending' && p.status === 'pending') setItems(prev => [p, ...prev])
  //   }
  //   const onUpdated = (p: Prescription) => {
  //     setItems(prev => prev.map(x => x._id === p._id ? p : x))
  //   }
  //   socket.on('prescription:new', onNew)
  //   socket.on('prescription:updated', onUpdated)
  //   return () => {
  //     socket.off('prescription:new', onNew)
  //     socket.off('prescription:updated', onUpdated)
  //     socket.close()
  //   }
  // }, [tab])

  const update = async (id: string, status: string) => {
    console.log(`Starting update for prescription ${id} to status: ${status}`)
    
    try {
      // First update the UI immediately (optimistic update)
      setItems((prev) => {
        const updated = prev.map((p) => {
          if (p._id === id) {
            console.log(`Updating prescription ${id} from ${p.status} to ${status}`)
            return { ...p, status: status }
          }
          return p
        })
        console.log('Updated items:', updated)
        return updated
      })

      // Force a re-render by updating state again
      setTimeout(() => {
        setItems((prev) => {
          console.log('Force re-render - current items:', prev)
          return prev
        })
      }, 100)

      // Then update the backend
      await axios.patch(`/api/prescriptions/${id}`, { status })
      
      alert(`Prescription ${status} successfully!`)
    } catch (error) {
      console.error('Failed to update prescription:', error)
      alert('Failed to update prescription. Please try again.')
      
      // Revert the optimistic update on error
      setItems((prev) => prev.map((p) => {
        if (p._id === id) {
          return { ...p, status: 'pending' } // Revert to original status
        }
        return p
      }))
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

  const stats = useMemo(() => {
    const total = items.length
    const pending = items.filter(p => p.status === 'pending').length
    const approved = items.filter(p => p.status === 'approved').length
    const rejected = items.filter(p => p.status === 'rejected').length
    return { total, pending, approved, rejected }
  }, [items])

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-slate-500">Loading prescriptions...</div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Tabs */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-lg bg-gradient-to-br from-blue-500 to-purple-500 shadow-lg">
            <FileCheck className="w-6 h-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold text-slate-900">Prescriptions Management</h2>
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
              {t.charAt(0).toUpperCase() + t.slice(1)} ({stats[t]})
            </button>
          ))}
        </div>
      </div>

      {/* Prescription cards */}
      <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {items.map(p => (
          <Card key={p._id} className={`p-6 shadow-lg hover:shadow-xl transition-all duration-300 hover:scale-105 relative overflow-hidden ${
            p.status === 'pending' ? 'shadow-amber-500/25' :
            p.status === 'approved' ? 'shadow-emerald-500/25' :
            'shadow-red-500/25'
          }`}>
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

             {/* Buttons */}
             <div className="mt-3 flex items-center justify-between">
               <div />
               <div className="flex gap-2">
                 {/* Debug: Show current status */}
                 <div className="text-xs text-gray-500 mr-2">Status: {p.status}</div>
                 
                 {/* ✅ Approved state → show only Place order + Reset (NO APPROVE) */}
                 {p.status === 'approved' && (
                   <>
                     <Button size="sm" onClick={async ()=>{
                       try {
                         const { data } = await axios.get('/api/delivery-partners/approved')
                         setPartners(data || [])
                         setOrderPartnerId('')
                         setOrderPrice('')
                         setOrdering({ _id: p._id, paymentMethod: (p as any).paymentMethod || 'cod', customerAddress: p.customerAddress || '-', customerPhone: p.customerPhone || '-' })
                         setShowOrderModal(true)
                       } catch {
                         alert('Failed to load delivery partners')
                       }
                     }}>Place the order</Button>
                     <Button size="sm" variant="secondary" onClick={()=>update(p._id,'pending')}>Reset</Button>
                   </>
                 )}

                 {/* Pending state → show Approve + Reject + Print */}
                 {p.status === 'pending' && (
                   <>
                     <Button size="sm" onClick={()=>{
                       console.log('Approve button clicked for prescription:', p._id, 'current status:', p.status)
                       update(p._id,'approved')
                     }}>Approve</Button>
                     <Button size="sm" variant="secondary" onClick={()=>update(p._id,'rejected')}>Reject</Button>
                     <Button size="sm" variant="ghost" onClick={()=>printItem(p)}>Print</Button>
                   </>
                 )}

                 {/* Rejected state → show only Print */}
                 {p.status === 'rejected' && (
                   <Button size="sm" variant="ghost" onClick={()=>printItem(p)}>Print</Button>
                 )}
               </div>
             </div>
          </Card>
        ))}
      </div>

      {/* Order Modal */}
      {showOrderModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-96 max-w-md mx-4">
            <h3 className="text-lg font-semibold mb-4">Place Order</h3>
            <p className="text-sm text-gray-600 mb-4">
              Prescription: {ordering?._id?.slice?.(-6)} | Customer: {ordering?.customerName || '-'}
            </p>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select Delivery Partner
              </label>
              {partners.length === 0 ? (
                <div className="w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-500">
                  No delivery partners available
                </div>
              ) : (
                <select
                  value={orderPartnerId}
                  onChange={(e) => setOrderPartnerId(e.target.value)}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Choose a delivery partner</option>
                  {partners.map(partner => (
                    <option key={partner._id} value={partner._id}>
                      {partner.name} - {partner.contact || 'No contact'}
                    </option>
                  ))}
                </select>
              )}
            </div>

            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Order Price (Rs.)
              </label>
              <input
                type="number"
                value={orderPrice}
                onChange={(e) => setOrderPrice(e.target.value)}
                placeholder="Enter order price"
                className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
            
            <div className="flex gap-2">
              <button
                onClick={() => {
                  setShowOrderModal(false)
                  setOrderPartnerId('')
                  setOrderPrice('')
                  setOrdering(null)
                }}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={async () => {
                  if (!orderPartnerId || !orderPrice) {
                    alert('Please select a delivery partner and enter the price')
                    return
                  }
                  
                  try {
                    // Get the selected partner details
                    const selectedPartner = partners.find(p => p._id === orderPartnerId)
                    
                    // Create order with selected partner and price
                    const orderData = {
                      prescriptionId: ordering._id,
                      deliveryPartnerId: orderPartnerId,
                      deliveryPartnerName: selectedPartner?.name || 'Unknown Partner',
                      deliveryPartnerPhone: selectedPartner?.contact || 'No contact',
                      total: parseFloat(orderPrice),
                      customerAddress: ordering.customerAddress,
                      customerPhone: ordering.customerPhone,
                      paymentMethod: ordering.paymentMethod,
                      status: 'pending'
                    }
                    
                    console.log('Creating order with data:', orderData)
                    const { data } = await axios.post('/api/orders', orderData)
                    console.log('Order created successfully:', data)
                    console.log('Order has deliveryPartnerId:', data.deliveryPartnerId)
                    alert('Order placed successfully!')
                    
                    // Close modal and reset
                    setShowOrderModal(false)
                    setOrderPartnerId('')
                    setOrderPrice('')
                    setOrdering(null)
                    
                    // Navigate to orders page
                    window.location.href = '/orders'
                  } catch (error) {
                    console.error('Failed to place order:', error)
                    alert('Failed to place order. Please try again.')
                  }
                }}
                disabled={!orderPartnerId || !orderPrice}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Place Order
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

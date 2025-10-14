import React, { useEffect, useState } from 'react'
import axios from 'axios'

export default function AdminOrders() {
  const [orders, setOrders] = useState<any[]>([])
  const [deliveryPartners, setDeliveryPartners] = useState<any[]>([])
  const [selectedOrder, setSelectedOrder] = useState<any>(null)
  const [selectedPartner, setSelectedPartner] = useState<string>('')
  const [isProcessing, setIsProcessing] = useState(false)

  useEffect(() => { 
    console.log('🔄 Loading orders and delivery partners...')
    
    // Test authentication first
    axios.get('/api/test-auth')
      .then(({ data }) => {
        console.log('🔍 Auth test result:', data)
      })
      .catch(error => {
        console.error('❌ Auth test failed:', error)
      })
    
    axios.get('/api/admin/orders')
      .then(({ data }) => {
        console.log('📦 Orders loaded:', data.length, 'orders')
        setOrders(data)
      })
      .catch(error => {
        console.error('❌ Error loading orders:', error)
        setOrders([])
      })
      
    axios.get('/api/public/delivery-partners/available')
      .then(({ data }) => {
        console.log('🚚 Delivery partners loaded:', data)
        setDeliveryPartners(data || [])
      })
      .catch(error => {
        console.error('❌ Error loading delivery partners:', error)
        setDeliveryPartners([])
      })
  }, [])

  const handleAssignDeliveryPartner = async () => {
    if (!selectedOrder || !selectedPartner) return
    
    console.log('🚀 Assigning delivery partner:', {
      orderId: selectedOrder._id,
      partnerId: selectedPartner,
      order: selectedOrder
    })
    
    setIsProcessing(true)
    try {
      const response = await axios.put(`/api/orders/${selectedOrder._id}/assign-delivery`, {
        deliveryPartnerId: selectedPartner
      })
      
      console.log('✅ Assignment response:', response.data)
      
      // Update the order in the local state
      setOrders(orders.map(order => 
        order._id === selectedOrder._id 
          ? { ...order, deliveryPartnerId: selectedPartner, status: 'assigned' }
          : order
      ))
      
      setSelectedOrder(null)
      setSelectedPartner('')
      alert('Delivery partner assigned successfully!')
    } catch (error) {
      console.error('❌ Error assigning delivery partner:', error)
      console.error('❌ Error details:', {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status,
        url: error.config?.url
      })
      alert(`Failed to assign delivery partner: ${error.response?.data?.error || error.message}`)
    } finally {
      setIsProcessing(false)
    }
  }

  const handleConfirmOrder = async (orderId: string) => {
    console.log('🚀 Confirming order:', orderId)
    
    setIsProcessing(true)
    try {
      const response = await axios.put(`/api/orders/${orderId}/confirm`)
      
      console.log('✅ Confirmation response:', response.data)
      
      // Update the order in the local state
      setOrders(orders.map(order => 
        order._id === orderId 
          ? { ...order, status: 'confirmed' }
          : order
      ))
      
      alert('Order confirmed successfully!')
    } catch (error) {
      console.error('❌ Error confirming order:', error)
      console.error('❌ Error details:', {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status,
        url: error.config?.url
      })
      alert(`Failed to confirm order: ${error.response?.data?.error || error.message}`)
    } finally {
      setIsProcessing(false)
    }
  }

  return (
    <div className="bg-white border border-slate-200 rounded-lg p-4">
      <div className="text-slate-900 font-semibold mb-3">Orders Management</div>
      
      {/* Delivery Partner Assignment Modal */}
      {selectedOrder && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-96">
            <h3 className="text-lg font-semibold mb-4">Select Delivery Partner</h3>
            <p className="text-sm text-gray-600 mb-4">
              Order: {selectedOrder._id?.slice?.(-6)} | Total: Rs. {(selectedOrder.total || 0).toFixed(2)}
            </p>
            <p className="text-xs text-blue-600 mb-4">
              ⚠️ You must select a delivery partner before confirming the order
            </p>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select Delivery Partner
              </label>
              {deliveryPartners.length === 0 ? (
                <div className="w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-500">
                  No delivery partners available
                </div>
              ) : (
                <select
                  value={selectedPartner}
                  onChange={(e) => setSelectedPartner(e.target.value)}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Choose a delivery partner</option>
                  {deliveryPartners.map(partner => (
                    <option key={partner._id} value={partner._id}>
                      {partner.name} - {partner.contact || 'No contact'}
                    </option>
                  ))}
                </select>
              )}
            </div>
            
            <div className="flex gap-2">
              <button
                onClick={() => {
                  setSelectedOrder(null)
                  setSelectedPartner('')
                }}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleAssignDeliveryPartner}
                disabled={!selectedPartner || isProcessing}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-50"
              >
                {isProcessing ? 'Assigning...' : 'Assign & Enable Confirmation'}
              </button>
            </div>
          </div>
        </div>
      )}

      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-slate-600">
            <th className="py-2">Order</th>
            <th>Status</th>
            <th>Total</th>
            <th>Date</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {orders.map(o => (
            <tr key={o._id} className="border-t">
              <td className="py-2 font-mono">{o._id?.slice?.(-6)}</td>
              <td>
                <div className="flex flex-col">
                  <span className={`px-2 py-1 rounded text-xs font-semibold ${
                    o.status === 'confirmed' ? 'bg-green-100 text-green-800' :
                    o.status === 'assigned' ? 'bg-blue-100 text-blue-800' :
                    o.status === 'processing' ? 'bg-purple-100 text-purple-800' :
                    o.status === 'out_for_delivery' ? 'bg-yellow-100 text-yellow-800' :
                    o.status === 'delivered' ? 'bg-emerald-100 text-emerald-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {o.status === 'out_for_delivery' ? 'dispatched' : 
                     o.status === 'processing' ? 'processing' :
                     o.status}
                  </span>
                  {o.deliveryPartnerId && (
                    <span className="text-xs text-slate-500">Partner assigned</span>
                  )}
                  {o?.tracking?.pickedUpAt && (
                    <span className="text-xs text-slate-500">Picked up</span>
                  )}
                </div>
              </td>
              <td>Rs. {(o.total || 0).toFixed(2)}</td>
              <td>{new Date(o.createdAt).toLocaleString()}</td>
              <td>
                <div className="flex gap-2">
                  {!o.deliveryPartnerId && (o.status === 'pending' || o.status === 'processing') && (
                    <button
                      onClick={() => setSelectedOrder(o)}
                      className="px-3 py-1 bg-blue-600 text-white text-xs rounded hover:bg-blue-700"
                    >
                      Select Delivery Partner
                    </button>
                  )}
                  {o.deliveryPartnerId && (o.status === 'assigned' || o.status === 'processing') && (
                    <button
                      onClick={() => handleConfirmOrder(o._id)}
                      disabled={isProcessing}
                      className={`px-3 py-1 text-xs rounded font-semibold ${
                        !isProcessing
                          ? 'bg-green-600 text-white hover:bg-green-700'
                          : 'bg-gray-400 text-gray-200 cursor-not-allowed'
                      } disabled:opacity-50`}
                    >
                      {isProcessing ? 'Confirming...' : '✓ Confirm Order'}
                    </button>
                  )}
                  {o.status === 'confirmed' && (
                    <span className="px-3 py-1 bg-green-100 text-green-800 text-xs rounded font-semibold">
                      ✓ Confirmed
                    </span>
                  )}
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}



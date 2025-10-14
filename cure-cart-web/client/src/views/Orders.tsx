import React, { useEffect, useState } from 'react'
import axios from 'axios'
import { Button } from '../ui/Button'
import { Package, CreditCard } from 'lucide-react'
import { useAuth } from '../stores/auth'

type Order = {
  _id: string
  status: string
  total: number
  createdAt: string
  deliveryDate?: string
  trackingId?: string
  paymentStatus?: string
  invoiceId?: any
  customerId?: string
  orderedByRole?: string
  deliveryPartnerId?: string
  deliveryPartnerName?: string
  deliveryPartnerPhone?: string
  items?: { name?: string; quantity?: number; price?: number }[]
  tracking?: { pickedUpAt?: string; pickedUpBy?: string }
  address?: string
  paymentMethod?: string
}

export default function Orders() {
  const { user } = useAuth()
  const [orders, setOrders] = useState<Order[]>([])
  const [partners, setPartners] = useState<any[]>([])
  const [selectedPartner, setSelectedPartner] = useState<Record<string, string>>({})
  const [confirmed, setConfirmed] = useState<Record<string, boolean>>({})
  const [detail, setDetail] = useState<Record<string, any>>({})
  const [catalog, setCatalog] = useState<any[]>([])
  const [showPartnerModal, setShowPartnerModal] = useState(false)
  const [selectedOrderForPartner, setSelectedOrderForPartner] = useState<Order | null>(null)
  const [tempSelectedPartner, setTempSelectedPartner] = useState<string>('')
  const [partnerAssignmentComplete, setPartnerAssignmentComplete] = useState(false)
  const [assignedPartners, setAssignedPartners] = useState<Record<string, string>>({})
  const [showDetailsModal, setShowDetailsModal] = useState(false)
  const [selectedOrderForDetails, setSelectedOrderForDetails] = useState<Order | null>(null)

  // ✅ Fix unpaid delivered orders on load
  const fixDeliveredOrdersPayment = async (orders: Order[]) => {
    const deliveredUnpaidOrders = orders.filter(
      o => o.status === 'delivered' && (o.paymentStatus === 'unpaid' || !o.paymentStatus)
    )

    if (deliveredUnpaidOrders.length > 0) {
      for (const order of deliveredUnpaidOrders) {
        try {
          await axios.patch(`/api/orders/${order._id}`, { paymentStatus: 'paid' })
        } catch (error) {
          console.error(`Failed to update payment status for order ${order._id}:`, error)
        }
      }
      const { data } = await axios.get('/api/orders')
      return data
    }

    return orders
  }

  useEffect(() => {
    const hydrateFrom = (list: Order[]) => {
      setOrders(list)
      const partnerMap = list.reduce((acc, o: any) => {
        const partnerId = o.deliveryPartnerId
        console.log(`🔍 Order ${o._id}: deliveryPartnerId=${o.deliveryPartnerId}, deliveryPartnerName=${o.deliveryPartnerName}, deliveryPartnerPhone=${o.deliveryPartnerPhone}`)
        if (o && partnerId) {
          acc[o._id] = String(partnerId)
          console.log(`✅ Mapped partner ${partnerId} to order ${o._id}`)
        } else {
          console.log(`❌ No partner ID found for order ${o._id}`)
        }
        return acc
      }, {} as Record<string, string>)
      
      console.log('✅ Partner map from orders:', partnerMap)
      console.log('✅ Orders with delivery partners:', list.filter(o => o.deliveryPartnerId || o.deliveryPartnerName))
      
      // Set both states to ensure persistence after refresh
      setSelectedPartner(partnerMap)
      setAssignedPartners(partnerMap)
      
      // Mark partner assignment as complete if any partners are assigned
      if (Object.keys(partnerMap).length > 0) {
        setPartnerAssignmentComplete(true)
      }
      
      setConfirmed(
        list.reduce((acc, o) => {
          const s = (o.status || '').toLowerCase()
          acc[o._id] = s === 'processing' || s === 'dispatched' || s === 'delivered'
          return acc
        }, {} as Record<string, boolean>)
      )
    }

    const loadOrders = async () => {
      try {
        const { data } = await axios.get('/api/orders')
        console.log('✅ Loaded orders:', data?.length || 0)
        console.log('✅ Orders data:', data)
        const updatedOrders = await fixDeliveredOrdersPayment(data)
        hydrateFrom(updatedOrders)
      } catch (error) {
        console.error('❌ Failed to load orders:', error)
        // Set empty state on error
        setOrders([])
        setSelectedPartner({})
        setConfirmed({})
      }
    }

    loadOrders()
  }, [])

  // Force refresh data after component mounts to ensure delivery partner info is loaded
  useEffect(() => {
    const forceRefresh = async () => {
      try {
        const { data } = await axios.get('/api/orders')
        console.log('🔄 Force refresh orders:', data?.length || 0)
        
        // Always update orders and selectedPartner state to ensure persistence
        setOrders(data)
        
        // Update selectedPartner state for all orders with delivery partners
        const partnerMap = data.reduce((acc, o: any) => {
          const partnerId = o.deliveryPartnerId
          if (o && partnerId) {
            acc[o._id] = String(partnerId)
            console.log(`✅ Force refresh: Mapped partner ${partnerId} to order ${o._id}`)
          }
          return acc
        }, {} as Record<string, string>)
        
        // Update selectedPartner state to persist partner assignments
        setSelectedPartner(partnerMap)
        setAssignedPartners(partnerMap)
        
        // Mark partner assignment as complete if any partners are assigned
        if (Object.keys(partnerMap).length > 0) {
          setPartnerAssignmentComplete(true)
        }
        
        console.log('✅ Force refresh: Updated selectedPartner state:', partnerMap)
        
        // Update confirmed state based on order status
        setConfirmed(
          data.reduce((acc, o) => {
            const s = (o.status || '').toLowerCase()
            acc[o._id] = s === 'processing' || s === 'dispatched' || s === 'delivered'
            return acc
          }, {} as Record<string, boolean>)
        )
        
        // Check if any orders have delivery partners
        const ordersWithPartners = data.filter(o => o.deliveryPartnerId || o.deliveryPartnerName)
        console.log('🔍 Orders with delivery partners on force refresh:', ordersWithPartners.length)
        
        if (ordersWithPartners.length > 0) {
          console.log('✅ Found orders with delivery partners:', ordersWithPartners.map(o => ({
            id: o._id,
            partnerId: o.deliveryPartnerId,
            partnerName: o.deliveryPartnerName
          })))
        }
      } catch (error) {
        console.error('❌ Force refresh failed:', error)
      }
    }
    
    // Run force refresh after a short delay to ensure initial load is complete
    const timer = setTimeout(forceRefresh, 1000)
    
    // Remove the periodic refresh that was causing delivery partner selection to revert
    // The periodic refresh was overriding the selectedPartner state every 30 seconds
    
    return () => {
      clearTimeout(timer)
    }
  }, [])

  useEffect(() => {
    // Try multiple endpoints for delivery partners
    const loadPartners = async () => {
      try {
        // Try the approved endpoint first
        const { data } = await axios.get('/api/delivery-partners/approved')
        setPartners(data || [])
        console.log('✅ Loaded delivery partners:', data?.length || 0)
      } catch (error) {
        console.log('❌ Approved endpoint failed, trying public endpoint:', error)
        try {
          // Fallback to public endpoint
          const { data } = await axios.get('/api/public/delivery-partners/available')
          setPartners(data || [])
          console.log('✅ Loaded delivery partners from public endpoint:', data?.length || 0)
        } catch (error2) {
          console.log('❌ Public endpoint also failed, trying basic endpoint:', error2)
          try {
            // Final fallback to basic endpoint
            const { data } = await axios.get('/api/delivery-partners')
            setPartners(data || [])
            console.log('✅ Loaded delivery partners from basic endpoint:', data?.length || 0)
          } catch (error3) {
            console.log('❌ All delivery partner endpoints failed:', error3)
            setPartners([])
          }
        }
      }
    }
    loadPartners()
  }, [])

  // Additional effect to ensure delivery partner assignments persist after page refresh
  useEffect(() => {
    if (orders.length > 0 && partners.length > 0) {
      // Re-sync delivery partner assignments with partners list
      const updatedAssignedPartners = { ...assignedPartners }
      let hasUpdates = false
      
      orders.forEach(order => {
        if (order.deliveryPartnerId && !assignedPartners[order._id]) {
          updatedAssignedPartners[order._id] = order.deliveryPartnerId
          hasUpdates = true
        }
      })
      
      if (hasUpdates) {
        setAssignedPartners(updatedAssignedPartners)
        setSelectedPartner(updatedAssignedPartners)
        console.log('✅ Re-synced delivery partner assignments after partners loaded')
      }
    }
  }, [orders, partners, assignedPartners])

  useEffect(() => {
    axios.get('/api/inventory')
      .then(({ data }) => setCatalog(data || []))
      .catch(error => {
        console.log('❌ Failed to load inventory:', error)
        setCatalog([])
      })
  }, [])

  // Load order details to get customer and pharmacy addresses
  useEffect(() => {
    const load = async () => {
      console.log('🔍 [AUTH DEBUG] User:', user)
      console.log('🔍 [AUTH DEBUG] Auth header:', axios.defaults.headers.common['Authorization'])
      
      const pendingIds = orders.map(o => o._id).filter(id => !(id in detail)).slice(0, 5)
      console.log('🔍 [ORDER DETAILS] Loading details for orders:', pendingIds)
      
      await Promise.all(
        pendingIds.map(async id => {
          try {
            console.log(`🔍 [ORDER DETAILS] Loading details for order ${id}`)
            const { data } = await axios.get(`/api/orders/${id}/details`)
            setDetail(s => ({ ...s, [id]: data }))
            console.log(`✅ Loaded details for order ${id}:`, data)
            console.log(`📋 [ORDER DETAILS] Prescription data:`, data.prescription)
            console.log(`📋 [ORDER DETAILS] Customer address:`, data.prescription?.customerAddress)
            console.log(`📋 [ORDER DETAILS] Pharmacy address:`, data.prescription?.pharmacyAddress)
          } catch (error) {
            console.log(`❌ Failed to load details for order ${id}:`, error.response?.status || error.message)
            console.log(`❌ Error details:`, error.response?.data)
            setDetail(s => ({ ...s, [id]: null }))
          }
        })
      )
    }
    if (orders.length) load()
  }, [orders, user])

  const getDisplayMedicineName = (o: Order): string => {
    const nameFromItems =
      o.items && o.items.length > 0 && o.items[0]?.name ? String(o.items[0].name) : ''
    if (nameFromItems) return nameFromItems
    const nameFromDetails = detail[o._id]?.prescription?.medicines?.[0]?.name
    return nameFromDetails || 'Order'
  }

  const createInvoice = async (id: string) => {
    const { data } = await axios.post(`/api/orders/${id}/invoice`, { paymentMethod: 'cash' })
    alert(`Invoice created ${data._id}`)
    const { data: fresh } = await axios.get('/api/orders')
    setOrders(fresh)
  }

  const remove = async (id: string) => {
    if (!confirm('Delete this order?')) return
    try {
      await axios.delete(`/api/admin/orders/${id}`)
      setOrders(prev => prev.filter(o => o._id !== id))
    } catch (e: any) {
      const msg = e?.response?.data?.error || e?.message || 'Failed to delete'
      alert(msg)
    }
  }

  const openPartnerModal = (order: Order) => {
    setSelectedOrderForPartner(order)
    setTempSelectedPartner(selectedPartner[order._id] || order.deliveryPartnerId || '')
    setShowPartnerModal(true)
  }

  const createDeliveryPartner = async (order: Order) => {
    try {
      console.log('🔄 Creating new delivery partner for order:', order._id)
      
      // Create a new delivery partner
      const newPartner = {
        name: `Delivery Partner ${order._id.slice(-6)}`,
        contact: 'Auto-assigned',
        status: 'active',
        vehicleType: 'bike',
        vehicleNumber: `AUTO-${order._id.slice(-4)}`,
        address: 'Auto-generated',
        isAutoCreated: true,
        orderId: order._id
      }

      const { data: createdPartner } = await axios.post('/api/delivery-partners', newPartner)
      console.log('✅ Created delivery partner:', createdPartner._id)
      
      // Connect with delivery app
      try {
        await axios.post('/api/delivery-partners/connect-app', {
          partnerId: createdPartner._id,
          orderId: order._id
        })
        console.log('✅ Connected delivery partner with delivery app')
      } catch (connectError) {
        console.log('⚠️ Failed to connect with delivery app, but partner created:', connectError)
      }

      return createdPartner
    } catch (error) {
      console.error('❌ Failed to create delivery partner:', error)
      throw error
    }
  }

  const assignDeliveryPartner = async () => {
    if (!selectedOrderForPartner) {
      alert('No order selected')
      return
    }

    try {
      let partnerId = tempSelectedPartner
      let partnerName = 'Unknown Partner'
      let partnerPhone = 'No contact'

      // If no partner selected, create one automatically
      if (!tempSelectedPartner) {
        console.log('🔄 No partner selected, creating auto-delivery partner...')
        const createdPartner = await createDeliveryPartner(selectedOrderForPartner)
        partnerId = createdPartner._id
        partnerName = createdPartner.name
        partnerPhone = createdPartner.contact
        
        // Add to partners list
        setPartners(prev => [...prev, createdPartner])
      } else {
        // Use selected partner
        const partner = partners.find(p => p._id === tempSelectedPartner)
        partnerName = partner?.name || 'Unknown Partner'
        partnerPhone = partner?.contact || 'No contact'
      }

      const updateData = {
        deliveryPartnerId: partnerId,
        deliveryPartnerName: partnerName,
        deliveryPartnerPhone: partnerPhone
      }

      console.log('🔄 Assigning delivery partner to order:', {
        orderId: selectedOrderForPartner._id,
        partnerId,
        partnerName,
        partnerPhone
      })

      const { data } = await axios.patch(`/api/orders/${selectedOrderForPartner._id}`, updateData)
      
      console.log('✅ Partner assignment response:', data)
      console.log('✅ Partner ID assigned:', partnerId)
      
      // Verify the assignment was successful
      if (!data.deliveryPartnerId && !data.deliveryPartnerName) {
        console.error('❌ Partner assignment failed - no partner data in response')
        alert('Failed to assign delivery partner. Please try again.')
        return
      }
      
      // Close modal first
      setShowPartnerModal(false)
      setSelectedOrderForPartner(null)
      setTempSelectedPartner('')
      
      // Show success message first
      alert(`Delivery partner ${tempSelectedPartner ? 'assigned' : 'created and assigned'} successfully!`)
      
      // Update local state after alert to ensure it persists
      setOrders(prev => prev.map(order => 
        order._id === selectedOrderForPartner._id 
          ? { 
              ...order, 
              deliveryPartnerId: partnerId,
              deliveryPartnerName: partnerName,
              deliveryPartnerPhone: partnerPhone
            }
          : order
      ))
      
      // Update selectedPartner state to ensure persistence
      setSelectedPartner(prev => ({
        ...prev,
        [selectedOrderForPartner._id]: partnerId
      }))
      
      // Update assignedPartners state to track permanent assignments
      setAssignedPartners(prev => ({
        ...prev,
        [selectedOrderForPartner._id]: partnerId
      }))
      
      // Mark partner assignment as complete to prevent state resets
      setPartnerAssignmentComplete(true)
      
      // Force refresh orders from server to ensure data persistence
      try {
        // Small delay to ensure server has processed the update
        await new Promise(resolve => setTimeout(resolve, 500))
        
        const { data: refreshedOrders } = await axios.get('/api/orders')
        console.log('✅ Refreshed orders from server:', refreshedOrders)
        
        // Debug: Check if the assigned order has partner data
        const refreshedAssignedOrder = refreshedOrders.find(o => o._id === selectedOrderForPartner._id)
        if (refreshedAssignedOrder) {
          console.log('🔍 Assigned order after refresh:', {
            _id: refreshedAssignedOrder._id,
            deliveryPartnerId: refreshedAssignedOrder.deliveryPartnerId,
            deliveryPartnerName: refreshedAssignedOrder.deliveryPartnerName,
            deliveryPartnerPhone: refreshedAssignedOrder.deliveryPartnerPhone
          })
        } else {
          console.log('❌ Assigned order not found in refreshed data')
        }
        
        // Only update state if the server data has the partner assignment
        if (refreshedAssignedOrder && refreshedAssignedOrder.deliveryPartnerId) {
          setOrders(refreshedOrders)
          setSelectedPartner(
            refreshedOrders.reduce((acc, o: any) => {
              const partnerId = o.deliveryPartnerId
              if (o && partnerId) acc[o._id] = String(partnerId)
              return acc
            }, {} as Record<string, string>)
          )
        } else {
          console.log('⚠️ Server data doesn\'t have partner assignment, keeping local state')
        }
        
        console.log('✅ State updated with refreshed data')
        console.log('✅ Orders count:', refreshedOrders.length)
        console.log('✅ Orders with partners:', refreshedOrders.filter(o => o.deliveryPartnerId).length)
        
        // Mark partner assignment as complete
        setPartnerAssignmentComplete(true)
        
        console.log('✅ Final state after refresh:', {
          orders: refreshedOrders,
          selectedPartner: refreshedOrders.reduce((acc, o: any) => {
            const partnerId = o.deliveryPartnerId
            if (o && partnerId) acc[o._id] = String(partnerId)
            return acc
          }, {} as Record<string, string>)
        })
        
        // Debug: Check if the assigned order has the partner data
        const assignedOrder = refreshedOrders.find(o => o._id === selectedOrderForPartner._id)
        if (assignedOrder) {
          console.log('✅ Assigned order data:', {
            _id: assignedOrder._id,
            deliveryPartnerId: assignedOrder.deliveryPartnerId,
            deliveryPartnerName: assignedOrder.deliveryPartnerName,
            deliveryPartnerPhone: assignedOrder.deliveryPartnerPhone
          })
        }
      } catch (refreshError) {
        console.error('❌ Failed to refresh orders:', refreshError)
        alert('Delivery partner assigned, but failed to refresh data. Please refresh the page.')
      }
    } catch (error) {
      console.error('Failed to assign delivery partner:', error)
      alert('Failed to assign delivery partner. Please try again.')
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <div className="p-2 rounded-lg bg-gradient-to-br from-orange-500 to-red-500 shadow-lg">
          <Package className="w-6 h-6 text-white" />
        </div>
        <h2 className="text-2xl font-bold text-slate-900">Order Management</h2>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 p-0 overflow-hidden shadow-lg hover:shadow-xl transition-all duration-300">
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-slate-600 bg-gradient-to-r from-slate-50 to-slate-100">
              <th className="py-3 px-4 font-semibold">Order</th>
              <th className="px-3 font-semibold">Ordered By</th>
              <th className="px-3 font-semibold">Total</th>
              <th className="px-3 font-semibold">Status</th>
              <th className="px-3 font-semibold">Payment</th>
              <th className="px-3 font-semibold">Delivery Partner</th>
              <th className="px-3 font-semibold">Addresses</th>
              <th className="px-3 font-semibold">Confirm</th>
              <th className="px-3 font-semibold">Invoice</th>
              <th className="px-3 font-semibold">Delete</th>
            </tr>
          </thead>

          <tbody>
            {orders.map(o => (
              <tr key={`${o._id}-${o.deliveryPartnerId || selectedPartner[o._id] || 'no-partner'}`} className="border-t hover:bg-slate-50 transition-colors duration-200">
                <td className="py-3 px-4">
                  <div className="text-slate-900 font-semibold">{getDisplayMedicineName(o)}</div>
                  <div className="text-xs text-slate-400 font-mono">
                    #{o._id.slice(-6)} • {new Date(o.createdAt).toLocaleString()}
                  </div>
                </td>

                <td className="px-3 text-slate-600">{o.orderedByRole || 'customer'}</td>

                <td className="px-3 font-semibold text-green-600">
                  Rs. {o.total?.toFixed(2) || '0.00'}
                </td>

                <td className="px-3">
                  <span
                    className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                      o.status === 'delivered'
                        ? 'bg-green-100 text-green-800'
                        : o.status === 'processing'
                        ? 'bg-blue-100 text-blue-800'
                        : o.status === 'dispatched'
                        ? 'bg-yellow-100 text-yellow-800'
                        : 'bg-gray-100 text-gray-800'
                    }`}
                  >
                    {o.status}
                  </span>
                </td>

                {/* ✅ Payment column auto shows Paid when delivered */}
                <td className="px-3">
                  <div className="flex items-center gap-1">
                    <CreditCard
                      className={`w-3 h-3 ${
                        o.status === 'delivered' || o.paymentStatus === 'paid'
                          ? 'text-green-500'
                          : 'text-slate-400'
                      }`}
                    />
                    <span
                      className={`text-xs font-medium ${
                        o.status === 'delivered' || o.paymentStatus === 'paid'
                          ? 'text-green-600'
                          : 'text-slate-600'
                      }`}
                    >
                      {o.status === 'delivered' || o.paymentStatus === 'paid'
                        ? 'paid'
                        : o.paymentStatus || 'unpaid'}
                    </span>
                  </div>
                </td>

                <td className="px-3">
                  {(() => {
                    // Check if order has any delivery partner assigned - be more thorough
                    const hasPartner = !!(o.deliveryPartnerId || o.deliveryPartnerName || selectedPartner[o._id] || assignedPartners[o._id])
                    
                    console.log(`🔍 Order ${o._id}: hasPartner=${hasPartner}, deliveryPartnerId=${o.deliveryPartnerId}, deliveryPartnerName=${o.deliveryPartnerName}`)
                    console.log(`🔍 Order ${o._id}: selectedPartner state:`, selectedPartner[o._id])
                    console.log(`🔍 Order ${o._id}: assignedPartners state:`, assignedPartners[o._id])
                    console.log(`🔍 Order ${o._id}: full order data:`, o)
                    
                    if (hasPartner) {
                      // Get partner info from order data or find from partners list
                      let partnerName = o.deliveryPartnerName || 'Partner Assigned'
                      let partnerPhone = o.deliveryPartnerPhone || 'No contact'
                      
                      // If we have selectedPartner state but no order data, find from partners list
                      const partnerId = selectedPartner[o._id] || assignedPartners[o._id] || o.deliveryPartnerId
                      if (partnerId && !o.deliveryPartnerName) {
                        const partner = partners.find(p => p._id === partnerId)
                        if (partner) {
                          partnerName = partner.name
                          partnerPhone = partner.contact || 'No contact'
                        } else {
                          // If partner not found in partners list but we have a partner ID, show generic info
                          partnerName = `Partner ${partnerId.slice(-6)}`
                          partnerPhone = 'Contact not available'
                        }
                      }
                      
                      return (
                        <div className="text-sm">
                          <div className="font-medium text-slate-900">
                            {partnerName}
                          </div>
                          <div className="text-xs text-slate-500">
                            {partnerPhone}
                          </div>
                          <div className="text-xs text-blue-600">
                            Partner assigned
                          </div>
                        </div>
                      )
                    } else {
                      // Only show Select Partner button if order truly has no partner
                      console.log(`❌ Order ${o._id} has no delivery partner - showing Select Partner button`)
                      return (
                        <button
                          onClick={() => openPartnerModal(o)}
                          className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 transition-colors"
                        >
                          Select Partner
                        </button>
                      )
                    }
                  })()}
                </td>

                {/* Addresses column */}
                <td className="px-3">
                  <button
                    onClick={() => {
                      setSelectedOrderForDetails(o)
                      setShowDetailsModal(true)
                    }}
                    className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700 transition-colors"
                  >
                    View Details
                  </button>
                </td>

                {/* ✅ Only Confirm Order (no delivered badge) */}
                <td className="px-3">
                  <div className="flex flex-col gap-1">
                    {(() => {
                      const isConfirmed = !!confirmed[o._id]
                      const hasPartner = !!(o.deliveryPartnerId || o.deliveryPartnerName || selectedPartner[o._id] || assignedPartners[o._id])
                      const disabled = isConfirmed || !hasPartner
                      
                      console.log(`🔍 Confirm Order for ${o._id}: isConfirmed=${isConfirmed}, hasPartner=${hasPartner}, disabled=${disabled}`)
                      console.log(`🔍 Order data: deliveryPartnerId=${o.deliveryPartnerId}, deliveryPartnerName=${o.deliveryPartnerName}`)
                      console.log(`🔍 SelectedPartner state:`, selectedPartner[o._id])
                      console.log(`🔍 Full order data:`, o)
                      
                      const btnClass = disabled
                        ? 'px-3 py-1 rounded border border-slate-300 bg-white text-slate-400 text-sm cursor-not-allowed'
                        : 'px-3 py-1 rounded bg-emerald-600 hover:bg-emerald-700 text-white text-sm shadow'
                      
                      return (
                        <button
                          className={btnClass}
                          disabled={disabled}
                          onClick={async () => {
                            // Use the partner ID from order data or selectedPartner state or assignedPartners state
                            const partnerId = o.deliveryPartnerId || selectedPartner[o._id] || assignedPartners[o._id]
                            console.log(`🔄 Confirming order ${o._id} with partnerId: ${partnerId}`)
                            
                            if (!partnerId) {
                              alert('No delivery partner assigned to this order')
                              return
                            }
                            
                            try {
                              const { data } = await axios.patch(`/api/orders/${o._id}`, {
                                status: 'processing',
                                deliveryPartnerId: partnerId,
                              })
                              
                              console.log(`✅ Order ${o._id} confirmed successfully, response:`, data)
                              
                              // Preserve delivery partner information when updating state
                              setOrders(prev => prev.map(x => {
                                if (x._id === o._id) {
                                  return {
                                    ...x,
                                    ...data,
                                    // Preserve delivery partner info from original order
                                    deliveryPartnerId: x.deliveryPartnerId || data.deliveryPartnerId,
                                    deliveryPartnerName: x.deliveryPartnerName || data.deliveryPartnerName,
                                    deliveryPartnerPhone: x.deliveryPartnerPhone || data.deliveryPartnerPhone
                                  }
                                }
                                return x
                              }))
                              
                              setConfirmed(s => ({ ...s, [o._id]: true }))
                              
                              // Ensure selectedPartner state is maintained
                              if (partnerId && !selectedPartner[o._id]) {
                                setSelectedPartner(prev => ({
                                  ...prev,
                                  [o._id]: partnerId
                                }))
                              }
                              
                              // Show success message
                              alert(`Order ${o._id.slice(-6)} confirmed and sent to delivery partner!`)
                            } catch (error) {
                              console.error('Failed to confirm order:', error)
                              alert('Failed to confirm order. Please try again.')
                            }
                          }}
                        >
                          {isConfirmed ? 'Confirmed' : 'Confirm Order'}
                        </button>
                      )
                    })()}
                  </div>
                </td>

                <td className="px-3">
                  {!o.invoiceId ? (
                    <Button onClick={() => createInvoice(o._id)} size="sm">
                      Create
                    </Button>
                  ) : (
                    <span className="text-xs text-blue-600">
                      inv {o.invoiceId._id?.slice?.(-6)}
                    </span>
                  )}
                </td>

                <td className="px-3">
                  <button
                    onClick={() => remove(o._id)}
                    className="px-2 py-1 text-xs bg-red-600 text-white rounded hover:bg-red-700 transition-colors"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Delivery Partner Selection Modal */}
      {showPartnerModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-96 max-w-md mx-4">
            <h3 className="text-lg font-semibold mb-4">Select Delivery Partner</h3>
            <p className="text-sm text-gray-600 mb-4">
              Order: {selectedOrderForPartner?._id?.slice?.(-6)} | Total: Rs. {selectedOrderForPartner?.total?.toFixed(2)}
            </p>
            
            <div className="mb-4">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select Delivery Partner
              </label>
              {partners.length === 0 ? (
                <div className="w-full border border-gray-300 rounded-md px-3 py-2 bg-gray-50 text-gray-500">
                  <div className="text-center">
                    <div className="text-sm font-medium">No delivery partners available</div>
                    <div className="text-xs mt-1">Auto-create partner will be used</div>
                  </div>
                </div>
              ) : (
                <select
                  value={tempSelectedPartner}
                  onChange={(e) => setTempSelectedPartner(e.target.value)}
                  className="w-full border border-gray-300 rounded-md px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                >
                  <option value="">Choose a delivery partner or leave empty for auto-create</option>
                  {partners.map(partner => (
                    <option key={partner._id} value={partner._id}>
                      {partner.name} - {partner.contact || 'No contact'}
                    </option>
                  ))}
                </select>
              )}
              <div className="mt-2 text-xs text-gray-500">
                💡 Leave empty to auto-create a delivery partner and connect with delivery app
              </div>
            </div>
            
            <div className="flex gap-2">
              <button
                onClick={() => {
                  setShowPartnerModal(false)
                  setSelectedOrderForPartner(null)
                  setTempSelectedPartner('')
                }}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={assignDeliveryPartner}
                className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700"
              >
                {tempSelectedPartner ? 'Assign Partner' : 'Auto-Create & Assign'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Order Details Modal */}
      {showDetailsModal && selectedOrderForDetails && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-96 max-w-md mx-4">
            <h3 className="text-lg font-semibold mb-4">Order Details</h3>
            <p className="text-sm text-gray-600 mb-4">
              Order: {selectedOrderForDetails._id?.slice?.(-6)} | Total: Rs. {selectedOrderForDetails.total?.toFixed(2)}
            </p>
            
            {(() => {
              const orderDetails = detail[selectedOrderForDetails._id]
              console.log('🔍 [MODAL] Order details for', selectedOrderForDetails._id, ':', orderDetails)
              
              if (!orderDetails) {
                return (
                  <div className="text-center text-gray-500 py-4">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-2"></div>
                    Loading order details...
                    <div className="text-xs text-gray-400 mt-2">
                      This may take a moment if authentication is required.
                    </div>
                  </div>
                )
              }
              
              const prescription = orderDetails.prescription
              console.log('🔍 [MODAL] Prescription data:', prescription)
              
              if (prescription) {
                return (
                  <div className="space-y-4">
                    <div>
                      <h4 className="font-medium text-gray-900 mb-2">Customer Information</h4>
                      <div className="text-sm text-gray-600 space-y-1">
                        <div><strong>Name:</strong> {prescription.patientName || 'Not provided'}</div>
                        <div><strong>Address:</strong> {prescription.customerAddress || 'Not provided'}</div>
                        <div><strong>Phone:</strong> {prescription.customerPhone || 'Not provided'}</div>
                        <div><strong>Payment:</strong> {prescription.paymentMethod || 'Not specified'}</div>
                      </div>
                    </div>
                    
                    <div>
                      <h4 className="font-medium text-gray-900 mb-2">Pharmacy Information</h4>
                      <div className="text-sm text-gray-600 space-y-1">
                        <div><strong>Name:</strong> {prescription.pharmacyName || 'Not provided'}</div>
                        <div><strong>Address:</strong> {prescription.pharmacyAddress || 'Not provided'}</div>
                      </div>
                    </div>
                    
                    {prescription.medicines && prescription.medicines.length > 0 && (
                      <div>
                        <h4 className="font-medium text-gray-900 mb-2">Medicines</h4>
                        <div className="text-sm text-gray-600">
                          {prescription.medicines.map((med: any, index: number) => (
                            <div key={index} className="mb-1">
                              • {med.name} - {med.dosage} - {med.duration}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                    
                    {prescription.notes && (
                      <div>
                        <h4 className="font-medium text-gray-900 mb-2">Notes</h4>
                        <div className="text-sm text-gray-600">{prescription.notes}</div>
                      </div>
                    )}
                  </div>
                )
              } else {
                // Show basic order information if prescription data is not available
                return (
                  <div className="space-y-4">
                    <div>
                      <h4 className="font-medium text-gray-900 mb-2">Order Information</h4>
                      <div className="text-sm text-gray-600 space-y-1">
                        <div><strong>Order ID:</strong> {selectedOrderForDetails._id}</div>
                        <div><strong>Status:</strong> {selectedOrderForDetails.status}</div>
                        <div><strong>Total:</strong> Rs. {selectedOrderForDetails.total?.toFixed(2)}</div>
                        <div><strong>Address:</strong> {selectedOrderForDetails.address || 'Not provided'}</div>
                        <div><strong>Payment:</strong> {selectedOrderForDetails.paymentMethod || 'Not specified'}</div>
                      </div>
                    </div>
                    
                    <div className="text-sm text-yellow-600 bg-yellow-50 p-3 rounded">
                      <strong>Note:</strong> Detailed prescription information is not available. This might be because the order details could not be loaded or the order was not created from a prescription.
                    </div>
                  </div>
                )
              }
            })()}
            
            <div className="flex gap-2 mt-6">
              <button
                onClick={() => {
                  setShowDetailsModal(false)
                  setSelectedOrderForDetails(null)
                }}
                className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

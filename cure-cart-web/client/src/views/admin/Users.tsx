import { useEffect, useState } from 'react'
import axios from 'axios'
import { useAuth } from '../../stores/auth'
import { X, Check, AlertCircle } from 'lucide-react'

// Add animation styles
const style = document.createElement('style')
style.textContent = `
  @keyframes scale-up {
    from {
      opacity: 0;
      transform: scale(0.95) translateY(10px);
    }
    to {
      opacity: 1;
      transform: scale(1) translateY(0);
    }
  }
  .animate-scale-up {
    animation: scale-up 0.2s ease-out;
  }
`
document.head.appendChild(style)

export default function AdminUsers() {
  const [items, setItems] = useState<any[]>([])
  const [q, setQ] = useState('')
  const [showAddModal, setShowAddModal] = useState(false)
  const [newUser, setNewUser] = useState({
    name: '',
    email: '',
    password: '',
    role: 'customer',
    status: 'active'
  })
  
  // Popup state
  const [popup, setPopup] = useState<{
    show: boolean
    message: string
    type: 'success' | 'error'
  }>({
    show: false,
    message: '',
    type: 'success'
  })

  const [deleteConfirm, setDeleteConfirm] = useState<{
    show: boolean
    userId: string
    userName: string
  }>({
    show: false,
    userId: '',
    userName: ''
  })
  
  const refresh = () => axios.get('/api/admin/users').then(({ data }) => setItems(data))
  
  const handleAddUser = async (e: React.FormEvent) => {
    e.preventDefault()
    try {
      // Validate password length
      if (newUser.password.length < 6) {
        alert('Password must be at least 6 characters long')
        return
      }

      // Create the user with the provided password
      const { data } = await axios.post('/api/admin/users', newUser)
      
      if (data) {
        // Show success message
        showPopup('User created successfully! The user can now log in with their email and password.', 'success')
        
        // Update the users list
        setItems(prev => [...prev, data])
        
        // Close modal and reset form
        setShowAddModal(false)
        setNewUser({
          name: '',
          email: '',
          password: '',
          role: 'customer',
          status: 'active'
        })
      }
    } catch (error: any) {
      console.error('Error adding user:', error)
      const errorMessage = error.response?.data?.message || error.message || 'Failed to add user. Please try again.'
      showPopup('Error creating user: ' + errorMessage, 'error')
      
      // Log detailed error for debugging
      console.log('Detailed error:', {
        status: error.response?.status,
        data: error.response?.data,
        error: error
      })
    }
  }
  useEffect(() => { refresh() }, [])
  const setRole = async (id: string, role: string) => {
    const { data } = await axios.patch(`/api/admin/users/${id}/role`, { role })
    setItems(prev => prev.map(u => u._id === id ? data : u))
  }
  const setStatus = async (id: string, status: string) => {
    const { data } = await axios.patch(`/api/admin/users/${id}/status`, { status })
    setItems(prev => prev.map(u => u._id === id ? data : u))
  }
  const setKyc = async (id: string, verified: boolean) => {
    const { data } = await axios.patch(`/api/admin/users/${id}/kyc`, { verified })
    setItems(prev => prev.map(u => u._id === id ? data : u))
  }

  const handleDeleteConfirm = (id: string, userName: string) => {
    setDeleteConfirm({
      show: true,
      userId: id,
      userName
    })
  }

  const handleDeleteUser = async () => {
    try {
      await axios.delete(`/api/admin/users/${deleteConfirm.userId}`)
      setItems(prev => prev.filter(u => u._id !== deleteConfirm.userId))
      showPopup('User deleted successfully', 'success')
      setDeleteConfirm({ show: false, userId: '', userName: '' })
    } catch (error: any) {
      console.error('Error deleting user:', error)
      const errorMessage = error.response?.data?.message || error.message || 'Failed to delete user'
      showPopup('Error deleting user: ' + errorMessage, 'error')
    }
  }
  
  const showPopup = (message: string, type: 'success' | 'error' = 'success') => {
    setPopup({ show: true, message, type })
    // Auto hide after 3 seconds
    setTimeout(() => {
      setPopup(prev => ({ ...prev, show: false }))
    }, 3000)
  }

  const filtered = items.filter(u => `${u.name} ${u.email} ${u.role}`.toLowerCase().includes(q.toLowerCase()))
  const { user } = useAuth()
  
  // Debug logging
  console.log('Current user:', user)
  console.log('Is admin@gmail.com?:', user?.email === 'admin@gmail.com')

  return (
    <div className="bg-white border border-slate-200 rounded-lg p-4">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <div className="text-slate-900 font-semibold">Users</div>
          {/* Show Add User button only for admin@gmail.com */}
          {user?.email === 'admin@gmail.com' && (
            <button 
              className="text-sm bg-blue-600 hover:bg-blue-700 px-3 py-1 rounded text-white"
              onClick={() => setShowAddModal(true)}
            >
              Add user
            </button>
          )}
        </div>
        <input className="border rounded px-2 py-1 text-sm" placeholder="Search users..." value={q} onChange={(e)=>setQ(e.target.value)} />
      </div>
      <table className="w-full text-sm">
        <thead>
          <tr className="text-left text-slate-600">
            <th className="py-2">Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Status</th>
            <th>KYC</th>
            <th>Activity</th>
            {user?.email === 'admin@gmail.com' && <th>Actions</th>}
          </tr>
        </thead>
        <tbody>
          {filtered.map(u => (
            <tr key={u._id} className="border-t">
              <td className="py-2">{u.name}</td>
              <td>{u.email}</td>
              <td>{u.role}</td>
              <td>
                <select className="border rounded px-2 py-1" value={u.role} onChange={(e)=>setRole(u._id, e.target.value)}>
                  {['admin', 'pharmacist', 'customer'].map(r => <option key={r} value={r}>{r}</option>)}
                </select>
              </td>
              <td>
                <select className="border rounded px-2 py-1" value={u.status || 'active'} onChange={(e)=>setStatus(u._id, e.target.value)}>
                  {['active','suspended'].map(s => <option key={s} value={s}>{s}</option>)}
                </select>
              </td>
              <td>
                <button onClick={()=>setKyc(u._id, !u?.kyc?.verified)} className={`px-2 py-1 text-xs rounded ${u?.kyc?.verified ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-700'}`}>
                  {u?.kyc?.verified ? 'Verified' : 'Verify'}
                </button>
              </td>
              <td>
                <span className="text-xs text-slate-500">Last login: {u.lastLoginAt ? new Date(u.lastLoginAt).toLocaleString() : '-'}</span>
              </td>
              {user?.email === 'admin@gmail.com' && (
                <td>
                  <button
                    onClick={() => handleDeleteConfirm(u._id, u.name)}
                    className="text-sm text-red-600 hover:text-red-700 bg-red-50 hover:bg-red-100 px-2 py-1 rounded"
                  >
                    Delete
                  </button>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>

      {/* Add User Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold">Add New User</h3>
              <button onClick={() => setShowAddModal(false)} className="text-gray-500 hover:text-gray-700">
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <form onSubmit={handleAddUser}>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Name</label>
                  <input
                    type="text"
                    required
                    className="w-full border rounded px-3 py-2"
                    value={newUser.name}
                    onChange={e => setNewUser(prev => ({ ...prev, name: e.target.value }))}
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                  <input
                    type="email"
                    required
                    className="w-full border rounded px-3 py-2"
                    value={newUser.email}
                    onChange={e => setNewUser(prev => ({ ...prev, email: e.target.value }))}
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
                  <input
                    type="password"
                    required
                    minLength={6}
                    className="w-full border rounded px-3 py-2"
                    value={newUser.password}
                    onChange={e => setNewUser(prev => ({ ...prev, password: e.target.value }))}
                  />
                  <p className="text-xs text-gray-500 mt-1">Minimum 6 characters</p>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Role</label>
                  <select
                    className="w-full border rounded px-3 py-2"
                    value={newUser.role}
                    onChange={e => setNewUser(prev => ({ ...prev, role: e.target.value }))}
                  >
                    {['admin', 'pharmacist', 'customer'].map(role => (
                      <option key={role} value={role}>{role}</option>
                    ))}
                  </select>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Status</label>
                  <select
                    className="w-full border rounded px-3 py-2"
                    value={newUser.status}
                    onChange={e => setNewUser(prev => ({ ...prev, status: e.target.value }))}
                  >
                    {['active', 'suspended'].map(status => (
                      <option key={status} value={status}>{status}</option>
                    ))}
                  </select>
                </div>
                
                <div className="flex justify-end gap-2 mt-6">
                  <button
                    type="button"
                    onClick={() => setShowAddModal(false)}
                    className="px-4 py-2 text-sm border rounded text-gray-600 hover:bg-gray-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
                  >
                    Add User
                  </button>
                </div>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Confirmation Popup */}
      {deleteConfirm.show && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          {/* Dark overlay */}
          <div 
            className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity"
            onClick={() => setDeleteConfirm({ show: false, userId: '', userName: '' })}
          />
          
          {/* Popup content */}
          <div className="relative animate-scale-up max-w-md w-11/12 mx-4">
            <div className="relative rounded-xl p-6 shadow-2xl bg-white border-l-4 border-l-red-500">
              {/* Icon and content */}
              <div className="flex items-start gap-4">
                <div className="rounded-full p-3 bg-red-100">
                  <AlertCircle className="h-6 w-6 text-red-600" />
                </div>
                <div className="flex-1">
                  <h3 className="text-lg font-semibold mb-1 text-red-700">
                    Delete User
                  </h3>
                  <p className="text-gray-600">
                    Are you sure you want to delete user "{deleteConfirm.userName}"?<br/>
                    This action cannot be undone.
                  </p>
                </div>
              </div>

              {/* Action buttons */}
              <div className="mt-6 flex justify-end gap-3">
                <button
                  onClick={() => setDeleteConfirm({ show: false, userId: '', userName: '' })}
                  className="px-4 py-2 rounded-lg text-sm font-medium transition-colors bg-gray-100 text-gray-700 hover:bg-gray-200"
                >
                  Cancel
                </button>
                <button
                  onClick={handleDeleteUser}
                  className="px-4 py-2 rounded-lg text-sm font-medium transition-colors bg-red-600 text-white hover:bg-red-700"
                >
                  Delete User
                </button>
              </div>

              {/* Close button */}
              <button 
                onClick={() => setDeleteConfirm({ show: false, userId: '', userName: '' })}
                className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Notification Popup */}
      {popup.show && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          {/* Dark overlay */}
          <div 
            className="absolute inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity"
            onClick={() => setPopup(prev => ({ ...prev, show: false }))}
          />
          
          {/* Popup content */}
          <div className="relative animate-scale-up max-w-md w-11/12 mx-4">
            <div className={`relative rounded-xl p-6 shadow-2xl ${
              popup.type === 'success' 
                ? 'bg-white border-l-4 border-l-green-500' 
                : 'bg-white border-l-4 border-l-red-500'
            }`}>
              {/* Icon and content */}
              <div className="flex items-start gap-4">
                <div className={`rounded-full p-3 ${
                  popup.type === 'success' ? 'bg-green-100' : 'bg-red-100'
                }`}>
                  {popup.type === 'success' ? (
                    <Check className="h-6 w-6 text-green-600" />
                  ) : (
                    <AlertCircle className="h-6 w-6 text-red-600" />
                  )}
                </div>
                <div className="flex-1">
                  <h3 className={`text-lg font-semibold mb-1 ${
                    popup.type === 'success' ? 'text-green-700' : 'text-red-700'
                  }`}>
                    {popup.type === 'success' ? 'Success' : 'Error'}
                  </h3>
                  <p className="text-gray-600">
                    {popup.message}
                  </p>
                </div>
              </div>

              {/* Action buttons */}
              <div className="mt-6 flex justify-end gap-3">
                <button
                  onClick={() => setPopup(prev => ({ ...prev, show: false }))}
                  className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                    popup.type === 'success'
                      ? 'bg-green-50 text-green-700 hover:bg-green-100'
                      : 'bg-red-50 text-red-700 hover:bg-red-100'
                  }`}
                >
                  Close
                </button>
              </div>

              {/* Close button */}
              <button 
                onClick={() => setPopup(prev => ({ ...prev, show: false }))}
                className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}



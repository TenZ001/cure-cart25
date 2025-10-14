import { Outlet, NavLink, useLocation } from 'react-router-dom'
import { useState } from 'react'
import { Menu, LayoutDashboard, Users, Package, Star, Truck, LifeBuoy, Building2, LogOut } from 'lucide-react'
import { useAuth } from '../../stores/auth'
import { ConfirmDialog } from '../../ui/ConfirmDialog'

const links = [
  { to: '/admin/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/admin/users', label: 'Users', icon: Users },
  { to: '/admin/orders', label: 'Orders', icon: Package },
  { to: '/admin/feedback', label: 'Feedback', icon: Star },
  { to: '/admin/delivery-partners', label: 'Delivery', icon: Truck },
  { to: '/admin/pharmacies', label: 'Pharmacies', icon: Building2 },
  { to: '/admin/support', label: 'Support', icon: LifeBuoy },
]

export default function AdminRootLayout() {
  const [open, setOpen] = useState(true)
  const [showLogoutDialog, setShowLogoutDialog] = useState(false)
  const location = useLocation()
  const { logout } = useAuth()

  const handleLogout = () => {
    setShowLogoutDialog(true)
  }

  const confirmLogout = () => {
    logout()
  }

  return (
    <div className="min-h-screen flex bg-slate-50">
      <aside className={`${open ? 'w-64' : 'w-16'} transition-all duration-300 bg-white border-r border-slate-200`}>
        <div className="flex items-center justify-between px-3 py-3 border-b border-slate-200">
          <button onClick={()=>setOpen(!open)} className="p-2 rounded-md hover:bg-slate-100"><Menu size={18} /></button>
          <div className={`${open ? '' : 'opacity-0 w-0'} overflow-hidden transition-all text-slate-900 font-semibold`}>Admin</div>
        </div>
        <nav className="px-2 py-2 space-y-1">
          {links.map(({ to, label, icon: Icon }) => (
            <NavLink key={to} to={to} className={({ isActive }) => `flex items-center gap-3 px-3 py-2 rounded-md relative ${isActive ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'}`}>
              <Icon size={18} className="shrink-0" />
              <span className={`${open ? 'opacity-100 w-auto' : 'opacity-0 w-0'} overflow-hidden transition-all`}>{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="mt-auto p-3">
            <button onClick={handleLogout} className="w-full inline-flex items-center gap-2 btn-primary justify-center"><LogOut size={16}/> Logout</button>
        </div>
      </aside>
      <main className="flex-1 p-6">
        <header className="bg-white border border-slate-200 rounded-lg px-4 py-3 mb-4">
          <div className="text-sm text-slate-500">Admin area · <span className="font-medium text-slate-900">{location.pathname.replace('/admin/','') || 'dashboard'}</span></div>
        </header>
        <Outlet />
        <footer className="mt-8 text-xs text-slate-500">© {new Date().getFullYear()} CureCart Admin</footer>
      </main>
      
      {/* Logout Confirmation Dialog */}
      <ConfirmDialog
        isOpen={showLogoutDialog}
        onClose={() => setShowLogoutDialog(false)}
        onConfirm={confirmLogout}
        title="Confirm Logout"
        message="Are you sure you want to log out? You will need to sign in again to access the admin dashboard."
        confirmText="Logout"
        cancelText="Cancel"
        type="danger"
      />
    </div>
  )
}



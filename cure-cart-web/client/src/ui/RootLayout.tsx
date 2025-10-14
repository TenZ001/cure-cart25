import { Outlet, NavLink, useLocation, useNavigate } from 'react-router-dom'
import { Menu, LayoutDashboard, FileCheck, Package, MessageSquare, History, Boxes, Info, Star, BarChart3, Settings, LogOut, Users, ClipboardList, Bell, CreditCard, UserCircle2 } from 'lucide-react'
import { useState } from 'react'
import { useAuth } from '../stores/auth'
import { AnimatePresence, motion } from 'framer-motion'
import { ConfirmDialog } from './ConfirmDialog'
import { useDashboardSummary } from '../hooks/useDashboardSummary'
import { NotificationBadge } from './NotificationBadge'

const links = [
  { to: '/app/dashboard', label: 'Dashboard', icon: LayoutDashboard, badgeKey: null },
  { to: '/app/prescriptions', label: 'Prescriptions', icon: FileCheck, badgeKey: 'pendingPrescriptions' },
  { to: '/app/customers', label: 'Customers', icon: Users, badgeKey: null },
  { to: '/app/orders', label: 'Orders', icon: Package, badgeKey: 'activeOrders' },
  { to: '/app/medicines', label: 'Medicines', icon: ClipboardList, badgeKey: 'lowStock' },
  { to: '/app/billing', label: 'Billing', icon: CreditCard, badgeKey: null },
  { to: '/app/notifications', label: 'Notifications', icon: Bell, badgeKey: 'notifications.unread' },
  { to: '/app/reports', label: 'Reports', icon: BarChart3, badgeKey: null },
  { to: '/app/settings', label: 'Settings', icon: Settings, badgeKey: null },
  { to: '/app/profile', label: 'My Profile', icon: Settings, badgeKey: null },
  { to: '/app/chat', label: 'Chat / Support', icon: MessageSquare, badgeKey: 'unreadChatMessages' },
  { to: '/app/order-history', label: 'Order History', icon: History, badgeKey: null },
  { to: '/app/inventory', label: 'Inventory', icon: Boxes, badgeKey: 'lowStock' },
  { to: '/app/pharmacy-info', label: 'Pharmacy Info', icon: Info, badgeKey: null },
  { to: '/app/feedback', label: 'Feedback', icon: Star, badgeKey: null },
]

export default function RootLayout() {
  const [open, setOpen] = useState(true)
  const [showLogoutDialog, setShowLogoutDialog] = useState(false)
  const { user, logout } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()
  const { summary } = useDashboardSummary()

  const handleLogout = () => {
    setShowLogoutDialog(true)
  }

  const confirmLogout = () => {
    logout()
  }

  const getBadgeCount = (badgeKey: string | null): number => {
    if (!badgeKey || !summary) return 0
    
    const keys = badgeKey.split('.')
    let value: any = summary
    
    for (const key of keys) {
      value = value?.[key]
      if (value === undefined || value === null) return 0
    }
    
    return typeof value === 'number' ? value : 0
  }
  return (
    <div className="min-h-screen flex">
      <aside className={`${open ? 'w-64' : 'w-16'} transition-all duration-300 bg-white border-r border-slate-200` }>
        <div className="flex items-center justify-between px-3 py-3 border-b border-slate-200">
          <button onClick={() => setOpen(!open)} className="p-2 rounded-md hover:bg-slate-100"><Menu size={18} /></button>
          <button onClick={() => navigate('/app/profile')} className={`flex items-center gap-2 text-slate-900 font-semibold ${open ? '' : 'pointer-events-none'}`}>
            {(user as any)?.avatarUrl ? (
              <img 
                src={(user as any).avatarUrl} 
                alt="avatar" 
                className="w-6 h-6 rounded-full object-cover border"
                onError={(e) => {
                  (e.target as HTMLImageElement).style.display = 'none'
                  ;(e.target as HTMLImageElement).nextElementSibling?.classList.remove('hidden')
                }}
              />
            ) : null}
            <UserCircle2 
              size={20} 
              className={`text-brand-dark ${open ? '' : 'hidden'} ${(user as any)?.avatarUrl ? 'hidden' : ''}`} 
            />
            <span className={`${open ? 'opacity-100' : 'opacity-0'} transition-opacity`}>{user?.name || 'CureCart'}</span>
          </button>
        </div>
        <nav className="px-2 py-2 space-y-1">
          {links.map(({ to, label, icon: Icon, badgeKey }) => {
            const badgeCount = getBadgeCount(badgeKey)
            return (
              <NavLink key={to} to={to} className={({ isActive }) => `flex items-center gap-3 px-3 py-2 rounded-md ${isActive ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'}`}>
                <Icon size={18} className="shrink-0" />
                <span className={`${open ? 'opacity-100 w-auto' : 'opacity-0 w-0'} overflow-hidden transition-all flex-1`}>{label}</span>
                {open && badgeCount > 0 && (
                  <NotificationBadge count={badgeCount} />
                )}
              </NavLink>
            )
          })}
        </nav>
        <div className="mt-auto p-3">
            <button onClick={handleLogout} className="w-full inline-flex items-center gap-2 btn-primary justify-center"><LogOut size={16}/> Logout</button>
        </div>
      </aside>
      <main className="flex-1 p-6 bg-brand-sky">
        <header className="bg-white border border-slate-200 rounded-lg px-4 py-3 mb-4">
          <div className="text-sm text-slate-500">Signed in as <span className="font-medium text-slate-900">{user?.name}</span></div>
        </header>
        <AnimatePresence mode="wait">
          <motion.div
            key={location.pathname}
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -6 }}
            transition={{ duration: 0.15 }}
          >
            <Outlet />
          </motion.div>
        </AnimatePresence>
        <footer className="mt-8 text-xs text-slate-500">© {new Date().getFullYear()} CureCart. All rights reserved.</footer>
      </main>
      
      {/* Logout Confirmation Dialog */}
      <ConfirmDialog
        isOpen={showLogoutDialog}
        onClose={() => setShowLogoutDialog(false)}
        onConfirm={confirmLogout}
        title="Confirm Logout"
        message="Are you sure you want to log out? You will need to sign in again to access your dashboard."
        confirmText="Logout"
        cancelText="Cancel"
        type="danger"
      />
    </div>
  )
}



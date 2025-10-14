import { Navigate } from 'react-router-dom'
import RootLayout from './ui/RootLayout'
import LandingPage from './views/LandingPage'
import SimpleLanding from './views/SimpleLanding'
import Login from './views/auth/Login'
import Register from './views/auth/Register'
import ForgotPassword from './views/auth/ForgotPassword'
import Dashboard from './views/Dashboard'
import Prescriptions from './views/Prescriptions'
import Orders from './views/Orders'
import Chat from './views/Chat'
import OrderHistory from './views/OrderHistory'
import Inventory from './views/Inventory'
import PharmacyInfo from './views/PharmacyInfo'
import Feedback from './views/Feedback'
import Reports from './views/Reports'
import Settings from './views/Settings'
import { AuthGuard } from './stores/auth'
import Customers from './views/Customers'
import Medicines from './views/Medicines'
import Billing from './views/Billing'
import Notifications from './views/Notifications'
import Profile from './views/Profile'
import DeliverySignup from './views/DeliverySignup'
import AdminRootLayout from './views/admin/AdminRootLayout'
import AdminDashboard from './views/admin/Dashboard'
import AdminUsers from './views/admin/Users'
import AdminOrders from './views/admin/Orders'
import AdminFeedback from './views/admin/Feedback'
import AdminDelivery from './views/admin/DeliveryPartners'
import AdminSupport from './views/admin/Support'
import { AdminGuard } from './stores/auth'
import AdminPharmacies from './views/admin/Pharmacies'
import ErrorBoundary from './components/ErrorBoundary'
import NotFound from './components/NotFound'

export const routes = [
  // Landing page (public)
  { path: '/', element: <ErrorBoundary><SimpleLanding /></ErrorBoundary> },
  
  // Auth pages (public)
  { path: '/login', element: <ErrorBoundary><Login /></ErrorBoundary> },
  { path: '/register', element: <ErrorBoundary><Register /></ErrorBoundary> },
  { path: '/forgot-password', element: <ErrorBoundary><ForgotPassword /></ErrorBoundary> },
  
  // Protected app routes
  {
    path: '/app',
    element: <ErrorBoundary><AuthGuard><RootLayout /></AuthGuard></ErrorBoundary>,
    children: [
      { index: true, element: <Navigate to="/app/dashboard" /> },
      { path: 'dashboard', element: <Dashboard /> },
      { path: 'prescriptions', element: <Prescriptions /> },
      { path: 'customers', element: <Customers /> },
      { path: 'orders', element: <Orders /> },
      { path: 'medicines', element: <Medicines /> },
      { path: 'billing', element: <Billing /> },
      { path: 'notifications', element: <Notifications /> },
      { path: 'profile', element: <Profile /> },
      { path: 'chat', element: <Chat /> },
      { path: 'order-history', element: <OrderHistory /> },
      { path: 'inventory', element: <Inventory /> },
      { path: 'pharmacy-info', element: <PharmacyInfo /> },
      { path: 'feedback', element: <Feedback /> },
      { path: 'reports', element: <Reports /> },
      { path: 'settings', element: <Settings /> },
      { path: 'delivery-signup', element: <DeliverySignup /> },
      { path: '*', element: <NotFound /> },
    ],
  },
  {
    path: '/admin',
    element: <ErrorBoundary><AdminGuard><AdminRootLayout /></AdminGuard></ErrorBoundary>,
    children: [
      { index: true, element: <Navigate to="/admin/dashboard" /> },
      { path: 'dashboard', element: <AdminDashboard /> },
      { path: 'users', element: <AdminUsers /> },
      { path: 'orders', element: <AdminOrders /> },
      { path: 'feedback', element: <AdminFeedback /> },
      { path: 'delivery-partners', element: <AdminDelivery /> },
      { path: 'support', element: <AdminSupport /> },
      { path: 'pharmacies', element: <AdminPharmacies /> },
      { path: '*', element: <NotFound /> },
    ],
  },
  { path: '*', element: <NotFound /> },
]



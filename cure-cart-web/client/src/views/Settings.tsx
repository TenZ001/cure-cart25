import { useAuth } from '../stores/auth'

export default function Settings() {
  const { user } = useAuth()
  return (
    <div className="card max-w-xl">
      <div className="font-medium mb-4">Settings / Profile</div>
      <div className="space-y-3 text-sm">
        <div><span className="text-slate-500">Name:</span> <span className="font-medium">{user?.name}</span></div>
        <div><span className="text-slate-500">Email:</span> <span className="font-medium">{user?.email}</span></div>
        <div><span className="text-slate-500">Role:</span> <span className="font-medium">{user?.role}</span></div>
      </div>
    </div>
  )
}



import React, { useEffect, useState } from 'react'
import { useAuth } from '../stores/auth'
import { Card } from '../ui/Card'
import { Input } from '../ui/Input'
import { Button } from '../ui/Button'
import { useToast } from '../hooks/useToast'
import axios from 'axios'

export default function Profile() {
  const { user, hydrate } = useAuth()
  const { success, error: showError } = useToast()
  const [form, setForm] = useState<any>({
    name: user?.name || '',
    phone: (user as any)?.phone || '',
    employeeId: (user as any)?.employeeId || '',
    branch: (user as any)?.branch || '',
    qualifications: (user as any)?.qualifications || '',
    licenseNumber: (user as any)?.licenseNumber || '',
    address: (user as any)?.address || '',
    age: (user as any)?.age || '',
    gender: (user as any)?.gender || '',
  })

  const save = async () => {
    try {
      await axios.patch('/api/auth/me', form)
      await hydrate()
      success('Profile Updated', 'Your profile information has been updated successfully')
    } catch (error: any) {
      const errorMessage = error?.response?.data?.error || 'Failed to update profile'
      showError('Update Failed', errorMessage)
    }
  }

  const upload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    try {
      const fd = new FormData()
      fd.append('avatar', file)
      await axios.post('/api/auth/me/avatar', fd, { 
        headers: { 'Content-Type': 'multipart/form-data' } 
      })
      await hydrate()
      success('Profile Picture Updated', 'Your profile picture has been updated successfully')
    } catch (error: any) {
      const errorMessage = error?.response?.data?.error || 'Failed to upload profile picture'
      showError('Upload Failed', errorMessage)
    }
  }

  useEffect(() => {
    setForm({
      name: user?.name || '',
      phone: (user as any)?.phone || '',
      employeeId: (user as any)?.employeeId || '',
      branch: (user as any)?.branch || '',
      qualifications: (user as any)?.qualifications || '',
      licenseNumber: (user as any)?.licenseNumber || '',
      address: (user as any)?.address || '',
      age: (user as any)?.age || '',
      gender: (user as any)?.gender || '',
    })
  }, [user])
  return (
    <div className="grid md:grid-cols-2 gap-4">
      <Card className="p-4">
        <div className="font-medium mb-2">Pharmacist Details</div>
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div className="col-span-2 flex items-center gap-3">
            <img 
              src={(user as any)?.avatarUrl || 'https://via.placeholder.com/48'} 
              alt="avatar" 
              className="w-12 h-12 rounded-full border object-cover" 
              onError={(e) => {
                (e.target as HTMLImageElement).src = 'https://via.placeholder.com/48'
              }}
            />
            <div className="flex flex-col gap-1">
              <label className="text-xs cursor-pointer">
                <span className="btn-primary px-3 py-1 rounded-md cursor-pointer inline-block">Upload Photo</span>
                <input onChange={upload} type="file" accept="image/*" className="hidden" />
              </label>
              <span className="text-xs text-slate-500">JPG, PNG up to 2MB</span>
            </div>
          </div>
          <div className="col-span-2">
            <div className="text-slate-500 mb-1">Name</div>
            <Input value={form.name} onChange={(e)=>setForm((f:any)=>({ ...f, name: e.target.value }))} />
          </div>
          <div>
            <div className="text-slate-500 mb-1">Employee ID</div>
            <Input value={form.employeeId} onChange={(e)=>setForm((f:any)=>({ ...f, employeeId: e.target.value }))} />
          </div>
          <div>
            <div className="text-slate-500 mb-1">Branch</div>
            <Input value={form.branch} onChange={(e)=>setForm((f:any)=>({ ...f, branch: e.target.value }))} />
          </div>
          <div>
            <div className="text-slate-500 mb-1">Phone</div>
            <Input value={form.phone} onChange={(e)=>setForm((f:any)=>({ ...f, phone: e.target.value }))} />
          </div>
          <div className="col-span-2">
            <div className="text-slate-500 mb-1">Address</div>
            <Input value={form.address} onChange={(e)=>setForm((f:any)=>({ ...f, address: e.target.value }))} />
          </div>
        </div>
        <div className="mt-3 flex justify-end"><Button onClick={save}>Save</Button></div>
      </Card>
      <Card className="p-4">
        <div className="font-medium mb-2">Security</div>
        <div className="text-sm text-slate-500">Password change and 2FA setup coming soon.</div>
      </Card>
      <Card className="p-4">
        <div className="font-medium mb-2">Qualification & License</div>
        <div className="grid grid-cols-2 gap-3 text-sm">
          <div>
            <div className="text-slate-500 mb-1">Qualification</div>
            <Input value={form.qualifications} onChange={(e)=>setForm((f:any)=>({ ...f, qualifications: e.target.value }))} />
          </div>
          <div>
            <div className="text-slate-500 mb-1">License</div>
            <Input value={form.licenseNumber} onChange={(e)=>setForm((f:any)=>({ ...f, licenseNumber: e.target.value }))} />
          </div>
        </div>
      </Card>
      <Card className="p-4">
        <div className="font-medium mb-2">Attendance</div>
        <div className="text-sm text-slate-500">Shift timings & attendance log coming soon.</div>
      </Card>
    </div>
  )
}



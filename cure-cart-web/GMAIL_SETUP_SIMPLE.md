# 🚀 Simple Gmail Setup for CureCart

## Quick Setup (5 minutes)

### Step 1: Get Gmail App Password
1. Go to: https://myaccount.google.com/security
2. Turn ON "2-Step Verification" (if not already on)
3. Go to "App passwords" 
4. Select "Mail" and generate password
5. Copy the 16-character password (like: `abcd efgh ijkl mnop`)

### Step 2: Update .env file
Open `cure-cart-web/server/.env` and replace:

```env
EMAIL_USER=your-actual-email@gmail.com
EMAIL_PASS=your-16-character-app-password
```

### Step 3: Test it!
```bash
cd cure-cart-web/server
node setup-email.js
```

You should see: `✅ [EMAIL] Email configuration is working!`

## 🎯 What You Get

### Professional Email Design:
- ✅ **CureCart Logo & Branding**
- ✅ **Beautiful Gradient Header**
- ✅ **Large, Clear OTP Display**
- ✅ **Security Warnings**
- ✅ **Professional Footer**
- ✅ **Mobile Responsive**

### Features:
- ✅ **OTP in Console** (for debugging)
- ✅ **OTP in Gmail** (for users)
- ✅ **Professional Design**
- ✅ **Security Information**
- ✅ **CureCart Branding**

## 🔧 Current Status
- ✅ Backend: Working
- ✅ Frontend: Working  
- ✅ Console Logging: Working
- ⚠️ Gmail: Needs your credentials

## 📧 Email Preview
The email will look like:
- **Header**: CureCart logo with gradient background
- **OTP Box**: Large, clear 6-digit code
- **Security Info**: Important warnings
- **Footer**: Professional branding

Just add your Gmail credentials and it's ready! 🎉

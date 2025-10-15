# 🏥 CureCart System Demo Guide

## 📋 System Overview

**CureCart** is a comprehensive pharmacy management ecosystem consisting of:

### 🏗️ **System Architecture**
- **Mobile App**: Flutter-based cross-platform mobile application
- **Web Application**: React-based admin and pharmacy management dashboard  
- **Backend Services**: Two Node.js/Express servers (Mobile API + Web API)
- **Database**: MongoDB Atlas cloud database
- **Real-time Features**: Socket.io for live chat and notifications

### 👥 **User Roles**
1. **Patients**: Order medicines, track orders, chat with pharmacists
2. **Pharmacists**: Manage orders, chat with patients, update inventory
3. **Delivery Partners**: Accept deliveries, track locations, update status
4. **Admins**: System management, analytics, user management

---

## 🚀 **Demo Setup Instructions**

### **Prerequisites**
- Flutter SDK 3.8.0+
- Node.js 18+
- Android Studio / Xcode
- MongoDB Atlas account
- Git

### **1. Clone and Setup**
```bash
# Clone the repository
git clone <your-repo-url>
cd cure-cart-mobile

# Install Flutter dependencies
flutter pub get

# Install web dependencies
cd cure-cart-web
npm install

# Install mobile backend dependencies
cd ../backend
npm install
```

### **2. Database Configuration**
```bash
# Update MongoDB connection strings in:
# - backend/config/database.js
# - cure-cart-web/server/config/database.js

# Default connection: [YOUR_MONGODB_CONNECTION_STRING]
```

### **3. Start All Services**
```bash
# Terminal 1: Mobile Backend (Port 5000)
cd backend
npm start

# Terminal 2: Web Backend (Port 4000)  
cd cure-cart-web
npm run server

# Terminal 3: Web Frontend (Port 5173)
cd cure-cart-web
npm run client

# Terminal 4: Mobile App
cd cure-cart-mobile
flutter run
```

---

## 📱 **Mobile App Demo Script**

### **Demo Flow 1: Patient Journey**

#### **Step 1: User Registration & Login**
1. **Open the mobile app**
2. **Register as Patient:**
   - Email: `patient@demo.com`
   - Password: `demo123`
   - Role: Patient
3. **Login with credentials**
4. **Navigate to Home Screen**

#### **Step 2: Medicine Discovery**
1. **Search for medicines:**
   - Tap search bar
   - Type "Paracetamol" or "Aspirin"
   - Browse search results
2. **Quick Care Categories:**
   - Tap "Fever" category
   - Explore fever-related medicines
3. **Browse by Pharmacy:**
   - Scroll through pharmacy cards
   - Tap "View Details" on any pharmacy

#### **Step 3: Medicine Scanning**
1. **Navigate to Med Scan:**
   - Tap hamburger menu → "Med Scan"
2. **Scan Medicine:**
   - Tap camera button
   - Point at medicine packaging
   - View OCR results
3. **Add to Cart:**
   - Review detected medicine
   - Add to cart if correct

#### **Step 4: Prescription Upload**
1. **Upload Prescription:**
   - Tap "Upload Prescription" button
   - Take photo of prescription
   - Submit for processing
2. **View Prescriptions:**
   - Navigate to "Prescriptions" in menu
   - View uploaded prescriptions

#### **Step 5: Order Management**
1. **Add Items to Cart:**
   - Search and add medicines
   - Review cart contents
2. **Checkout Process:**
   - Tap cart icon
   - Review order details
   - Select delivery address
   - Choose payment method
   - Place order
3. **Track Order:**
   - Navigate to "My Orders"
   - View order status
   - Track delivery progress

#### **Step 6: Chat & Support**
1. **PharmaMate Chat:**
   - Tap "PharmaMate" card
   - Ask health-related questions
   - Get AI-powered responses
2. **Help Desk:**
   - Navigate to "HelpDesk"
   - Submit support requests
   - View response history

### **Demo Flow 2: Delivery Partner Journey**

#### **Step 1: Delivery Partner Login**
1. **Login as Delivery Partner:**
   - Email: `delivery@demo.com`
   - Password: `demo123`
   - Role: Delivery Partner

#### **Step 2: Delivery Dashboard**
1. **View Available Orders:**
   - Check pending deliveries
   - Review order details
   - Accept delivery assignments
2. **Location Tracking:**
   - Enable GPS tracking
   - Update delivery status
   - Navigate to customer location

#### **Step 3: Order Completion**
1. **Mark as Picked Up:**
   - Confirm pickup from pharmacy
   - Update order status
2. **Mark as Delivered:**
   - Confirm delivery to customer
   - Complete order process

---

## 🌐 **Web Application Demo Script**

### **Demo Flow 1: Admin Dashboard**

#### **Step 1: Admin Login**
1. **Open web application** (http://localhost:5173)
2. **Login as Admin:**
   - Email: `admin@demo.com`
   - Password: `admin123`

#### **Step 2: User Management**
1. **View All Users:**
   - Navigate to "Users" section
   - View patient, pharmacist, delivery partner lists
   - Filter by role and status
2. **User Actions:**
   - Suspend/activate users
   - View user details
   - Edit user information

#### **Step 3: Order Management**
1. **View All Orders:**
   - Navigate to "Orders" section
   - Filter by status (pending, processing, delivered)
   - View order details and timeline
2. **Order Processing:**
   - Update order status
   - Assign delivery partners
   - Handle order issues

#### **Step 4: Pharmacy Management**
1. **Manage Pharmacies:**
   - View pharmacy list
   - Approve/reject pharmacy registrations
   - Update pharmacy information
2. **Analytics Dashboard:**
   - View sales reports
   - Monitor system performance
   - Track user engagement

### **Demo Flow 2: Pharmacy Dashboard**

#### **Step 1: Pharmacist Login**
1. **Login as Pharmacist:**
   - Email: `pharmacist@demo.com`
   - Password: `demo123`

#### **Step 2: Order Processing**
1. **View Incoming Orders:**
   - Check new orders
   - Review prescription details
   - Process orders
2. **Inventory Management:**
   - Update medicine stock
   - Add new medicines
   - Set prices

#### **Step 3: Customer Communication**
1. **Chat with Customers:**
   - Respond to patient queries
   - Provide medicine information
   - Handle prescription clarifications

---

## 🎯 **Key Demo Features to Highlight**

### **Mobile App Features**
- ✅ **Multi-role Authentication** (Patient, Pharmacist, Delivery)
- ✅ **Medicine Scanning** (OCR-based recognition)
- ✅ **Prescription Upload** (Image processing)
- ✅ **Real-time Order Tracking** (GPS integration)
- ✅ **In-app Chat System** (Socket.io)
- ✅ **Medicine Reminders** (Push notifications)
- ✅ **Offline Support** (Local data caching)

### **Web Application Features**
- ✅ **Admin Dashboard** (User management, analytics)
- ✅ **Pharmacy Management** (Multi-pharmacy support)
- ✅ **Order Processing** (Complete lifecycle)
- ✅ **Real-time Chat** (Customer support)
- ✅ **Analytics & Reports** (Business insights)
- ✅ **File Management** (Cloudinary integration)

### **Backend Features**
- ✅ **RESTful APIs** (Mobile + Web endpoints)
- ✅ **Real-time Communication** (Socket.io)
- ✅ **File Upload Handling** (Multer + Cloudinary)
- ✅ **JWT Authentication** (Secure token-based auth)
- ✅ **Database Integration** (MongoDB Atlas)

---

## 📊 **Sample Data for Demo**

### **Test Users**
```javascript
// Patients
{ email: "patient@demo.com", password: "demo123", role: "patient" }
{ email: "john@demo.com", password: "demo123", role: "patient" }

// Pharmacists  
{ email: "pharmacist@demo.com", password: "demo123", role: "pharmacist" }
{ email: "pharmacy1@demo.com", password: "demo123", role: "pharmacist" }

// Delivery Partners
{ email: "delivery@demo.com", password: "demo123", role: "delivery" }
{ email: "driver1@demo.com", password: "demo123", role: "delivery" }

// Admin
{ email: "admin@demo.com", password: "admin123", role: "admin" }
```

### **Sample Pharmacies**
```javascript
{
  name: "City Pharmacy",
  address: "123 Main Street, Colombo",
  phone: "+94 77 123 4567",
  image: "pharmacy1.jpg",
  status: "approved"
}
```

### **Sample Orders**
```javascript
{
  customerId: "patient_user_id",
  pharmacyId: "pharmacy_id", 
  items: [
    { medicine: "Paracetamol", quantity: 2, price: 199 },
    { medicine: "Aspirin", quantity: 1, price: 180 }
  ],
  total: 578,
  status: "processing",
  deliveryAddress: "123 Customer Street"
}
```

---

## 🔧 **Troubleshooting Demo Issues**

### **Common Issues & Solutions**

#### **Mobile App Issues**
```bash
# Flutter dependencies
flutter clean
flutter pub get

# Android build issues
cd android
./gradlew clean
cd ..
flutter run

# iOS build issues  
cd ios
pod install
cd ..
flutter run
```

#### **Web Application Issues**
```bash
# Clear node modules
rm -rf node_modules package-lock.json
npm install

# Backend connection issues
# Check MongoDB connection string
# Verify backend services are running
```

#### **Database Connection Issues**
```bash
# Check MongoDB Atlas connection
# Verify network access settings
# Test connection with MongoDB Compass
```

---

## 📈 **Demo Performance Tips**

### **Optimization Checklist**
- ✅ **Database Indexing**: Ensure proper MongoDB indexes
- ✅ **Image Optimization**: Use Cloudinary for image processing
- ✅ **Caching**: Enable local storage for offline support
- ✅ **Real-time Updates**: Socket.io for live features
- ✅ **Error Handling**: Proper error messages and fallbacks

### **Demo Environment Setup**
- ✅ **Stable Internet**: Required for real-time features
- ✅ **Device Permissions**: Camera, location, notifications
- ✅ **Backend Services**: All services running simultaneously
- ✅ **Database Access**: MongoDB Atlas connection active

---

## 🎬 **Demo Presentation Flow**

### **1. System Overview (5 minutes)**
- Architecture diagram
- Technology stack
- Key features overview

### **2. Mobile App Demo (15 minutes)**
- Patient journey (registration → order → delivery)
- Medicine scanning
- Prescription upload
- Real-time chat

### **3. Web Application Demo (10 minutes)**
- Admin dashboard
- Pharmacy management
- Order processing
- Analytics

### **4. Technical Deep Dive (10 minutes)**
- Backend APIs
- Database schema
- Real-time features
- Security measures

### **5. Q&A Session (10 minutes)**
- Technical questions
- Feature requests
- Implementation details

---

## 📞 **Demo Support**

### **Pre-Demo Checklist**
- [ ] All services running (Mobile API, Web API, Web Frontend)
- [ ] Database connection active
- [ ] Test data populated
- [ ] Mobile app installed and configured
- [ ] Web application accessible
- [ ] Demo script prepared

### **Demo Day Setup**
- [ ] Stable internet connection
- [ ] Backup demo environment
- [ ] Screen sharing setup
- [ ] Audio/video equipment
- [ ] Demo data ready
- [ ] Troubleshooting guide available

---

**🎯 Ready to showcase your comprehensive CureCart pharmacy management system!**

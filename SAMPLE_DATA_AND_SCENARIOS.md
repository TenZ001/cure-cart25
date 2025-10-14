# 📊 CureCart Sample Data & Test Scenarios

## 🎯 Demo Data Overview

This document provides comprehensive sample data and test scenarios for demonstrating the CureCart system effectively.

---

## 👥 **Sample Users**

### **Patient Users**
```javascript
// Primary Demo Patient
{
  _id: "patient_demo_001",
  name: "John Smith",
  email: "patient@demo.com",
  password: "$2b$10$encrypted_password_hash",
  role: "patient",
  phone: "+94 77 123 4567",
  address: "123 Main Street, Colombo 03",
  avatar: "patient_avatar.jpg",
  status: "active",
  createdAt: "2024-01-15T10:00:00Z"
}

// Secondary Demo Patient
{
  _id: "patient_demo_002", 
  name: "Sarah Johnson",
  email: "sarah@demo.com",
  password: "$2b$10$encrypted_password_hash",
  role: "patient",
  phone: "+94 77 234 5678",
  address: "456 Park Avenue, Colombo 07",
  avatar: "sarah_avatar.jpg",
  status: "active",
  createdAt: "2024-01-20T14:30:00Z"
}
```

### **Pharmacist Users**
```javascript
// Primary Demo Pharmacist
{
  _id: "pharmacist_demo_001",
  name: "Dr. Michael Chen",
  email: "pharmacist@demo.com", 
  password: "$2b$10$encrypted_password_hash",
  role: "pharmacist",
  phone: "+94 77 345 6789",
  address: "789 Pharmacy Lane, Colombo 05",
  pharmacyId: "pharmacy_demo_001",
  avatar: "pharmacist_avatar.jpg",
  status: "active",
  createdAt: "2024-01-10T09:00:00Z"
}

// Secondary Demo Pharmacist
{
  _id: "pharmacist_demo_002",
  name: "Dr. Lisa Rodriguez",
  email: "lisa@demo.com",
  password: "$2b$10$encrypted_password_hash", 
  role: "pharmacist",
  phone: "+94 77 456 7890",
  address: "321 Health Street, Colombo 04",
  pharmacyId: "pharmacy_demo_002",
  avatar: "lisa_avatar.jpg",
  status: "active",
  createdAt: "2024-01-12T11:15:00Z"
}
```

### **Delivery Partner Users**
```javascript
// Primary Demo Delivery Partner
{
  _id: "delivery_demo_001",
  name: "Alex Kumar",
  email: "delivery@demo.com",
  password: "$2b$10$encrypted_password_hash",
  role: "delivery",
  phone: "+94 77 567 8901",
  address: "654 Delivery Road, Colombo 06",
  vehicleType: "motorcycle",
  licenseNumber: "DL123456",
  avatar: "delivery_avatar.jpg",
  status: "active",
  createdAt: "2024-01-08T08:00:00Z"
}

// Secondary Demo Delivery Partner
{
  _id: "delivery_demo_002",
  name: "Priya Singh",
  email: "priya@demo.com",
  password: "$2b$10$encrypted_password_hash",
  role: "delivery", 
  phone: "+94 77 678 9012",
  address: "987 Transport Avenue, Colombo 08",
  vehicleType: "bicycle",
  licenseNumber: "DL789012",
  avatar: "priya_avatar.jpg",
  status: "active",
  createdAt: "2024-01-14T16:45:00Z"
}
```

### **Admin Users**
```javascript
// System Administrator
{
  _id: "admin_demo_001",
  name: "Admin User",
  email: "admin@demo.com",
  password: "$2b$10$encrypted_password_hash",
  role: "admin",
  phone: "+94 77 789 0123",
  address: "Admin Office, CureCart HQ",
  avatar: "admin_avatar.jpg",
  status: "active",
  createdAt: "2024-01-01T00:00:00Z"
}
```

---

## 🏥 **Sample Pharmacies**

### **Primary Demo Pharmacy**
```javascript
{
  _id: "pharmacy_demo_001",
  name: "City Health Pharmacy",
  description: "Leading pharmacy providing comprehensive healthcare solutions with 24/7 emergency services.",
  address: "123 Health Street, Colombo 03",
  phone: "+94 11 234 5678",
  email: "info@cityhealth.com",
  image: "city_health_pharmacy.jpg",
  location: {
    latitude: 6.9271,
    longitude: 79.8612,
    address: "123 Health Street, Colombo 03"
  },
  services: ["prescription", "consultation", "emergency", "delivery"],
  operatingHours: {
    monday: "08:00-22:00",
    tuesday: "08:00-22:00", 
    wednesday: "08:00-22:00",
    thursday: "08:00-22:00",
    friday: "08:00-22:00",
    saturday: "08:00-20:00",
    sunday: "09:00-18:00"
  },
  status: "approved",
  rating: 4.8,
  reviewCount: 156,
  createdAt: "2024-01-05T10:00:00Z"
}
```

### **Secondary Demo Pharmacy**
```javascript
{
  _id: "pharmacy_demo_002",
  name: "Wellness Care Pharmacy",
  description: "Modern pharmacy specializing in wellness and preventive care with expert pharmacists.",
  address: "456 Wellness Avenue, Colombo 07",
  phone: "+94 11 345 6789",
  email: "contact@wellnesscare.com",
  image: "wellness_care_pharmacy.jpg",
  location: {
    latitude: 6.9147,
    longitude: 79.8730,
    address: "456 Wellness Avenue, Colombo 07"
  },
  services: ["prescription", "consultation", "wellness", "delivery"],
  operatingHours: {
    monday: "07:00-21:00",
    tuesday: "07:00-21:00",
    wednesday: "07:00-21:00", 
    thursday: "07:00-21:00",
    friday: "07:00-21:00",
    saturday: "08:00-19:00",
    sunday: "10:00-17:00"
  },
  status: "approved",
  rating: 4.6,
  reviewCount: 89,
  createdAt: "2024-01-12T14:30:00Z"
}
```

---

## 💊 **Sample Medicines**

### **Common Medicines**
```javascript
// Pain Relief
{
  _id: "medicine_demo_001",
  name: "Paracetamol 500mg",
  genericName: "Acetaminophen",
  category: "pain_relief",
  description: "Common pain reliever and fever reducer",
  price: 199,
  stock: 150,
  unit: "tablets",
  image: "paracetamol.jpg",
  manufacturer: "ABC Pharmaceuticals",
  prescriptionRequired: false,
  sideEffects: ["Nausea", "Stomach upset"],
  dosage: "1-2 tablets every 4-6 hours",
  expiryDate: "2025-12-31",
  pharmacyId: "pharmacy_demo_001",
  status: "active"
}

// Antibiotic
{
  _id: "medicine_demo_002", 
  name: "Azithromycin 250mg",
  genericName: "Azithromycin",
  category: "antibiotic",
  description: "Used to treat various bacterial infections",
  price: 500,
  stock: 75,
  unit: "tablets",
  image: "azithromycin.jpg",
  manufacturer: "XYZ Pharma",
  prescriptionRequired: true,
  sideEffects: ["Nausea", "Diarrhea", "Stomach pain"],
  dosage: "1 tablet daily for 3-5 days",
  expiryDate: "2025-08-15",
  pharmacyId: "pharmacy_demo_001",
  status: "active"
}

// Fever Medicine
{
  _id: "medicine_demo_003",
  name: "Aspirin 100mg", 
  genericName: "Acetylsalicylic Acid",
  category: "fever",
  description: "Used to reduce fever and relieve pain",
  price: 180,
  stock: 200,
  unit: "tablets",
  image: "aspirin.jpg",
  manufacturer: "DEF Medical",
  prescriptionRequired: false,
  sideEffects: ["Stomach irritation", "Bleeding risk"],
  dosage: "1-2 tablets every 4-6 hours",
  expiryDate: "2025-06-20",
  pharmacyId: "pharmacy_demo_002",
  status: "active"
}

// Vitamin
{
  _id: "medicine_demo_004",
  name: "Vitamin C 1000mg",
  genericName: "Ascorbic Acid", 
  category: "vitamin",
  description: "Essential vitamin for immune system support",
  price: 299,
  stock: 100,
  unit: "tablets",
  image: "vitamin_c.jpg",
  manufacturer: "GHI Health",
  prescriptionRequired: false,
  sideEffects: ["Diarrhea in high doses"],
  dosage: "1 tablet daily",
  expiryDate: "2025-10-10",
  pharmacyId: "pharmacy_demo_002",
  status: "active"
}
```

---

## 📋 **Sample Orders**

### **Active Order (Processing)**
```javascript
{
  _id: "order_demo_001",
  customerId: "patient_demo_001",
  pharmacyId: "pharmacy_demo_001",
  deliveryPartnerId: "delivery_demo_001",
  items: [
    {
      medicineId: "medicine_demo_001",
      name: "Paracetamol 500mg",
      quantity: 2,
      price: 199,
      total: 398
    },
    {
      medicineId: "medicine_demo_004", 
      name: "Vitamin C 1000mg",
      quantity: 1,
      price: 299,
      total: 299
    }
  ],
  total: 697,
  status: "processing",
  paymentMethod: "cash_on_delivery",
  deliveryAddress: "123 Main Street, Colombo 03",
  prescriptionId: "prescription_demo_001",
  timeline: [
    {
      status: "placed",
      timestamp: "2024-01-25T10:00:00Z",
      description: "Order placed successfully"
    },
    {
      status: "confirmed", 
      timestamp: "2024-01-25T10:15:00Z",
      description: "Order confirmed by pharmacy"
    },
    {
      status: "processing",
      timestamp: "2024-01-25T10:30:00Z", 
      description: "Order being prepared"
    }
  ],
  estimatedDelivery: "2024-01-25T14:00:00Z",
  createdAt: "2024-01-25T10:00:00Z"
}
```

### **Completed Order**
```javascript
{
  _id: "order_demo_002",
  customerId: "patient_demo_002",
  pharmacyId: "pharmacy_demo_002", 
  deliveryPartnerId: "delivery_demo_002",
  items: [
    {
      medicineId: "medicine_demo_002",
      name: "Azithromycin 250mg",
      quantity: 1,
      price: 500,
      total: 500
    }
  ],
  total: 500,
  status: "delivered",
  paymentMethod: "credit_card",
  deliveryAddress: "456 Park Avenue, Colombo 07",
  prescriptionId: "prescription_demo_002",
  timeline: [
    {
      status: "placed",
      timestamp: "2024-01-24T09:00:00Z",
      description: "Order placed successfully"
    },
    {
      status: "confirmed",
      timestamp: "2024-01-24T09:10:00Z", 
      description: "Order confirmed by pharmacy"
    },
    {
      status: "processing",
      timestamp: "2024-01-24T09:20:00Z",
      description: "Order being prepared"
    },
    {
      status: "ready_for_pickup",
      timestamp: "2024-01-24T11:00:00Z",
      description: "Order ready for pickup"
    },
    {
      status: "picked_up",
      timestamp: "2024-01-24T11:30:00Z",
      description: "Order picked up by delivery partner"
    },
    {
      status: "out_for_delivery",
      timestamp: "2024-01-24T12:00:00Z",
      description: "Order out for delivery"
    },
    {
      status: "delivered",
      timestamp: "2024-01-24T14:30:00Z",
      description: "Order delivered successfully"
    }
  ],
  deliveredAt: "2024-01-24T14:30:00Z",
  createdAt: "2024-01-24T09:00:00Z"
}
```

---

## 📄 **Sample Prescriptions**

### **Active Prescription**
```javascript
{
  _id: "prescription_demo_001",
  patientId: "patient_demo_001",
  doctorName: "Dr. Sarah Wilson",
  doctorLicense: "MD123456",
  hospital: "City General Hospital",
  prescriptionDate: "2024-01-25T08:00:00Z",
  medicines: [
    {
      name: "Paracetamol 500mg",
      dosage: "1-2 tablets every 4-6 hours",
      duration: "3 days",
      quantity: 6
    },
    {
      name: "Vitamin C 1000mg", 
      dosage: "1 tablet daily",
      duration: "7 days",
      quantity: 7
    }
  ],
  image: "prescription_image_001.jpg",
  status: "active",
  notes: "Take with food. Complete full course.",
  createdAt: "2024-01-25T08:00:00Z"
}
```

### **Completed Prescription**
```javascript
{
  _id: "prescription_demo_002",
  patientId: "patient_demo_002",
  doctorName: "Dr. Michael Brown",
  doctorLicense: "MD789012",
  hospital: "Wellness Medical Center",
  prescriptionDate: "2024-01-24T07:30:00Z",
  medicines: [
    {
      name: "Azithromycin 250mg",
      dosage: "1 tablet daily",
      duration: "5 days", 
      quantity: 5
    }
  ],
  image: "prescription_image_002.jpg",
  status: "completed",
  notes: "Take on empty stomach. Complete full course.",
  completedAt: "2024-01-24T14:30:00Z",
  createdAt: "2024-01-24T07:30:00Z"
}
```

---

## 💬 **Sample Chat Messages**

### **Patient-Pharmacist Chat**
```javascript
{
  _id: "chat_demo_001",
  participants: ["patient_demo_001", "pharmacist_demo_001"],
  messages: [
    {
      _id: "msg_001",
      senderId: "patient_demo_001",
      senderName: "John Smith",
      content: "Hi, I have a question about my prescription",
      timestamp: "2024-01-25T10:00:00Z",
      type: "text"
    },
    {
      _id: "msg_002", 
      senderId: "pharmacist_demo_001",
      senderName: "Dr. Michael Chen",
      content: "Hello John! I'd be happy to help. What's your question?",
      timestamp: "2024-01-25T10:02:00Z",
      type: "text"
    },
    {
      _id: "msg_003",
      senderId: "patient_demo_001", 
      senderName: "John Smith",
      content: "Can I take Paracetamol with my other medications?",
      timestamp: "2024-01-25T10:05:00Z",
      type: "text"
    },
    {
      _id: "msg_004",
      senderId: "pharmacist_demo_001",
      senderName: "Dr. Michael Chen", 
      content: "Yes, Paracetamol is generally safe with most medications. However, please consult with your doctor if you're taking blood thinners or have liver conditions.",
      timestamp: "2024-01-25T10:07:00Z",
      type: "text"
    }
  ],
  status: "active",
  createdAt: "2024-01-25T10:00:00Z"
}
```

---

## 🔔 **Sample Notifications**

### **Order Notifications**
```javascript
{
  _id: "notification_demo_001",
  userId: "patient_demo_001",
  type: "order_update",
  title: "Order Status Update",
  message: "Your order #ORD001 is now being prepared",
  data: {
    orderId: "order_demo_001",
    status: "processing"
  },
  read: false,
  createdAt: "2024-01-25T10:30:00Z"
}

{
  _id: "notification_demo_002",
  userId: "delivery_demo_001", 
  type: "new_delivery",
  title: "New Delivery Assignment",
  message: "You have been assigned a new delivery order",
  data: {
    orderId: "order_demo_001",
    customerAddress: "123 Main Street, Colombo 03"
  },
  read: false,
  createdAt: "2024-01-25T10:15:00Z"
}
```

---

## 🎭 **Demo Test Scenarios**

### **Scenario 1: Complete Patient Journey**
1. **User Registration**
   - Register as new patient
   - Verify email confirmation
   - Complete profile setup

2. **Medicine Discovery**
   - Search for "Paracetamol"
   - Browse medicine details
   - Add to cart

3. **Prescription Upload**
   - Upload sample prescription
   - Verify OCR processing
   - Review prescription details

4. **Order Placement**
   - Proceed to checkout
   - Select delivery address
   - Choose payment method
   - Place order

5. **Order Tracking**
   - View order status
   - Track delivery progress
   - Receive notifications

### **Scenario 2: Pharmacist Workflow**
1. **Login as Pharmacist**
   - Access pharmacist dashboard
   - View pending orders

2. **Order Processing**
   - Review prescription
   - Check medicine availability
   - Update inventory
   - Mark order as ready

3. **Customer Communication**
   - Respond to patient queries
   - Provide medicine information
   - Handle prescription clarifications

### **Scenario 3: Delivery Partner Workflow**
1. **Login as Delivery Partner**
   - Access delivery dashboard
   - View available orders

2. **Order Acceptance**
   - Accept delivery assignment
   - Navigate to pharmacy
   - Pick up order

3. **Delivery Process**
   - Navigate to customer
   - Update delivery status
   - Complete delivery

### **Scenario 4: Admin Management**
1. **Login as Admin**
   - Access admin dashboard
   - View system overview

2. **User Management**
   - View all users
   - Manage user roles
   - Handle user issues

3. **Order Management**
   - Monitor all orders
   - Handle order issues
   - Generate reports

4. **Pharmacy Management**
   - Approve new pharmacies
   - Manage pharmacy information
   - Monitor performance

---

## 📊 **Analytics Data**

### **System Metrics**
```javascript
{
  totalUsers: 1250,
  activeUsers: 980,
  totalOrders: 3450,
  completedOrders: 3200,
  totalRevenue: 1250000,
  averageOrderValue: 362,
  pharmacies: 25,
  medicines: 1500,
  prescriptions: 890
}
```

### **User Engagement**
```javascript
{
  dailyActiveUsers: 450,
  weeklyActiveUsers: 1200,
  monthlyActiveUsers: 980,
  averageSessionDuration: 8.5,
  featureUsage: {
    medicineSearch: 85,
    prescriptionUpload: 60,
    chatSupport: 40,
    orderTracking: 90
  }
}
```

---

## 🎯 **Demo Success Metrics**

### **Technical Performance**
- App launch time: < 3 seconds
- Search response time: < 1 second
- Real-time update latency: < 500ms
- Image upload time: < 5 seconds
- Chat message delivery: < 200ms

### **User Experience**
- Intuitive navigation
- Clear error messages
- Responsive design
- Offline functionality
- Accessibility features

### **Business Value**
- Reduced order processing time
- Improved customer satisfaction
- Enhanced communication
- Better inventory management
- Data-driven insights

---

**🎯 Your CureCart demo is now equipped with comprehensive sample data and realistic test scenarios!**

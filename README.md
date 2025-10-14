# 🏥 CureCart - Complete Pharmacy Management System

A comprehensive pharmacy management system consisting of a **Flutter mobile app** and a **React web application**, both connected to a **MongoDB database** with **Node.js backends**.

## 📱 **CureCart Mobile (Flutter App)**

### **Technology Stack**
- **Framework:** Flutter 3.8.0+ with Dart
- **State Management:** Built-in Flutter state management
- **HTTP Client:** http package for API calls
- **Local Storage:** SharedPreferences for data persistence
- **Image Processing:** image_picker, google_mlkit_text_recognition
- **Maps & Location:** google_maps_flutter, geolocator, flutter_map
- **Notifications:** flutter_local_notifications
- **Environment:** flutter_dotenv for configuration

### **Key Features**
- **Multi-role Authentication:** Patients, Pharmacists, Delivery Partners
- **Medicine Scanning:** Camera-based medicine recognition
- **Prescription Management:** Upload and manage prescriptions
- **Order Tracking:** Real-time order status updates
- **Location Services:** GPS tracking for delivery
- **Chat System:** In-app messaging between users
- **Medicine Reminders:** Push notifications for medication
- **Offline Support:** Local data caching

### **Project Structure**
```
lib/
├── main.dart                    # App entry point
├── api_config.dart             # API configuration
├── api_service.dart            # API service layer
├── home_screen.dart            # Main dashboard
├── login_screen.dart           # Authentication
├── register_screen.dart        # User registration
├── med_scan.dart              # Medicine scanning
├── my_orders.dart              # Order management
├── track_order.dart            # Order tracking
├── chat_page.dart              # Messaging system
├── delivery/                   # Delivery partner features
│   ├── dashboard.dart
│   ├── orders_screen.dart
│   └── location_tracking_screen.dart
└── assets/                     # Images and icons
```

### **Dependencies**
```yaml
dependencies:
  flutter: sdk: flutter
  http: ^1.2.0                 # API communication
  shared_preferences: ^2.2.3   # Local storage
  image_picker: ^1.2.0        # Camera/gallery access
  google_mlkit_text_recognition: ^0.15.0  # OCR
  google_maps_flutter: ^2.9.0  # Maps integration
  geolocator: ^10.1.0          # Location services
  flutter_local_notifications: ^17.2.3  # Push notifications
  mongo_dart: ^0.10.5          # Direct MongoDB access
```

---

## 🌐 **CureCart Web (React Application)**

### **Technology Stack**
- **Frontend:** React 19.1.1 with TypeScript
- **Build Tool:** Vite 7.1.2
- **Routing:** React Router DOM 7.8.2
- **Styling:** Tailwind CSS 3.4.13
- **State Management:** Zustand 5.0.8
- **UI Components:** Radix UI primitives
- **Real-time:** Socket.io Client
- **Charts:** Recharts for analytics

### **Key Features**
- **Admin Dashboard:** Comprehensive management panel
- **Pharmacy Management:** Multi-pharmacy support
- **Order Processing:** Complete order lifecycle
- **Real-time Chat:** Socket.io powered messaging
- **Inventory Management:** Medicine stock tracking
- **Analytics & Reports:** Data visualization
- **User Management:** Role-based access control
- **File Uploads:** Cloudinary integration

### **Project Structure**
```
cure-cart-web/
├── client/                    # React Frontend
│   ├── src/
│   │   ├── components/        # Reusable components
│   │   ├── views/            # Page components
│   │   │   ├── admin/        # Admin panel pages
│   │   │   ├── auth/         # Login/Register
│   │   │   └── *.tsx         # Main app pages
│   │   ├── stores/           # Zustand state management
│   │   ├── ui/              # UI component library
│   │   └── routes.tsx        # React Router config
│   └── package.json
├── server/                   # Node.js Backend
│   ├── routes/              # API endpoints
│   ├── schemas/             # MongoDB models
│   ├── utils/               # Helper functions
│   └── index.js             # Server entry point
└── package.json             # Root configuration
```

### **Dependencies**
```json
{
  "dependencies": {
    "react": "^19.1.1",
    "react-dom": "^19.1.1",
    "react-router-dom": "^7.8.2",
    "tailwindcss": "^3.4.13",
    "zustand": "^5.0.8",
    "socket.io-client": "^4.8.1",
    "axios": "^1.11.0",
    "framer-motion": "^12.23.12"
  }
}
```

---

## 🗄️ **Database Architecture**

### **MongoDB Atlas (Cloud Database)**
- **Connection:** `mongodb+srv://CureCart:Pramod@1997@curecart.ce760px.mongodb.net/`
- **Database:** `curecart` (main), `curecartmobile` (mobile users)
- **ODM:** Mongoose for both web and mobile backends

### **Database Collections**
- **Users:** Multi-role user management (patients, pharmacists, delivery, admin)
- **Pharmacies:** Pharmacy information and locations
- **Orders:** Complete order lifecycle tracking
- **Prescriptions:** Digital prescription management
- **Medicines:** Medicine catalog and inventory
- **ChatMessages:** Real-time messaging system
- **Feedback:** User feedback and reviews
- **Notifications:** Push notification management

---

## 🚀 **Backend Services**

### **Mobile Backend (Node.js/Express)**
- **Port:** 5000
- **Features:** Mobile-specific API endpoints
- **Authentication:** JWT-based auth for mobile users
- **Database:** `curecartmobile` collection
- **File Upload:** Multer for image handling

### **Web Backend (Node.js/Express)**
- **Port:** 4000
- **Features:** Web application API endpoints
- **Authentication:** JWT-based auth for web users
- **Database:** `curecart` collection
- **Real-time:** Socket.io for live features

### **API Endpoints**
```
Mobile Backend (Port 5000):
├── /api/auth/login          # Mobile user login
├── /api/auth/register       # Mobile user registration
├── /api/pharmacies          # Get pharmacies
├── /api/orders              # Order management
└── /api/chat                # Chat system

Web Backend (Port 4000):
├── /api/auth/login          # Web user login
├── /api/orders              # Order management
├── /api/chat                # Real-time chat
├── /api/admin               # Admin functions
└── /public                  # Public endpoints
```

---

## 🛠️ **Development Setup**

### **Prerequisites**
- Flutter SDK 3.8.0+
- Node.js 18+
- MongoDB Atlas account
- Android Studio / Xcode (for mobile)

### **Mobile App Setup**
```bash
# Install Flutter dependencies
flutter pub get

# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Build APK
flutter build apk --release
```

### **Web Application Setup**
```bash
# Install dependencies
npm install

# Start both frontend and backend
npm run dev

# Start separately
npm run client    # Frontend (port 5173)
npm run server    # Backend (port 4000)
```

### **Mobile Backend Setup**
```bash
cd backend
npm install
npm start        # Port 5000
```

---

## 🔧 **Configuration**

### **Environment Variables**
```env
# Database
MONGO_URI=mongodb+srv://CureCart:Pramod@1997@curecart.ce760px.mongodb.net/
MONGODB_DB=curecart

# JWT
JWT_SECRET=your_jwt_secret

# Cloudinary (for file uploads)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

### **API Configuration**
- **Mobile API:** `http://172.20.10.3:5000/api`
- **Web API:** `http://172.20.10.3:4000/api`
- **Emulator:** `http://10.0.2.2:5000/api`

---

## 📱 **Mobile App Features**

### **User Roles**
- **Patients:** Order medicines, track orders, chat with pharmacists
- **Pharmacists:** Manage orders, chat with patients, update inventory
- **Delivery Partners:** Accept deliveries, track locations, update status

### **Core Functionality**
- **Medicine Scanning:** OCR-based medicine recognition
- **Prescription Upload:** Digital prescription management
- **Order Management:** Complete order lifecycle
- **Real-time Chat:** In-app messaging system
- **Location Tracking:** GPS-based delivery tracking
- **Push Notifications:** Medicine reminders and order updates

---

## 🌐 **Web Application Features**

### **Admin Panel**
- **User Management:** Manage all user accounts
- **Order Management:** Process and track orders
- **Pharmacy Management:** Manage pharmacy locations
- **Analytics Dashboard:** Business insights and reports
- **Support System:** Handle user feedback and issues

### **Pharmacy Dashboard**
- **Order Processing:** Manage incoming orders
- **Inventory Management:** Track medicine stock
- **Customer Chat:** Real-time customer support
- **Reports:** Sales and performance analytics

---

## 🔐 **Security Features**

- **JWT Authentication:** Secure token-based auth
- **Password Hashing:** bcryptjs for password security
- **CORS Protection:** Cross-origin request security
- **Role-based Access:** Different permissions per user role
- **Input Validation:** Server-side data validation
- **File Upload Security:** Secure file handling

---

## 📊 **Database Schema**

### **User Schema**
```javascript
{
  name: String,
  email: String (unique),
  password: String (hashed),
  role: ['patient', 'pharmacist', 'delivery', 'admin'],
  phone: String,
  address: String,
  avatar: Buffer,
  status: ['active', 'suspended']
}
```

### **Order Schema**
```javascript
{
  customerId: ObjectId,
  pharmacyId: ObjectId,
  items: [{
    medicineId: ObjectId,
    quantity: Number,
    price: Number
  }],
  total: Number,
  status: String,
  paymentMethod: String,
  deliveryAddress: String
}
```

---

## 🚀 **Deployment**

### **Mobile App**
- **Android:** Generate signed APK for Play Store
- **iOS:** Build for App Store distribution
- **Testing:** Use Firebase App Distribution for beta testing

### **Web Application**
- **Frontend:** Deploy to Vercel/Netlify
- **Backend:** Deploy to Heroku/Railway
- **Database:** MongoDB Atlas (cloud)

---

## 📈 **Performance Optimizations**

- **Image Optimization:** Cloudinary for image processing
- **Caching:** Local storage for offline support
- **Lazy Loading:** On-demand component loading
- **Database Indexing:** Optimized MongoDB queries
- **Real-time Updates:** Socket.io for live features

---

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 📄 **License**

This project is licensed under the MIT License.

---

## 📞 **Support**

For support and questions:
- **Email:** support@curecart.com
- **Documentation:** [Link to docs]
- **Issues:** GitHub Issues

---

**CureCart** - Revolutionizing pharmacy management with modern technology! 🏥💊📱
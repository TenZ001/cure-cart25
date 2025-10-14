# 🚀 CureCart Demo Setup Instructions

## 📋 Prerequisites Checklist

### **System Requirements**
- [ ] **Flutter SDK 3.8.0+** installed and configured
- [ ] **Node.js 18+** installed
- [ ] **Android Studio** or **Xcode** for mobile development
- [ ] **MongoDB Atlas** account (free tier available)
- [ ] **Git** installed
- [ ] **Stable internet connection**

### **Development Tools**
- [ ] **VS Code** or **Android Studio** for development
- [ ] **Postman** for API testing (optional)
- [ ] **MongoDB Compass** for database management (optional)

---

## 🛠️ **Step-by-Step Setup Guide**

### **Step 1: Clone Repository**
```bash
# Clone the repository
git clone <your-repo-url>
cd cure-cart-mobile

# Verify project structure
ls -la
```

### **Step 2: Database Setup**

#### **2.1 MongoDB Atlas Configuration**
1. **Create MongoDB Atlas Account**
   - Go to https://www.mongodb.com/cloud/atlas
   - Sign up for free account
   - Create new cluster (free tier: M0)

2. **Configure Database Access**
   ```bash
   # Database connection string format:
   mongodb+srv://<username>:<password>@<cluster-url>/<database-name>
   
   # Example:
   mongodb+srv://CureCart:Pramod@1997@curecart.ce760px.mongodb.net/
   ```

3. **Create Database Collections**
   ```javascript
   // Required collections:
   - users
   - pharmacies  
   - orders
   - medicines
   - prescriptions
   - chatmessages
   - notifications
   ```

#### **2.2 Update Database Configuration**
```bash
# Update backend/config/database.js
const MONGODB_URI = "mongodb+srv://CureCart:Pramod@1997@curecart.ce760px.mongodb.net/";

# Update cure-cart-web/server/config/database.js  
const MONGODB_URI = "mongodb+srv://CureCart:Pramod@1997@curecart.ce760px.mongodb.net/";
```

### **Step 3: Mobile Backend Setup**

#### **3.1 Install Dependencies**
```bash
cd backend
npm install
```

#### **3.2 Configure Environment Variables**
```bash
# Create .env file in backend directory
touch .env

# Add the following content:
JWT_SECRET=your_jwt_secret_key_here
MONGODB_URI=mongodb+srv://CureCart:Pramod@1997@curecart.ce760px.mongodb.net/
PORT=5000
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret
```

#### **3.3 Start Mobile Backend**
```bash
cd backend
npm start

# Expected output:
# Server running on port 5000
# MongoDB connected successfully
# Socket.io server started
```

### **Step 4: Web Application Setup**

#### **4.1 Install Dependencies**
```bash
cd cure-cart-web
npm install
```

#### **4.2 Configure Environment Variables**
```bash
# Create .env file in cure-cart-web directory
touch .env

# Add the following content:
JWT_SECRET=your_jwt_secret_key_here
MONGODB_URI=mongodb+srv://CureCart:Pramod@1997@curecart.ce760px.mongodb.net/
PORT=4000
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret
```

#### **4.3 Start Web Backend**
```bash
cd cure-cart-web
npm run server

# Expected output:
# Server running on port 4000
# MongoDB connected successfully
# Socket.io server started
```

#### **4.4 Start Web Frontend**
```bash
# In a new terminal
cd cure-cart-web
npm run client

# Expected output:
# Local: http://localhost:5173
# Network: http://192.168.x.x:5173
```

### **Step 5: Mobile App Setup**

#### **5.1 Install Flutter Dependencies**
```bash
cd cure-cart-mobile
flutter pub get
```

#### **5.2 Configure API Endpoints**
```bash
# Update lib/api_config.dart with your local IP
# Find your local IP address:
# Windows: ipconfig
# Mac/Linux: ifconfig

# Update the following lines in api_config.dart:
static const String localNetworkBaseUrl = "http://YOUR_LOCAL_IP:5000/api";
static const String localNetworkWebBaseUrl = "http://YOUR_LOCAL_IP:4000/api";
```

#### **5.3 Run Mobile App**
```bash
# For Android
flutter run

# For iOS (Mac only)
flutter run -d ios

# For specific device
flutter devices
flutter run -d <device-id>
```

---

## 🔧 **Configuration Details**

### **API Configuration**
```dart
// lib/api_config.dart
class ApiConfig {
  // Your local machine IP (replace with actual IP)
  static const String localNetworkBaseUrl = "http://192.168.1.100:5000/api";
  static const String localNetworkWebBaseUrl = "http://192.168.1.100:4000/api";
  
  // Emulator configuration
  static const String emulatorBaseUrl = "http://10.0.2.2:5000/api";
  static const String emulatorWebBaseUrl = "http://10.0.2.2:4000/api";
}
```

### **Database Configuration**
```javascript
// backend/config/database.js
const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error('Database connection error:', error);
    process.exit(1);
  }
};
```

### **Environment Variables**
```bash
# Backend (.env)
JWT_SECRET=your_super_secret_jwt_key_here
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/
PORT=5000
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret

# Web Application (.env)
JWT_SECRET=your_super_secret_jwt_key_here
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/
PORT=4000
CLOUDINARY_CLOUD_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

---

## 🚀 **Quick Start Commands**

### **Start All Services (Recommended)**
```bash
# Terminal 1: Mobile Backend
cd backend
npm start

# Terminal 2: Web Backend  
cd cure-cart-web
npm run server

# Terminal 3: Web Frontend
cd cure-cart-web
npm run client

# Terminal 4: Mobile App
cd cure-cart-mobile
flutter run
```

### **Start Services Individually**
```bash
# Mobile Backend only
cd backend && npm start

# Web Backend only
cd cure-cart-web && npm run server

# Web Frontend only
cd cure-cart-web && npm run client

# Mobile App only
cd cure-cart-mobile && flutter run
```

---

## 🔍 **Verification Steps**

### **1. Backend Services Verification**
```bash
# Test Mobile Backend
curl http://localhost:5000/api/health
# Expected: {"status": "OK", "message": "Mobile API is running"}

# Test Web Backend
curl http://localhost:4000/api/health
# Expected: {"status": "OK", "message": "Web API is running"}
```

### **2. Database Connection Verification**
```bash
# Check MongoDB connection in backend logs
# Look for: "MongoDB Connected: <host>"
# Look for: "Database connection established"
```

### **3. Mobile App Verification**
```bash
# Check Flutter app logs
# Look for: "API connection successful"
# Look for: "Database connection established"
# Look for: "Socket.io connection established"
```

### **4. Web Application Verification**
```bash
# Open browser to http://localhost:5173
# Check for: Login page loads
# Check for: No console errors
# Check for: Real-time features working
```

---

## 🛠️ **Troubleshooting Common Issues**

### **Issue 1: Flutter App Won't Connect to Backend**
```bash
# Check IP address configuration
# Update api_config.dart with correct local IP
# Verify backend is running on correct port
# Check firewall settings
# Test with curl: curl http://YOUR_IP:5000/api/health
```

### **Issue 2: Database Connection Failed**
```bash
# Check MongoDB Atlas connection string
# Verify network access in MongoDB Atlas
# Check IP whitelist in MongoDB Atlas
# Test connection with MongoDB Compass
```

### **Issue 3: Web Application Won't Load**
```bash
# Check if all services are running
# Verify port availability (5173, 4000, 5000)
# Clear browser cache
# Check console for errors
# Restart all services
```

### **Issue 4: Real-time Features Not Working**
```bash
# Check Socket.io connection
# Verify backend services are running
# Check network connectivity
# Review Socket.io configuration
# Test with browser developer tools
```

### **Issue 5: File Upload Issues**
```bash
# Check Cloudinary configuration
# Verify file permissions
# Check upload limits
# Review file types
# Test with small files first
```

---

## 📱 **Device-Specific Setup**

### **Android Setup**
```bash
# Enable Developer Options
# Enable USB Debugging
# Connect device via USB
# Run: flutter devices
# Run: flutter run
```

### **iOS Setup (Mac Only)**
```bash
# Install Xcode
# Install iOS Simulator
# Run: flutter run -d ios
# Or use physical device with Xcode
```

### **Web Browser Setup**
```bash
# Use Chrome for best compatibility
# Enable JavaScript
# Allow camera/microphone permissions
# Disable ad blockers for localhost
```

---

## 🔐 **Security Configuration**

### **JWT Secret Configuration**
```bash
# Generate strong JWT secret
# Use: openssl rand -base64 32
# Update in all .env files
# Keep secret secure
```

### **Database Security**
```bash
# Use strong MongoDB password
# Enable IP whitelisting
# Use SSL connections
# Regular security updates
```

### **API Security**
```bash
# Enable CORS properly
# Use HTTPS in production
# Implement rate limiting
# Validate all inputs
```

---

## 📊 **Performance Optimization**

### **Database Optimization**
```bash
# Create proper indexes
# Use connection pooling
# Monitor query performance
# Regular database maintenance
```

### **Application Optimization**
```bash
# Enable gzip compression
# Use CDN for static assets
# Implement caching
# Monitor memory usage
```

### **Network Optimization**
```bash
# Use stable internet connection
# Minimize network requests
# Implement offline support
# Use efficient data formats
```

---

## 🎯 **Demo Preparation Checklist**

### **Pre-Demo Setup**
- [ ] All services running successfully
- [ ] Database connection established
- [ ] Mobile app installed and configured
- [ ] Web application accessible
- [ ] Test data populated
- [ ] Demo script prepared
- [ ] Backup plan ready

### **Demo Day Setup**
- [ ] Stable internet connection
- [ ] All devices charged and ready
- [ ] Screen sharing configured
- [ ] Audio/video equipment tested
- [ ] Demo data verified
- [ ] Troubleshooting guide available
- [ ] Backup environment ready

### **Post-Demo Cleanup**
- [ ] Stop all services
- [ ] Clear temporary data
- [ ] Reset demo environment
- [ ] Document any issues
- [ ] Plan improvements

---

## 📞 **Support and Resources**

### **Documentation**
- Flutter Documentation: https://flutter.dev/docs
- React Documentation: https://react.dev/
- MongoDB Atlas: https://docs.atlas.mongodb.com/
- Node.js Documentation: https://nodejs.org/docs/

### **Community Support**
- Flutter Community: https://flutter.dev/community
- React Community: https://react.dev/community
- Stack Overflow: https://stackoverflow.com/
- GitHub Issues: Create issues in your repository

### **Professional Support**
- MongoDB Support: https://support.mongodb.com/
- Cloudinary Support: https://support.cloudinary.com/
- Flutter Support: https://flutter.dev/support

---

**🎯 Your CureCart demo environment is now ready for an impressive presentation!**

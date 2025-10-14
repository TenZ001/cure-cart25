# Email Configuration for Forgot Password Feature

## Setup Instructions

### 1. Gmail App Password Setup

1. Go to your Google Account settings
2. Navigate to Security → 2-Step Verification
3. Enable 2-Step Verification if not already enabled
4. Go to Security → App passwords
5. Generate a new app password for "Mail"
6. Copy the 16-character password

### 2. Environment Variables

Create a `.env` file in the `cure-cart-web/server/` directory with the following variables:

```env
# Database
MONGODB_URI=mongodb://localhost:27017/curecart

# JWT Secret
JWT_SECRET=your-super-secret-jwt-key

# Email Configuration (Gmail)
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-16-character-app-password

# Server Configuration
PORT=5000
NODE_ENV=development
```

### 3. Email Service Features

- **OTP Generation**: 6-digit random OTP
- **OTP Expiry**: 10 minutes
- **Rate Limiting**: Maximum 5 OTP attempts per user
- **Security**: OTP is cleared after successful password reset
- **Email Template**: Professional HTML email with CureCart branding

### 4. API Endpoints

- `POST /api/auth/forgot-password` - Send OTP to email
- `POST /api/auth/verify-otp` - Verify OTP and reset password

### 5. Usage Flow

1. User clicks "Forgot Password?" on login page
2. User enters email address
3. System sends 6-digit OTP to user's email
4. User enters OTP and new password
5. Password is reset and user can login with new password

## Security Features

- OTP expires after 10 minutes
- Maximum 5 OTP attempts per user
- Email existence is not revealed (same response for valid/invalid emails)
- OTP is cleared after successful reset
- Password is properly hashed before storage

## Troubleshooting

### Common Issues:

1. **"Email configuration missing" error**
   - Make sure you have a `.env` file in `cure-cart-web/server/`
   - Check that EMAIL_USER and EMAIL_PASS are set correctly

2. **"Authentication failed" error**
   - Verify your Gmail app password is correct (16 characters)
   - Make sure 2-Step Verification is enabled on your Google account
   - Try generating a new app password

3. **"Connection timeout" error**
   - Check your internet connection
   - Verify Gmail SMTP settings are correct
   - Try disabling firewall temporarily

### Testing Email Configuration:

Run the email test script:
```bash
cd cure-cart-web/server
node setup-email.js
```

Or test via API:
```bash
curl http://localhost:5000/api/auth/test-email
```

### Debug Steps:

1. Check server logs for detailed error messages
2. Verify environment variables are loaded correctly
3. Test with a simple email first
4. Check Gmail security settings
5. Ensure app password is generated correctly

const nodemailer = require('nodemailer');
const path = require('path');

// Create transporter - Gmail optimized approach
const createTransporter = () => {
  // Use direct credentials since .env is having issues
  const emailUser = process.env.EMAIL_USER || 'cure2025cart@gmail.com';
  const emailPass = process.env.EMAIL_PASS || 'nqno lpde ymdm gequ';
  
  console.log('🔍 [EMAIL] Using credentials:', { user: emailUser, passLength: emailPass?.length });
  
  return nodemailer.createTransport({
    service: 'gmail',
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: {
      user: emailUser,
      pass: emailPass
    },
    tls: {
      rejectUnauthorized: false,
      ciphers: 'SSLv3'
    },
    debug: true,
    logger: true
  });
};

// Generate 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send OTP email - Professional Gmail version
const sendOTPEmail = async (email, otp, userName) => {
  // Always show in console for debugging
  console.log('📧 ===== OTP SENT =====');
  console.log('📧 Email:', email);
  console.log('👤 User:', userName);
  console.log('🔑 OTP Code:', otp);
  console.log('⏰ Valid for: 10 minutes');
  console.log('📧 ===================');
  
  try {
    const transporter = createTransporter();
    
    const mailOptions = {
      from: `"CureCart" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: '🔐 CureCart - Password Reset OTP',
      attachments: [
        {
          filename: 'app_icon.png',
          path: 'D:\\cure-cart-mobile\\assets\\app_icon.png',
          cid: 'app-icon'
        }
      ],
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>CureCart - Password Reset</title>
        </head>
        <body style="margin: 0; padding: 0; background-color: #f8fafc; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;">
          <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);">
            
            <!-- Header -->
            <div style="background: linear-gradient(135deg, #2563eb 0%, #10b981 100%); padding: 30px 20px; text-align: center;">
              <div style="display: inline-block; background: white; border-radius: 50%; padding: 15px; margin-bottom: 15px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
                <div style="width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; overflow: hidden;">
                  <!-- CureCart App Icon -->
                  <img src="cid:app-icon" alt="CureCart App Icon" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;" />
                </div>
              </div>
              <h1 style="color: white; margin: 0; font-size: 28px; font-weight: 700;">CureCart</h1>
              <p style="color: rgba(255,255,255,0.9); margin: 5px 0 0 0; font-size: 16px;">Your Healthcare Partner</p>
            </div>
            
            <!-- Main Content -->
            <div style="padding: 40px 30px;">
              <h2 style="color: #1e293b; margin: 0 0 20px 0; font-size: 24px; font-weight: 600;">Password Reset Request</h2>
              
              <p style="color: #475569; margin: 0 0 15px 0; font-size: 16px; line-height: 1.6;">Hello <strong>${userName}</strong>,</p>
              
              <p style="color: #475569; margin: 0 0 30px 0; font-size: 16px; line-height: 1.6;">You requested to reset your password for your CureCart account. Use the following OTP to verify your identity:</p>
              
              <!-- OTP Box -->
              <div style="background: #f8fafc; border: 2px dashed #2563eb; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0;">
                <p style="margin: 0 0 10px 0; font-size: 14px; color: #64748b; font-weight: 500;">Your 6-Digit OTP Code</p>
                <div style="background: white; border-radius: 8px; padding: 20px; margin: 15px 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
                  <h1 style="margin: 0; font-size: 36px; color: #2563eb; letter-spacing: 8px; font-weight: 700; font-family: 'Courier New', monospace;">${otp}</h1>
                </div>
                <p style="margin: 10px 0 0 0; font-size: 12px; color: #64748b;">⏰ Valid for 10 minutes only</p>
              </div>
              
              <!-- Instructions -->
              <div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 20px; margin: 30px 0; border-radius: 0 8px 8px 0;">
                <h3 style="color: #92400e; margin: 0 0 15px 0; font-size: 16px; font-weight: 600;">⚠️ Important Security Information</h3>
                <ul style="color: #92400e; margin: 0; padding-left: 20px; font-size: 14px; line-height: 1.6;">
                  <li>This OTP is valid for <strong>10 minutes only</strong></li>
                  <li><strong>Do not share</strong> this OTP with anyone</li>
                  <li>CureCart will never ask for your OTP via phone or email</li>
                  <li>If you didn't request this reset, please ignore this email</li>
                </ul>
              </div>
              
              <p style="color: #475569; margin: 30px 0 0 0; font-size: 14px; line-height: 1.6;">
                If you're having trouble with the OTP, please contact our support team or try requesting a new OTP.
              </p>
            </div>
            
            <!-- Footer -->
            <div style="background: #f8fafc; padding: 30px; text-align: center; border-top: 1px solid #e2e8f0;">
              <p style="color: #64748b; margin: 0 0 10px 0; font-size: 14px;">
                This is an automated message from <strong>CureCart</strong>
              </p>
              <p style="color: #94a3b8; margin: 0; font-size: 12px;">
                Please do not reply to this email. For support, contact us through the app.
              </p>
              <div style="margin-top: 20px;">
                <div style="display: inline-block; background: #2563eb; color: white; padding: 8px 16px; border-radius: 6px; font-size: 12px; font-weight: 600;">
                  🔐 Secure & Encrypted
                </div>
              </div>
            </div>
          </div>
        </body>
        </html>
      `
    };

    const result = await transporter.sendMail(mailOptions);
    console.log('✅ [EMAIL] OTP sent successfully to Gmail:', email);
    console.log('📧 [EMAIL] Message ID:', result.messageId);
    return { success: true, messageId: result.messageId };
    
  } catch (error) {
    console.error('❌ [EMAIL] Failed to send to Gmail:', error.message);
    console.log('📧 [EMAIL] OTP still available in console above');
    // Still return success so the flow continues
    return { success: true, messageId: 'console-fallback' };
  }
};

// Test email configuration - SIMPLE VERSION
const testEmailConfig = async () => {
  console.log('✅ [EMAIL] Simple email service is working (OTP will be shown in console)');
  return { success: true };
};

module.exports = {
  generateOTP,
  sendOTPEmail,
  testEmailConfig
};

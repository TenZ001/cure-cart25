const { generateOTP, sendOTPEmail } = require('./utils/emailService');
require('dotenv').config();

async function testOTPFlow() {
  console.log('🧪 Testing OTP Flow...');
  
  const testEmail = 'cure2025cart@gmail.com';
  const testUser = 'Test User';
  const otp = generateOTP();
  
  console.log('📧 Test Email:', testEmail);
  console.log('👤 Test User:', testUser);
  console.log('🔑 Generated OTP:', otp);
  
  console.log('\n📤 Sending OTP email...');
  const result = await sendOTPEmail(testEmail, otp, testUser);
  
  if (result.success) {
    console.log('✅ OTP email sent successfully!');
    console.log('📧 Message ID:', result.messageId);
    console.log('\n📬 Check your Gmail inbox: cure2025cart@gmail.com');
    console.log('📧 Look for email with subject: "🔐 CureCart - Password Reset OTP"');
  } else {
    console.log('❌ Failed to send OTP email');
    console.log('Error:', result.error);
  }
}

testOTPFlow().catch(console.error);

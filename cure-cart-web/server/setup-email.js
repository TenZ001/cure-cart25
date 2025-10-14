const { testEmailConfig } = require('./utils/emailService');
require('dotenv').config();

async function testEmailSetup() {
  console.log('🔍 [SETUP] Testing email configuration...');
  console.log('📧 [SETUP] Email User:', process.env.EMAIL_USER ? 'Set' : 'Not set');
  console.log('🔑 [SETUP] Email Pass:', process.env.EMAIL_PASS ? 'Set' : 'Not set');
  
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.log('\n❌ [SETUP] Email configuration missing!');
    console.log('📝 [SETUP] Please create a .env file in the server directory with:');
    console.log('EMAIL_USER=your-email@gmail.com');
    console.log('EMAIL_PASS=your-16-character-app-password');
    console.log('\n📖 [SETUP] See EMAIL_SETUP.md for detailed instructions');
    return;
  }
  
  try {
    const result = await testEmailConfig();
    if (result.success) {
      console.log('✅ [SETUP] Email configuration is working!');
    } else {
      console.log('❌ [SETUP] Email configuration failed:', result.error);
    }
  } catch (error) {
    console.log('❌ [SETUP] Email test failed:', error.message);
  }
}

testEmailSetup();

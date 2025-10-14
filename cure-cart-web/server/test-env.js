require('dotenv').config();

console.log('🔍 Environment Variables Test:');
console.log('EMAIL_USER:', process.env.EMAIL_USER);
console.log('EMAIL_PASS:', process.env.EMAIL_PASS);
console.log('EMAIL_PASS Length:', process.env.EMAIL_PASS?.length);

if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
  console.log('✅ Environment variables loaded successfully');
} else {
  console.log('❌ Environment variables not loaded');
}

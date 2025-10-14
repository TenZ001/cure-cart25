const fs = require('fs');
const path = require('path');

// Read the logo file and convert to base64
const logoPath = path.join(__dirname, '../client/public/curecart_logo.png');
const logoBuffer = fs.readFileSync(logoPath);
const logoBase64 = logoBuffer.toString('base64');

console.log('Logo converted to base64:');
console.log(`data:image/png;base64,${logoBase64.substring(0, 100)}...`);
console.log(`Full length: ${logoBase64.length} characters`);

// Save to a file for easy copying
fs.writeFileSync(path.join(__dirname, 'logo-base64.txt'), logoBase64);
console.log('Base64 saved to logo-base64.txt');

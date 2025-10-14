// Test database information
const mongoose = require('mongoose');

async function testDatabaseInfo() {
  console.log('🧪 Testing database information...');
  
  try {
    // Try to connect to the same database the server is using
    const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/curecart';
    console.log('🔗 Connecting to:', mongoUri);
    
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB');
    
    // Get database info
    const db = mongoose.connection.db;
    const admin = db.admin();
    
    // List databases
    console.log('\n1. Available databases:');
    const databases = await admin.listDatabases();
    databases.databases.forEach(db => {
      console.log(`  - ${db.name} (${(db.sizeOnDisk / 1024 / 1024).toFixed(2)} MB)`);
    });
    
    // List collections in current database
    console.log('\n2. Collections in current database:');
    const collections = await db.listCollections().toArray();
    collections.forEach(col => {
      console.log(`  - ${col.name}`);
    });
    
    // Check if there are any documents in key collections
    console.log('\n3. Document counts:');
    for (const col of collections) {
      try {
        const count = await db.collection(col.name).countDocuments();
        console.log(`  - ${col.name}: ${count} documents`);
      } catch (e) {
        console.log(`  - ${col.name}: Error counting documents`);
      }
    }
    
    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testDatabaseInfo();

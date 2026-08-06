const mongoose = require('mongoose');

async function run() {
  await mongoose.connect('mongodb+srv://chungthanhpham2112_db_user:BNmpKZd5Io1QwVSy@cluster0.asdqtec.mongodb.net/luna');
  const db = mongoose.connection.db;
  const devices = await db.collection('devices').find().toArray();
  console.log('Devices:', JSON.stringify(devices, null, 2));
  process.exit(0);
}

run().catch(console.error);

const multer = require("multer");

// Use memory storage (file kept in RAM before uploading to Cloudinary)
const storage = multer.memoryStorage();
const upload = multer({ storage });

module.exports = upload;

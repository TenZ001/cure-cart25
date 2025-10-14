const mongoose = require("mongoose");

const medicineSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  price: Number,
  image: String,
});

module.exports = mongoose.models["Medicine"] || mongoose.model("Medicine", medicineSchema);

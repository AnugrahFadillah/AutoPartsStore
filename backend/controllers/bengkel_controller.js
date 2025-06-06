const Bengkel = require("../models/bengkel_model");

exports.getAllBengkels = async (req, res) => {
  try {
    const data = await Bengkel.findAll();
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createBengkel = async (req, res) => {
  try {
    const { name, address, latitude, longitude } = req.body;
    const newItem = await Bengkel.create({ name, address, latitude, longitude });
    res.status(201).json(newItem);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

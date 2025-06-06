const Sparepart = require("../models/sparepart_model");

exports.getAllSpareparts = async (req, res) => {
  try {
    const data = await Sparepart.findAll();
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getSparepartById = async (req, res) => {
  try {
    const item = await Sparepart.findByPk(req.params.id);
    if (!item) return res.status(404).json({ message: "Sparepart not found" });
    res.json(item);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.createSparepart = async (req, res) => {
  try {
    const { name, brand, price, stock, description, imageUrl } = req.body;
    const newItem = await Sparepart.create({ name, brand, price, stock, description, imageUrl });
    res.status(201).json(newItem);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.updateSparepart = async (req, res) => {
  try {
    const id = req.params.id;
    const [updated] = await Sparepart.update(req.body, { where: { id } });
    if (!updated) return res.status(404).json({ message: "Sparepart not found" });
    res.json({ message: "Updated successfully" });
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
};

exports.deleteSparepart = async (req, res) => {
  try {
    const deleted = await Sparepart.destroy({ where: { id: req.params.id } });
    if (!deleted) return res.status(404).json({ message: "Sparepart not found" });
    res.json({ message: "Deleted successfully" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

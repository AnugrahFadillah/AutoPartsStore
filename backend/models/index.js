const sequelize = require("../config/database");
const Sparepart = require("./sparepart_model");
const Bengkel = require("./bengkel_model");

const db = {
  sequelize,
  Sparepart,
  Bengkel,
};

module.exports = db;
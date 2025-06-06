const { DataTypes } = require("sequelize");
const sequelize = require("../config/database");

const Bengkel = sequelize.define("Bengkel", {
  name: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  address: {
    type: DataTypes.TEXT,
  },
  latitude: {
    type: DataTypes.DOUBLE,
    allowNull: false,
  },
  longitude: {
    type: DataTypes.DOUBLE,
    allowNull: false,
  },
});

module.exports = Bengkel;

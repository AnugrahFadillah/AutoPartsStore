const express = require("express");
const router = express.Router();
const controller = require("../controllers/bengkel_controller");

router.get("/", controller.getAllBengkels);
router.post("/", controller.createBengkel);

module.exports = router;

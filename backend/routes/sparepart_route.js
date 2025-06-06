const express = require("express");
const router = express.Router();
const controller = require("../controllers/sparepart_controller");

router.get("/", controller.getAllSpareparts);
router.get("/:id", controller.getSparepartById);
router.post("/", controller.createSparepart);
router.put("/:id", controller.updateSparepart);
router.delete("/:id", controller.deleteSparepart);

module.exports = router;

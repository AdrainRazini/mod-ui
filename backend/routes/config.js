// backend/routes/config.js

import { Router } from "express";

const router = Router();

// GET /config/latest
router.get("/latest", (req, res) => {
  res.status(200).json({
    message: "config endpoint placeholder"
  });
});

export default router;

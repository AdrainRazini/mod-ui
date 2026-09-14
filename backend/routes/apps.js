// backend/routes/apps.js

import { Router } from "express";

const router = Router();

// GET /apps
router.get("/", (req, res) => {
  res.status(200).json({
    apps: [
      {
        id: "theme_manager",
        name: "Theme Manager",
        version: "1.0.0",
        enabled: true
      },
      {
        id: "feature_flags",
        name: "Feature Flags",
        version: "1.0.0",
        enabled: true
      }
    ]
  });
});

// GET /apps/:id
router.get("/:id", (req, res) => {
  const { id } = req.params;

  res.status(200).json({
    id,
    status: "ok",
    message: "app endpoint placeholder"
  });
});

export default router;

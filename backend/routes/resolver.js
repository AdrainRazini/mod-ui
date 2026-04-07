// backend/routes/resolver.js
import { Router } from "express";

const router = Router();

router.get("/", (req, res) => {
  const protocol =
    req.headers["x-forwarded-proto"] || req.protocol;

  const host =
    req.headers["x-forwarded-host"] || req.get("host");

  const baseUrl = `${protocol}://${host}`;


  res.json({
    name: "Mod_UI Backend",
    version: process.env.VERSION || "1.0.0",
    environment: process.env.NODE_ENV || "development",
    timestamp: Date.now(),

    base: {
      root: baseUrl,
      api: `${baseUrl}/api`
    },

    endpoints: {
      health: `${baseUrl}/health`,
      apps: `${baseUrl}/apps`,
      config: `${baseUrl}/config`,
      resolver: `${baseUrl}/resolver`
    },

    scripts: {
      MeloBlox: `${baseUrl}/api/Mods/Folder_The_MeloBlox/The_MeloBlox`,
      Apocalypse: `${baseUrl}/api/Mods/Folder_The_Apocalypse/The_Apocalypse`
    },

    cache: {
      enabled: true,
      cdn: true,
      http: { strategy: "http-cache", maxAge: "60s", staleWhileRevalidate: "600s" },
      memory: { strategy: "memory", defaultTTL: "30s" }
    }

  });
});

export default router;

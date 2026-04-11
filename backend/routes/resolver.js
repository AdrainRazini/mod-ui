
// backend/routes/resolver.js
import { Router } from "express";
import fs from "fs";
import path from "path";

const router = Router();

function escapeLuaString(str) {
  return str
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r")
}

function toLuaTable(obj) {
  if (typeof obj === "string") {
    return `"${escapeLuaString(obj)}"`
  }

  if (typeof obj === "number" || typeof obj === "boolean") {
    return String(obj)
  }

  if (Array.isArray(obj)) {
    return `{ ${obj.map(toLuaTable).join(", ")} }`
  }

  if (typeof obj === "object" && obj !== null) {
    return `{ ${Object.entries(obj)
      .map(([k, v]) => `${k} = ${toLuaTable(v)}`)
      .join(", ")} }`
  }

  return "nil"
}

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
/*
    scripts: {
      MeloBlox: `${baseUrl}/api/Mods/Folder_The_MeloBlox/The_MeloBlox`,
      Apocalypse: `${baseUrl}/api/Mods/Folder_The_Apocalypse/The_Apocalypse`
    },
 */
    cache: {
      enabled: true,
      cdn: true,
      http: { strategy: "http-cache", maxAge: "60s", staleWhileRevalidate: "600s" },
      memory: { strategy: "memory", defaultTTL: "30s" }
    }

  });
});


router.post("/exec", async (req, res) => {
  try {
    const ctx = req.body || {}

    const { mod, features = [] } = ctx

    if (!mod) {
      return res.status(400).send("-- no mod provided")
    }

    // mapa seguro (NÃO expõe estrutura real)
    const MOD_MAP = {
      MeloBlox: "Mods/Folder_The_MeloBlox/The_MeloBlox",
      Apocalypse: "Mods/Folder_The_Apocalypse/The_Apocalypse",
      Wanderlands: "Mods/Folder_The_Wanderlands_Dungeon_RPG/Wanderlands"
    }

    const scriptPath = MOD_MAP[mod]

    if (!scriptPath) {
      return res.status(404).send("-- mod not found")
    }

    // pega script internamente (sem expor rota pública)
    const filePath = path.resolve("scripts", `${scriptPath}.lua`)

    if (!fs.existsSync(filePath)) {
      return res.status(404).send("-- script missing")
    }

    let script = fs.readFileSync(filePath, "utf-8")

    // aqui você pode injetar ctx no script
    const injected =`getgenv().__CTX__ = ${toLuaTable(ctx)}${script}`

    res.setHeader("Content-Type", "text/plain")
    res.send(injected)

  } catch (err) {
    console.error(err)
    res.status(500).send("-- internal error")
  }
})

export default router;

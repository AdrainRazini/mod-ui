// backend/routes/api.js

import { Router } from "express";
import fs from "fs";
import path from "path";

const router = Router();
//v2
router.get(/^\/(.+)/, (req, res) => {
  const scriptPath = req.params[0];

  const filePath = path.resolve("scripts", `${scriptPath}.lua`);

  if (!fs.existsSync(filePath)) {
    return res
      .status(404)
      .type("text/plain")
      .send("-- script not found");
  }

  const content = fs.readFileSync(filePath, "utf-8");

  // CACHE AQUI
  res.setHeader(
    "Cache-Control",
    "public, max-age=60, s-maxage=300, stale-while-revalidate=600"
  );

  res.type("text/plain");
  res.send(content);
});

// GET /api/*
/*
//v1
router.get(/^\/(.+)/, (req, res) => {
  const scriptPath = req.params[0]; // tudo depois da /
  
  const filePath = path.join(
    process.cwd(),
    "scripts",
    `${scriptPath}.lua`
  );

  if (!fs.existsSync(filePath)) {
    return res
      .status(404)
      .type("text/plain")
      .send("-- script not found");
  }

  res.type("text/plain");
  res.send(fs.readFileSync(filePath, "utf-8"));
});
 */

export default router;

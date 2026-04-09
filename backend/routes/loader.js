import { Router } from "express";
import fs from "fs";
import path from "path";

const router = Router();

router.get("/", (req, res) => {
  try {
    const filePath = path.resolve("scripts/Loader.lua");

    if (!fs.existsSync(filePath)) {
      return res.status(404).type("text/plain").send("-- loader not found");
    }

    const content = fs.readFileSync(filePath, "utf-8");

    res.setHeader(
      "Cache-Control",
      "public, max-age=60, s-maxage=300, stale-while-revalidate=600"
    );

    res.type("text/plain");
    res.send(content);
  } catch (err) {
    console.error(err);
    res.status(500).type("text/plain").send("-- loader error");
  }
});

export default router;
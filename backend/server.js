/* Server.js */
// backend/server.js

import express from "express";
import dotenv from "dotenv";


// Rotas Caseiras 
import configRoutes from "./routes/config.js";
import appsRoutes from "./routes/apps.js";
import apiRoutes from "./routes/api.js";
import resolverRoutes from "./routes/resolver.js";

// Services
import {
  getCollection,
  addDocument,
  updateDocument,
  findDocumentByField
} from "./services/firestoreService.js";

import { db } from "./services/firebase.js";

//import { dbAdmin } from "./services/firebaseAdmin.js";


// ============================
// ENV
// ============================

// Carrega variáveis do .env
dotenv.config();

// ============================
// APP
// ============================

const app = express();

//index.html principal
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.use(
  "/",
  express.static(path.join(__dirname, "../public"), {
    index: "index.html",
    setHeaders: (res, filePath) => {
      if (filePath.endsWith(".html")) {
        res.setHeader("Cache-Control", "no-cache");
      } else {
        res.setHeader(
          "Cache-Control",
          "public, max-age=86400, s-maxage=604800, immutable"
        );
      }
    }
  })
);


// ============================
// MIDDLEWARES GLOBAIS
// ============================

// Permite JSON no body
app.use(express.json());

// Log simples (depois pode virar Logger real)
app.use((req, res, next) => {
  console.log(`[${req.method}] ${req.url}`);
  next();
});
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Internal Server Error" });
});

// ============================
// ROTAS
// ============================

// Health check (Importante)
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "ok",
    service: "mod_ui_backend",
    version: "1.0.0",
    timestamp: Date.now()
  });
});

// (FUTURO)

app.use("/config", configRoutes);
app.use("/apps", appsRoutes);
app.use("/api", apiRoutes);
app.use("/resolver", resolverRoutes);
// app.use("/features", featureRoutes);

// ============================
// SERVER
// ============================

const PORT = process.env.PORT || 3000;

const isServerless = process.env.VERCEL || process.env.AWS_REGION;

if (!isServerless) {
  app.listen(PORT, () => {
    console.log(`[Mod_UI] Backend rodando na porta ${PORT}`);
  });
} else {
  console.log("Backend pronto para Serverless");
}

export default app;

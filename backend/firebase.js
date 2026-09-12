import admin from "firebase-admin";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// resolver dirname (ESM)
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// caminho do JSON
const serviceAccountPath = path.join(__dirname, "./serviceAccountKey.json");

// ler arquivo manualmente
const serviceAccount = JSON.parse(
  fs.readFileSync(serviceAccountPath, "utf-8")
);

// inicializar apenas 1x
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

// Firestore
const db = admin.firestore();

export { admin, db };
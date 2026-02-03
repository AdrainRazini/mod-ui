import admin from "firebase-admin";
import { fileURLToPath } from "url"; // 🔹 Import obrigatório
import path from "path";
import fs from "fs";

// Corrige caminho do __dirname em ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Lê a chave do JSON
const serviceAccountPath = path.join(__dirname, "../serviceAccountKey.json");
const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, "utf-8"));

// Inicializa Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

// Exporta Firestore Admin
export const dbAdmin = admin.firestore();

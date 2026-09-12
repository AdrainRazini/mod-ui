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
//if (!admin.apps.length) {admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });}

if (!admin.apps.length) {
    const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n");

    if (!process.env.FIREBASE_PROJECT_ID) {
        throw new Error("FIREBASE_PROJECT_ID não configurado");
    }

    if (!process.env.FIREBASE_CLIENT_EMAIL) {
        throw new Error("FIREBASE_CLIENT_EMAIL não configurado");
    }

    if (!privateKey) {
        throw new Error("FIREBASE_PRIVATE_KEY não configurado");
    }

    admin.initializeApp({
        credential: admin.credential.cert({
            projectId: process.env.FIREBASE_PROJECT_ID,
            clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            privateKey
        })
    });
}


// Firestore
const db = admin.firestore();

export { admin, db };
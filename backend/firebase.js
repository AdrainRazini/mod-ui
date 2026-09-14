
import admin from "firebase-admin";

if (!admin.apps.length) {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY
        ?.replace(/\\n/g, "\n");

    if (!projectId) {
        throw new Error("FIREBASE_PROJECT_ID não configurado");
    }

    if (!clientEmail) {
        throw new Error("FIREBASE_CLIENT_EMAIL não configurado");
    }

    if (!privateKey) {
        throw new Error("FIREBASE_PRIVATE_KEY não configurado");
    }

    admin.initializeApp({
        credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey
        }),

        storageBucket: process.env.FIREBASE_STORAGE_BUCKET
    });
}

const db = admin.firestore();

export {
    admin,
    db
};

/** 
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

*/
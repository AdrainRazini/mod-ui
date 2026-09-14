
import admin from "firebase-admin";

if (!admin.apps.length) {
    const serviceAccount = {
        project_id: process.env.FIREBASE_PROJECT_ID,
        private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
        private_key: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
        client_email: process.env.FIREBASE_CLIENT_EMAIL,
        client_id: process.env.FIREBASE_CLIENT_ID,
        token_uri: "https://oauth2.googleapis.com/token"
    };

    // Verificação para evitar inicialização com credenciais vazias
    if (
        !serviceAccount.project_id ||
        !serviceAccount.private_key ||
        !serviceAccount.client_email
    ) {
        throw new Error(
            "Credenciais do Firebase Admin não configuradas. " +
            "Verifique FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY e FIREBASE_CLIENT_EMAIL na Vercel."
        );
    }

    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();

export { admin, db };


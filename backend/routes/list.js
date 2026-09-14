import { Router } from "express";

const router = Router();

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID;

router.get("/", async (req, res) => {
    try {
        const url =
            `https://firestore.googleapis.com/v1/` +
            `projects/${PROJECT_ID}/databases/(default)/documents/arrays`;

        const response = await fetch(url);

        if (!response.ok) {
            const error = await response.text();

            console.error("Firestore:", error);

            return res.status(response.status).json({
                success: false,
                message: "Erro ao acessar Firestore"
            });
        }

        const result = await response.json();

        const arrays = (result.documents || []).map(doc => {
            const id = doc.name.split("/").pop();

            return {
                id,
                fields: doc.fields || {}
            };
        });

        return res.json({
            success: true,
            total: arrays.length,
            data: arrays
        });

    } catch (error) {
        console.error("Erro ao buscar arrays:", error);

        return res.status(500).json({
            success: false,
            message: "Erro interno do servidor"
        });
    }
});

export default router;
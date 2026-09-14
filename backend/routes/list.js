import { Router } from "express";

const router = Router();

router.get("/", async (req, res) => {
    try {
        const projectId = process.env.FIREBASE_PROJECT_ID;

        if (!projectId) {
            return res.status(500).json({
                success: false,
                message: "FIREBASE_PROJECT_ID não configurado"
            });
        }

        const url =
            `https://firestore.googleapis.com/v1/projects/${projectId}` +
            `/databases/(default)/documents/arrays/ugcs`;

        const response = await fetch(url);

        const data = await response.json();

        if (!response.ok) {
            console.error("Firestore REST Error:", data);

            return res.status(response.status).json({
                success: false,
                message: "Erro ao buscar arrays/ugcs",
                error: data
            });
        }

        return res.json({
            success: true,
            id: "ugcs",
            data
        });

    } catch (error) {
        console.error("Erro ao buscar arrays/ugcs:", error);

        return res.status(500).json({
            success: false,
            message: "Erro interno do servidor",
            error: error.message
        });
    }
});

export default router;
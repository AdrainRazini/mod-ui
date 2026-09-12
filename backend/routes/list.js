
import { Router } from "express";
import { db } from "../firebase.js";

const router = Router();

router.get("/", async (req, res) => {
    try {
        const snapshot = await db
            .collection("Publics")
            .get();

        const publics = snapshot.docs.map((document) => ({
            id: document.id,
            ...document.data()
        }));

        return res.json({
            success: true,
            total: publics.length,
            data: publics
        });

    } catch (error) {
        console.error("Erro ao buscar Publics:", error);

        return res.status(500).json({
            success: false,
            message: "Erro interno do servidor"
        });
    }
});

export default router;

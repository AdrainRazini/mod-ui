import { Router } from "express";
import { db } from "../firebase.js";

const router = Router();

router.get("/:name", async (req, res) => {
    try {
        const { name } = req.params;

        if (!name) {
            return res.status(400).json({
                success: false,
                error: "Nome do documento não informado"
            });
        }

        const snapshot = await db
            .collection("arrays")
            .doc(name)
            .get();

        if (!snapshot.exists) {
            return res.status(404).json({
                success: false,
                error: "Documento não encontrado",
                document: name
            });
        }

        const document = snapshot.data();

        return res.json({
            success: true,
            name: document.name || name,
            version: document.version ?? 1,
            data: document.data || {}
        });

    } catch (error) {
        console.error("[LIST API]", error);

        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

export default router;
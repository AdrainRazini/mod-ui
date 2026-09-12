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

        console.log(`[LIST] Buscando arrays/${name}`);

        const snapshot = await db
            .collection("arrays")
            .doc(name)
            .get();

        if (!snapshot.exists) {
            console.log(`[LIST] Documento não encontrado: arrays/${name}`);

            return res.status(404).json({
                success: false,
                error: "Documento não encontrado",
                document: name
            });
        }

        const document = snapshot.data();

        console.log(`[LIST] Documento encontrado: arrays/${name}`);

        return res.status(200).json({
            success: true,
            name: document.name || name,
            version: document.version ?? 1,
            data: document.data || {}
        });

    } catch (error) {

        console.error("=================================");
        console.error("[LIST API ERROR]");
        console.error("Message:", error?.message);
        console.error("Stack:", error?.stack);
        console.error("=================================");

        return res.status(500).json({
            success: false,
            error: error?.message || "Erro interno ao buscar documento"
        });
    }
});

export default router;
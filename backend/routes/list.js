// backend/routes/ugcs.js

import { Router } from "express";
import { db } from "../firebase.js";

const router = Router();

router.get("/", async (req, res) => {
    try {
        const snapshot = await db
            .collection("arrays")
            .doc("ugcs")
            .get();

        if (!snapshot.exists) {
            return res.status(404).json({
                success: false,
                message: "Array de UGCs não encontrado"
            });
        }

        return res.json({
            success: true,
            id: snapshot.id,
            data: snapshot.data()
        });

    } catch (error) {
        console.error("Erro ao buscar arrays/ugcs:", error);

        return res.status(500).json({
            success: false,
            message: "Erro interno do servidor"
        });
    }
});

export default router;

import { Router } from "express";

import {
    doc,
    getDoc
} from "firebase/firestore";

import { db } from "../services/firebase.js";

const router = Router();

router.get("/", async (req, res) => {
    try {
        // Acessa diretamente:
        // arrays/ugcs

        const ref = doc(db, "arrays", "ugcs");

        const snapshot = await getDoc(ref);

        if (!snapshot.exists()) {
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


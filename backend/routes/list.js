import { Router } from "express";
import { db } from "../firebase.js";

import {
    collection,
    getDocs,
    doc,
    getDoc
} from "firebase/firestore";

const router = Router();

router.get("/:name", async (req, res) => {
    try {
        const { name } = req.params;

        const publicRef = doc(db, "Publics", name);
        const publicSnap = await getDoc(publicRef);

        if (!publicSnap.exists()) {
            return res.status(404).json({
                success: false,
                message: "Public não encontrado"
            });
        }

        return res.json({
            success: true,
            id: publicSnap.id,
            data: publicSnap.data()
        });

    } catch (error) {
        console.error("Erro ao buscar Public:", error);

        return res.status(500).json({
            success: false,
            message: "Erro interno do servidor"
        });
    }
});

export default router;
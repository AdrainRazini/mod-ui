import { Router } from "express";
import { db } from "../firebase.js";

import {
    collection,
    getDocs
} from "firebase/firestore";

const router = Router();

router.get("/", async (req, res) => {
    try {

        const snapshot = await getDocs(
            collection(db, "Publics")
        );

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
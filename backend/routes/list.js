// backend/routes/list.js

import { Router } from "express";
import { db } from "../firebase.js";

const router = Router();

/*
    GET /api/list/:name

    Exemplo:
    GET /api/list/ugcs

    Firestore:
    arrays/
      └── ugcs
           ├── name
           ├── ownerId
           ├── updatedAt
           ├── version
           └── data
                ├── Animated 8-bit Pop Cat
                ├── Black Hat
                ├── Blue Dragon
                └── ...
*/

router.get("/:name", async (req, res) => {
    try {
        const { name } = req.params;

        if (!name) {
            return res.status(400).json({
                success: false,
                error: "Nome do documento não informado"
            });
        }

        const docRef = db.collection("arrays").doc(name);
        const snapshot = await docRef.get();

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
            data: document.data || {},
            meta: {
                name: document.name || name,
                version: document.version ?? null,
                ownerId: document.ownerId ?? null,
                updatedAt: document.updatedAt ?? null
            }
        });

    } catch (error) {
        console.error("[LIST API]", error);

        return res.status(500).json({
            success: false,
            error: "Erro interno ao buscar documento"
        });
    }
});

export default router;
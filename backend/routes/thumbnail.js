// backend/routes/thumbnail.js

import { Router } from "express";

const router = Router();

const API = "";

router.get("/thumbnail/:assetId", async (req, res) => {

    const { assetId } = req.params;

    if (!assetId) {
        return res.status(400).json({
            success: false,
            message: "AssetId não informado"
        });
    }

    try {

        const response = await fetch(
            `https://thumbnails.roblox.com/v1/assets` +
            `?assetIds=${encodeURIComponent(assetId)}` +
            `&size=420x420` +
            `&format=Png` +
            `&isCircular=false`
        );

        if (!response.ok) {

            return res.status(response.status).json({
                success: false,
                message:
                    `Roblox retornou HTTP ${response.status}`
            });

        }

        const result = await response.json();

        const thumbnail =
            result.data?.[0] || null;

        if (!thumbnail) {

            return res.status(404).json({
                success: false,
                message: "Thumbnail não encontrada"
            });

        }

        return res.json({

            success: true,

            assetId: Number(assetId),

            targetId:
                thumbnail.targetId ?? null,

            state:
                thumbnail.state ?? null,

            imageUrl:
                thumbnail.imageUrl ?? null

        });

    } catch (error) {

        console.error(
            "Erro ao buscar thumbnail Roblox:",
            error
        );

        return res.status(500).json({

            success: false,

            message:
                "Erro ao consultar thumbnail da Roblox"

        });

    }

});

export default router;
// backend/routes/market.js

import { Router } from "express";

const router = Router();

const API = "https://economy.roblox.com/v2/assets/:id/details";

// Cache em memória
const cache = new Map();
const CACHE_TIME = 1000 * 60 * 10; // 10 minutos

router.get("/:assetId", async (req, res) => {

    const { assetId } = req.params;

    // Verifica cache
    const cached = cache.get(assetId);

    if (cached && cached.expires > Date.now()) {
        return res.json({
            ...cached.data,
            cached: true
        });
    }

    try {

        const url = API.replace(":id", assetId);

        const response = await fetch(url, {
            headers: {
                "User-Agent": "ADN-Core"
            }
        });

        if (!response.ok) {

            return res.status(response.status).json({
                success: false,
                status: response.status,
                message: "Roblox API Error"
            });

        }

        const data = await response.json();

        const result = {
            success: true,
            data
        };

        // Salva no cache
        cache.set(assetId, {
            expires: Date.now() + CACHE_TIME,
            data: result
        });

        res.json(result);

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            error: err.message
        });

    }

});

export default router;
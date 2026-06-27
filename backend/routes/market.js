// backend/routes/market.js

import { Router } from "express";

const router = Router();

const API =
    "https://economy.roblox.com/v2/assets/:id/details";

// GET /market/:assetId
router.get("/:assetId", async (req, res) => {

    const { assetId } = req.params;

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

        res.json({
            success: true,
            data
        });

    } catch (err) {

        console.error(err);

        res.status(500).json({
            success: false,
            error: err.message
        });

    }

});

export default router;
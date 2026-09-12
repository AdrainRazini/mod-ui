// backend/routes/ugcs.js

import { Router } from "express";

const router = Router();


/*
============================================================
ROBLOX API
============================================================
*/

const API =
    "https://economy.roblox.com/v2/assets/:id/details";


/*
============================================================
CACHE
============================================================
*/

const cache =
    new Map();


const CACHE_TIME =
    1000 * 60 * 10; // 10 minutos


/*
============================================================
TIMEOUT ROBLOX
============================================================
*/

const ROBLOX_TIMEOUT =
    5000;


/*
============================================================
GET UGC
============================================================
*/

router.get(
    "/:assetId",
    async (req, res) => {

        const {
            assetId
        } = req.params;


        /*
        ====================================================
        VALIDAR ID
        ====================================================
        */

        if (
            !/^\d+$/.test(assetId)
        ) {

            return res.status(400).json({

                success: false,

                message:
                    "AssetId inválido."
            });
        }


        /*
        ====================================================
        CACHE
        ====================================================
        */

        const cached =
            cache.get(assetId);


        if (
            cached &&
            cached.expires > Date.now()
        ) {

            return res.json({

                ...cached.data,

                cached: true
            });
        }


        /*
        ====================================================
        BUSCAR ROBLOX
        ====================================================
        */

        try {

            const url =
                API.replace(
                    ":id",
                    assetId
                );


            const controller =
                new AbortController();


            const timeout =
                setTimeout(
                    () => {

                        controller.abort();

                    },
                    ROBLOX_TIMEOUT
                );


            let response;


            try {

                response =
                    await fetch(
                        url,
                        {
                            method: "GET",

                            signal:
                                controller.signal,

                            headers: {

                                "User-Agent":
                                    "ADN-Core",

                                "Accept":
                                    "application/json"
                            }
                        }
                    );

            } finally {

                clearTimeout(
                    timeout
                );
            }


            /*
            ====================================================
            ERRO ROBLOX
            ====================================================
            */

            if (
                !response.ok
            ) {

                return res
                    .status(response.status)
                    .json({

                        success: false,

                        status:
                            response.status,

                        assetId,

                        message:
                            "Roblox API Error"
                    });
            }


            const data =
                await response.json();


            /*
            ====================================================
            RESPOSTA NORMALIZADA
            ====================================================
            */

            const result = {

                success: true,

                cached: false,

                data: {

                    TargetId:
                        data.TargetId,

                    ProductType:
                        data.ProductType,

                    AssetId:
                        data.AssetId,

                    ProductId:
                        data.ProductId,

                    Name:
                        data.Name,

                    Description:
                        data.Description,

                    AssetTypeId:
                        data.AssetTypeId,


                    Creator:
                        data.Creator
                            ? {
                                Id:
                                    data.Creator.Id,

                                Name:
                                    data.Creator.Name,

                                CreatorType:
                                    data.Creator.CreatorType,

                                CreatorTargetId:
                                    data.Creator
                                        .CreatorTargetId,

                                HasVerifiedBadge:
                                    data.Creator
                                        .HasVerifiedBadge
                            }
                            : null,


                    IconImageAssetId:
                        data.IconImageAssetId,


                    Created:
                        data.Created,

                    Updated:
                        data.Updated,


                    PriceInRobux:
                        data.PriceInRobux,

                    PriceInTickets:
                        data.PriceInTickets,


                    Sales:
                        data.Sales,


                    IsNew:
                        data.IsNew,

                    IsForSale:
                        data.IsForSale,

                    IsPublicDomain:
                        data.IsPublicDomain,

                    IsLimited:
                        data.IsLimited,

                    IsLimitedUnique:
                        data.IsLimitedUnique,


                    Remaining:
                        data.Remaining,


                    MinimumMembershipLevel:
                        data.MinimumMembershipLevel,


                    ContentRatingTypeId:
                        data.ContentRatingTypeId,


                    SaleAvailabilityLocations:
                        data.SaleAvailabilityLocations,


                    SaleLocation:
                        data.SaleLocation,


                    CollectibleItemId:
                        data.CollectibleItemId,

                    CollectibleProductId:
                        data.CollectibleProductId,


                    CollectiblesItemDetails:
                        data.CollectiblesItemDetails
                            ? {

                                CollectibleLowestResalePrice:
                                    data
                                        .CollectiblesItemDetails
                                        .CollectibleLowestResalePrice,

                                CollectibleLowestAvailableResaleProductId:
                                    data
                                        .CollectiblesItemDetails
                                        .CollectibleLowestAvailableResaleProductId,

                                CollectibleLowestAvailableResaleItemInstanceId:
                                    data
                                        .CollectiblesItemDetails
                                        .CollectibleLowestAvailableResaleItemInstanceId,

                                CollectibleQuantityLimitPerUser:
                                    data
                                        .CollectiblesItemDetails
                                        .CollectibleQuantityLimitPerUser,

                                IsForSale:
                                    data
                                        .CollectiblesItemDetails
                                        .IsForSale,

                                TotalQuantity:
                                    data
                                        .CollectiblesItemDetails
                                        .TotalQuantity,

                                IsLimited:
                                    data
                                        .CollectiblesItemDetails
                                        .IsLimited

                            }
                            : null,


                    TimedOptions:
                        data.TimedOptions ?? null
                }
            };


            /*
            ====================================================
            SALVAR CACHE
            ====================================================
            */

            cache.set(
                assetId,
                {

                    expires:
                        Date.now() +
                        CACHE_TIME,

                    data:
                        result
                }
            );


            /*
            ====================================================
            RESPONSE
            ====================================================
            */

            return res.json(
                result
            );


        } catch (err) {

            console.error(
                "Roblox API:",
                err
            );


            /*
                Timeout
            */

            if (
                err.name ===
                "AbortError"
            ) {

                return res
                    .status(504)
                    .json({

                        success: false,

                        assetId,

                        message:
                            "Roblox API timeout."
                    });
            }


            /*
                Erro interno
            */

            return res
                .status(500)
                .json({

                    success: false,

                    assetId,

                    error:
                        err.message
                });
        }
    }
);

/*
============================================================
LISTA COMPLETA DE UGCs
GET /ugcs/List
============================================================
*/

router.get("/List", async (req, res) => {

    try {

        const ref = doc(
            db,
            "arrays",
            "ugcs"
        );

        const snapshot = await getDoc(ref);

        if (!snapshot.exists()) {

            return res.status(404).json({
                success: false,
                message: "Documento arrays/ugcs não encontrado.",
                data: {}
            });

        }

        const documento = snapshot.data();

        const List =
            documento.data || {};

        return res.json({

            success: true,

            name:
                documento.name ||
                "UGCS_DATA",

            version:
                documento.version ||
                1,

            updatedAt:
                documento.updatedAt ||
                null,

            count:
                Object.keys(List).length,

            data:
                List

        });

    } catch (err) {

        console.error(
            "UGCs List:",
            err
        );

        return res.status(500).json({

            success: false,

            message:
                "Erro ao carregar lista de UGCs.",

            error:
                err.message

        });

    }

});


export default router;
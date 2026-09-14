import { Router } from "express";

const router = Router();

const API_MARKET =
    "https://mod-ui.vercel.app/market/";

const API_UGCS =
    "https://mod-ui.vercel.app/ugcs/";

const DB_ID = "mod-ui";


/*
============================================================
FIRESTORE → JAVASCRIPT
============================================================
*/

function convertFirestoreValue(value) {

    if (!value) {
        return null;
    }

    if ("stringValue" in value) {
        return value.stringValue;
    }

    if ("integerValue" in value) {
        return Number(value.integerValue);
    }

    if ("doubleValue" in value) {
        return Number(value.doubleValue);
    }

    if ("booleanValue" in value) {
        return value.booleanValue;
    }

    if ("nullValue" in value) {
        return null;
    }

    if ("timestampValue" in value) {
        return value.timestampValue;
    }

    if ("referenceValue" in value) {
        return value.referenceValue;
    }

    if ("arrayValue" in value) {

        return (value.arrayValue.values || [])
            .map(convertFirestoreValue);
    }

    if ("mapValue" in value) {

        return convertFirestoreFields(
            value.mapValue.fields || {}
        );
    }

    return null;
}


function convertFirestoreFields(fields) {

    const result = {};

    for (
        const [key, value]
        of Object.entries(fields || {})
    ) {

        result[key] =
            convertFirestoreValue(value);
    }

    return result;
}


/*
============================================================
ATUALIZAR UGC
============================================================
*/

async function updateUGCData(ugc) {

    if (
        !ugc ||
        !ugc.IdUGC
    ) {

        return ugc;
    }


    const id = ugc.IdUGC;


    try {

        /*
        --------------------------------------------------------
        Primeiro /ugcs/:id
        --------------------------------------------------------
        */

        let response =
            await fetch(
                `${API_UGCS}${id}`
            );


        /*
        --------------------------------------------------------
        Fallback /market/:id
        --------------------------------------------------------
        */

        if (!response.ok) {

            response =
                await fetch(
                    `${API_MARKET}${id}`
                );
        }


        if (!response.ok) {

            console.warn(
                `Não foi possível atualizar UGC ${id}`
            );

            return ugc;
        }


        const result =
            await response.json();


        /*
        --------------------------------------------------------
        Dados normalizados
        --------------------------------------------------------
        */

        const liveData =
            result?.data ||
            result?.Roblox ||
            result;


        /*
        --------------------------------------------------------
        Merge
        --------------------------------------------------------
        */

        return {

            ...ugc,

            Roblox: {

                ...(ugc.Roblox || {}),

                ...(liveData.Roblox || liveData)

            }

        };

    } catch (error) {

        console.warn(
            `Erro ao atualizar UGC ${id}:`,
            error.message
        );


        /*
        * Se a API falhar,
        * mantém o Firestore.
        */

        return ugc;
    }
}


/*
============================================================
STRING → LUA
============================================================
*/

function luaString(value) {

    return JSON.stringify(
        String(value)
    )
        .replace(
            /\\u2028/g,
            "\\u2028"
        )
        .replace(
            /\\u2029/g,
            "\\u2029"
        );
}


/*
============================================================
JAVASCRIPT → LUA
============================================================
*/

function toLua(
    value,
    indent = 0
) {

    const spacing =
        "    ".repeat(indent);

    const nextSpacing =
        "    ".repeat(
            indent + 1
        );


    /*
    --------------------------------------------------------
    NIL
    --------------------------------------------------------
    */

    if (
        value === null ||
        value === undefined
    ) {

        return "nil";
    }


    /*
    --------------------------------------------------------
    STRING
    --------------------------------------------------------
    */

    if (
        typeof value === "string"
    ) {

        return luaString(value);
    }


    /*
    --------------------------------------------------------
    NUMBER
    --------------------------------------------------------
    */

    if (
        typeof value === "number"
    ) {

        return String(value);
    }


    /*
    --------------------------------------------------------
    BOOLEAN
    --------------------------------------------------------
    */

    if (
        typeof value === "boolean"
    ) {

        return value
            ? "true"
            : "false";
    }


    /*
    --------------------------------------------------------
    ARRAY
    --------------------------------------------------------
    */

    if (
        Array.isArray(value)
    ) {

        if (
            value.length === 0
        ) {

            return "{}";
        }


        const items =
            value.map(
                item =>
                    `${nextSpacing}${toLua(
                        item,
                        indent + 1
                    )}`
            );


        return (
            `{\n` +
            items.join(",\n") +
            `\n${spacing}}`
        );
    }


    /*
    --------------------------------------------------------
    OBJECT
    --------------------------------------------------------
    */

    if (
        typeof value === "object"
    ) {

        const entries =
            Object.entries(value);


        if (
            entries.length === 0
        ) {

            return "{}";
        }


        const items =
            entries.map(
                ([key, val]) =>
                    `${nextSpacing}[${luaString(key)}] = ${toLua(
                        val,
                        indent + 1
                    )}`
            );


        return (
            `{\n` +
            items.join(",\n") +
            `\n${spacing}}`
        );
    }


    return "nil";
}


/*
============================================================
ROUTE
============================================================
*/

router.get(
    "/",
    async (req, res) => {

        try {

            /*
            ====================================================
            PARAMETERS
            ====================================================
            */

            const type =
                String(
                    req.query.type || "lua"
                ).toLowerCase();


            const live =
                String(
                    req.query.live
                ).toLowerCase() === "true";


            /*
            ====================================================
            VALIDAR TYPE
            ====================================================
            */

            if (
                type !== "lua" &&
                type !== "http"
            ) {

                return res.status(400).json({

                    success: false,

                    message:
                        "Tipo inválido. Use type=lua ou type=http."

                });
            }


            /*
            ====================================================
            FIRESTORE
            ====================================================
            */

            const url =
                `https://firestore.googleapis.com/v1/projects/${DB_ID}` +
                `/databases/(default)/documents/arrays/ugcs`;


            const response =
                await fetch(url);


            const data =
                await response.json();


            if (!response.ok) {

                console.error(
                    "Firestore REST Error:",
                    data
                );


                return res
                    .status(response.status)
                    .json({

                        success: false,

                        message:
                            "Erro ao buscar arrays/ugcs",

                        error:
                            data

                    });
            }


            /*
            ====================================================
            CONVERTER
            ====================================================
            */

            const firestoreData =
                convertFirestoreFields(
                    data.fields || {}
                );


            let ugcs =
                firestoreData.data || {};


            /*
            ====================================================
            LIVE
            ====================================================
            */

            if (live) {

                const entries =
                    Object.entries(ugcs);


                const updatedEntries =
                    await Promise.all(

                        entries.map(
                            async ([name, ugc]) => {

                                const updated =
                                    await updateUGCData(
                                        ugc
                                    );


                                return [
                                    name,
                                    updated
                                ];
                            }
                        )
                    );


                ugcs =
                    Object.fromEntries(
                        updatedEntries
                    );
            }


            /*
            ====================================================
            HTTP / JSON
            ====================================================
            */

            if (
                type === "http"
            ) {

                return res
                    .type("application/json")
                    .json({

                        success: true,

                        type: "http",

                        live,

                        count:
                            Object.keys(
                                ugcs
                            ).length,

                        data:
                            ugcs

                    });
            }


            /*
            ====================================================
            LUA
            ====================================================
            */

            const lua =
                `local UGCs = ${toLua(ugcs)}\n\nreturn UGCs`;


            return res
                .type("text/plain")
                .send(lua);


        } catch (error) {

            console.error(
                "Erro ao buscar arrays/ugcs:",
                error
            );


            return res
                .status(500)
                .json({

                    success: false,

                    message:
                        "Erro interno do servidor",

                    error:
                        error.message

                });
        }
    }
);


export default router;

/*
import { Router } from "express";

const router = Router();

router.get("/", async (req, res) => {
    try {
        const projectId = "mod-ui";

        const url =
            `https://firestore.googleapis.com/v1/projects/${projectId}` +
            `/databases/(default)/documents/arrays/ugcs`;

        const response = await fetch(url);
        const data = await response.json();

        if (!response.ok) {
            console.error("Firestore REST Error:", data);

            return res.status(response.status).json({
                success: false,
                message: "Erro ao buscar arrays/ugcs",
                error: data
            });
        }

        return res.json({
            success: true,
            id: "ugcs",
            data
        });

    } catch (error) {
        console.error("Erro ao buscar arrays/ugcs:", error);

        return res.status(500).json({
            success: false,
            message: "Erro interno do servidor",
            error: error.message
        });
    }
});

export default router;

*/
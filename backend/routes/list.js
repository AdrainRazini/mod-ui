
import { Router } from "express";

const router = Router();

const API_MARKET = "https://mod-ui.vercel.app/market/";
const API_UGCS = "https://mod-ui.vercel.app/ugcs/";

const DB_ID = "mod-ui";

/**
 * Converte valores do Firestore REST
 * para valores JavaScript normais.
 */
function convertFirestoreValue(value) {
    if (!value) return null;

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

/**
 * Converte os fields do Firestore.
 */
function convertFirestoreFields(fields) {
    const result = {};

    for (const [key, value] of Object.entries(fields || {})) {
        result[key] = convertFirestoreValue(value);
    }

    return result;
}

/**
 * Atualiza os dados do UGC usando a API.
 */
async function updateUGCData(ugc) {
    if (!ugc || !ugc.IdUGC) {
        return ugc;
    }

    const id = ugc.IdUGC;

    try {
        /*
         * Primeiro tenta /ugcs/:id
         */
        let response = await fetch(`${API_UGCS}${id}`);

        /*
         * Se falhar, tenta /market/:id
         */
        if (!response.ok) {
            response = await fetch(`${API_MARKET}${id}`);
        }

        if (!response.ok) {
            console.warn(
                `Não foi possível atualizar UGC ${id}`
            );

            return ugc;
        }

        const result = await response.json();

        /*
         * Dependendo da estrutura da sua API,
         * tenta localizar os dados.
         */
        const liveData =
            result?.data ||
            result?.Roblox ||
            result;

        /*
         * Mantém os dados do Firestore e
         * substitui/adiciona os dados atuais.
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

        // Se a API falhar, mantém o cache do Firestore.
        return ugc;
    }
}

/**
 * Escapa strings para Lua.
 */
function luaString(value) {
    return JSON.stringify(String(value))
        .replace(/\\u2028/g, "\\u2028")
        .replace(/\\u2029/g, "\\u2029");
}

/**
 * Converte JavaScript -> Lua.
 */
function toLua(value, indent = 0) {
    const spacing = "    ".repeat(indent);
    const nextSpacing = "    ".repeat(indent + 1);

    if (value === null || value === undefined) {
        return "nil";
    }

    if (typeof value === "string") {
        return luaString(value);
    }

    if (typeof value === "number") {
        return String(value);
    }

    if (typeof value === "boolean") {
        return value ? "true" : "false";
    }

    if (Array.isArray(value)) {
        if (value.length === 0) {
            return "{}";
        }

        const items = value.map(item => {
            return `${nextSpacing}${toLua(item, indent + 1)}`;
        });

        return `{\n${items.join(",\n")}\n${spacing}}`;
    }

    if (typeof value === "object") {
        const entries = Object.entries(value);

        if (entries.length === 0) {
            return "{}";
        }

        const items = entries.map(([key, val]) => {
            return `${nextSpacing}[${luaString(key)}] = ${toLua(val, indent + 1)}`;
        });

        return `{\n${items.join(",\n")}\n${spacing}}`;
    }

    return "nil";
}


router.get("/", async (req, res) => {

    try {

        /*
         * ======================================================
         * MODO DE ATUALIZAÇÃO
         * ======================================================
         *
         * /list?live=true
         * → consulta API atual
         *
         * /list?live=false
         * → somente Firestore
         *
         * Sem parâmetro:
         * → false
         */

        const live =
            String(req.query.live).toLowerCase() === "true";


        /*
         * ======================================================
         * FIRESTORE
         * ======================================================
         */

        const url =
            `https://firestore.googleapis.com/v1/projects/${DB_ID}` +
            `/databases/(default)/documents/arrays/ugcs`;

        const response = await fetch(url);

        const data = await response.json();

        if (!response.ok) {

            console.error(
                "Firestore REST Error:",
                data
            );

            return res.status(response.status).json({
                success: false,
                message: "Erro ao buscar arrays/ugcs",
                error: data
            });
        }


        /*
         * ======================================================
         * CONVERTER FIRESTORE
         * ======================================================
         */

        const firestoreData =
            convertFirestoreFields(
                data.fields || {}
            );

        const ugcs =
            firestoreData.data || {};


        /*
         * ======================================================
         * ATUALIZAÇÃO EM TEMPO REAL
         * ======================================================
         */

        let finalUGCs = ugcs;

        if (live) {

            const entries =
                Object.entries(ugcs);

            const updatedEntries =
                await Promise.all(
                    entries.map(
                        async ([name, ugc]) => {

                            const updated =
                                await updateUGCData(ugc);

                            return [
                                name,
                                updated
                            ];
                        }
                    )
                );

            finalUGCs =
                Object.fromEntries(
                    updatedEntries
                );
        }


        /*
         * ======================================================
         * LUA
         * ======================================================
         */

        const lua =
            `local UGCs = ${toLua(finalUGCs)}\n\nreturn UGCs`;


        /*
         * ======================================================
         * RESPOSTA
         * ======================================================
         */

        return res
            .type("text/plain")
            .send(lua);

    } catch (error) {

        console.error(
            "Erro ao buscar arrays/ugcs:",
            error
        );

        return res.status(500).json({
            success: false,
            message: "Erro interno do servidor",
            error: error.message
        });
    }
});


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
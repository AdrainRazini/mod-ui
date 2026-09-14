import { Router } from "express";

const router = Router();

/**
 * Converte valores do Firestore REST para valores JavaScript normais.
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
 * Converte um objeto "fields" do Firestore.
 */
function convertFirestoreFields(fields) {
    const result = {};

    for (const [key, value] of Object.entries(fields || {})) {
        result[key] = convertFirestoreValue(value);
    }

    return result;
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

    if (typeof value === "number" || typeof value === "boolean") {
        return String(value);
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

        // Converte o documento Firestore para JSON normal
        const firestoreData = convertFirestoreFields(
            data.fields || {}
        );

        /*
         * Seu documento possui:
         *
         * fields
         * └── data
         *     └── { UGCs }
         *
         * Então pegamos somente data.
         */
        const ugcs = firestoreData.data || {};

        // Gera Lua
        const lua = `local UGCs = ${toLua(ugcs)}\n\nreturn UGCs`;

        return res.type("text/plain").send(lua);

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
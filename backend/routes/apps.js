// backend/routes/apps.js

import { Router } from "express";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";

const router = Router();

/* ============================================================
   PATHS
============================================================ */

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SCRIPT_ROOT = path.resolve(
    __dirname,
    "../../../scripts"
);

/* ============================================================
   CACHE
============================================================ */

let appsCache = null;
let lastScan = 0;

const CACHE_TIME = 30 * 1000;

/* ============================================================
   HELPERS
============================================================ */

/**
 * Converte um nome para ID.
 *
 * Ex:
 *
 * Legends Of Speeds
 * ↓
 * legends_of_speeds
 */
function gerarSlug(value) {

    if (!value) {
        return null;
    }

    return String(value)
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .toLowerCase()
        .trim()
        .replace(/[^a-z0-9]+/g, "_")
        .replace(/^_+|_+$/g, "");
}

/**
 * Retorna o nome da pasta pai do arquivo.
 *
 * Ex:
 *
 * scripts/Mods/Folder_Legends/Script.lua
 *
 * → Folder_Legends
 */
function obterFolderPai(filePath) {

    return path.basename(
        path.dirname(filePath)
    );
}

/* ============================================================
   MODINFO
============================================================ */

/**
 * Procura:
 *
 * local ModInfo = {
 *     Name = "Legends Of Speeds",
 *     Version = "1.0.0",
 *     Date = "2026-04-05",
 *     Notes = "Mode Menu"
 * }
 *
 * Também aceita:
 *
 * ModInfo = {
 *     ...
 * }
 *
 * Todos os campos são opcionais.
 */
function extrairModInfo(content) {

    if (typeof content !== "string") {
        return null;
    }

    /*
     * Procura o início do ModInfo.
     */
    const match = content.match(
        /(?:local\s+)?ModInfo\s*=\s*\{([\s\S]*?)\}/m
    );

    /*
     * Se não existe ModInfo,
     * retorna objeto vazio.
     *
     * Isso permite que o App
     * use o nome da pasta como fallback.
     */
    if (!match) {
        return {};
    }

    const bloco = match[1];

    /**
     * Extrai um campo de string.
     *
     * Ex:
     *
     * Name = "Legends Of Speeds"
     */
    function campo(nome) {

        const regex = new RegExp(
            `${nome}\\s*=\\s*["']([\\s\\S]*?)["']`,
            "m"
        );

        const resultado = bloco.match(regex);

        return resultado
            ? resultado[1].trim()
            : null;
    }

    return {
        Name: campo("Name"),
        Version: campo("Version"),
        Date: campo("Date"),
        Notes: campo("Notes")
    };
}

/* ============================================================
   ID
============================================================ */

function gerarId(modInfo, filePath) {

    /*
     * Primeiro tenta usar:
     *
     * ModInfo.Name
     */
    if (modInfo?.Name) {

        const id = gerarSlug(
            modInfo.Name
        );

        if (id) {
            return id;
        }
    }

    /*
     * Fallback:
     *
     * Nome da pasta pai.
     */
    return gerarSlug(
        obterFolderPai(filePath)
    );
}

/* ============================================================
   RECURSIVE FILE SCAN
============================================================ */

async function encontrarScripts(directory) {

    const resultados = [];

    let entries;

    try {

        entries = await fs.readdir(
            directory,
            {
                withFileTypes: true
            }
        );

    } catch {

        return resultados;
    }

    for (const entry of entries) {

        const fullPath = path.join(
            directory,
            entry.name
        );

        /*
         * Diretório
         */
        if (entry.isDirectory()) {

            const children =
                await encontrarScripts(
                    fullPath
                );

            resultados.push(
                ...children
            );

            continue;
        }

        /*
         * Não é arquivo
         */
        if (!entry.isFile()) {
            continue;
        }

        /*
         * Somente .lua
         */
        if (
            !entry.name
                .toLowerCase()
                .endsWith(".lua")
        ) {
            continue;
        }

        resultados.push(
            fullPath
        );
    }

    return resultados;
}

/* ============================================================
   SCAN APPS
============================================================ */

async function scanApps() {

    const scriptFiles =
        await encontrarScripts(
            SCRIPT_ROOT
        );

    const apps = [];

    for (const filePath of scriptFiles) {

        let content;

        try {

            content = await fs.readFile(
                filePath,
                "utf8"
            );

        } catch (error) {

            console.warn(
                "[Apps] Não foi possível ler:",
                filePath,
                error.message
            );

            continue;
        }

        /*
         * ModInfo pode existir
         * ou não existir.
         */
        const modInfo =
            extrairModInfo(
                content
            );

        /*
         * Pasta pai.
         */
        const folder =
            obterFolderPai(
                filePath
            );

        /*
         * Nome do App:
         *
         * 1. ModInfo.Name
         * 2. Folder pai
         */
        const name =
            modInfo?.Name ||
            folder;

        /*
         * ID:
         *
         * 1. ModInfo.Name
         * 2. Folder pai
         */
        const id =
            gerarId(
                modInfo,
                filePath
            );

        /*
         * Caminho relativo ao /scripts.
         */
        const relativePath =
            path.relative(
                SCRIPT_ROOT,
                filePath
            );

        apps.push({

            id,

            name,

            version:
                modInfo?.Version ||
                "0.0.0",

            date:
                modInfo?.Date ||
                null,

            notes:
                modInfo?.Notes ||
                null,

            enabled:
                true,

            folder,

            file:
                relativePath
                    .split(path.sep)
                    .join("/")

        });
    }

    /*
     * Ordena alfabeticamente.
     */
    apps.sort(
        (a, b) =>
            a.name.localeCompare(
                b.name
            )
    );

    return apps;
}

/* ============================================================
   GET /apps
============================================================ */

router.get(
    "/",
    async (req, res) => {

        try {

            const now =
                Date.now();

            /*
             * Cache de 30 segundos.
             */
            if (
                appsCache &&
                now - lastScan <
                    CACHE_TIME
            ) {

                return res.status(200).json({

                    success: true,

                    count:
                        appsCache.length,

                    apps:
                        appsCache,

                    cached:
                        true

                });
            }

            /*
             * Nova varredura.
             */
            const apps =
                await scanApps();

            appsCache =
                apps;

            lastScan =
                now;

            return res.status(200).json({

                success: true,

                count:
                    apps.length,

                apps,

                cached:
                    false

            });

        } catch (error) {

            console.error(
                "[Apps] Erro ao fazer varredura:",
                error
            );

            return res.status(500).json({

                success: false,

                error:
                    "Erro ao procurar Apps.",

                message:
                    error.message

            });
        }
    }
);

/* ============================================================
   GET /apps/:id
============================================================ */

router.get(
    "/:id",
    async (req, res) => {

        try {

            const id =
                String(
                    req.params.id
                )
                    .toLowerCase();

            const apps =
                await scanApps();

            const app =
                apps.find(
                    item =>
                        item.id
                            .toLowerCase() ===
                        id
                );

            if (!app) {

                return res.status(404).json({

                    success: false,

                    error:
                        "App não encontrado."

                });
            }

            return res.status(200).json({

                success: true,

                app

            });

        } catch (error) {

            console.error(
                "[Apps] Erro:",
                error
            );

            return res.status(500).json({

                success: false,

                error:
                    "Erro ao procurar App.",

                message:
                    error.message

            });
        }
    }
);

/* ============================================================
   EXPORT
============================================================ */

export default router;
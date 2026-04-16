
//pages/index.js
import "../core/main.js"
import "../core/script.js"
import "../core/cache.js"

import ADN from "../core/app.js";

 ADN.run("load",{
    steps:["Inicializando sistema...", "Carregando módulos...", "Conectando APIs...", "Sincronizando dados...", "Preparando interface...", "Sistema pronto"],
    loadingEl: document.getElementById("loading-screen"),
    textEl: document.getElementById("loading-text"),
    progressEl: document.getElementById("loading-progress"),
    imageEl: document.getElementById("loading-image"),
    toolbarEl: document.getElementById("toolbar-tab"),
    onFinish: ()=> console.log("Sistema carregado!"),
    num: 500})
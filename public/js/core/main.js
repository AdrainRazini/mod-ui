import ADN from "./app.js";

function getId(name){

    if(name instanceof HTMLElement) return name;

    const el = document.getElementById(name);

    if(!el){
        console.warn(`Elemento com id "${name}" não encontrado`);
    }

    return el;
}


function filter(data = {}, id){

    const etiquetaData = {
        ID: id,
        Nome: data.nome,
        Produto:"Etiqueta",
        Qtd: data.volume,
        Origem: `${data.cidade_origem} - ${data.uf_origem}`,
        Destino: `${data.cidade_destino} - ${data.uf_destino}`,
        Logo: "image/Logo_Transcotempo_black.png",
        Imagem: "image/Logo_Transcotempo_black.png"
    };

    return etiquetaData;

}


// Função para criar o templates de html

/* Alert */
function createAlert(args = {}) {

    if(typeof args === "string"){
        args = { text: args };
    }

    const { text = "", duration = 3000 } = args;

    const alertEl = document.createElement("div");
    alertEl.className = "custom-alert";
    alertEl.textContent = text;

    document.body.appendChild(alertEl);

    setTimeout(() => alertEl.classList.add("show"), 10);

    setTimeout(() => {
        alertEl.classList.remove("show");
        setTimeout(() => alertEl.remove(), 500);
    }, duration);
}

/* Alert Confirm */
function createConfirm(args={}) {

    if(typeof args === "string"){
        args = { text: args };
    }

    const { text = "", onYes = null, onNo = null } = args;

    const overlay = document.createElement("div");
    overlay.className = "custom-confirm-overlay";

    const box = document.createElement("div");
    box.className = "custom-confirm-box";

    const p = document.createElement("p");
    p.textContent = text;

    const btnYes = document.createElement("button");
    btnYes.textContent = "Sim";
    btnYes.className = "confirm-btn";

    const btnNo = document.createElement("button");
    btnNo.textContent = "Não";
    btnNo.className = "cancel-btn";

    btnYes.addEventListener("click", () => {
        if(onYes) onYes();
        overlay.remove();
    });

    btnNo.addEventListener("click", () => {
        if(onNo) onNo();
        overlay.remove();
    });

    box.appendChild(p);
    box.appendChild(btnYes);
    box.appendChild(btnNo);
    overlay.appendChild(box);
    document.body.appendChild(overlay);
}

// Exemplo de alerta
// createAlert({ text: "Sistema carregado com sucesso!" });

// Exemplo de confirm
// createConfirm({text: "Deseja salvar as alterações?",onYes: () => console.log("Salvo!"),onNo: () => console.log("Cancelado!")});


//Loading
function createLoadingScreen(arg={}) {
    // Container principal
    const loadingScreen = createobj("div", { id: "loading-screen" });

    // Logo / imagem
    const logo = createobj("img", {
        src: "image/fa_ADN_Loading_Mod.png",
        class: "logo",
        id: "loading-image"
    });
    loadingScreen.appendChild(logo);

    // Slider / barra de progresso
    const slider = createobj("div", { class: "slider" });
    const progress = createobj("div", { class: "progress", id: "loading-progress" });
    slider.appendChild(progress);
    loadingScreen.appendChild(slider);

    // Texto de loading
    const loadingText = createobj("p", { class: "loading-text", id: "loading-text" });
    loadingText.innerHTML = '<i class="fa-solid fa-microchip"></i> Inicializando sistema...';
    loadingScreen.appendChild(loadingText);

    // Adiciona ao body
    document.body.appendChild(loadingScreen);

    return { loadingScreen, logo, progress, loadingText };
}
// Modal
function createModalTemplate(arg={}) {
    // Overlay
    const overlay = createobj("div", { id: "modal-overlay", class: "modal-overlay" });

    // Janela principal
    const modalWindow = createobj("div", { class: "modal-window" });
    overlay.appendChild(modalWindow);

    // Header
    const header = createobj("div", { class: "modal-header" });
    modalWindow.appendChild(header);

    header.appendChild(createobj("h2", { id: "modal-title", html: '<i class="fa-solid fa-circle-info"></i> Criar Etiqueta' }));

    const closeBtn = createobj("button", { id: "modal-close", class: "modal-close", html: '<i class="fa-solid fa-xmark"></i>' });
    header.appendChild(closeBtn);
    closeBtn.addEventListener("click", () => overlay.remove());

    // Body
    const body = createobj("div", { class: "modal-body", id: "modal-body" });
    modalWindow.appendChild(body);

    const text = createobj("p", { id: "modal-text" });
    body.appendChild(text);

    const image = createobj("img", { id: "modal-image", class: "modal-image", style: "display:none;" });
    body.appendChild(image);

    const inputsContainer = createobj("div", { id: "modal-inputs" });
    body.appendChild(inputsContainer);

    const textSub = createobj("p", { id: "modal-text-sub" });
    body.appendChild(textSub);

    // Footer
    const footer = createobj("div", { class: "modal-footer" });
    modalWindow.appendChild(footer);

    const btnCancel = createobj("button", { class: "btn cancel", id: "btn_cancel", text: "Cancelar" });
    footer.appendChild(btnCancel);
    btnCancel.addEventListener("click", () => overlay.remove());

    const btnConfirm = createobj("button", { class: "btn confirm", id: "btn_confirm", text: "Confirmar" });
    footer.appendChild(btnConfirm);

    // Adiciona o modal ao body
    document.body.appendChild(overlay);

    return {
        overlay,
        modalWindow,
        header,
        body,
        text,
        image,
        inputsContainer,
        textSub,
        btnCancel,
        btnConfirm,
        closeBtn
    };
}


/* =========================
LOADING SYSTEM
========================= */

function runLoading({ steps, loadingEl, textEl, progressEl, imageEl, toolbarEl, onFinish, num}) {
    let step = 0;

    loadingEl.classList.add("show");
    if(toolbarEl) toolbarEl.classList.remove("show");

    const interval = setInterval(() => {
        if(step >= steps.length){
            clearInterval(interval);
            
            // Esconde loading
            loadingEl.classList.remove("show");
            loadingEl.classList.add("hide");

            setTimeout(()=>{
                loadingEl.style.display = "none";
                if(toolbarEl) toolbarEl.classList.add("show");
                if(onFinish) onFinish();
            }, 800);

            return;
        }

        // Atualiza texto
        textEl.innerHTML = `<i class="fa-solid fa-microchip"></i> ${steps[step]}`;

        // Atualiza progresso
        progressEl.style.width = ((step+1)/steps.length) * 100 + "%";

        // Anima imagem
        if(imageEl){
            imageEl.style.transform = "scale(1.02)";
            setTimeout(()=> imageEl.style.transform = "scale(1)", 300);
        }

        step++;
    }, num);
}

// Sistema Modal de Informação
const modal = getId("modal-overlay");
const closeBtn = getId("modal-close");

const titleEl = getId("modal-title");
const textEl = getId("modal-text");
const imageEl = getId("modal-image");

const inputsEl = getId("modal-inputs");

const textSubEl = getId("modal-text-sub");

const SenderBtn = getId("btn_confirm");
const CancelBtn = getId("btn_cancel");



/* Criação Dinamica */

let modalCallback = null;

function createobj(tag, options = {}) {

    const el = document.createElement(tag);

    Object.entries(options).forEach(([key,value])=>{

        if(key === "class"){
            el.classList.add(...value.split(" "));
        }

        else if(key === "text"){
            el.textContent = value;
        }

        else if(key === "html"){
            el.innerHTML = value;
        }

        // suporte a eventos
        else if(key.startsWith("on") && typeof value === "function"){

            const event = key.substring(2); // onclick → click
            el.addEventListener(event,value);

        }

        else if(key === "options" && tag === "select"){

            value.forEach(opt=>{

                const option = document.createElement("option");

                if(typeof opt === "string"){
                    option.value = opt;
                    option.textContent = opt;
                }else{
                    option.value = opt.value;
                    option.textContent = opt.text;
                }

                el.appendChild(option);

            });

        }

        else if(key in el){
         el[key] = value;
        }
        else{
         el.setAttribute(key,value);
        }

    });

    el.addEventListener("input", ()=>{
        el.classList.remove("input-error");
    });

    return el;
}

// Pegar Dados + Validação
function getModalData(){

    const dados = {};
    let valid = true;

    inputsEl.querySelectorAll("[name]").forEach(el => {

        let value = el.value;

        el.classList.remove("input-error");

        if(el.required && !value.trim()){
            el.classList.add("input-error");
            valid = false;
        }

        if(el.type === "number" && value !== ""){
            value = Number(value);
        }

        dados[el.name] = value;

    });

    if(!valid){
        //alert("Preencha os campos obrigatórios.");
        createAlert({ text: "Preencha os campos obrigatórios." });
        return null;
    }

    return dados;
}




function openModal(args = {}) {

    modalCallback = args.onConfirm || null;
    

    titleEl.innerHTML = `<i class="fa-solid fa-circle-info"></i> ${args.title || "Informações"}`;

    textEl.textContent = args.text || "";
    textSubEl.textContent = args.textsub || "";

    if (args.image) {
        imageEl.src = args.image;
        imageEl.style.display = "block";
    } else {
        imageEl.style.display = "none";
    }

    inputsEl.innerHTML = "";

    if(args.inputs){
        args.inputs.forEach(obj => {
            const el = createobj(obj.tag, obj.options);
            inputsEl.appendChild(el);
        });
    }

    modal.classList.add("show");

    const firstInput = inputsEl.querySelector("input, textarea, select");

    if(firstInput){
    setTimeout(()=> firstInput.focus(),100);
    }

}

function closeModal(args = {}){

    inputsEl.innerHTML = "";
    textEl.textContent = "";
    imageEl.src = "";

    modal.classList.remove("show");

}


    // Enviar Dados
   SenderBtn.addEventListener("click", ()=>{

    const dados = getModalData();

    if(!dados) return; // bloqueia envio

    if(modalCallback){
        modalCallback(dados);
    }

    closeModal();

    });


closeBtn.addEventListener("click", closeModal);
CancelBtn.addEventListener("click", closeModal);

modal.addEventListener("click", (e)=>{
    if(e.target === modal){
        closeModal();
    }
});



// Funções
function abrirInfoServer(){

    openModal({
        title: "Central ADN Core System",
        text: "Engine carregada com sucesso",
        textsub: "Servidor Ativo",

        inputs: [

            { tag:"label", options:{ text:"Arquivos" } },

            {
                tag:"button",
                options:{
                    text:"Abrir",
                    class:"btn cancel",
                    onclick:()=>{
                        createAlert("Abrindo arquivos...");
                        window.location.href = "index_pdf.html";
                    }
                }
            },

            { tag:"label", options:{ text:"Servidor" } },

            {
                tag:"button",
                options:{
                    text:"Abrir",
                    class:"btn cancel",
                    onclick:()=>{
                        createAlert("Abrindo servidor...");
                        window.location.href = "index.html";
                    }
                }
            }

        ]
    });

}

function abrirInfoInputs(){

openModal({
    title:"ADN Core",
    text:"Sistema modular carregado com sucesso.",
    textsub:"Este modal demonstra o funcionamento do sistema dinâmico de interfaces do ADN Core.",

    inputs:[

        {tag:"label", options:{text:"Módulo"}},

        {
            tag:"select",
            options:{
                name:"modulo",
                class:"modal-input",
                options:[
                    "Modal System",
                    "Cache System",
                    "Forms Engine",
                    "UI Components"
                ]
            }
        },

        {tag:"label", options:{text:"Versão da Engine"}},

        {
            tag:"input",
            options:{
                name:"versao",
                type:"text",
                class:"modal-input",
                value: ADN.name + " " + ADN.version
            }
        },

        {tag:"label", options:{text:"Tipo de Interface"}},

        {
            tag:"select",
            options:{
                name:"interface",
                class:"modal-input",
                options:[
                    "Formulário Dinâmico",
                    "Modal Informativo",
                    "Painel de Controle",
                    "Sistema de Configuração"
                ]
            }
        },

        {tag:"label", options:{text:"Descrição do Sistema"}},

        {
            tag:"textarea",
            options:{
                name:"descricao",
                class:"modal-input",
                value:"O ADN Core é uma engine modular projetada para criar interfaces, formulários e sistemas interativos de forma dinâmica utilizando configurações em JSON."
            }
        }

    ],

    onConfirm:(dados)=>{

        console.log("Configuração selecionada:", dados);

    }

});

}


function abrirConfigs(){

openModal({
    title:"Configurações",
    text:"Engine carregada com sucesso",
    textsub:"Configurações",
    inputs:[],
    //Confimação Print
    onConfirm:(dados)=>{

    console.log("Config criada:", dados);

    }
});

}

function abrirChat(){

 const API_URL = "https://adn-ia.vercel.app/chat";
 const CORE_CHAT = "bot_adn";
 const UserDefault = "Null";

 openModal({
    title:"Chat Adn",
    text:"Engine carregada com sucesso",
    textsub:"IA Cloud",

    inputs:[

        { tag:"label", options:{ text:"Chat" } },

        {
            tag:"input",
            options:{
                id:"rq-chat-pergunta",
                class:"modal-input",
                placeholder:"Digite sua pergunta..."
            }
        },

        {
            tag:"button",
            options:{
                text:"Enviar",
                id:"rq-sender-ia",
                class:"btn cancel",
                onclick: async ()=>{

                    const input = document.getElementById("rq-chat-pergunta");
                    const pergunta = input.value.trim();

                    const respostaBox = document.getElementById("rq-ia");
                    const btnSender = document.getElementById("rq-sender-ia");

                    if(!pergunta){
                        respostaBox.value = "Digite uma pergunta.";
                        return;
                    }

                    btnSender.disabled = true;
                    respostaBox.value = "Pensando...";

                    const payload = {
                        message: pergunta,
                        core: CORE_CHAT,
                        author: UserDefault
                    };

                    try{

                        const res = await fetch(API_URL,{
                            method:"POST",
                            headers:{
                                "Content-Type":"application/json"
                            },
                            body: JSON.stringify(payload)
                        });

                        const data = await res.json();

                        console.log("Resposta IA:", data);

                        respostaBox.value = data.reply || "Sem resposta da IA";

                        input.value = "";

                    }catch(err){

                        console.error("Erro API:",err);
                        respostaBox.value = "Erro ao consultar IA.";

                    }finally{

                        btnSender.disabled = false;

                    }

                }
            }
        },

        {
            tag:"textarea",
            options:{
                id:"rq-ia",
                class:"modal-input modal-textarea lock",
                placeholder:"Resposta da IA aparecerá aqui..."
            }
        },

        ADN.templates.link("https://adn-ia.vercel.app/")
    ],

    onConfirm:(dados)=>{
        console.log("Chat criada:", dados);
    }

 });

}

// Abrir ou editar
function abrirEtiqueta(arg={}){

const data = arg.data || {};
const editId = arg.id || null;

openModal({
title: editId ? "Editar Etiqueta" : "Criar Etiqueta",
text: "Preencha os dados da etiqueta",

inputs:[

{ tag:"label", options:{text:"Nome do Cliente"} },
{ tag:"input", options:{name:"nome", type:"text", class:"modal-input", value:data.nome || "", placeholder:"Digite o nome", required:true} },

{ tag:"label", options:{text:"Volume"} },
{ tag:"input", options:{name:"volume", type:"number", class:"modal-input", value:data.volume || "", placeholder:"Qtd Volume", required:true} },

// Origem
{ tag:"label", options:{text:"Origem"} },
{ tag:"input", options:{name:"origem", type:"text", class:"modal-input", value:data.origem || "", placeholder:"Endereço de Origem", required:true} },
{ tag:"select", options:{name:"uf_origem",id:"uf-origem", class:"modal-input",value:data.uf_origem || "", options:data.uf_origem ? [{value:data.uf_origem, text:data.uf_origem}] : []  ,required:true}},
{ tag:"select", options:{name:"cidade_origem",id:"cidade-origem",class:"modal-input",value:data.cidade_origem || "", options:data.cidade_origem ? [{value:data.cidade_origem, text:data.cidade_origem}] : []  ,required:true}},

// Destino
{ tag:"label", options:{text:"Destino"} },
{ tag:"input", options:{name:"destino", type:"text", class:"modal-input", value:data.destino || "", placeholder:"Endereço de Destino", required:true} },
{ tag:"select", options:{name:"uf_destino",id:"uf-destino",class:"modal-input",value:data.uf_destino || "", options:data.uf_destino ? [{value:data.uf_destino, text:data.uf_destino}] : [] ,required:true}},
{ tag:"select", options:{name:"cidade_destino",id:"cidade-destino",class:"modal-input",value:data.cidade_destino || "", options:data.cidade_destino ? [{value:data.cidade_destino, text:data.cidade_destino}] : []  ,required:true}},

// Obs
{ tag:"label", options:{text:"Observações"} },
{ tag:"textarea", options:{name:"obs", class:"modal-input", value:data.obs || ""} }

],

onConfirm:(dados)=>{
console.log(dados)
   // let data = dados

createConfirm({

text: editId ? 
"Deseja atualizar esta etiqueta?" : 
"Deseja salvar esta etiqueta?",

onYes:()=>{

const etiquetas = ADN.cache.get("etiquetas") || {};
const id = editId ?? Date.now();

etiquetas[id] = dados;

ADN.cache.set("etiquetas", etiquetas);

createAlert({
text: editId 
? "Etiqueta atualizada com sucesso"
: "Etiqueta criada com sucesso"
});

},

onNo:()=>{

if (!editId){
ADN.run("alert",{text:"pdf"});
const id = editId ?? Date.now();
const etiquetaData = filter(dados, id);
ADN.run("generatePDFData",etiquetaData);
}

}

});

}

});

}



/* buttons toolbar */

// ToolBar

const toolbar = getId("toolbar-tab");
const infoBar = getId("tool_info_bar");


function updateInfoBar(label){

    if(!infoBar) return;

    infoBar.textContent = label || "";
    infoBar.classList.add("show");

}

function hideInfoBar(){

    if(!infoBar) return;

    infoBar.classList.remove("show");

}

function actionMonitor(container){

    if(!container) return;

    // CLICK
    container.addEventListener("click",(e)=>{

        const btn = e.target.closest("[data-action],[data-label]");
        if(!btn || !container.contains(btn)) return;

        const action = btn.dataset.action || null;
        const label = btn.dataset.label || null;

        if(action){
            handleAction(action, btn, label);
        }

    });

    // HOVER SHOW LABEL
    container.addEventListener("mouseover",(e)=>{

        const btn = e.target.closest("[data-label]");
        if(!btn || !container.contains(btn)) return;

        updateInfoBar(btn.dataset.label);

    });

    // HOVER LEAVE
    container.addEventListener("mouseleave",()=>{
        hideInfoBar();
    });

}

function handleAction(action, el, label){

    switch(action){

        case "server":
            abrirInfoServer();
        break;

        case "chat":
            abrirChat();
        break;

        case "config":
            abrirConfigs();
        break;

        case "info":
            abrirInfoInputs();
        break;

        case "tag":
            abrirEtiqueta();
        break;

        default:
            console.warn("Ação não registrada:", action);

    }

}

// inicia monitor somente na toolbar

actionMonitor(toolbar);
actionMonitor(getId("sidebar"));



function menu() {

    const sidebar = getId("sidebar");
    const toggle = getId("toggle-menu");

    if(!sidebar || !toggle) return;

    toggle.onclick = () => {
        sidebar.classList.toggle("hide");
    };

}

function initUI(){

    menu();

}

document.addEventListener("DOMContentLoaded", initUI);

ADN.register("abrirEtiqueta", {
    type:"ui",
    run:abrirEtiqueta
});

ADN.register("alert", {
    type:"ui",
    run:createAlert
});

ADN.register("confirm", {
    type:"ui",
    run:createConfirm
});

ADN.register("load", {
    type:"ui",
    run:runLoading
});

console.log(ADN);
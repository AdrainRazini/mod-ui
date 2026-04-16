
// Exportação de Dados
const ADN = {
    name: "ADN Core",
    version: "3.2.0",

    // Resumo de Func (acelerar interação com importação e Exportação)
    modules: {}, // criação e armazem de nome,func
    modals: {}, // modulos registro principal
    ui: {}, // Interface
    forms: {}, // formulários dinâmicos (para Clientes)
    templates: {}, // Templates 
    func:{}, // func externas
    cache:{}, // Memory app

    // usando conceitos de nóss ou Plugs
    register(name, args = {}) {

    if(this.modules[name]){
    console.warn("Modulo já registrado:", name);
    }

    
    if(typeof args === "function"){
        args = { run: args };
    }

    const type = args.type || "module";

    const module = {
        name,
        type,
        open: args.open || null,
        run: args.run || null,
        ...args
    };

    this.modules[name] = module;

    switch(type){

        case "modal":
            this.modals[name] = module;
        break;

        case "ui":
            this.ui[name] = module;
        break;

        case "form":
            this.forms[name] = module;
        break;

    }

    },

    run(name, data = null){

    const mod = this.modules[name];

    if(!mod){
        console.warn("Modulo não encontrado:", name);
        return;
    }

    if(typeof mod.open === "function"){
        mod.open(data);
    }

    if(typeof mod.run === "function"){
        mod.run(data);
    }

}

};



/* Conexões de App */ 
//Registros

// type define local
// open define func

ADN.templates = {

    label(text){
        return { tag:"label", options:{ text } };
    },

    input(name, placeholder="", required=false){
        return {
            tag:"input",
            options:{
                name,
                type:"text",
                class:"modal-input",
                placeholder,
                required
            }
        };
    },

    textarea(name){
        return {
            tag:"textarea",
            options:{
                name,
                class:"modal-input"
            }
        };
    },

    link(url){
    return {
        tag:"a",
        options:{
            href:url,
            text:url,
            target:"_blank",
            class:"modal-link"
        }
    };
}
};

// Script.js tem que ser em ESModule ou Type:"Module" (type="module") em .json ou .html
export default ADN


-- Tema esse projeto sera focado apenas no Mod_Ui melhorado para FrameWork
-- e publicado por GitHub , hospedado em vercel , com tecnologias como FireBase 
-- Obejetivo testar meus limites aplicando Lua + HTTP + infra web.
-- Sem Estimativa de Tempo  


[Mod_Ui]/
│
├── data/          # Configurações globais editáveis via HTTP
├── public/        # Front-end (site, docs, painel)
├── scripts/       # Framework Lua (o coração)
│
├── backend/       # Backend Node.js (API / Auth / Config)
└── .env           # Chaves locais (dev only)

-- default
[data]/
├── defaults/
│   └── config.json
├── themes/
│   └── dark.json
└── versions.json


-- Back-end
[backend]/
│
├── server.js      # Server http  entrypoint 
│
├── routes/        # pelo que sei provavelmente app.get ou 202
│
├── services/      # 
│   ├── configService.js
│   └── featureService.js
│
└── .env 


-- Front-end
[public]/

-- Scripts Lua
[scripts]/
│
├── Config/                 # Configurações globais Editaveis
│   ├── Defaults.lua
│   ├── Remote.lua
│   └── Resolver.lua
│
├── Core/                   # Conexões Principais (Futuro vou usar para conexão geral http)
│   ├── Mod_UI.lua          # Modulo antigo (para referencia) legacy / referência 
│   ├── Bootstrap.lua    -- init do framework
│   ├── Http.lua         -- cliente HTTP central
│   ├── Version.lua
│   └── Logger.lua
│   
├── Data/                   # Dados globais Cache (icons, Colors, descrições)
│   ├── Cache.lua           # Controlador De Dados Local e armazenamento de referência
│   ├── Colors.lua
│   └── Icons.lua
│   
├── Utilities/              # Criação Dinamica Interna
│   
├── Modules/                # Modulos Auxiliares globais
│   ├── ThemeManager.lua
│   ├── FeatureFlags.lua
│   └── Permissions.lua



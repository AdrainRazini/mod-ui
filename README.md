-- Tema:
-- Este projeto será focado exclusivamente no Mod_UI Framework.
-- Será publicado no GitHub, hospedado na Vercel e utilizará tecnologias
-- como Firebase para armazenamento e sincronização.
--
-- Objetivo:
-- Testar meus limites aplicando Lua + HTTP + Infraestrutura Web,
-- criando um framework modular, escalável e desacoplado.
--
-- Sem estimativa de conclusão.

[Mod_UI]/
│
├── data/              # Configurações públicas e dados remotos
├── public/            # Front-end (Site, Docs, Painel)
├── scripts/           # Framework Lua (Core)
├── backend/           # API Node.js
├── .github/           # Workflows GitHub Actions (futuro)
├── docs/              # Documentação técnica
├── package.json
├── vercel.json
└── .env               # Apenas desenvolvimento

-- default
[data]/
│
├── defaults/
│   └── config.json        # Configuração padrão
│
├── themes/
│   ├── dark.json
│   └── light.json         # Futuro
│
├── locales/               # Futuro (traduções)
│
└── versions.json

-- Back-end
[backend]/
│
├── server.js              # Entry Point HTTP
│
├── routes/                # Rotas da API
│   ├── config.js
│   ├── features.js
│   ├── themes.js
│   └── version.js
│
├── services/              # Regras de negócio
│   ├── configService.js
│   ├── featureService.js
│   ├── themeService.js
│   └── versionService.js
│
├── middleware/            # Auth, RateLimit...
│
├── utils/
│
└── .env


-- Front-end
[public]/
│
├── index.html
├── docs/
├── assets/
│   ├── css/
│   ├── js/
│   └── images/
│
└── dashboard/

-- Scripts Lua
[scripts]/
│
├── Config/
│   ├── Defaults.lua       -- Configuração padrão
│   ├── Remote.lua         -- Configuração recebida da API
│   └── Resolver.lua       -- Mescla Default + Remoto
│
├── Core/
│   ├── Bootstrap.lua      -- Inicialização do Framework
│   ├── Http.lua           -- Cliente HTTP
│   ├── Version.lua        -- Controle de versões
│   ├── Logger.lua         -- Sistema de Logs
│   └── Mod_UI.lua         -- Legacy (Referência)
│
├── Data/
│   ├── Cache.lua          -- Cache Global
│   ├── Colors.lua
│   ├── Icons.lua
│   └── Assets.lua         -- Futuro
│
├── Utilities/
│   ├── Builder.lua        -- Construção dinâmica
│   ├── Serializer.lua
│   ├── Signal.lua
│   └── Helpers.lua
│
├── Modules/
│   ├── ThemeManager.lua
│   ├── FeatureFlags.lua
│   ├── Permissions.lua
│   └── UpdateChecker.lua
│
└── Init.lua               -- Entrada pública do Framework


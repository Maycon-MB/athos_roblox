# IDEIA — Roteiro de Implementação: Escape do Tsunami (YouTuber Jump Shop)

---

## CHECKLIST DE MODIFICAÇÕES

### MAPA PRINCIPAL (Escape Waves For Brainmodz)

- [ ] Ocultar AdminPanel toggle button por padrão; expor via comando `:showadmin` / `:hideadmin`
- [ ] Adicionar `Part` invisível (trigger) na parede mid-track → teleport para **Loja de pulos de youtubers**
- [ ] Adicionar `Part` invisível (trigger) na parede mid-track → teleport para **Base separada**
- [ ] Injetar `ProgressTracker_Frame` no StarterGui replicando os 7 ícones de pulo (top-right)
- [ ] Adicionar `WaveShieldService` no ServerScriptService
- [ ] Adicionar `WaveMachineService` no ServerScriptService (consome tokens, spawna ondas por player)
- [ ] Adicionar Galaxy Bat como `Tool` no ReplicatedStorage com hitbox que lança alvo
- [ ] Registrar 3 brainrots customizados em `BrainrotConfig` (Jamezini, Mikey, Athos)
- [ ] Adicionar floating BillboardGui acima de cada brainrot model (nome + rarity + $/s)

### MAPA: Loja de pulos de youtubers

- [ ] Criar mapa com fachada/paredes decoradas com logos do YouTube (Decals)
- [ ] Replicar HUD completo do mapa original (Gems, Coins, JumpLevel, SpeedLevel, Money) — valores editáveis via admin
- [ ] Inserir `JumpShop_Frame` com 7 cards (ver `jump_shop_items` no blueprint)
- [ ] Cards exibem: ícone do pulo, stats por símbolos (🦵=jump, ⚡=speed), custo, sem texto descritivo longo
- [ ] Card bloqueado: overlay escuro `#00000080`. Card desbloqueado: fundo verde `#27AE60` + checkmark
- [ ] `ProgressTracker_Frame` sincronizado com estado de compra do player

### MAPA: Base separada

- [ ] Criar área fechada com muros no estilo do jogo original
- [ ] Única base slot (igual ao original)
- [ ] Suporta placement dos 3 brainrots customizados
- [ ] Income ticker: a cada 1s → `AddMoney(player, brainrot.income_per_second)` por slot ocupado
- [ ] Replicar HUD completo do mapa original — valores editáveis via admin

---

## ARQUITETURA DE SCRIPTS

```
ServerScriptService/
├── AdminService.lua           -- Comandos :hideadmin :showadmin :setjump :setspeed :setmoney :givetokens :giveitem :givebrainrot
├── JumpShopService.lua        -- Lógica de compra dos 7 pulos; valida custo_type; concede rewards
├── WaveShieldService.lua      -- Intercepta colisão wave/player quando shield ativo; decrementa carga
├── WaveMachineService.lua     -- Consome wave tokens; spawna ondas direcionadas por player target
├── BaseIncomeService.lua      -- Ticker 1s por slot ocupado; dispara RemoteEvent AddMoney
├── TeleportService_Handler.lua -- Detecta touch nos trigger Parts; chama TeleportService
└── BrainrotConfig.lua         -- Definições estáticas dos 3 brainrots (id, rarity, income, skin, aura)

ReplicatedStorage/
├── RemoteEvents/
│   ├── AddMoney
│   ├── ProgressUnlock
│   ├── ShieldActivated
│   └── WaveTokenUpdate
├── Tools/
│   └── GalaxyBat.rbxm
└── Models/
    ├── Jamezini_Cakenini.rbxm
    ├── Mikey.rbxm
    └── Athos_Brainrot.rbxm    -- Inclui ParticleEmitter de fogo

StarterGui/
├── HUD/
│   ├── HUD_Gems (TextLabel)
│   ├── HUD_Coins (TextLabel)
│   ├── HUD_JumpLevel (TextLabel)
│   ├── HUD_SpeedLevel (TextLabel)
│   └── HUD_Money (TextLabel)
├── AdminPanel/
│   ├── AdminPanel_Frame (Frame, Visible=false)
│   └── AdminPanel_ToggleButton (TextButton, Visible=false por padrão)
├── JumpShop/
│   ├── JumpShop_Frame (Frame, Visible=false)
│   ├── JumpShop_Title
│   ├── JumpShop_CloseButton
│   └── JumpCard x7 (Frame com template)
└── ProgressTracker/
    └── ProgressTracker_Frame (7 slots, top-right)

StarterPlayerScripts/
├── HUDController.lua          -- Atualiza TextLabels do HUD via RemoteEvents
├── JumpShopController.lua     -- Abre/fecha JumpShop_Frame; envia pedido de compra ao server
└── ProgressTrackerController.lua -- Recebe ProgressUnlock; aplica verde + checkmark no card correto
```

---

## RESSALVAS / CONFLITOS

| # | Conflito | Detalhe |
|---|----------|---------|
| 1 | **TeleportService em lugar único** | O mapa base usa `TeleportService` para teleporte entre os 3 mapas. Se o jogo for single-place (não Universe), teleporte não funciona. **Requisito:** Publicar os 3 mapas como Places separados dentro do mesmo Universe no Roblox Studio. |
| 2 | **AdminPanel do mapa original vs. novo** | O mapa Escape Waves For Brainmodz já tem um AdminPanel próprio com botões (Loja, Trocar, Índice, VIP, Renascimento, Convidar). Os comandos `:hideadmin`/`:showadmin` precisam controlar **esse** painel existente, não criar um novo — verificar se ele usa `LocalScript` ou `Script` antes de sobrescrever. |
| 3 | **HUD replicado nos mapas auxiliares** | O HUD dos mapas auxiliares precisa ter seus valores sincronizados com o `PlayerData` persistido (via `DataStoreService` ou passado via `TeleportData`). Se `DATASTORE_ENABLED = false`, os valores resetam ao trocar de mapa — usar `TeleportService:ReserveServer` + `TeleportData` para passar estado. |
| 4 | **Custo `kill_players_with_waves` (Matheus)** | "Matar 5 players com ondas" requer que a onda identifique o atacante (Athos). A `WaveMachineService` precisa taggear a onda com `owner = player` antes do hit para atribuir o kill corretamente. Ondas do mapa original não têm esse tag — não sobrescrever lógica original de dano. |
| 5 | **Custo `waves_survived` (Pdoro)** | O contador de ondas sobrevividas precisa ser por streak (10 consecutivas sem morrer), não total. Resetar contador ao morrer. Confirmar se o mapa original já expõe esse evento ou se é necessário criar listener próprio. |
| 6 | **`sell_brainrots` session counter (Caylus)** | O contador de brainrots vendidos é de sessão. Se o player trocar de mapa e voltar, o contador reseta via `TeleportData`. Decidir se deve ser persistido em DataStore ou mantido apenas em sessão. |
| 7 | **Galaxy Bat hitbox vs. Wave colisão** | O Galaxy Bat usa `Tool.Handle.Touched` para detectar hit. Se o player atingido já estiver em zona de onda no mesmo frame, pode dobrar o dano ou triggerar dois kills. Adicionar debounce de 0.5s por target. |
| 8 | **Brainrot Athos (Infinity / 999M/s)** | Income de 999M/s em tick de 1s pode causar overflow em `IntValue` do Roblox (max ~2^53). Usar `NumberValue` ou string-formatted money (ex: `$1.11T`) no HUD e armazenar como `double` no DataStore. |
| 9 | **ProgressTracker nos 3 mapas** | O `ProgressTracker_Frame` precisa mostrar o mesmo estado nos 3 mapas. Passar estado atual via `TeleportData` ao trocar de mapa e re-aplicar no `ProgressTrackerController` no `PlayerAdded`/`LocalScript init`. |
| 10 | **Cards sem texto vs. UI do roteiro** | O roteiro pede cards "sem escrita, preço nem nada — só o pulo" na **animação de progresso** (ProgressTracker). A **JumpShop** pode mostrar stats por símbolos. São dois componentes distintos — não unificar. |
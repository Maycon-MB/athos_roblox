# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Contrato
Freelance PJ para Athos (criador de conteúdo Roblox). Dois projetos:
1. **Hub World** (`src/`) — placeId `79528061984127`
2. **Fábrica de Mapas** (`engine-template/` + `entregas/`) — pipeline 20+ entregas/mês

GitHub: `Maycon-MB/athos_roblox` · Branch: `main`

## Comandos

```bash
# Build de uma entrega (rodar dentro de entregas/YYYY-MM-DD_slug/)
rojo build default.project.json --output game_ready.rbxl

# Lint — zero erros obrigatório antes de qualquer commit
selene entregas/2026-04-02_escape-tsunami/src/

# Formatação
StyLua src/server/Engine/

# Toolchain gerenciado via aftman (aftman.toml na raiz)
# Binários: C:\Users\MayconBruno\.aftman\bin\
# Ferramentas registradas: rojo 7.7.0-rc.1 · selene 0.30.1 · StyLua 2.4.1
```

## Arquitetura

```
entregas/YYYY-MM-DD_slug/
  default.project.json          ← Rojo: mapa em ServerStorage, engine em SSS
  mapa_referencia.rbxm          ← Asset bruto do kit (quarentenado — nunca editar)
  game_ready.rbxl               ← Output do rojo build (não editar, não commitar manualmente)
  src/shared/Settings.lua       ← ÚNICO arquivo editado por roteiro (Lei de Hyrum)
  src/server/
    CoreEngine.server.lua       ← Orquestrador de boot — NÃO editar lógica aqui
    Engine/
      MapLoader.lua             ← Padrão Sandbox: clona + sanitiza + injeta mapa
      MapTagger.lua             ← Tags CollectionService por nome de peça (contains)
      PlayerData.lua            ← Estado do player + transações atômicas
      WaveSystem.lua            ← Onda tsunâmi
      BrainrotSystem.lua        ← Spawn/coleta/entrega de brainrots via ProximityPrompt
      JumpSystem.lua            ← Loja de pulos + CrackWall
      AdminSystem.lua           ← Comandos de admin via chat
      MobSystem.lua             ← NPCs (opcional, desativado se sem Mobs no SS)
  src/client/
    CoreClient.client.lua       ← Bootstrapper cliente
    UI/                         ← Painéis (StatusBar, JumpShop, ProgressPanel, etc.)

engine-template/src/            ← Cópia canônica dos módulos (referência imutável)
processor/                      ← watch.py + processor.py (automação PDF→ROTEIRO.md→build)
```

## Padrão Sandbox (arquitetura de mapa)

O mapa bruto fica em `ServerStorage.Assets.Maps.RawMap`. Nunca vai direto ao Workspace.
`MapLoader.setup()` retorna `Model?` e executa o pipeline antes de `clone.Parent = ws`:

1. **Wipe** — destrói `Script/LocalScript/ModuleScript` + Folders com "ServerScriptService" no nome
2. **Destroy barriers** — BaseParts com nomes `.` `line` `secret` `wall` `fence` `divider` são destruídas (`:Destroy()`, não transparência)
3. **Anchor** — toda BasePart restante: `Anchored=true`, `CanCollide=true`
4. **Inject** — `clone.Name = "GameMap"; clone.Parent = ws`

Scripts clonados de ServerStorage → Workspace **executam** no Roblox. O wipe deve acontecer antes do `Parent = ws`, não depois.

## Sequência de boot (CoreEngine)

```
MapLoader (captura gameMap: Model?)
  → MapTagger (tags CollectionService, contains match)
  → PlayerData → WaveSystem → BrainrotSystem → JumpSystem → AdminSystem → MobSystem
  → SetupCollections(gameMap)   ← Touched/Spatial em SafeZone-tagged parts
  → task.wait(1)
  → Spawn (RespawnLocation + LoadCharacter — física nativa)
```

`safeInit(name, fn)` — `pcall` em cada módulo; falha isolada não derruba o boot.

## Spawn — 3 prioridades

1. `gameMap:FindFirstChild("SpawnPoint", true)` — BasePart nomeada pelo dev (marcador manual)
2. `gameMap:FindFirstChildWhichIsA("SpawnLocation", true)` — SpawnLocation do kit preservada
3. Fallback: cria SpawnLocation em `Settings.SPAWN.POSITION` (Y = -86.1 calibrado)

Todos os caminhos terminam em `player.RespawnLocation = sl` + `player:LoadCharacter()`.

## Mandatos Técnicos (Enterprise / Zero Legacy)

### Proibido
- `wait()` `spawn()` `delay()` — use exclusivamente `task.wait()` `task.spawn()` `task.defer()`
- Lógica acoplada a instâncias (scripts dentro de moedas, portões, partes do mapa)
- Hardcodar dados de roteiro em Engine/* — apenas `Settings.lua` varia entre entregas

### Obrigatório
- `--!strict` em todo arquivo Luau
- Cast explícito antes de acessar propriedades: `obj :: BasePart`
- Arquitetura **Centralizada, Event-Driven, desacoplada**: toda lógica de gameplay em Engine/*
- `selene .` + `StyLua .` antes de cada commit; zero erros de lint

### APIs modernas (2025/2026)
- Prefer `GetPartBoundsInBox` / `GetPartsInPart` (Spatial Query) para detecção em área sobre `.Touched` em massa
- `BasePart.CollisionGroup = "GroupName"` (direto) — `PhysicsService:SetPartCollisionGroup()` está **depreciado**
- `player.RespawnLocation` + `LoadCharacter()` para spawn canônico
- `task.defer()` para diferir execução ao próximo frame sem criar nova thread pesada

### Fontes de referência (hierarquia)
1. **create.roblox.com/docs** — API oficial (fonte primária)
2. **luau-lang.org** — tipagem estática, performance nativa
3. **rojo.space / aftman / wally** — toolchain CI/CD
4. **Frameworks OSS**: Knit (Sleitnick), Nevermore (Quenty), ProfileService

## Settings.lua — contrato por roteiro

| Chave | Tipo | Uso |
|---|---|---|
| `TAG_MAP` | `{ [tag]: { string } }` | Nomes de peças → tags CollectionService (contains) |
| `WAVE` | table | Parâmetros da onda (INTERVAL, SPEED, RISE_HEIGHT, etc.) |
| `BRAINROTS` | `{ {id, name, rarity, income, color} }` | Items coletáveis |
| `SPAWN_WEIGHTS` | `{ number }` | Pesos de raridade (índice = rarity) |
| `RARITIES` | `{ [n]: {name, color} }` | Definição de raridades |
| `JUMPS` | `{ {id, label, jump, speed, cost_type, cost_value, ...} }` | Loja de pulos |
| `BASE` | `{SLOTS_DEFAULT, SLOTS_MAX}` | Slots do inventário |
| `SPAWN` | `{POSITION: Vector3}` | Coordenada XYZ do spawn (fallback se mapa sem SpawnLocation) |

`cost_type` válidos: `"free"` · `"money"` · `"survive_waves"` · `"kill_noobs"` · `"sell_brainrots"` · `"fuse_brainrots"`

## Regras de domínio (sob demanda)
→ `.claude/rules/luau-erros.md`
→ `.claude/rules/sistemas-recorrentes.md`
→ `.claude/rules/engine-contratos.md`
→ `.claude/rules/hub-world.md`
→ `.claude/rules/valores-calibrados.md`

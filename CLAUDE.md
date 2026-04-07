# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Contrato
Freelance PJ para Athos (criador de conteúdo Roblox). Dois projetos:
1. **Hub World** (`src/`) — placeId `79528061984127`
2. **Fábrica de Mapas** (`engine-template/` + `entregas/`) — pipeline automático

GitHub: `Maycon-MB/athos_roblox` · Branch: `main`

## Comandos

```bash
# Build de uma entrega (rodar dentro de entregas/YYYY-MM-DD_slug/)
rojo build default.project.json --output game_ready.rbxl

# Lint (zero erros obrigatório antes de commit)
selene entregas/2026-04-02_escape-tsunami/src/

# Formatação
StyLua src/server/Engine/

# Selene + StyLua gerenciados via aftman (aftman.toml na raiz)
# Binários ficam em: C:\Users\MayconBruno\.aftman\bin\
```

## Arquitetura

```
entregas/YYYY-MM-DD_slug/
  default.project.json          ← Rojo: mapa em ServerStorage, engine em SSS
  mapa_referencia.rbxm          ← Asset bruto do kit (quarentenado)
  game_ready.rbxl               ← Output do rojo build (não editar)
  src/shared/Settings.lua       ← ÚNICO arquivo editado por roteiro
  src/server/
    CoreEngine.server.lua       ← Orquestrador de boot (não editar)
    Engine/
      MapLoader.lua             ← Padrão Sandbox: clona + sanitiza mapa
      MapTagger.lua             ← Tags CollectionService por nome de peça
      PlayerData.lua            ← Dados do player + transações
      WaveSystem.lua            ← Onda tsunâmi
      BrainrotSystem.lua        ← Spawn/coleta/entrega de brainrots
      JumpSystem.lua            ← Loja de pulos + CrackWall
      AdminSystem.lua           ← Comandos de admin via chat
      MobSystem.lua             ← NPCs (opcional)
  src/client/
    CoreClient.client.lua       ← Bootstrapper cliente
    UI/                         ← Painéis de UI (StatusBar, JumpShop, etc.)

engine-template/src/            ← Cópia canônica dos módulos (referência)
processor/                      ← watch.py + processor.py (automação PDF→build)
```

## Padrão Sandbox (arquitetura de mapa)

O mapa bruto fica em `ServerStorage.Assets.Maps.RawMap` (nunca no Workspace direto).
`MapLoader.setup()` clona, executa o pipeline de limpeza e injeta como `GameMap`:

1. **Wipe** — destrói Script/LocalScript/ModuleScript + SpawnLocations do kit + Folders com "ServerScriptService" no nome
2. **Anchor** — toda BasePart: `Anchored=true`, `CanCollide=true`
3. **Barrier sanitize** — partes grandes (>100 studs) em modelos chamados Wall/Fence/Divider: `Transparency=0.5`, `CanCollide=false`
4. **Inject** — `clone.Parent = ws` (scripts não rodam pois foram destruídos antes)

## Sequência de boot (CoreEngine)

```
MapLoader → MapTagger → PlayerData → WaveSystem → BrainrotSystem →
JumpSystem → AdminSystem → MobSystem → task.wait(2) → Spawn
```

Cada módulo é protegido por `safeInit(name, fn)` — falha num módulo não derruba os demais.

## Mandatos Técnicos

1. **Plan Mode obrigatório** — mudanças em Engine/* ou CoreEngine exigem plano aprovado
2. **Lei de Hyrum** — lógica volátil em Settings.lua; Engine/* nunca hardcodeia dados do roteiro
3. **Governança de qualidade** — rodar `selene .` e `StyLua` antes de cada commit; zero erros
4. **Sem leitura de PDF** — usar sempre `entregas/.../ROTEIRO.md`
5. `--!strict` em todo Luau · `task.wait()` nunca `wait()` · cast explícito `obj :: BasePart`

## Settings.lua — contrato por roteiro

É o único ponto de variação entre entregas. Chaves esperadas:

| Chave | Tipo | Uso |
|---|---|---|
| `TAG_MAP` | `{ [tag]: { string } }` | Nomes de peças → tags CollectionService |
| `WAVE` | table | Parâmetros da onda (INTERVAL, SPEED, etc.) |
| `BRAINROTS` | `{ {id, name, rarity, income, color} }` | Items coletáveis |
| `SPAWN_WEIGHTS` | `{ number }` | Pesos de raridade (índice = rarity) |
| `RARITIES` | `{ [n]: {name, color} }` | Definição de raridades |
| `JUMPS` | `{ {id, label, jump, speed, cost_type, cost_value, ...} }` | Loja de pulos |
| `BASE` | `{SLOTS_DEFAULT, SLOTS_MAX}` | Slots do inventário |
| `SPAWN` | `{POSITION: Vector3}` | Coordenada XYZ do spawn do jogador |

`cost_type` válidos: `"free"` · `"money"` · `"survive_waves"` · `"kill_noobs"` · `"sell_brainrots"` · `"fuse_brainrots"`

## Regras de domínio (sob demanda)
→ `.claude/rules/luau-erros.md`
→ `.claude/rules/sistemas-recorrentes.md`
→ `.claude/rules/engine-contratos.md`
→ `.claude/rules/hub-world.md`
→ `.claude/rules/valores-calibrados.md`

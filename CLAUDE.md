# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Contrato
Freelance PJ para Athos (Roblox content creator). Dois projetos:
1. **Hub World** (`src/`) — placeId `79528061984127`
2. **Fábrica de Mapas** (`engine-template/` + `entregas/`) — pipeline 20+ entregas/mês

## Comandos
```bash
rojo serve default.project.json           # live-sync com Studio (rodar em entregas/SLUG/)
selene entregas/SLUG/src/                 # lint — zero erros antes de commit
StyLua src/server/Engine/
python processor/watch.py                 # PDF → pasta entrega completa
# Todos via aftman (C:\Users\MayconBruno\.aftman\bin\): rojo · selene · StyLua
```

## ⚠️ NUNCA rodar `rojo build`
Reconstrói o `.rbxl` apenas a partir de `default.project.json` — **destrói mapa + models + assets manuais do ServerStorage**.
Já causou perda permanente de assets (2026-04-19). Use sempre `rojo serve` + Studio salvar manualmente.

## Arquivo de jogo (escape-tsunami)
- **`em_manutencao.rbxl`** — place atual com mapa, models, ShopEntrance/ShopExit/BrainrotSpawn tags
- Único backup dos assets manuais → commitar regularmente após salvar no Studio

## Workflow de publicação no Roblox
1. Studio: `File → Open` → `em_manutencao.rbxl`
2. Terminal: `rojo serve` em `entregas/2026-04-02_escape-tsunami/`
3. Studio: aba Plugins → Rojo → Connect (porta 34872)
4. Testar com F5 (Play Solo)
5. **Ctrl+S no Studio** (grava code+assets no `.rbxl`)
6. Studio: `File → Publish to Roblox` → Athos Preview (placeId `79528061984127`)
7. Git: `git add em_manutencao.rbxl src/` + commit + push

## Arquitetura
```
entregas/YYYY-MM-DD_slug/
  default.project.json     ← Rojo: mapa→ServerStorage, engine→SSS, UI→StarterPlayer
  mapa_referencia.rbxm     ← asset bruto (nunca editar)
  src/shared/Settings.lua  ← ÚNICO arquivo editado por roteiro
  src/server/CoreEngine.server.lua  ← orquestrador (não adicionar lógica aqui)
  src/server/Engine/       ← MapLoader · MapTagger · PlayerData · WaveSystem
                              BrainrotSystem · JumpSystem · AdminSystem · MobSystem
  src/client/UI/           ← StatusBar · JumpShop · ProgressPanel · WaveAlert · AdminPanel
engine-template/src/       ← cópia canônica dos módulos (referência imutável)
```
Boot: `MapLoader → MapTagger → PlayerData → WaveSystem → BrainrotSystem → JumpSystem → AdminSystem → MobSystem → SetupCollections → Spawn`  
`safeInit(name, fn)` — pcall isolado; falha num módulo não derruba o boot.

## Mandatos Técnicos
- `--!strict` em todo arquivo Luau; cast explícito `obj :: BasePart`
- Proibido: `wait()` `spawn()` `delay()` → usar `task.*`; lógica acoplada a instâncias; hardcode em Engine/*
- **Lei de Hyrum / Ocultação de Informação**: encapsule lógicas voláteis em módulos isolados — refatorações não devem exigir edições em múltiplos arquivos
- **Princípio DAMP**: legibilidade > DRY; nomes descritivos, sem abstrações prematuras
- **Regra de Beyoncé**: bugs exigem teste — proponha plano de teste antes de codar a correção
- APIs: `GetPartBoundsInBox` sobre `.Touched` em massa; `BasePart.CollisionGroup` direto (PhysicsService depreciado)

## Fonte de Verdade
Especificação técnica: **XML meta-prompt** (não ROTEIRO.md). ROTEIRO.md = organização de pastas apenas.

## Workflow
**Mudanças não-triviais exigem Plan Mode.** Entre em Plan Mode → apresente o plano → aguarde aprovação explícita antes de escrever código.

## Regras de domínio (ler sob demanda)
→ `.claude/rules/bugs-pendentes.md` — 3 bugs + roadmap de 7 itens do XML (escape-tsunami)
→ `.claude/rules/meta-prompt-spec.md` — spec XML: módulos, tiers, validators, brainrots  
→ `.claude/rules/engine-contratos.md` — contratos de módulo + padrão sandbox + spawn  
→ `.claude/rules/settings-contrato.md` — tabela completa de chaves do Settings.lua  
→ `.claude/rules/sistemas-recorrentes.md` — BrainRots, JumpShop, Tsunami, Admin, NPCs, Fusão  
→ `.claude/rules/luau-erros.md` — erros e APIs depreciadas  
→ `.claude/rules/valores-calibrados.md` — valores calibrados (não reverter)  
→ `.claude/rules/hub-world.md` — Hub World layout e serviços

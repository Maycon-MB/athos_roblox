# Bugs Pendentes + Roadmap — escape-tsunami

Documentado em 2026-04-08. Atualizado em 2026-04-16.

---

## Bugs 1-4: N/A (WaveSystem reescrito)

Os bugs 1-4 foram documentados para o WaveSystem antigo que usava auto-discovery de bounds
(`findMapBounds()`, `getOrCreateWavePart()`, tags `TsunamiWater`/`Tsunami`).

**Na refatoração cinematográfica (2026-04-11)**, o WaveSystem foi reescrito do zero:
- Onda opera dentro de `MAP_AREAS.main` (bounds fixos, sem auto-discovery)
- Cria Part fresh a cada wave (sem buscar tag de mapa)
- Direção correta: +X → -X (do fim da área em direção ao spawn)
- SafeZone não interfere nos bounds (não existe mais `findMapBounds()`)
- `j.color` adicionado a todos os JUMPS em Settings.lua (Bug 3 resolvido)

**Estes bugs não se aplicam mais.**

---

## Roadmap — itens pendentes para o roteiro

### Implementado (Phases 1-4)
- [x] MapSystem (3 áreas fake: main/shop/base)
- [x] CoreEngine simplificado (sem MapLoader/MapTagger)
- [x] WaveSystem (MAP_AREAS.main, admin trigger)
- [x] BrainrotSystem (spawn em MAP_AREAS.main, carry, SafeZone, fusion)
- [x] MobSystem (spawn em MAP_AREAS.main)
- [x] AdminSystem expandido (teleport, give_jump, set_coins, god_mode, reset)
- [x] AdminPanel com seções (Areas, Economy, Jumps, Waves, Tools)
- [x] JumpShop + ProgressPanel + StatusBar + WaveAlert + AreaLabel
- [x] Settings reescrito (MAP_AREAS, CHALLENGES, name/color em JUMPS)

### Implementado (Phase 5 — 2026-04-16)
- [x] JumpShop redesign — warm dark + gold, cards 160×220, English, X button
- [x] ProgressPanel redesign — faixa vertical direita, iniciais, tween unlock
- [x] AdminPanel rewrite — F8 toggle, todas as seções em inglês, AutomaticCanvasSize
- [x] BasePanel — botão ✕ de fechar adicionado
- [x] FusionMachinePanel — seleção visual de 2 brainrots, inglês, popup de resultado
- [x] infinity_lucky_box adicionado a Settings.BRAINROTS (era referenciado mas indefinido)
- [x] MobSystem desativado no CoreEngine (noobs causavam travamento sem animação)
- [x] Texto todo em inglês em todos os painéis

### Pendente / Descartado
- ~~HudController~~ (tier visível no ProgressPanel — suficiente para câmera)
- ~~NPC wandering AI~~ (MobSystem desativado; admin dá jumps diretamente)
- ~~Recompensas visuais particles~~ (ParticleEmitter hearts/fire no HRP — baixa prioridade)
- ~~BaseSystem pedestais 3D~~ (BasePanel UI cobre o caso de uso do roteiro)

### Loja (MapSystem.setupShopArea) — FINALIZADA 2026-04-15
- [x] Chão Studs (Plastic, laranja)
- [x] Paredes Brick laranja + teto marrom escuro
- [x] Stall (pilares azuis + balcão vermelho) posicionado na metade traseira (cz+10)
- [x] NPC R6 branco/cabeça preta/olhos neon vermelhos atrás do balcão — sem nametag
- [x] Aura de chamas negras (Fire, quase preto/roxo)
- [x] 7 monitores YouTube SurfaceGui nas paredes
- [x] Silver YouTube buttons clonados do ServerStorage — 3 na parede traseira, 2 em cada lateral
- [x] Sinal "Youtuber Jump Shop" vermelho na entrada
- [x] CrackWall trigger para abrir JumpShop UI

### Descartado (desnecessário para roteiro)
- ~~EventBus~~ (comunicação direta funciona)
- ~~Validators separados~~ (admin bypassa via give_jump)
- ~~ChallengeSystem separado~~ (admin controla tudo)
- ~~DataStore~~ (memória suficiente para gravação)

---

## Contexto de arquivos relevantes
- Settings.JUMPS: `src/shared/Settings.lua` — 7 tiers com id, label, name, color, jump, speed, cost_type, cost_value
- JumpSystem: `src/server/Engine/JumpSystem.lua` — compra + aplicação de rewards
- BrainrotSystem: `src/server/Engine/BrainrotSystem.lua` — coleta, carry, sell, fuse
- MobSystem: `src/server/Engine/MobSystem.lua` — spawn de Noobs
- MapSystem: `src/server/Engine/MapSystem.lua` — 3 áreas + teleporte
- AdminSystem: `src/server/Engine/AdminSystem.lua` — painel de controle para gravação
- CoreEngine: `src/server/CoreEngine.server.lua` — boot sequence

# Bugs Pendentes + Roadmap — escape-tsunami

Documentado em 2026-04-08. Atualizado em 2026-04-12.

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

### Pendente
- [ ] BaseSystem.lua + BasePanel.lua — pedestais 3D + UI inventário
- [ ] HudController.lua — sprite do tier atual (canto inferior esquerdo)
- [ ] NPC wandering AI — `Humanoid:MoveTo()` em loop no MobSystem
- [ ] Recompensas visuais — ParticleEmitter hearts/fire no HRP
- [ ] FusionMachine UI completa — seleção visual de 2 brainrots

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

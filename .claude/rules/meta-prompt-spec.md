# Meta-Prompt Spec — Arquitetura XML

Fonte de verdade técnica para implementações. O XML `meta-prompt-escape-tsunami.xml` define módulos, tiers, brainrots e fluxos.
ROTEIRO.md serve apenas para organização de pastas.

## Abordagem Cinematográfica (2026-04-11)

**Paradigma atual**: cenários fake isolados, sem injeção de código em mapas de terceiros.
- Mapa original: gravação nativa apenas (sem código)
- 3 áreas fake (main/shop/base) criadas por MapSystem
- Admin Panel controla tudo para gravação
- Descartados: MapLoader, MapTagger, CORRIDOR/ZONES, auto-discovery

## Módulos XML (11 módulos, 0-10)

| # | XML | Engine Atual | Status |
|---|---|---|---|
| 0 | EventBus | comunicação direta via require | NÃO IMPLEMENTADO (desnecessário para roteiro) |
| 1 | TierConfig | Settings.JUMPS | ✅ implementado |
| 2 | PlayerDataService | PlayerData.lua | ✅ implementado |
| 3 | JumpShopService | JumpSystem.lua + JumpShop.lua (UI) | ✅ implementado |
| 4 | Validators (5 módulos) | inline em JumpSystem (admin bypassa) | PARCIAL — admin bypassa via give_jump |
| 5 | WaveMachineService | WaveSystem.lua | ✅ implementado (MAP_AREAS.main) |
| 6 | NpcService | MobSystem.lua | PARCIAL — spawn OK, falta wandering AI |
| 7 | FusionMachineService | inline em BrainrotSystem.lua | ✅ implementado (2 brainrots → fuse) |
| 8 | AdminService | AdminSystem.lua + AdminPanel.lua | ✅ implementado (expandido: teleport, give_jump, god_mode, etc.) |
| 9 | UI (3 componentes) | ver tabela abaixo | PARCIAL |
| 10 | BrainrotConfig + CashEngine | Settings.BRAINROTS + PlayerData income loop | ✅ implementado |

## UI — Módulo 9 (Cliente)

| XML | Engine Atual | Status |
|---|---|---|
| JumpShopUI | JumpShop.lua | ✅ implementado |
| HudController | — | NÃO IMPLEMENTADO |
| ProgressChecklist | ProgressPanel.lua | ✅ implementado (falta polish visual) |

### UI extras (não no XML, criados para cinematografia)
| Componente | Função |
|---|---|
| StatusBar.lua | Barra money/brainrot/jump/tokens |
| WaveAlert.lua | Banner de onda |
| WaveMachinePanel.lua | Painel proximity-based |
| AdminPanel.lua | Painel expandido para gravação |
| AreaLabel.lua | Overlay cinematográfico ao trocar área |

## Tabela de Tiers (XML Módulo 1)

| ID | Nome | WalkSpeed | JumpPower | costType | Condição | Recompensas extras |
|---|---|---|---|---|---|---|
| 1 | James | 16 | 50 | free | — | brainrot: Jamezini |
| 2 | JJ | 24 | 70 | money (5000) | — | brainrot: Mikey, wave_shield |
| 3 | Mana | 32 | 90 | money (500000) | — | particles: hearts, base_upgrade |
| 4 | Pdoro | 40 | 120 | survive_waves (10) | 10 pulos sem dano de onda | wave_tokens: 1000 |
| 5 | Matheus | 50 | 150 | kill_noobs (5) | matar 5 NPCs | brainrot: Glaciero x3, galaxy_bat |
| 6 | Caylus | 60 | 180 | sell_brainrots (10) | vender 10 Brainrots | brainrot: InfinityLuckyBox x3 |
| 7 | Athos | 80 | 250 | fuse_brainrots (2) | completar 1 fusão | particles: fire, fill_base |

## Validators (XML Módulo 4)

| Validator | Lógica | Implementação |
|---|---|---|
| CashValidator | `cash >= cost` → deduz | inline JumpSystem |
| WaveKillValidator | `waveJumpStreak >= 10` | campo `wavesSurvived` em PlayerData |
| NpcKillValidator | `npcKillCount >= 5` | campo `noobsKilled` em PlayerData |
| BrainrotSaleValidator | `brainrotSoldCount >= 10` | campo `brainrotsSold` em PlayerData |
| FusionValidator | `hasFused == true` | campo `brainrotsFused` em PlayerData |

**Nota**: Admin bypassa todos via `give_jump`. Validators separados são desnecessários para o roteiro.

## Brainrots (XML Módulo 10)

| Nome | Raridade | cashPerSec |
|---|---|---|
| Jamezini cakenini | Comum | 2 |
| Mikey | Lendário | 7000 |
| O Athos brainrot | Infinito | 999000000 |
| AthosBreinrotMutacaoFogo | Infinito | 999000000 |
| Glaciero infernati | Épico | 50000 |

## EventBus — Eventos Definidos (XML Módulo 0)

| Evento | Args | Status |
|---|---|---|
| TierPurchased | player, tierId | via RemoteEvent JumpPurchased |
| CashChanged | player, newAmount | via SyncData |
| WaveStarted | waveParams | via RemoteEvent WaveStarted |
| NpcKilled | player, npcInstance | não implementado |
| BrainrotSold | player, brainrotType, count | inline BrainrotSystem |
| FusionCompleted | player | inline BrainrotSystem |
| DamageTaken | player, source | inline WaveSystem |

**Nota**: EventBus formal desnecessário. Comunicação via RemoteEvents + require direto funciona para o escopo do roteiro.

## O que falta implementar para o roteiro

| Item | Prioridade | Motivo |
|---|---|---|
| BaseSystem + BasePanel | MÉDIA | Base aparece no vídeo com pedestais de brainrot |
| HudController | MÉDIA | Tier atual visível na câmera (canto inferior esquerdo) |
| NPC wandering AI | BAIXA | Noobs andando (visual de cena) |
| Recompensas visuais (particles) | BAIXA | hearts/fire no personagem (aparece na câmera) |
| FusionMachine UI | BAIXA | Cena de fusão precisa funcionar visualmente |

Items **descartados** (desnecessários para roteiro):
- EventBus (módulos se comunicam direto)
- Validators separados (admin bypassa tudo)
- DataStore persistence (memória suficiente)
- ChallengeSystem separado (admin dá jumps direto)

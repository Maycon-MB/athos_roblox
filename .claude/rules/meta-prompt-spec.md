# Meta-Prompt Spec — Arquitetura XML

Fonte de verdade técnica para implementações. O XML `meta-prompt-escape-tsunami.xml` define módulos, tiers, brainrots e fluxos.
ROTEIRO.md serve apenas para organização de pastas.

## Estrutura de Módulos (XML)

| Módulo | Responsabilidade |
|---|---|
| EventBus | Hub central de BindableEvents (lazy init). `fire(name, ...)` / `on(name, cb)` |
| TierConfig | Dados estáticos dos 7 tiers (sem lógica) |
| BrainrotConfig | Tabela de brainrots + CashEngine (loop task.wait(1) somando cashPerSec) |
| PlayerDataService | Source of truth dos dados do jogador (memória, DataStore opcional) |
| JumpShopService | Compras de tiers → Validator → applyTierRewards → EventBus "TierPurchased" |
| WaveMachineService | Controle de ondas + Wave Tokens + detecção de dano |
| NpcService | Spawn de Noobs com IA de wandering + knockback (GalaxyBat) |
| FusionMachineService | Exige 2 brainrots → destrói → dispara "FusionCompleted" |
| AdminService | `/admin` no chat → painel de gerenciamento |

## Tabela de Tiers

| ID | Nome | WalkSpeed | JumpPower | costType | Condição |
|---|---|---|---|---|---|
| 1 | James | 16 | 50 | FREE | — |
| 2 | JJ | 24 | 70 | CASH (5000) | — |
| 3 | Mana | 32 | 90 | CASH (500000) | reward: hearts + base upgrade |
| 4 | Pdoro | 40 | 120 | CUSTOM | 10 pulos consecutivos sem dano de onda |
| 5 | Matheus | 50 | 150 | CUSTOM | matar 5 NPCs Noobs |
| 6 | Caylus | 60 | 180 | CUSTOM | vender 10 Brainrots |
| 7 | Athos | 80 | 250 | CUSTOM | completar 1 fusão |

## Validators

Cada Validator é um ModuleScript com `validate(player) → boolean`:

| Validator | Lógica |
|---|---|
| CashValidator | `cash >= tier.cost` → deduz valor |
| WaveKillValidator | `waveJumpStreak >= 10` (reseta se tomar dano de onda) |
| NpcKillValidator | `npcKillCount >= 5` |
| BrainrotSaleValidator | `brainrotSoldCount >= 10` |
| FusionValidator | `hasFused == true` |

## Brainrots (XML)

| Nome | Raridade | cashPerSec |
|---|---|---|
| Jamezini cakenini | Comum | 2 |
| Mikey | Lendário | 7000 |
| O Athos brainrot | Infinito | 999000000 |
| AthosBreinrotMutacaoFogo | Infinito | 999000000 |
| Glaciero infernati | Épico | 50000 |

## EventBus — Eventos Definidos

| Evento | Args | Disparado por |
|---|---|---|
| TierPurchased | player, tierId | JumpShopService |
| CashChanged | player, newAmount | PlayerDataService |
| WaveStarted | waveParams | WaveMachineService |
| NpcKilled | player, npcInstance | NpcService |
| BrainrotSold | player, brainrotType, count | transação de venda |
| FusionCompleted | player | FusionMachineService |
| DamageTaken | player, source | WaveMachineService |

## Mapeamento XML → Engine Atual

| XML | Engine Atual |
|---|---|
| PlayerDataService | PlayerData |
| JumpShopService | JumpSystem |
| WaveMachineService | WaveSystem |
| TierConfig + BrainrotConfig | Settings.lua (JUMPS + BRAINROTS) |
| EventBus | não implementado (comunicação direta via require) |
| Validators | inline em JumpSystem |
| NpcService | MobSystem |
| FusionMachineService | inline em BrainrotSystem |

## UI (Cliente)

| Componente | Função |
|---|---|
| JumpShopUI | Menu da loja secreta — 7 tiers em grid, neon escuro |
| HudController | Barra de status — tênis/tier atual (canto inferior esquerdo) |
| ProgressChecklist | Painel central — 7 pulos com check verde ao comprar |

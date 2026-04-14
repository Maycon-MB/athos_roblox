# Status da Entrega — Escape do Tsunami
**Roteiro**: [AT-RB-L1352-260325]
**Deadline**: 2026-04-14 12:00
**Última atualização**: 2026-04-13 23h

---

## Contexto

Vídeo do Athos: "Escape do Tsunami Mas Posso Comprar PULO de YOUTUBERS!"
- **Mapa original** (Escape Waves For Brainmodz): gravação nativa, sem código nosso
- **2 cenários fake** no mesmo Place: Loja Secreta + Base Separada
- **Admin Panel** oculto controla tudo "em off" durante gravação

O roteiro NÃO exige sistema de ondas próprio — o Athos joga no mapa original pra isso.
Nossos cenários só precisam: loja de pulos + base com brainrots + HUD replicado.

---

## O que funciona (pronto)

| Sistema | Arquivo | O que faz |
|---|---|---|
| MapSystem | `Engine/MapSystem.lua` | Cria 2 áreas fake (shop/base) + teleporte via CFrame |
| JumpSystem | `Engine/JumpSystem.lua` | 7 tiers de pulo com compra + aplicação de stats |
| JumpShop UI | `UI/JumpShop.lua` | Interface da loja com 7 cards |
| AdminSystem | `Engine/AdminSystem.lua` | teleport, give_jump, set_coins, god_mode, reset |
| AdminPanel UI | `UI/AdminPanel.lua` | Painel com seções: Areas, Economy, Jumps, Tools |
| PlayerData | `Engine/PlayerData.lua` | Estado do jogador + income loop ($/s por brainrot) |
| BrainrotSystem | `Engine/BrainrotSystem.lua` | Spawn, coleta (E), carry, sell, fuse |
| ProgressPanel | `UI/ProgressPanel.lua` | Cards de progresso (ficam verdes ao comprar) |
| StatusBar | `UI/StatusBar.lua` | Barra: money / brainrots / jump / tokens |
| AreaLabel | `UI/AreaLabel.lua` | Overlay cinematográfico ao trocar área |
| Settings | `shared/Settings.lua` | Config central: JUMPS, BRAINROTS, MAP_AREAS, BASE |

## O que falta (trabalho pra amanhã 08:30-12:00)

### P0 — Crítico (aparece diretamente no vídeo)

| # | Item | Descrição | Estimativa |
|---|---|---|---|
| 1 | **BaseSystem + BasePanel** | Pedestais circulares na base + UI de inventário. Roteiro mostra base com brainrots gerando $/s | 45min |
| 2 | **HUD replicado** | StatusBar precisa parecer o HUD do jogo original (Image 2 do roteiro): botões Store/Trade/Index/VIP no canto, money bar embaixo | 30min |

### P1 — Importante (melhora a qualidade visual)

| # | Item | Descrição | Estimativa |
|---|---|---|---|
| 3 | **Particles (hearts/fire)** | ParticleEmitter no HRP ao comprar Mana (hearts) e Athos (fire) | 20min |
| 4 | **Wave Shield visual** | SelectionBox azul + atributo ShieldActive no player | 15min |
| 5 | **GalaxyBat** | Tool com knockback (VectorForce em raio de 10 studs) | 20min |

### P2 — Nice to have

| # | Item | Descrição | Estimativa |
|---|---|---|---|
| 6 | **NPC wandering** | Noobs andando com MoveTo em loop | 15min |
| 7 | **FusionMachine UI** | Seleção visual de 2 brainrots | 20min |

**Total estimado: ~2h45 de trabalho para ~3h30 disponíveis**

---

## Plano de Trabalho — 14/04 (08:30-12:00)

```
08:30  git pull + rojo serve + Studio aberto
08:35  #1 BaseSystem.lua (server) — pedestais + SafeZone na base
09:00  #1 BasePanel.lua (client) — grid de inventário + income/s
09:20  #2 HUD replicado — refinar StatusBar pra parecer original
09:50  #3 Particles — hearts/fire no HRP via JumpSystem rewards
10:10  #4 Wave Shield — visual + lógica inline
10:25  #5 GalaxyBat — Tool + knockback
10:45  #6 NPC wandering — MoveTo loop no MobSystem
11:00  #7 FusionMachine UI — seleção visual
11:20  Teste integrado no Studio (play test completo)
11:40  StyLua + selene (lint/format)
11:50  Commit final + push
12:00  Entrega
```

---

## Arquivos relevantes

```
entregas/2026-04-02_escape-tsunami/
  default.project.json          ← Rojo: o que vai pro Studio
  src/shared/Settings.lua       ← ÚNICO arquivo de config
  src/shared/Remotes.lua        ← Nomes dos RemoteEvents
  src/server/CoreEngine.server.lua  ← Boot: MapSystem → PlayerData → ... → MobSystem
  src/server/Engine/             ← Módulos do servidor
    MapSystem.lua   PlayerData.lua   JumpSystem.lua
    AdminSystem.lua BrainrotSystem.lua MobSystem.lua
    WaveSystem.lua  (não usado no roteiro — só se quiser testar)
  src/client/CoreClient.client.lua  ← Boot do cliente
  src/client/UI/                 ← Módulos de UI
    StatusBar.lua   JumpShop.lua   ProgressPanel.lua
    AdminPanel.lua  AreaLabel.lua  WaveAlert.lua
    WaveMachinePanel.lua

docs/
  meta-prompt-escape-tsunami-engine.xml  ← Spec XML (fonte de verdade)
```

## Spec do roteiro (PDF)

**7 pulos, nesta ordem:**

| # | Nome | Pulo | Speed | Custo | Recompensas | Cena do vídeo |
|---|---|---|---|---|---|---|
| 1 | James | 10 | 67 | FREE | Jamezini cakenini | Pega de graça, noob impressionado |
| 2 | JJ | 40 | 250 | 5k coins | Mikey + Wave Shield | Farma 5k, mostra base secreta |
| 3 | Mana | 90 | 400 | 500k coins | hearts + base upgrade | Farma com Mikey, escudo bloqueia onda |
| 4 | Pdoro | 140 | 600 | Pular 10 ondas | 10k wave tokens | Pula ondas, noobs morrem |
| 5 | Matheus | 170 | 800 | Matar 5 noobs | 3x Glaciero + GalaxyBat | Mata noobs com máquina de ondas |
| 6 | Caylus | 200 | 2000 | Vender 10 brainrots | 3x Infinity Lucky Box | Trolla noobs, vende tudo |
| 7 | Athos | 250 | 2500 | Fundir 2 brainrots | Base cheia de Athos brainrot + fire | Fusão + base explode de riqueza |

**Nota**: Os valores de Jump/Speed do PDF divergem um pouco do que está no Settings.lua atual. Os valores atuais no Settings.lua foram calibrados para gameplay — não são exatamente os do PDF.

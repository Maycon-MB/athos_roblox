# Bugs Pendentes + Roadmap — escape-tsunami

Documentado em 2026-04-08. Tudo pronto para implementar em casa.

---

## Bugs Conhecidos (corrigir primeiro)

### Bug 4 — Wave vai no sentido errado (start→end em vez de end→start)
- **Arquivo**: `entregas/2026-04-02_escape-tsunami/src/server/Engine/WaveSystem.lua` linhas 133-135 e 211-214
- **Sintoma**: onda sai de trás do jogador (lado minX ≈ -1272 = spawn) e vai para frente — jogador não precisa fugir
- **Causa**: `startX = minX - 20` + movimento `+speed*dt` fazem a onda ir de minX→maxX. Mas o player spawna perto de minX, então a onda começa onde o jogador já está.
- **Contexto de mapa (Play mode medido)**:
  - X: -1272 → 1045 (len=2317) — eixo longo = fuga
  - Player spawn em X≈-1084 (perto de minX)
  - Onda deve COMEÇAR em maxX+20 ≈ 1065 e MOVER em direção a minX (sentido negativo)
- **Fix** (3 linhas em `startWave()`):
  ```lua
  -- linha ~133: trocar
  local startX  = minX - 20
  local endX    = maxX + 20
  -- por
  local startX  = maxX + 20   -- começa atrás do fim do mapa
  local endX    = minX - 20   -- termina antes do início (onde player spawna)
  
  -- linha ~214: trocar
  local newX = wave.Position.X + speed * dt
  -- por
  local newX = wave.Position.X - speed * dt
  
  -- linha ~215: trocar
  if newX >= endX then
  -- por
  if newX <= endX then
  
  -- linha ~228: trocar (reset position)
  wave.CFrame = CFrame.new(startX, wave.Position.Y, wave.Position.Z)
  -- já está correto pois startX agora = maxX+20
  ```



### Bug 1 — Wave usa parede genérica em vez do modelo do mapa
- **Arquivo**: `entregas/2026-04-02_escape-tsunami/src/server/Engine/WaveSystem.lua` linha 90
- **Causa**: `getOrCreateWavePart()` busca tag `"TsunamiWater"` mas MapTagger aplica `"Tsunami"`
- **Sintoma**: sempre cria parede azul de fallback, ignora o modelo de água do kit
- **Fix**:
  ```lua
  -- linha 90: trocar
  for _, obj in CollectionService:GetTagged("TsunamiWater") do
  -- por
  for _, obj in CollectionService:GetTagged("Tsunami") do
  ```

### Bug 2 — Wave começa/termina na posição errada
- **Arquivo**: `entregas/2026-04-02_escape-tsunami/src/server/Engine/WaveSystem.lua` linhas 21–62
- **Causa**: `findMapBounds()` inclui partes tagueadas como `SafeZone` no cálculo dos limites Z, distorcendo startZ/endZ
- **Sintoma**: onda começa muito antes ou muito depois do mapa
- **Fix**: adicionar no loop de `findMapBounds()`, logo após os checks de `TsunamiWater`:
  ```lua
  if CollectionService:HasTag(bp, "SafeZone") then
      continue
  end
  ```

### Bug 3 — JumpShop não renderiza nenhum card
- **Arquivo**: `entregas/2026-04-02_escape-tsunami/src/client/UI/JumpShop.lua` linha 62
- **Causa**: `card.BackgroundColor3 = j.color` — Settings.JUMPS não tem campo `color` → nil → crash silencioso → loop aborta antes de criar qualquer card
- **Sintoma**: loja abre vazia
- **Fix**:
  ```lua
  -- linha 62: trocar
  card.BackgroundColor3 = j.color
  -- por
  card.BackgroundColor3 = j.color or Color3.fromRGB(80, 80, 80)
  ```

---

## Roadmap do XML (itens não implementados)

Ordem sugerida de implementação após corrigir os bugs acima.

### 3. EventBus
- **O que é**: hub central de BindableEvents (lazy init) — elimina require direto entre módulos para eventos
- **Criar**: `src/server/Engine/EventBus.lua`
- **API**:
  ```lua
  EventBus.fire("NomeDоEvento", arg1, arg2)
  EventBus.on("NomeDoEvento", function(arg1, arg2) ... end)
  ```
- **Eventos definidos no XML**: `TierPurchased`, `CashChanged`, `WaveStarted`, `NpcKilled`, `BrainrotSold`, `FusionCompleted`, `DamageTaken`

### 4. Validators (5 módulos)
- **Criar pasta**: `src/server/Engine/Validators/`
- **Módulos**:
  - `CashValidator.lua` — `cash >= cost` → deduz valor
  - `WaveKillValidator.lua` — `waveJumpStreak >= 10` (reseta ao tomar dano de onda)
  - `NpcKillValidator.lua` — `npcKillCount >= 5`
  - `BrainrotSaleValidator.lua` — `brainrotSoldCount >= 10`
  - `FusionValidator.lua` — `hasFused == true`
- **Integração**: JumpSystem delega `validate(player)` para o Validator correto por `costType`

### 5. Recompensas completas por tier
Atualmente JumpSystem aplica `WalkSpeed` e `JumpPower`. Faltam:

| Tier | Recompensa faltante |
|---|---|
| 3 Mana | ParticleEmitter `"hearts"` no HRP + upgrade de slots da base |
| 4 Pdoro | `d.waveTokens += 1000` |
| 5 Matheus | Spawn "Glaciero infernati" na base + dar Tool "GalaxyBat" |
| 6 Caylus | Dar item "InfinityLuckyBox" |
| 7 Athos | ParticleEmitter `"fire"` no HRP + preencher base com "AthosBreinrotMutacaoFogo" + cashPerSec = 999000000 |

### 6. FusionMachine (fluxo completo)
- ProximityPrompt no objeto "FusionMachine" no mapa
- Servidor: lê inventário do player → exige 2 brainrots quaisquer → remove ambos → dispara `EventBus.fire("FusionCompleted", player)`
- Se inventário insuficiente: retorna feedback de erro ao cliente via RemoteEvent
- Desbloqueia Tier 7 (Athos) via `FusionValidator`

### 7. NPC wandering AI
- **Arquivo atual**: `src/server/Engine/MobSystem.lua`
- Adicionar loop `Humanoid:MoveTo()` com destino aleatório em cada Noob
- Knockback: RemoteEvent `"ApplyKnockback"` → `BodyVelocity` temporária no RootPart do Noob
- Noobs também morrem por dano da onda (Spatial Query ou Touched)

### 8. HudController (cliente)
- **Criar**: `src/client/UI/HudController.lua`
- Frame fixo no canto inferior esquerdo
- `ImageLabel` com sprite do tier atual
- Escuta RemoteEvent `"TierChanged"` → Tween de scale pulse ao trocar tier

### 9. ProgressChecklist (cliente)
- **Criar**: `src/client/UI/ProgressChecklist.lua`
- Painel central com 7 linhas (uma por tier): ícone + nome + estado
- Ao comprar tier: anima item → verde com checkmark
- Exibe por 3s com Tween de entrada/saída ao comprar; abre manualmente via botão no HUD
- Estado persistente: ao reabrir reflete todos os tiers já comprados

---

## Contexto de arquivos relevantes
- Settings.JUMPS: `src/shared/Settings.lua` — 7 tiers com `id, label, jump, speed, cost_type, cost_value`
- JumpSystem: `src/server/Engine/JumpSystem.lua` — onde Validators serão integrados
- BrainrotSystem: `src/server/Engine/BrainrotSystem.lua` — FusionMachine e cashPerSec vivem aqui
- MobSystem: `src/server/Engine/MobSystem.lua` — wandering AI vai aqui
- CoreEngine: `src/server/CoreEngine.server.lua` — EventBus.init() entra no boot

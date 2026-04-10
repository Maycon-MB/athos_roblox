# Contratos de Interface — Engine Modules

## Lei de Hyrum aplicada
Nenhum módulo Engine/* lê outro módulo Engine/* diretamente no topo do arquivo.
Use `require(script.Parent.X)` dentro de funções para evitar ciclos e acoplamento em init.

## Contratos públicos por módulo

### PlayerData
```
.get(player)              → any (dados mutáveis, não copiar)
.sync(player)             → void (dispara SyncData ao cliente)
.addMoney(player, n)      → void
.addBrainrot(player, id, qty?) → void
.removeBrainrot(player, id) → boolean
.countBrainrots(player)   → number
.unlockJump(player, id)   → void
.hasJump(player, id)      → boolean
.init(Settings)           → void
```

### WaveSystem
```
.startWave(speed?, killer?) → void  (idempotente: ignora se waveActive)
.init(Settings)             → void
```

### BrainrotSystem / JumpSystem / AdminSystem
```
.init(Settings) → void   (único ponto de entrada)
```

### MapTagger
```
.init(TAG_MAP) → void   (executa uma vez no boot; DescendantAdded mantém ativo)
```

## Regras de extensão
- Novo sistema recorrente → novo arquivo em `Engine/` + linha em `CoreEngine.server.lua`
- Novo dado de roteiro → nova chave em `Settings.lua` + leitura via `cfg.CHAVE` no módulo correspondente
- **Nunca** adicionar lógica de negócio em CoreEngine.server.lua — ele é só orquestrador

## Padrão Sandbox (MapLoader)

O mapa bruto fica em `ServerStorage.Assets.Maps.RawMap`. Nunca vai direto ao Workspace.
`MapLoader.setup()` retorna `Model?` e executa o pipeline antes de `clone.Parent = ws`:

1. **Wipe** — destrói `Script/LocalScript/ModuleScript` + Folders com "ServerScriptService" no nome
2. **Destroy barriers** — BaseParts com nomes `.` `line` `secret` `wall` `fence` `divider` são destruídas
   - **Exceção**: `vipwalls`/`vipwall` são preservadas (parede CrackWall da JumpShop)
   - **Exceção**: partes com `Size.X > 8 AND Size.Z > 8` são preservadas (pisos/plataformas)
3. **Anchor** — toda BasePart restante: `Anchored=true`, `CanCollide=true`; Transparency ≥ 0.95 → zerada
4. **Inject** — `clone.Name = "GameMap"; clone.Parent = ws`

O wipe deve acontecer **antes** do `Parent = ws` — scripts clonados para Workspace executam imediatamente.

## Spawn — 3 prioridades (CoreEngine)

1. `gameMap:FindFirstChild("SpawnPoint", true)` — BasePart nomeada pelo dev (marcador manual)
2. `gameMap:FindFirstChildWhichIsA("SpawnLocation", true)` — SpawnLocation do kit preservada
3. Fallback: cria SpawnLocation em `Settings.SPAWN.POSITION` (Y = -86.1 calibrado)

Todos os caminhos terminam em `player.RespawnLocation = sl` + `player:LoadCharacter()`.

## SetupCollections (inline em CoreEngine)

Não é um módulo separado. Roda após todos os sistemas, varre `CollectionService:GetTagged("SafeZone")`.

- **Permanentes** (protegem do tsunami, não consumidas): `SafeZone`, `Shelter`, `Cosmic`, `Mythical`
- **Consumíveis** (coletadas por Spatial Query): `Common`, `Uncommon`, `Rare`, `Epic`, `Legendary`, `Secret`

Usa `GetPartBoundsInBox` + Raycast de confirmação (HRP → baixo) para evitar falsos positivos laterais.

## Remotes (src/shared/Remotes.lua)

| Nome | Direção | Uso |
|---|---|---|
| `SyncData` | Server→Client | Atualiza estado do player na UI |
| `BuyJump` | Client→Server | Requisição de compra de pulo |
| `JumpPurchased` | Server→Client | Confirma compra, atualiza ProgressPanel |
| `WaveStarted` / `WaveSurvived` | Server→Client | Alerta de onda + contagem |
| `UseWaveToken` | Client→Server | Ativa máquina de ondas |
| `SellBrainrot` / `FuseBrainrots` | Client→Server | Transações de brainrot |
| `ShowShop` | Server→Client | Abre JumpShop ao tocar CrackWall |
| `AdminCmd` / `AdminResp` | Bidirecional | Painel de admin |

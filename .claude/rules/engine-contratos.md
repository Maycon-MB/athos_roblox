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

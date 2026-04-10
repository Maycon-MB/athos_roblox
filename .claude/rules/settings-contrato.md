# Settings.lua — Contrato por Roteiro

O único arquivo editado entre entregas. Toda lógica de negócio lê de `cfg.CHAVE`; nunca hardcode em Engine/*.

| Chave | Tipo | Uso |
|---|---|---|
| `TAG_MAP` | `{ [tag]: { string } }` | Nomes de peças → tags CollectionService (contains match) |
| `WAVE` | table | Parâmetros da onda: INTERVAL, SPEED, SPEED_MAX, HOLD_TIME, RECEDE_MULT, TAG_WATER, TAG_SAFEZONE |
| `BRAINROTS` | `{ {id, name, rarity, income, color} }` | Items coletáveis |
| `BRAINROT_ZONE` | table | Z_MIN, Z_MAX, X_RANGE, Y, MAX, RATE — área de spawn de brainrots |
| `SPAWN_WEIGHTS` | `{ number }` | Pesos de raridade (índice = rarity level) |
| `RARITIES` | `{ [n]: {name, color} }` | Definição de raridades (1=Common … 7=Infinity) |
| `JUMPS` | `{ {id, label, jump, speed, cost_type, cost_value, …} }` | Loja de pulos |
| `BASE` | `{SLOTS_DEFAULT, SLOTS_MAX}` | Slots do inventário |
| `SPAWN` | `{POSITION: Vector3}` | Coordenada XYZ do spawn (fallback se mapa sem SpawnLocation) |

## cost_type válidos para JUMPS
`"free"` · `"money"` · `"survive_waves"` · `"kill_noobs"` · `"sell_brainrots"` · `"fuse_brainrots"`

## Campos opcionais de JUMPS
| Campo | Efeito |
|---|---|
| `particles` | `"hearts"` ou `"fire"` — ParticleEmitter no HRP |
| `brainrot` + `brainrot_qty` | Adiciona brainrot ao inventário na compra |
| `fill_base` | Preenche todos os slots da base com brainrot especial |
| `wave_tokens` | Adiciona tokens à máquina de ondas |
| `extra = "wave_shield"` | Ativa `d.hasShield = true` |
| `base_upgrade` | Expande slots para `BASE.SLOTS_MAX` |

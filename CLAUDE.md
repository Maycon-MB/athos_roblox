# CLAUDE.md — Contexto do Projeto Athos Hub (Roblox)

## Publicação

- **PlaceId:** `79528061984127`
- **URL do jogo:** https://www.roblox.com/pt/games/79528061984127/Athos-Preview
- **Experiência:** Athos Preview (Privado por padrão — tornar Público para testes do cliente)
- **GitHub:** https://github.com/Maycon-MB/athos_roblox

---

## Objetivo do Projeto

Hub world profissional para o criador de conteúdo **Athos** no Roblox.
Este preview define se o contrato PJ será fechado. A meta é nota **10/10**.

O Athos quer:
1. Um hub server profissional e visualmente impressionante
2. Suporte técnico para gravações (modificar mapas/personagens)
3. Demandas contínuas de app/programação

---

## Framework de Arquitetura — 6 Módulos (versão atual)

### Módulo 1 — Core & Lifecycle Management

- **Rojo + Git**: sincronização VS Code ↔ Roblox Studio via Rojo; versionamento com Git
- **`--!strict`** em todos os scripts Luau, sem exceção
- **`export type`** para interfaces de dados — código resiliente e fácil de depurar
- **Janitor/Maid Pattern**: limpar explicitamente conexões de eventos, loops e Tweens ao destruir modelos para evitar memory leaks
- **Organização por pastas**: `Environment`, `Structures`, `Borders`, `Gameplay` no workspace
- **Ancoragem global**: função utilitária que percorre modelos e garante `Anchored = true` em todas as partes estáticas

### Módulo 2 — Security & Networking (Zero Trust)

- **Sanitização de Remotes**: nenhum RemoteEvent permite que o cliente faça mudanças estruturais sem validação total no servidor
- **Magnitude Check**: servidor valida `(Player.Position - Object.Position).Magnitude < MaxDistance` antes de processar interações (portas, compras)
- **Sincronização de Estado**: efeitos visuais/animações processados no cliente (fluidez); lógica de estado (posse de itens, progressão) exclusivamente no servidor

### Módulo 3 — Layout Estratégico e Fluxo do Jogador

- **Escala**: 250×250 studs (MAP_HALF = 125)
- **Spawn no canto NW** (-70, 2, -70): guia o jogador a atravessar o cenário e descobrir recursos progressivamente
- **Spawn orientation**: `CFrame.new(pos, lookAt)` — jogador nasce olhando para o centro do hub (0, 2, 0)
- **Archimedes Logic**: 48 segmentos de ângulo constante, raio 55 — nunca alterar o ângulo durante uma seção
- **Hierarquia de caminhos**:
  - Caminho circular principal (48 segs + postes a cada 6)
  - Grand Pathway de alto contraste (mármore diagonal hub → portais)
- **Propósito distinguível**: objetivo do jogo claro visualmente ao carregar, sem texto explicativo excessivo

### Módulo 4 — Estética, Filler e Ambientação

- **Fix de iluminação imediato**: sobrescrever a iluminação padrão do Roblox; evitar saturação e vibrant colors que cansem a visão
- **Originalidade arquitetônica**: sem formato de bloco, sem Suburban/Treehouse clássicos; visão moderna com profundidade e detalhes
- **Metodologia Large-to-Small**:
  - Fase 1: elementos grandes (árvores e rochas maiores) nas bordas — seed 42 para reprodutibilidade
  - Fase 2: detalhes menores (pedras, grama) ao redor dos grandes
- **Transições suaves**: rochas na base de elevações de terreno
- **Variedade de cor**: cachoeiras (azul) para quebrar monotonia de verde e marrom
- **Bordas robustas**: muros com topo duplicado para aspecto de projeto completo

### Módulo 5 — Monetização, UX e Interatividade

- **Hub de Spawn de alta conversão** agrupa perto do spawn:
  - Leaderboard (torre), Wheel Spin (giro grátis), Loja (Shop), Starter Eggs
- **Psicologia de receita**: Titanic Pet (ou equivalente premium) constantemente visível no spawn para incentivar monetização imediata
- **CollectionService (Tags)**: gerenciar objetos interativos (botões, lixeiras, portais) de forma centralizada e performática
- **Segregação VIP**: portal VIP em zona distinta e levemente afastada — transmitir exclusividade

### Módulo 6 — Performance e Observabilidade

- **StreamingEnabled**: ativo para suportar mobile
- **`task.wait()`** em vez de `wait()` em todos os scripts
- **Singleton Pattern**: todos os sistemas via ModuleScripts; sem scripts soltos
- **ProfileService com Session Locking**: integridade de dados, sem duplicação de itens
- **Telemetria / Analytics**: monitorar comportamento do jogador; testes A/B para posicionamento de itens; heatmaps para identificar zonas mortas
- **Áudio espacial**: SoundGroups com reverberação e equalização dinâmica por localização do jogador

---

## Arquitetura de Código

```
src/
├── shared/
│   ├── GameConfig.luau       — constantes centralizadas
│   └── RemoteNames.luau      — nomes de RemoteEvents
├── server/
│   ├── RemoteSetup.server.luau
│   ├── Main.server.luau      — boot: Lighting → Folder → Map → Spawn
│   └── Services/
│       ├── FolderService.luau
│       ├── LightingService.luau
│       ├── AnimationService.luau
│       ├── MapService.luau
│       └── SpawnService.luau
└── client/
    ├── Main.client.luau
    └── Controllers/
        └── CharacterController.luau
```

**Ordem de boot:**
```
LightingService.init() → FolderService.init() → MapService.init() → SpawnService.init()
```

---

## AnimationService — API

```lua
AnimationService.rotate(part, radiansPerSec)    -- rotateY: halos, wheel spin
AnimationService.rotateZ(part, radiansPerSec)   -- rotateZ: portais (efeito vórtice)
AnimationService.float(part, amplitude, speed)  -- bobbing senoidal: eggs, pets
```

---

## Valores Calibrados (não reverter)

| Parâmetro | Valor correto | Motivo |
|---|---|---|
| `pe.LightEmission` | `0.18` | 0.85 inundava o mapa de luz cyan |
| Portal PointLight range | `16` | 35+ causava overflow de luz |
| VIP Portal PointLight range | `18` | idem |
| Waterfall PointLight range | `12` | idem |
| Particle rate portais | `6` | mais que isso fica poluído |
| Bloom Intensity | `0.35` | suave, sem machucar os olhos |
| Bloom Threshold | `0.92` | só realça neons fortes |
| `Lighting.Technology` | **NÃO SETAR** | RobloxScript não tem permissão — erro fatal |
| `ShadowIntensity` em PointLight | **NÃO USAR** | propriedade inexistente — erro fatal |

---

## GameConfig Atual

```lua
MAP_HALF      = 125      -- mapa 250×250 studs
WALL_HEIGHT   = 30
PATH_RADIUS   = 55
PATH_SEGMENTS = 48
PATH_WIDTH    = 14
SPAWN_POSITION    = Vector3.new(-70, 2, -70)   -- canto NW, y=2 no chão
PORTAL_AREA_POS   = Vector3.new(70, 0, 70)     -- canto SE
VIP_PORTAL_POS    = Vector3.new(108, 0, 50)    -- leste (exclusivo)
SPAWN_SHIELD_SEC  = 3
BORDER_SEED  = 42
TREE_COUNT   = 60
ROCK_COUNT   = 40
```

## Layout v3 (hub no centro, gateway de entrada, jardim interno)

```
NW (-70,-70): Spawn — nasce aqui, olha para (0,2,0)
(-44,-44):    Gateway ATHOS HUB — 2 colunas mármore + arco neon dourado + placa
CENTRO (0,0): Hub platform (3 camadas: cobblestone → pedra → mármore, trim NEON dourado)
  - (0,0):    Fountain — 3 camadas, ~27 studs, canteiros de flores nas 4 direções
  - (+28,+5): Leaderboard Tower — LESTE do hub (não bloqueia vista da fonte)
  - (+22,-22): Loja A-frame — NE (à direita ao entrar)
  - (-24,+20): Wheel Spin — SW (CollectionService tag "WheelSpin", ProximityPrompt)
  - (+24,+20): Starter Eggs — SE
  - (0,+28):  Titanic Pet — Sul (3 halos concêntricos)
  - 4 cantos: Pilares decorativos com luz quente
  - 3 bancos: ao redor da fonte (E, W, N)
RAIO 44:      Jardim interno — 6 pequenas árvores + rochas (sem NW = corredor de entrada)
RAIO 55:      Caminho circular Archimedes (48 segmentos + 8 postes de luz)
DIAGONAL:     Grand Pathway mármore (hub → portais)
SE (70,70):   Portal Area — 3 portais (Floresta/Oceano/Deserto), colunas
E (108,50):   VIP Portal — plataforma 3 camadas, arco dourado
```

## Novos Serviços (v3)

- `SoundService.luau` — áudio espacial: hub music + fountain water + portal hum + VIP ambient
- `WheelService.luau` — ProximityPrompt "Girar", magnitude check 18 studs, cooldown 30s, CollectionService tag "WheelSpin"; entrega coins em leaderstats e dispara WHEEL_REWARD
- `CinematicController.luau` (client) — câmera panorâmica 3 fases ao nascer (4.2s total, TweenService)
- `NotificationController.luau` (client) — popup animado de recompensa do Wheel Spin; slide-in + fade-out, cores por tier

---

## Histórico de Erros Resolvidos

- `Lighting.Technology` → remover a linha; RobloxScript não tem permissão
- `ShadowIntensity is not a valid member of PointLight` → propriedade inexistente, remover
- Fonte aparecia como cruz (`+`) → substituir 4 bordas por base sólida única
- Portais girando como porta → trocar `rotateY` por `rotateZ` nos rings
- Mapa inundado de luz cyan → calibrar LightEmission (0.18) e ranges (12-18)
- Hub dentro do spawn → mover centro de (-70,-70) para (0,0); spawn continua em NW

---

## Backlog (Módulo 6 — próximos passos)

- [x] `task.wait()` em vez de `wait()` — todos os scripts usam task.wait/task.delay
- [x] Câmera de abertura no cliente (CinematicController — 3 fases, 4.2s)
- [x] Áudio espacial: SoundService (hub music + fountain + portals + VIP)
- [x] CollectionService para objetos interativos (WheelSpin tag)
- [x] Magnitude check em interações (WheelService, 18 studs)
- [x] Notificação de recompensa na tela (NotificationController)
- [x] Leaderstats (Coins) criados no SpawnService

- [x] Grama alta eliminada — base terrain alterada para Ground; diagonais spawn→hub e hub→portais cobertas
- [x] WheelService entrega Coins em leaderstats + dispara RemoteEvent para NotificationController
- [x] NotificationController: popup slide-in/fade-out com cores por tier de recompensa

- [ ] ProfileService para persistência de dados de jogador (Coins entre sessões)
- [ ] SoundIds de música — Studio → Toolbox → Audio → criador "Roblox" → MUSIC_CANDIDATES em SoundService.luau
- [ ] StreamingEnabled ativo (Studio → Game Settings → Rendering → StreamingEnabled)
- [ ] Telemetria básica (heatmap de posições, tempo médio em cada POI)

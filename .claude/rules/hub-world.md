# Hub World — Referência Técnica

## PlaceId e URLs
- PlaceId: `79528061984127`
- URL: https://www.roblox.com/pt/games/79528061984127/Athos-Preview
- Experiência: Athos Preview (tornar Público para testes do cliente)

## Layout v3
```
NW (-70,-70):  Spawn — nasce olhando para (0,2,0)
(-44,-44):     Gateway ATHOS HUB — colunas mármore + arco neon dourado
CENTRO (0,0):  Hub platform (3 camadas, trim neon dourado)
  (0,0):       Fountain 3 camadas ~27 studs + flores
  (+28,+5):    Leaderboard Tower (leste)
  (+22,-22):   Loja A-frame (NE)
  (-24,+20):   Wheel Spin (SW, tag "WheelSpin", ProximityPrompt)
  (+24,+20):   Starter Eggs (SE)
  (0,+28):     Titanic Pet (sul, 3 halos)
RAIO 44:       Jardim interno — 6 árvores + rochas
RAIO 55:       Caminho circular Archimedes (48 segs + 8 postes)
SE (70,70):    Portal Area — 3 portais (Floresta/Oceano/Deserto)
E (108,50):    VIP Portal — plataforma 3 camadas, arco dourado
```

## Boot do servidor
```
LightingService → FolderService → MapService → SpawnService → SoundService → WheelService
```

## Serviços
- `MapService.luau` — gera todo o mapa proceduralmente
- `SpawnService.luau` — spawn NW + leaderstats (Coins)
- `SoundService.luau` — áudio espacial (rbxasset:// para fonte/portais)
- `WheelService.luau` — magnitude check 18 studs, cooldown 30s, CollectionService tag
- `AnimationService.luau` — rotate/rotateZ/float via Heartbeat
- `LightingService.luau` — iluminação calibrada + bloom suave
- `FolderService.luau` — cria pastas Environment/Structures/Borders/Gameplay

## Cliente
- `CinematicController.luau` — câmera panorâmica 3 fases (4.2s)
- `NotificationController.luau` — popup de recompensa com cores por tier
- `CharacterController.luau` — visual temático do personagem

## GameConfig
```
MAP_HALF=125  WALL_HEIGHT=30  PATH_RADIUS=55  PATH_SEGMENTS=48  PATH_WIDTH=14
SPAWN=(-70,2,-70)  PORTAL_AREA=(70,0,70)  VIP_PORTAL=(108,0,50)
BORDER_SEED=42  TREE_COUNT=60  ROCK_COUNT=40
```

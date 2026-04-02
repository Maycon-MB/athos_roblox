# Erros Luau/Roblox a Evitar

## Propriedades inexistentes
- `Lighting.Technology` — sem permissão em RobloxScript
- `ShadowIntensity` em PointLight — não existe
- `LightEmission > 0.18` em ParticleEmitter — inunda o mapa de luz
- `PointLight.Range > 18` — overflow de luz

## APIs depreciadas
- `wait()` → usar `task.wait()`
- `spawn()` → usar `task.spawn()`
- `delay()` → usar `task.delay()`

## Strict mode
- Todo arquivo começa com `--!strict`
- Nunca usar `any` em assinaturas públicas de módulo — só em `_cfg` interno
- Cast explícito: `obj :: BasePart` antes de acessar propriedades de BasePart

## Rojo / Studio
- Scripts do kit importado em ServerScriptService devem ser deletados antes de testar
- `FindFirstChild("X")` só busca filhos diretos — usar `(obj, true)` para recursivo
- SpawnLocation do Roblox tem prioridade sobre teleporte manual — reposicionar via script

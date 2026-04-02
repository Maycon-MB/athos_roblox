# CLAUDE.md — Athos Roblox

## Contrato
Freelance PJ: recriar jogos Roblox + modificações por roteiro. Privado, só para gravação.
Prazo: **2 dias/entrega**. Conteúdo infantil. GitHub: Maycon-MB/athos_roblox

## Arquitetura — Fábrica de Mapas
```
entregas/YYYY-MM-DD_nome/
  src/shared/Settings.lua          ← ÚNICO arquivo alterado por roteiro
  src/server/CoreEngine.server.lua ← orquestrador imutável
  src/server/Engine/*.lua          ← módulos imutáveis
  src/client/CoreClient.client.lua ← boot cliente
  src/client/UI/*.lua              ← UI imutável
  default.project.json             ← config Rojo
```

## Mandatos Técnicos
1. **Plan Mode obrigatório** — qualquer mudança em Engine/* ou CoreEngine exige plano aprovado primeiro
2. **Lei de Hyrum** — lógica volátil fica em Settings.lua; Engine nunca hardcodeia dados do roteiro
3. **DAMP** — variáveis nomeadas por domínio; sem comentários redundantes
4. **Regra de Beyoncé** — bugs exigem plano de teste aprovado antes de qualquer código corretivo
5. `--!strict` em todo Luau · `task.wait()` nunca `wait()`

## Workflow "God Mode" (10 min/mapa)
1. Baixar mapa na Creator Store (BTRoblox)
2. Rodar `.claude/scripts/wipe-map.lua` no Command Bar → limpa scripts do kit
3. Claude lê ROTEIRO.md → atualiza **apenas** Settings.lua
4. `rojo serve` → Studio Connect → Play → testar → entregar

## Comportamento automático do Engine
- **Spawn**: raycast de Y=1000 para baixo no centro do mapa (ignora água)
- **Tsunami**: auto-descobre limites Z pela geometria; move TsunamiWater de minZ a maxZ
- **NPCs**: spawna modelos de `ReplicatedStorage.Mobs` em posições aleatórias via raycast
- **Tags**: MapTagger tagueia peças por nome automaticamente (ver Settings.TAG_MAP)

## Regras de domínio
→ `.claude/rules/luau-erros.md`
→ `.claude/rules/sistemas-recorrentes.md`
→ `.claude/rules/engine-contratos.md`

---

## Estado atual (atualizado 2026-04-02)

### Entrega ativa
`entregas/2026-04-02_escape-tsunami/` — "Escape do Tsunami com Pulos de Youtubers"
- `game_ready.rbxl` gerado e testável (commit `e8e4a08`)
- Pipeline automático funcionando: solta PDF + .rbxm → build + git push

### Problema em aberto
**Settings.lua chega nil nos módulos Engine** (WAVE, BRAINROTS, BASE são nil).
Os módulos não crasham (guards adicionados), mas o jogo roda sem ondas nem brainrots.

### Diagnóstico em produção
CoreEngine imprime no Output ao dar Play:
- `[CoreEngine] Settings.lua retornou tabela VAZIA` → rojo build não está lendo o arquivo
- `[CoreEngine] Settings carregado. Chaves: TAG_MAP, WAVE, BASE...` → arquivo OK, problema é outro

### Próximo passo
1. Abrir `entregas/2026-04-02_escape-tsunami/game_ready.rbxl` no Studio (File → Open from File)
2. Dar Play e ler o Output
3. Reportar qual das duas mensagens apareceu → decidir o fix

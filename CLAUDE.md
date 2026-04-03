# CLAUDE.md — Athos Roblox

## Contrato
Freelance PJ para Athos (criador de conteúdo Roblox). Dois projetos:
1. **Hub World** (`src/`) — placeId `79528061984127`
2. **Fábrica de Mapas** (`engine-template/` + `entregas/`) — pipeline automático

GitHub: `Maycon-MB/athos_roblox` · Branch: `main`

## Arquitetura
```
src/                              ← Hub World (Rojo serve)
engine-template/src/              ← Engine imutável (fábrica de mapas)
entregas/YYYY-MM-DD_slug/
  src/shared/Settings.lua         ← ÚNICO arquivo editado por roteiro
  game_ready.rbxl                 ← output do rojo build
processor/                        ← watch.py + processor.py (automação)
```

## Mandatos Técnicos
1. **Plan Mode obrigatório** — mudança em Engine/* ou refactor exige plano aprovado
2. **Lei de Hyrum** — lógica volátil em Settings.lua; Engine nunca hardcodeia roteiro
3. **DAMP** — variáveis nomeadas por domínio; sem comentários redundantes
4. **Regra de Beyoncé** — bugs exigem plano de teste aprovado antes de código
5. `--!strict` em todo Luau · `task.wait()` nunca `wait()`

## Workflow
- Hub World: `rojo serve` → Studio Connect → Play → testar
- Fábrica: PDF + .rbxm → `processor/watch.py` → build + git push
- Engine/* nunca recebe lógica de roteiro — só Settings.lua muda

## Regras de domínio (sob demanda)
→ `.claude/rules/luau-erros.md`
→ `.claude/rules/sistemas-recorrentes.md`
→ `.claude/rules/engine-contratos.md`
→ `.claude/rules/hub-world.md`
→ `.claude/rules/valores-calibrados.md`

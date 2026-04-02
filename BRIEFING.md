# Briefing — Estado atual do projeto (2026-04-02)

Cole este arquivo no início de uma nova sessão do Claude Code para retomar o contexto.

---

## Projeto

Fábrica de mapas Roblox para freelance com Athos. Pipeline automático: PDF + .rbxm soltos em pastas → `game_ready.rbxl` pronto para abrir no Studio.

**Repo:** `https://github.com/Maycon-MB/athos_roblox` — branch `main`, commit `b80ba21`

---

## Arquitetura

```
engine-template/src/           <- modulos imutaveis do Engine
entregas/YYYY-MM-DD_slug/
  src/shared/Settings.lua      <- UNICO arquivo editado por roteiro
  game_ready.rbxl              <- output do rojo build
processor/watch.py             <- monitora roteiros/ e models_to_process/
processor/processor.py         <- gera entrega + rojo build + git push
```

## Entrega ativa

`entregas/2026-04-02_escape-tsunami/` — jogo "Escape do Tsunami com Pulos de Youtubers"

---

## Problema em aberto

**Settings.lua chega nil nos modulos Engine** (WAVE, BRAINROTS, BASE sao nil). Os modulos nao crasham (guards adicionados), mas o jogo roda vazio — sem ondas, sem brainrots.

## Diagnostico ja em producao

CoreEngine imprime no Output ao dar Play no Studio:

- `[CoreEngine] Settings.lua retornou tabela VAZIA` → arquivo nao esta sendo lido pelo rojo build
- `[CoreEngine] Settings carregado. Chaves: TAG_MAP, WAVE, BASE...` → arquivo OK, problema e outro

## Proximo passo

1. Abrir `entregas/2026-04-02_escape-tsunami/game_ready.rbxl` no Roblox Studio (File -> Open from File)
2. Dar Play
3. Ler o Output e reportar qual das duas mensagens apareceu
4. Com base nisso decidir o fix

---

## Regras do projeto (nao burlar)

- `--!strict` em todo Luau, `task.wait()` nunca `wait()`
- Engine/* nunca recebe logica de roteiro — so Settings.lua muda
- Mudancas em Engine/* exigem plan mode aprovado antes de codigo
- Rojo serve = sync ao vivo de scripts; rojo build = bake completo com .rbxm
- git push automatico apos cada build (processor.py ja faz isso)

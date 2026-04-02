# Sistemas Recorrentes — Referência de Domínio

## BrainRots
- Itens 3D na pista com renda passiva ($/s) e raridade (Common → Infinity)
- Coletados por toque, vendidos/fundidos em máquinas
- Spawn via `BrainrotSystem.lua` — zona definida em `Settings.BRAINROT_ZONE`
- Raridades e pesos em `Settings.RARITIES` / `Settings.SPAWN_WEIGHTS`

## Jump Shop
- Loja secreta atrás de parede falsa (`CrackWall` tagueada)
- 7 pulos de Youtubers com custo variado: free / money / survive_waves / kill_noobs / sell_brainrots / fuse_brainrots
- Definidos em `Settings.JUMPS` — engine aplica stats automaticamente
- UI: cards horizontais com scroll, botão verde=free / cinza=locked

## Tsunami / Onda
- Peças tagueadas `"Tsunami"` (nome "Water" etc.) sobem no eixo Y e causam dano
- Fallback: painel plano azul se nenhuma peça tagueada encontrada
- Parâmetros em `Settings.WAVE`: INTERVAL, RISE_SPEED, RISE_HEIGHT, HOLD_TIME, RECEDE_MULT
- SafeZone: peças tagueadas `"SafeZone"` protegem por bounding box

## Admin Panel
- Ativado via `/admin` no chat (qualquer player — jogo privado)
- Comandos: wave, fast_wave, give_money, kill_all, list
- UI: panel escuro com botões + log de resposta

## MapTagger (BTRoblox workflow)
- Usuário importa `.rbxm` via BTRoblox, renomeia peças-chave
- Nomes mapeados em `Settings.TAG_MAP` → tags CollectionService aplicadas automaticamente
- Auto-detecção de água: nome parcial + heurística (grande + azul/transparente)

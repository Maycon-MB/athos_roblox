# Pendências — UI Polish (sessão interrompida 2026-04-24)

Handoff do trabalho em andamento quando o limite de contexto estourou.
Commit base desta pendência: `4a4186f`.

## Contexto

Athos pediu comparação entre o menu atual (EN) e o jogo de referência (PT-BR).
Lista priorizada de ajustes foi feita; item 1 concluído, restam 3.

## Concluído neste commit (4a4186f)

- [x] **StatusBar vertical, 6 widgets + total** — `src/client/UI/StatusBar.lua`
  - Rows: brainrots · money (+) · jumps · tokens (+) · fused · kills
  - Total em ouro grande abaixo
  - Ícones emoji (🧠 💰 👟 🌊 🧬 💀) — substituir por assetIds depois se quiser
  - **Não testado em F5 ainda** — primeira coisa a validar na próxima sessão

## Pendente (ordem de prioridade original)

### 2. Espaçamento entre botões do MainMenu + NEW! reposicionado
- Aumentar `PAD` de `6` → `10` no generator do MainMenuOptions
- `NewBadge` atualmente top-right rotacionado 8°; referência tem **topo-centro** com fundo vermelho sólido, sem rotação
- Script pequeno de Command Bar, ~20 linhas

### 3. ADMIN PANEL button — reformatar
- Hoje: wide & curto (1 linha de texto)
- Referência: mais alto/quadrado, texto em **2 linhas** ("PAINEL DE / ADMINISTRADOR" / pode ficar em inglês: "ADMIN / PANEL")
- Ícone do martelo centralizado-esquerda, label centralizada
- Usuário pode querer rainbow ou dourado simples (escolha dele)

### 4. Cantos arredondados sutis
- Adicionar `UICorner` com radius 2-3px nos botões (hoje são cantos retos 0px)
- Apenas no `Button` e `AdminButton`, **não** no `InnerBorder`
- Trivial, 1 função `corner()` + loop

## Testes pendentes (Beyoncé)

Quando retomar:
1. `rojo serve` + F5 no Studio
2. Verificar StatusBar nova aparecendo bottom-left com 6 linhas + total
3. Admin give_money → lblMoney atualiza
4. Admin give_jump → lblJumps atualiza (x/7)
5. Wave trigger → lblTokens atualiza
6. Se algum emoji não renderizar (Roblox às vezes tem issue), substituir por ImageLabel

## Decisões ainda abertas

- **Rainbow vs dourado** no ADMIN PANEL button (usuário deve decidir)
- **Ícones da StatusBar**: emoji ou assetIds custom? (se custom, uploadar no Asset Manager e trocar por `ImageLabel`)
- **Clicks dos botões** do MainMenuOptions: hoje são visuais, podem virar funcionais (Store → abre JumpShop, Admin → toggle AdminPanel, etc)

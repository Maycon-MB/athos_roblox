# ideia.md — Escape do Tsunami (Athos)

## O que é
Ferramenta de gravação para o vídeo do YouTuber Athos:
**"Escape do Tsunami Mas Posso Comprar PULO de YOUTUBERS!"**

O vídeo usa **3 mapas distintos** — dois criados por nós, um jogo externo:

| Mapa | Origem | Função no vídeo |
|---|---|---|
| Escape Waves For Brainmodz | Jogo público do Roblox | Gameplay principal — tsunamis, noobs, farmagem |
| Loja de pulos de youtubers | Criado por nós (`game_ready.rbxl`) | Cena da compra de pulos, exibição de brainrots |
| Base separada | Criado por nós (`game_ready.rbxl`) | Cena da base com pedestais, fusão, venda |

A câmera **finge** que a loja e a base existem dentro do jogo principal.
Na prática, Athos troca de mapa fora da câmera.

## Para quem
Uso interno de gravação. Jogo privado, 1 jogador (Athos).

## Objetivo de negócio
Gerar um `.rbxl` estável que Athos abre no Studio, grava as cenas da
**Loja** e da **Base** sem bugs visíveis, fecha e edita o vídeo.

**Sucesso** = gravação das cenas da loja + base sem interrupção técnica.

## Fluxo das cenas (resumo do roteiro)

```
PULO 1 — James (grátis)
  Loja → compra James → ganha Jamezini Cakenini (brainrot)

PULO 2 — JJ ($5k)
  Base → mostra brainrot na base → farma $5k
  Loja → compra JJ → ganha Mikey + Wave Shield

PULO 3 — Mana ($500k)
  Base → mostra Mikey na base → farma $500k
  Loja → compra Mana → upgrade máximo na base

PULO 4 — Pdoro (pular 10 ondas)
  Loja → compra Pdoro → ganha 10.000 tokens de onda

PULO 5 — Matheus (matar 5 noobs com máquina de ondas)
  Loja → compra Matheus → ganha 3x Glaciero + GalaxyBat

PULO 6 — Caylus (vender 10 brainrots)
  Base → vende 10 brainrots
  Loja → compra Caylus → ganha 3x Infinity Lucky Box

PULO 7 — Athos (fundir 2 brainrots)
  Base → funde 2 brainrots na máquina de fusão
  Loja → compra Athos → base enchida de Athos Brainrots
```

## Conexão Base ↔ Loja (foco atual)

A Base e a Loja precisam estar **funcionalmente conectadas via PlayerData**:

| Ação na Base | Efeito na Loja |
|---|---|
| Acumular dinheiro ($5k/$500k) | Desbloqueia JJ e Mana |
| Vender 10 brainrots | Desbloqueia Caylus |
| Fundir 2 brainrots | Desbloqueia Athos |
| Brainrots no inventário | Aparecem nos pedestais da Base |

**Estado atual:**
- 3 áreas existem, teleporte via Admin Panel funciona
- Base tem pedestais 3D
- Loja tem CrackWall + JumpShop UI
- PlayerData rastreia `money`, `brainrotsSold`, `brainrotsFused`

**O que falta para conectar:**
- JumpShop UI mostrar corretamente qual pulo está disponível com base nos dados atuais
- Venda e fusão na Base incrementarem os contadores certos
- Admin Panel como bypass para gravar sem cumprir condições (já existe)

## Critério de "pronto" para gravação

- [ ] Play → nenhum erro no Output
- [ ] Coletar brainrot na área → aparece no pedestal da Base em ≤2s
- [ ] Vender brainrot → `brainrotsSold` incrementa → botão Caylus fica disponível
- [ ] Fundir brainrots → `brainrotsFused` incrementa → botão Athos fica disponível
- [ ] Dinheiro acumulado → botões JJ e Mana ficam disponíveis
- [ ] Admin Panel bypassa tudo sem precisar cumprir condições
- [ ] GalaxyBat aparece no Backpack ao dar pulo Matheus
- [ ] Partículas no HRP nos pulos Mana e Athos

## Restrições
- Sem DataStore — sessão única de gravação
- Sem testes automatizados — validação manual no Studio
- Admin bypassa todos os validators (gravação)
- Não modificar `engine-template/` — cópia canônica imutável
- O jogo do tsunami (Escape Waves For Brainmodz) **não é modificado**

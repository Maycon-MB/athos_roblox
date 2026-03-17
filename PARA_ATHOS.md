# Athos Hub — Documento de Apresentação

## O que foi construído

Um **hub world profissional** para o seu servidor Roblox, desenvolvido do zero com arquitetura de código de alto nível. O objetivo foi criar uma experiência visualmente impressionante, funcional e preparada para escalar conforme suas necessidades.

---

## O que o jogador experimenta ao entrar

1. **Câmera cinematográfica** — ao nascer, a câmera faz uma varredura panorâmica do mapa por 4 segundos antes de devolver o controle. Causa impacto imediato.
2. **Spawn orientado** — o personagem nasce no canto noroeste olhando diretamente para o hub central, guiando o olhar naturalmente.
3. **Gateway de entrada** — arco com a placa "ATHOS HUB" em neon dourado na diagonal do spawn.
4. **Hub central** — plataforma de 3 camadas (cobblestone → pedra → mármore) com trim dourado neon, 27 studs de fonte no centro, canteiros de flores, bancos e pilares com luz quente.
5. **Área de atividades** — Leaderboard Tower, Loja A-frame, Wheel Spin, Starter Eggs e Titanic Pet visíveis do spawn.
6. **Portais temáticos** — 3 portais (Floresta, Oceano, Deserto) com efeito vórtice e partículas. Portal VIP separado com plataforma exclusiva.
7. **Sons ambientes** — fonte com som de água e portais com hum eletrônico (garantidos). Música de fundo tentada automaticamente.
8. **Notificação de recompensa** — ao girar a roda, aparece um popup animado na tela com o prêmio.

---

## Funcionalidades técnicas incluídas

| Recurso | Detalhe |
|---|---|
| Leaderstats | Coins visíveis no tab de jogadores |
| Wheel Spin | ProximityPrompt "Girar" com cooldown de 30s |
| Recompensas | 50/100/200 Coins, Rare Egg (8%), Epic Pet (4%) |
| Segurança | Validação de distância no servidor antes de cada ação |
| Câmera | Introdução cinematográfica de 4.2s em 3 fases |
| Iluminação | Bloom calibrado, atmosfera suave, sem saturação |
| Áudio | Sons espaciais por área (fonte, portais, VIP) |

---

## Como testar

### Opção A — Roblox Studio (recomendado para review)
1. Instale o [Rojo](https://rojo.space) no VS Code e o plugin Rojo no Studio
2. No terminal da pasta do projeto: `rojo serve`
3. No Studio: clique **Connect** no plugin Rojo
4. Pressione **Play** (F5) para testar

### Opção B — Publicar e testar no Roblox
1. No Studio: **File → Publish to Roblox**
2. Defina o jogo como **Privado** (só você vê)
3. Abra o jogo pelo perfil → **Play**
4. Compartilhe o link direto: `roblox.com/games/[ID_DO_JOGO]`

---

## Próximos passos (sob demanda)

- **ProfileService** — persistência de Coins entre sessões (dados salvos na nuvem)
- **Mais portais / mapas** — cada portal pode levar a um jogo/mapa diferente
- **Loja funcional** — itens compráveis com Coins ou Robux
- **Sistema de pets** — exibição e interação com pets no hub
- **Eventos sazonais** — decorações e recompensas especiais por data

---

*Desenvolvido com arquitetura modular de 6 módulos — fácil de manter, expandir e adaptar para qualquer demanda futura.*

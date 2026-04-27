# ideia.md - Especificação Técnica: Escape do Tsunami (Mod de YouTubers)

## 1. Visão Geral da Arquitetura: Injeção e Spoofing
[cite_start]O jogo base ("Escape Waves For Brainmodz") deve permanecer intacto[cite: 1, 38]. Todas as modificações serão injetadas através de sistemas paralelos. O objetivo é "enganar" a perceção visual do jogador e dos espectadores (Spoofing de UI e Física), sem quebrar o loop principal do jogo ou os sistemas de colisão nativos do Roblox.

### 1.1. Spoofing de Interface (UI Fantasma)
* **Não alterar o `ScreenGui` original.**
* [cite_start]Criar um `Custom_ScreenGui` que se sobrepõe ao original[cite: 54]. 
* Os botões e os contadores (ex: "Brainrots", "Infinity Lucky Box") devem ser alimentados por um `CustomEconomyService` a correr no servidor, totalmente isolado dos `leaderstats` normais de sobrevivência do Tsunami.

### 1.2. Isolamento de Mapas (Instanciamento Seguro)
* [cite_start]**Loja Secreta e Base Secreta:** Estes não devem existir no mapa principal por defeito[cite: 52, 89]. 
* Devem ser instanciados no `Workspace` via `ServerStorage` ou posicionados em coordenadas muito distantes (ex: `Vector3(0, 10000, 0)`). 
* [cite_start]A interação com a "parede falsa" no mapa do Tsunami atua apenas como um gatilho de teletransporte (`CFrame`) para o ator (Athos), movendo-o para a Loja ou Base Secreta[cite: 124, 125].

### 1.3. Movimentação Híbrida (Prevenção de Clipping)
* [cite_start]O guião exige velocidades extremas (até 2500 de WalkSpeed)[cite: 87, 120]. O motor de colisão do Roblox falha com valores tão altos em paredes finas.
* [cite_start]**Solução de Spoofing:** O `CustomEconomyService` deve atualizar a UI para exibir "Velocidade: 2500"[cite: 32]. No entanto, o `Humanoid.WalkSpeed` real deve ser limitado a um máximo seguro (aprox. 200). 
* **Efeito Visual:** Para compensar e vender a ilusão de velocidade no vídeo, aplique um `Tween` no `Camera.FieldOfView` (110-120), ative Motion Blur na iluminação e adicione um `ParticleEmitter` (Speed Lines) ao Character sempre que as velocidades dos pulos finais forem equipadas.

---

## 2. Eventos Cronológicos e Lógica de Gatilhos (Pulo 1 ao 7)

O seu `InventoryService` e o gestor de estado da UI devem ser programados para seguir esta progressão exata, processando transações que misturam moedas virtuais, itens físicos e ações:

### Pulo 1: Pulo do James
* [cite_start]**Custo:** Grátis[cite: 80].
* [cite_start]**Ação/Gatilho:** O jogador clica no botão "FREE" da UI da loja fantasma[cite: 76, 138].
* **Recompensa:** `Humanoid.JumpPower = 10` | `Fake_WalkSpeed = 67`. [cite_start]Recebe no inventário o item físico "Jamezini cakenini" (Model: Skin do James com bolo na cabeça)[cite: 79, 139].

### Pulo 2: Pulo do JJ
* [cite_start]**Custo:** 5.000 Cash customizado[cite: 81].
* [cite_start]**Ação/Gatilho:** Servidor valida se o saldo >= 5k após o "farm" na base secreta[cite: 22].
* **Recompensa:** `Humanoid.JumpPower = 40` | `Fake_WalkSpeed = 250`. [cite_start]Recebe o item lendário "Brainrot Mikey" (7k/s na base) e o item equipável "Wave shield" (Escudo contra ondas)[cite: 22, 81, 97].

### Pulo 3: Pulo da Mana
* [cite_start]**Custo:** 500.000 Cash customizado[cite: 82].
* **Ação/Gatilho:** Servidor valida o saldo após farm melhorado.
* **Recompensa:** `Humanoid.JumpPower = 90` | `Fake_WalkSpeed = 400`. [cite_start]Desbloqueia a "Flag" de Upgrade máximo na base secreta[cite: 24, 82].

### Pulo 4: Pulo do Pdoro
* [cite_start]**Custo:** Pular 10 ondas sem sofrer dano[cite: 83].
* **Ação/Gatilho:** Necessário criar um sistema de tracking na arena. O servidor incrementa um contador sempre que o evento de colisão da onda no mapa ocorre sem atingir o `Humanoid` do jogador.
* **Recompensa:** `Humanoid.JumpPower = 140` | `Fake_WalkSpeed = 600`. [cite_start]Concede 10.000 tokens de onda para a máquina de controlo[cite: 26, 83].

### Pulo 5: Pulo do Matheus
* [cite_start]**Custo:** Matar 5 jogadores (Noobs) com a máquina de ondas[cite: 28, 84].
* **Ação/Gatilho:** O script da máquina de ondas deve emitir um evento quando uma onda ativada pelo jogador resultar na morte de outro Character no mapa.
* **Recompensa:** `Humanoid.JumpPower = 170` | `Fake_WalkSpeed = 800`. [cite_start]Recebe 3x "Glaciero Infernati" (brainrots) e a arma "Taco de Galáxia"[cite: 28, 84].

### Pulo 6: Pulo do Caylus (Início do End-Game)
* [cite_start]**Custo:** Vender 10 brainrots no sistema de Trade da UI[cite: 30, 85].
* [cite_start]**Ação/Gatilho:** O `CustomEconomyService` deve suportar uma interface simulada de "Trade" onde a transação é cancelada para os outros jogadores, mas processada como "Venda" para o ator principal[cite: 30].
* **Recompensa:** `Humanoid.JumpPower = 200` | [cite_start]`Fake_WalkSpeed = 2000` (Ativar limitador físico + VFX Extremo)[cite: 31, 85]. [cite_start]Concede 3 "Infinity Lucky Boxes" que devem abrir com animação visual chamativa (UI Unboxing de itens Overpower)[cite: 31, 85].

### Pulo 7: Pulo do Athos (Tier Máximo)
* [cite_start]**Custo:** 1x item "Fusão Brainrot"[cite: 32, 87].
* **Ação/Gatilho:** O jogador interage com o *Asset* "Máquina de Fusão". O servidor remove 2 Brainrots comuns do inventário e entrega 1 "Fusão Brainrot". [cite_start]A loja deteta este item no inventário e liberta a compra[cite: 32, 87].
* **Recompensa Final:** `Humanoid.JumpPower = 250` | `Fake_WalkSpeed = 2500` (Manter limitador físico + Efeito Flash/Speed Lines). [cite_start]Preenche automaticamente a base secreta do jogador com "Athos Brainrots com mutação de fogo" (999M/s) gerando um mar de recursos[cite: 32, 87, 98].
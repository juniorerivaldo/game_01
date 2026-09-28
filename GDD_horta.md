# Horta do Coelho - GDD base

**Gênero:** idle de horta com visão de cima, inspirado no *Tiny Terraces*
**Engine:** Odin + Raylib
**Visual:** só retângulos e círculos num grid. Sprite fica pra depois.
**Nome:** provisório. Troque à vontade.

Este documento não tem código pronto. Ele diz **quais arquivos criar, o que vai dentro de cada um, quais procs escrever e
de onde chamar cada proc**.

Meta: **você não põe a mão na terra.** Os ajudantes plantam, regam, tiram o mato, colhem e
guardam tudo no inventário sozinhos. Você é o dono do shop: vende a colheita do inventário
e, com o dinheiro que eles produzem, compra sementes, ferramentas, mais ajudantes, terreno
e decoração pra eles. Em volta da horta tem **floresta e pedra**: os ajudantes que você
escalar como lenhador e minerador juntam madeira e pedra, e com elas você constrói **casas**.
Como no *Age of Empires*: **sem casa, não nasce ajudante novo** (cada casa abriga 5).

**Inspiração, não cópia.** Mecânica não tem dono: "bonequinhos cuidam da horta sozinhos"
é livre. Nome, arte, personagens e textos do Tiny Terraces têm dono. Este jogo tem a
identidade dele: um coelho e a horta dele.

---

## 0. Pilares do jogo

| | Horta do Coelho |
|---|---|
| Mundo | um **grid 2D** (X e Y) **bem maior que a tela**: uma clareira no meio de uma floresta enorme, com jazidas de pedra espalhadas. Você move a vista com a **câmera** (mouse nas bordas) |
| Crescer | **cortar floresta abre espaço**: árvore cortada vira toco, toco arrancado vira grama, e na grama cabe canteiro e casa |
| Quem você controla | **ninguém**: você é o **mouse** no shop |
| Interação | **clicar nos botões do shop**. O grid só recebe clique pra posicionar lote, decoração e casa |
| Quem trabalha | **só os ajudantes**. Você nunca planta, rega, colhe, corta nem quebra. Você só escolhe a **profissão** de cada um |
| Recursos | **moedas** (vendendo colheita), **madeira** (árvore) e **pedra** (rocha) |
| População | **cada casa abriga 5 ajudantes**. Casas cheias: construa outra antes de criar mais ajudantes |
| Tensão | **não tem derrota**. A graça é ver crescer e decidir o que comprar |
| UI | **o shop no painel lateral**: metade do jogo |
| Persistência | **save/load obrigatório**: idle sem save não existe |

**A base do código:**
- O padrão `struct` + `_spawn` + `_update` + `_draw` (seção 3).
- Uma **máquina de estados** pro ajudante: procurar tarefa, andar, trabalhar, entregar.
- Um `move_towards_2d` pra andar liso até um ponto.
- A ideia de **entregar no depósito**: o ajudante leva a colheita até o cesto, que joga no
  inventário.
- Coisa viva ou morta com `active`.

**O que você vai aprender aqui:**
- Array 2D fixo (`[W][H]Tile`) e conversão **mouse -> tile**.
- **Câmera 2D**: um mapa maior que a tela, rolando pelas bordas, e a diferença entre
  coordenada de tela, de mapa e de tile.
- **UI de modo imediato**: botão que é só uma proc que desenha e responde "fui clicado?".
- **Reserva de tarefa**: dois ajudantes não podem regar o mesmo pé nem usar a mesma semente.
- **Upgrades globais**: ferramenta comprada no shop muda um número que todos os ajudantes leem.
- **Profissões**: a **mesma** máquina de estados serve pra fazendeiro, lenhador e minerador.
  A profissão só filtra quais tarefas o ajudante enxerga.
- **Limite de população por construção**: o "quantos ajudantes cabem" não é uma constante,
  é uma conta em cima do grid (casas × 5).
- **Salvar e carregar** em JSON.

---

## 1. A ideia em 5 linhas

Você cuida de uma horta vista de cima, dividida em quadradinhos, **sem tocar nela**.
Os **ajudantes** andam sozinhos pelo grid. Os **fazendeiros** plantam as sementes do inventário nos canteiros vazios, regam quem tem sede, arrancam o mato, colhem o que está pronto e levam pro cesto. Os **lenhadores** cortam árvore e os **mineradores** quebram pedra, e também levam pro cesto.
Tudo o que chega no cesto vai pro **inventário**.
No **shop** você vende a colheita do inventário e, com as moedas, compra **sementes** (o que eles vão plantar), **ferramentas** (eles trabalham melhor), **mais ajudantes**, **terreno** e **decoração**. Com a madeira e a pedra você constrói **casas**, que é o que deixa ter mais ajudantes.
Não tem derrota. A meta é a vila crescer **floresta adentro**: cada árvore cortada e cada toco arrancado vira espaço pra mais canteiros e casas.

```
+------------------------------------------------------------------------+
| Moedas 42  Madeira 12  Pedra 3  Ajudantes 4/5   Meta: Construa uma casa|  <- HUD (topo)
+---------------------------------------------+--------------------------+
|  T T T T T T T T T T T T T T T T T T T T T   |  INVENTÁRIO              |
|  T T T . T T T T T T T T T . T T T T T T T   |   colheita: Cen 5 Alf 2  |
|  T T . o . . . . . . . . . . . . . . . T T   |   sementes: Cen 3 Alf 1  |
|  T o . . . . . . . . . . . . . . . . . . T   |  VENDER                  |
|  T T . . . . . . [C][C][A] . . . . . . T T   |   [Cen +15] [Tudo +31]   |
|  T T h . . . [B] [C][ ][A] . . f . . . T T   |  SEMENTES                |
|  T T . . . . . . . . . . . . . h . . . . T   |   [Cen 1] [Alf 3] [Abó 8]|
|  T T . . . . [H] . . . . . . . . . . . P :   |  FERRAMENTAS  [Botas 20] |
|  T T . . . . . . . . . . . . . . . . . P P   |  PROFISSÕES              |
|  T T T T T T T T T T T T T T T T T T P : P   |   Lenhador 1  [-] [+]    |
|  T T T T T T T T T T T T T T T T T T T T T   |   Minerador 0 [-] [+]    |
|                                              |  AJUDANTE  [Criar]       |
|  [B] = cesto  [C] = canteiro  [H] = casa     |  CONSTRUIR [Casa 10m 5p] |
|  T = árvore  o = toco  P = rocha  : = cascalho|  TERRENO [Lote 10]       |
|  . = grama  f = flor  h = ajudante           |  DECORAR [Flor 5] ...    |
+---------------------------------------------+--------------------------+
       a VISTA: um pedaço de 22 x 19 tiles              shop (painel lateral)
       de um mapa de 96 x 64. Mouse na borda = anda
```

(O desenho é um esquema. A vista mostra só um pedaço do mapa: o resto é floresta, com
jazidas de pedra espalhadas, e aparece quando você rola a câmera.)

```
O MAPA INTEIRO (96 x 64), visto de longe:

   TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
   TTTTTTTTP TTTTTTTTTTTTTTTTTTTTTTTTTTTTT PTTT     P = jazida de pedra
   TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT     T = floresta
   TTTTTTTTTTTTTTTTTT.........TTTTTTTTTTTTTTTTT     . = clareira (onde o jogo começa)
   TTTTTTTTTTTTTTTTTT...[vista]...P TTTTTTTTTTT
   TTTTTTTTTTTTTTTTTT.........TTTTTTTTTTTTTTTTT
   TTTTP TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
   TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTP TTTTTTT
   TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

---

## 2. Onde o código mora e mapa dos arquivos

Todo o código mora em `game-dev/horta/src/`, com `package horta`. Um package Odin só pode
ter um `main`, então nada de fora entra nessa pasta.

| Arquivo | Do que cuida | Etapa em que nasce |
|---|---|---|
| `config.odin` | Só constantes. Zero lógica. | 1 |
| `main.odin` | Abre a janela, guarda o mundo, roda o loop, chama todo mundo. | 1 |
| `grid.odin` | O grid: tiles, desenho, mouse -> tile, cesto, floresta em volta. | 1, 2 e 11 |
| `crop.odin` | A planta dentro do tile: plantar, crescer, água, mato, colher. | 2 e 4 |
| `inventory.odin` | Moedas, colheita guardada, sementes guardadas, nível das ferramentas. | 3 |
| `shop.odin` | A lógica do shop: vender, comprar semente, ferramenta, ajudante, lote, decoração. Sem desenho. | 3, 8, 9 e 10 |
| `helper.odin` | Ajudante: andar, achar tarefa, trabalhar, entregar, criar novo, trocar de profissão. | 5, 6, 9 e 11 |
| `resource.odin` | Árvore e pedra dentro do tile: cortar, quebrar, crescer de novo, desenhar. | 11 |
| `house.odin` | Casa: posicionar, contar quantos ajudantes cabem, desenhar. | 12 |
| `utils.odin` | `move_towards_2d` e outras procs pequenas. | 5 |
| `ui.odin` | Painel do shop, botões, item na mão, info do tile embaixo do mouse. | 7 |
| `tools.odin` | O efeito de cada ferramenta nos números dos ajudantes. | 8 |
| `decor.odin` | Decoração: colocar, tirar, desenhar. | 10 |
| `camera.odin` | A vista do mapa: mover pelas bordas e pelo teclado, mouse -> tile, só desenhar o que aparece. | 1 |
| `hud.odin` | Barra de cima com números e metas. | 3 em diante |
| `save.odin` | Salvar e carregar o jogo. | 14 |

**Regra:** só crie o arquivo quando chegar na etapa dele.

---

## 3. O padrão que todo arquivo segue

```
1. um struct   -> os dados daquela coisa
2. um _spawn   -> cria a coisa e devolve pronta
3. um _update  -> recebe dt (e o que mais precisar), mexe nos dados
4. um _draw    -> só desenha, nunca muda dado nenhum
```

- **`_update` nunca desenha. `_draw` nunca muda valor.**
- **Lista de coisas** (ajudantes) ganha `xxx_update_all` e `xxx_draw_all`.
- **Quem muda algo recebe `^`.** Quem só lê recebe por valor.

**Uma regra nova, por causa do mouse:** proc que **lê clique** e proc que **executa a ação**
são separadas. `ui_update` lê o mouse e decide "o jogador clicou em Comprar semente de
Cenoura"; quem compra de verdade é `shop_try_buy_seed`. A `try_` não lê entrada nenhuma,
então dá pra testar sem janela.

**E uma regra nova, por causa do design:** **só o ajudante chama as `try_` da planta**
(`crop_try_plant`, `crop_try_water`, `crop_try_weed`, `crop_try_harvest`). O `ui_update` só
chama as `try_` do shop. Se algum dia o `ui.odin` chamar `crop_try_...`, o jogador voltou a
pôr a mão na terra e o jogo mudou de gênero.

---

## 4. `config.odin`

Só constantes. Zero lógica, zero `proc`. Quando quiser deixar o jogo mais rápido ou mais
lento, mexa **só aqui**: nenhum outro arquivo escreve `70`, `0.3` ou `30` direto no código,
todo mundo usa o nome da constante.

Cada bloco abaixo diz **em que etapa a constante começa a ser usada**. Pode declarar tudo de
uma vez na Etapa 1; o Odin não reclama de constante não usada.

**Janela** (Etapa 1)

```
SCREEN_WIDTH  :: 1280               // largura da janela, em pixels
SCREEN_HEIGHT :: 720                // altura da janela, em pixels
TITLE         :: "Horta do Coelho"  // texto na barra da janela
```

**O mapa** (Etapa 1)

O mapa é **muito maior que a tela**. Você vê só um pedaço dele por vez, pela câmera, e
move a câmera levando o mouse pras bordas (Etapa 1).

```
GRID_W :: 96    // quantos tiles o mapa tem na horizontal (colunas)
GRID_H :: 64    // quantos tiles o mapa tem na vertical (linhas)
TILE   :: 32    // lado de um tile, em pixels (todo tile é quadrado)

// A clareira: o pedaço sem floresta no meio do mapa, onde o jogo começa. Em TILES.
CLEARING_X :: 40   // coluna do canto de cima-esquerda
CLEARING_Y :: 27   // linha do canto de cima-esquerda
CLEARING_W :: 17   // largura
CLEARING_H :: 11   // altura

BASKET_TILE      :: [2]int{45, 32}   // em TILES: coluna 45, linha 32 (dentro da clareira)
START_HOUSE_TILE :: [2]int{45, 34}   // a casa que já vem pronta (Etapa 12), 2 tiles abaixo do cesto
```

- **Tamanho do mapa em pixels:** `96 * 32 = 3072` de largura e `64 * 32 = 2048` de altura.
  A vista (abaixo) tem 700 x 620, então o mapa tem umas **4 telas de largura e 3 de altura**.
- **A clareira é pequena de propósito:** 17 x 11 = 187 tiles no meio de 6144. O resto é
  floresta (Etapa 11), e **toda árvore cortada vira grama pra sempre**. É assim que a vila
  cresce: os lenhadores abrem espaço, e você usa o espaço aberto pra canteiros e casas.
- `BASKET_TILE` e `START_HOUSE_TILE` têm que estar **dentro da clareira**:
  `CLEARING_X <= x < CLEARING_X + CLEARING_W`, igual pro y. Fora disso eles nascem no meio
  das árvores.

**A tela: onde ficam a vista do mapa, o HUD e o shop** (Etapa 1)

```
// A "vista": o retângulo da tela onde o mapa aparece. Em PIXELS DE TELA.
VIEW_X :: 20
VIEW_Y :: 80    // em cima dela fica o HUD
VIEW_W :: 700   // termina em 720, antes do painel
VIEW_H :: 620   // termina em 700, antes do fim da tela (720)

PANEL_X :: 740  // daqui pra direita é o painel do shop
```

Confira que tudo cabe (faça essa conta de novo se mudar algum número):
- `VIEW_X + VIEW_W = 720`, antes do `PANEL_X` (740). Sobram 20 px de respiro.
- `VIEW_Y + VIEW_H = 700`, antes de `SCREEN_HEIGHT` (720).
- A vista mostra `700 / 32 = ~22` tiles de largura e `620 / 32 = ~19` de altura. A clareira
  inteira (17 x 11) cabe numa tela só.

**A câmera** (Etapa 1)

```
CAMERA_SPEED :: 600    // px por segundo que a câmera anda (borda do mouse ou teclado)
EDGE_MARGIN  :: 24     // px: mouse a menos disso da borda da vista empurra a câmera
EDGE_DELAY   :: 0.25   // segundos com o mouse parado na borda antes de começar a andar
```

**Por que o `EDGE_DELAY`:** o shop fica colado na borda direita da vista. Todo caminho do
mouse até o shop passa por essa borda, e sem a espera a câmera daria um tranco pra direita
toda vez que você fosse comprar alguma coisa. Com 0.25 s, passar rápido não move nada;
**parar** na borda move.

**Ajudante: velocidade e tempo de cada tarefa** (Etapas 5 e 6. Valores base, sem ferramenta)

```
HELPER_SPEED :: 48     // px por segundo. 48 / 32 = 1.5 tile por segundo

// Quantos SEGUNDOS o ajudante fica parado no tile fazendo a tarefa (o work_timer)
PLANT_TIME   :: 1.0
WATER_TIME   :: 1.0
WEED_TIME    :: 2.0
HARVEST_TIME :: 1.0
CHOP_TIME    :: 3.0    // lenhador derrubando uma árvore (Etapa 11)
STUMP_TIME   :: 2.0    // lenhador arrancando um toco (Etapa 11)
MINE_TIME    :: 4.0    // minerador quebrando uma rocha (Etapa 11)

FIND_TASK_INTERVAL :: 0.5  // de quantos em quantos segundos o ajudante .Idle procura tarefa
```

Repare: `HELPER_SPEED` é **velocidade** (quanto maior, mais rápido). Os `_TIME` são
**duração** (quanto maior, mais lento). Não chame os tempos de `_SPEED`: `WEED_SPEED :: 2.0`
parece "tira mato 2x mais rápido", quando na verdade é "demora 2 segundos".

**Água** (Etapa 4)

A água da planta é um número (`crop.water`) que vai de **1** (acabou de ser regada) até
**0** (seca). Ela desce sozinha com o tempo:

```
WATER_DECAY    :: 1.0 / 30.0  // quanto de água a planta perde POR SEGUNDO
THIRSTY_BELOW  :: 0.3         // abaixo disso a planta está "com sede"
```

- **`WATER_DECAY`**: perder `1/30` por segundo = a água cheia (1) chega a 0 em **30 s**.
  Quer que a água dure 60 s? `1.0 / 60.0`. Escrever como divisão deixa o "30 s" legível.
- **`THIRSTY_BELOW`** ("com sede") **não para a planta**. A planta com sede **continua
  crescendo**. Ele só serve pra duas coisas:
  1. O **ajudante só rega** planta com `water < THIRSTY_BELOW` (é o `crop_needs_water` da
     Etapa 4). Sem esse limite, ele regaria planta com 0.9 de água, que não precisa.
  2. O **desenho** fica apagado, pra você ver quem está esperando rega.

  O que **para** a planta é a água chegar a **0** (seca).

  **Por que 0.3 e não 0:** é a folga pro ajudante chegar a tempo. Descendo 1/30 por
  segundo, de 0.3 até 0 são `0.3 * 30 =` **9 s**. Se o limite fosse 0, o ajudante só sairia
  pra regar depois que a planta já parou.

Linha do tempo de uma planta que ninguém rega:

```
t = 0 s    água 1.0   acabou de plantar (nasce regada)
t = 21 s   água 0.3   COM SEDE: ajudante já pode vir regar. Continua crescendo
t = 30 s   água 0.0   SECA: parou de crescer até alguém regar
```

**Mato** (Etapa 4)

```
WEED_CHANCE :: 0.005   // 0.5% de chance POR SEGUNDO, pra cada planta crescendo
```

É chance **por segundo**, não por frame: no código ela sempre aparece como
`WEED_CHANCE * dt`. Na média, uma planta ganha mato a cada `1 / 0.005 = 200 s`. Planta pronta
não ganha mato.

**Começo do jogo e limites** (Etapas 2, 3, 6 e 9)

```
START_COINS   :: 20   // moedas no inventário quando começa um jogo novo
START_HELPERS :: 1    // ajudantes no começo
MAX_HELPERS   :: 8    // Etapas 9 a 11: o botão "Criar ajudante" some quando chega aqui
```

O `MAX_HELPERS` é provisório: na **Etapa 12** ele é apagado e quem decide quantos ajudantes
cabem passa a ser o número de casas (`HOUSE_CAPACITY`, logo abaixo).

Os 6 canteiros do começo (um bloco 3 x 2 no meio do grid) são desenhados no `grid_spawn`,
não precisam de constante.

**As plantas** (Etapa 2 em diante. Use **array enumerado**, um recurso do Odin que casa
perfeito aqui):

```
//                              .None     Cenoura        Alface          Abóbora
CROP_SEED_PRICE :: [CropKind]int { .None = 0, .Carrot = 1,  .Lettuce = 3,  .Pumpkin = 8  } // moedas pra comprar 1 semente
CROP_SELL_PRICE :: [CropKind]int { .None = 0, .Carrot = 3,  .Lettuce = 8,  .Pumpkin = 25 } // moedas ao vender 1 colhida
CROP_GROW_TIME  :: [CropKind]f32 { .None = 0, .Carrot = 20, .Lettuce = 40, .Pumpkin = 90 } // segundos crescendo (com água e sem mato)
START_SEEDS     :: #partial [CropKind]int { .Carrot = 4 }                                  // sementes no começo
```

Um array indexado pelo enum: `CROP_SELL_PRICE[.Pumpkin]` dá 25. Sem `switch`, sem
esquecer um caso: se você criar `CropKind.Tomato` e não puser o preço, o compilador reclama.

- **Por que tem `.None = 0`:** `.None` é "canteiro vazio" e também faz parte do enum. O
  array tem uma casa pra ele, e o 0 deixa claro que ninguém compra nem vende "nada".
- **Por que o `#partial` no `START_SEEDS`:** o Odin exige que um array enumerado liste
  **todos** os valores do enum, justamente pra pegar o esquecimento do tomate. O `#partial`
  diz "é de propósito, o resto é 0". Use ele só onde faltar valor for normal.
- **`CROP_GROW_TIME` conta só o tempo em que a planta cresce de verdade.** Seca ou com mato,
  o relógio dela para. Por isso, na prática, ela demora mais que isso.

(`CropKind` nasce na Etapa 2. Até lá, deixe esses quatro comentados, senão não compila.)

**As ferramentas** (Etapa 8):

```
TOOL_MAX_LEVEL :: 3
TOOL_PRICE     :: [ToolKind][TOOL_MAX_LEVEL]int {
    .Boots   = {20, 60, 150},
    .Can     = {20, 60, 150},
    .Hoe     = {15, 45, 120},
    .Sickle  = {25, 75, 180},
}
```

`TOOL_PRICE[.Boots][0]` é o preço do nível 1 das botas. Array enumerado de array: a tabela
inteira do shop de ferramentas numa constante só.

- **Nível** é quantas vezes você já comprou aquela ferramenta: 0 (não tem) até
  `TOOL_MAX_LEVEL` (3). Fica em `inv.tools[kind]`.
- **O índice é o nível atual**, não o que você vai comprar: com as botas no nível 0, o
  próximo preço é `TOOL_PRICE[.Boots][0]` (20). No nível 3 não tem próximo, e ler
  `[3]` sai do array: por isso o `tool_next_price` da Etapa 8 confere o máximo antes.
- O **efeito** de cada nível (+25% de velocidade, água +15 s...) **não** mora aqui: está nas
  procs de `tools.odin` (Etapa 8), junto da conta que usa ele.

**Floresta, pedra e casas** (Etapas 11 e 12)

```
// Jazidas de pedra: blocos de 3 x 3 rochas. Cada item é o canto de cima-esquerda, em TILES.
ROCK_CLUSTERS :: [?][2]int{ {60, 29}, {24, 14}, {74, 50}, {14, 48}, {82, 10} }

TREE_WOOD  :: 3          // madeira que a árvore dá quando cai
STUMP_WOOD :: 1          // madeira que o toco dá quando é arrancado
ROCK_STONE :: 2          // pedra que a rocha dá quando quebra

ROCK_RESPAWN_TIME :: 120.0  // segundos até o cascalho virar rocha inteira de novo

HOUSE_CAPACITY :: 5       // quantos ajudantes moram numa casa
HOUSE_COST     :: #partial [ResourceKind]int { .Wood = 10, .Stone = 5 }  // o que sai do inventário
```

Como no *Stardew Valley*, cortar e quebrar deixa marca no chão:

```
ÁRVORE:  .Tree  --cortar (CHOP_TIME)-->   .Stump  --arrancar (STUMP_TIME)-->  .Grass
                 +TREE_WOOD (3)            (toco)   +STUMP_WOOD (1)            (terreno livre, pra sempre)

PEDRA:   .Rock  --quebrar (MINE_TIME)-->  .Gravel  --espera ROCK_RESPAWN_TIME-->  .Rock
                 +ROCK_STONE (2)           (cascalho)                              (nasceu de novo)
```

- **A árvore cai e fica o toco.** O toco ocupa o tile: não dá pra pôr lote nem casa em cima.
  Só depois que um lenhador **arranca o toco** o tile vira `.Grass`, e aí sim é espaço livre
  pra vila.
- **Árvore não volta.** Terreno aberto fica aberto. **Cortar é o jeito de a vila crescer**,
  não um estoque que você precisa administrar. A madeira acaba um dia? São ~4900 árvores, 4
  madeiras cada: dá pra quase 2000 casas.
- **A pedra se renova pelo cascalho.** Rocha quebrada vira `.Gravel`: um chão de pedrinhas
  onde não dá pra construir. Depois de `ROCK_RESPAWN_TIME` (120 s), o cascalho vira rocha de
  novo, no mesmo lugar. A jazida é um lugar fixo no mapa e nunca acaba.
- **Por que a pedra é o recurso escasso:** a jazida mais perto (`{60, 29}`) tem 9 rochas.
  Cada uma dá 2 pedras e leva 120 s pra voltar: **9 pedras por minuto**, no máximo. Com a
  jazida perto esgotada (tudo cascalho), os mineradores vão pra seguinte, que é **bem mais
  longe**. Aí a pergunta "quantos mineradores eu escalo?" tem resposta certa. Veja a conta
  na seção 8.
- **`[?]`** no `ROCK_CLUSTERS` é o Odin contando o tamanho do array sozinho: quer mais uma
  jazida, acrescente um `{x, y}` e pronto.
- **Quantos ajudantes cabem** não é constante, é conta: `casas × HOUSE_CAPACITY`. O jogo já
  começa com 1 casa pronta (em `START_HOUSE_TILE`), então cabem 5.
- `HOUSE_COST` é um array enumerado de `ResourceKind` (`.None`, `.Wood`, `.Stone`), igual
  ao das plantas. O `#partial` deixa o `.None` como 0. (`ResourceKind` nasce na Etapa 11:
  até lá, deixe o `HOUSE_COST` comentado.)

**Por que esses números** (confira sempre que mexer):

| | Lucro por colheita | Tempo crescendo | Lucro por minuto por canteiro | Regas que o ajudante faz | Risco |
|---|---|---|---|---|---|
| Cenoura | 3 - 1 = **2** | 20 s | 2 × 60 / 20 = **~6** | 0 | quase nenhum: fica pronta (20 s) antes de dar sede (21 s) |
| Alface | 8 - 3 = **5** | 40 s | 5 × 60 / 40 = **~7.5** | 1 | pouco |
| Abóbora | 25 - 8 = **17** | 90 s | 17 × 60 / 90 = **~11** | 4 | alto: muita rega e 90 s de chance de mato |

Como ler a tabela:
- **Lucro por colheita** = preço de venda - preço da semente.
- **Lucro por minuto** é o **melhor caso**: conta só o tempo crescendo. Não conta o ajudante
  andando, plantando e colhendo, nem o tempo parado seca ou com mato. O real é menor, e a
  abóbora é a que mais perde, porque é a que mais depende do ajudante chegar a tempo.
- **Regas**: o ajudante rega quando a água cai abaixo de `THIRSTY_BELOW`, ou seja, a cada
  **21 s** (de 1.0 até 0.3, descendo 1/30 por segundo). Abóbora: regas em 21, 42, 63 e 84 s = 4.

Planta mais longa **rende mais por minuto, mas dá mais trabalho pros ajudantes**: mais regas,
mais chance de mato. Com poucos ajudantes, abóbora fica parada com sede e perde pra cenoura.
Com muitos ajudantes (ou com Regador e Enxada), abóbora ganha. **Essa é a decisão central do
jogo, e ela acontece no shop**: que semente comprar depende de quantos ajudantes você tem e
de quais ferramentas deu pra eles.

---

## 5. `main.odin`

É o **dono do mundo**. Tudo mora aqui dentro e é passado por ponteiro.

**O que main guarda**

```
grid     : Grid                (o array 2D de tiles, dentro de um struct)
inv      : Inventory           (moedas, colheita, sementes, ferramentas, madeira, pedra)
helpers  : [dynamic]Helper
cam      : Camera              (que pedaço do mapa aparece na tela)
ui       : UiState             (item na mão, tile embaixo do mouse)
```

Repare no que **não** tem: player (você é o mouse e a câmera), `game_over` (não tem
derrota).

**O `grid` é global.** O mapa tem 6144 tiles, uns 250 KB. Declare `grid: Grid` **fora** do
`main` (no topo do `main.odin`), e não como variável local. Local, ele mora na pilha, e o
`SaveData` da Etapa 14 carrega **outra** cópia dos tiles. O padrão do Windows é 1 MB de
pilha, e pilha estourada fecha o jogo sem mensagem nenhuma. O seu build (`.vscode/tasks.json`)
já sobe a pilha pra 8 MB com `/STACK:8388608`, mas global continua sendo o mais seguro: não
depende de uma flag que um dia alguém apaga. O resto
continua igual: o `main` passa `&grid` pra quem muda e `grid` pra quem só lê.

**A forma do `main`**

```
main :: proc() {
    InitWindow / SetTargetFPS

    // ---- SETUP: roda uma vez ----
    if !save_load(&grid, &inv, &helpers) {       // Etapa 14. Antes dela: só o else
        grid    = grid_spawn()
        inv     = inventory_spawn()
        helpers = spawn_initial_helpers()
    }

    cam = camera_spawn()                         // começa olhando pro cesto

    for !WindowShouldClose() {
        dt := GetFrameTime()

        // ---- UPDATE ----
        camera_update(&cam, dt)                  // borda do mouse, teclado: move a vista
        ui_update(&ui, cam, &grid, &inv, &helpers) // lê mouse e teclado, chama as try_ do shop
        crop_update_all(&grid, inv, dt)          // cresce, seca, nasce mato
        resource_update_all(&grid, dt)           // rochas esgotadas se recuperam (Etapa 11)
        helper_update_all(helpers[:], &grid, &inv, dt)
        goals_update(goals[:], grid, inv, len(helpers))
        save_autosave_update(&autosave_timer, grid, inv, helpers[:], dt)

        // ---- DRAW ----
        BeginDrawing()
        ClearBackground(BG_COLOR)
            camera_begin(cam)            // ---- daqui até o camera_end: coordenadas do MAPA ----
                grid_draw(grid, cam)             // chão: grama, canteiro, cesto
                crop_draw_all(grid, cam)         // plantas por cima do canteiro
                resource_draw_all(grid, cam)     // árvores e pedras (Etapa 11)
                house_draw_all(grid, cam)        // casas (Etapa 12)
                decor_draw_all(grid, cam)
                helper_draw_all(helpers[:])
                ui_draw_hover_outline(ui, grid, inv) // contorno do tile embaixo do mouse
            camera_end()                 // ---- daqui pra baixo: coordenadas da TELA ----
            ui_draw_hover_info(ui, grid) // caixinha de info do tile
            ui_draw_shop(ui, inv, len(helpers))
            hud_draw(inv, len(helpers), goals[:])
        EndDrawing()
    }
    save_write(grid, inv, helpers[:])            // salva ao fechar
    CloseWindow()
}
```

Esse é o esqueleto **do fim da Etapa 14**. Nas etapas iniciais cada linha aparece só quando
o arquivo dela nasce.

**Quatro coisas que esse esqueleto ensina:**

1. **O `ui_update` vem primeiro.** Ele transforma clique em compra ou venda. Tudo o que vem
   depois já vê o inventário com a compra aplicada neste frame: a semente que você acabou de
   comprar já pode ser pega por um ajudante no mesmo frame.
2. **O `camera_update` vem antes do `ui_update`.** Assim o "tile embaixo do mouse" é calculado
   com a câmera **já** na posição deste frame. Na ordem contrária, o clique cai no tile onde
   a câmera estava no frame passado.
3. **O draw tem duas metades.** Entre `camera_begin` e `camera_end`, tudo é desenhado em
   **coordenadas do mapa** e a câmera empurra pro lugar certo da tela. Depois do
   `camera_end`, tudo é **coordenada da tela**: HUD, shop e caixinha de info ficam paradas
   enquanto o mapa rola por baixo. Desenhou o shop dentro da câmera? Ele sai andando junto
   com o mapa.
4. **A ordem do draw é a profundidade.** Chão, planta, árvore, casa, decoração, ajudante,
   contorno do mouse, e por fim o shop. O ajudante por cima da planta, o shop por cima de tudo.

---

## 6. Fichas das etapas

Cada ficha diz: **struct**, **procs**, **onde chamar**. Siga na ordem.

**Sobre as teclas de debug:** o jogador final nunca planta nem colhe. Mas nas Etapas 2 a 4
ainda não existe ajudante, e você precisa testar a planta. Pra isso existem **teclas de
debug** provisórias (F1, F2...), todas marcadas com `// DEBUG` no código. A Etapa 7 apaga
todas.

---

### Etapa 1 - Janela, grid, câmera e mouse (`config.odin` + `main.odin` + `grid.odin` + `camera.odin`)

**Struct `Tile`** (começa mínimo e cresce nas próximas etapas)

| Campo | Tipo | Pra que serve |
|---|---|---|
| `kind` | enum `TileKind` | `.Grass`, `.Soil`, `.Basket` |

**Struct `Grid`**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `tiles` | `[GRID_W][GRID_H]Tile` | o terreno inteiro. **Array fixo**, não `[dynamic]`: o grid nunca muda de tamanho |

Por que embrulhar o array num struct: fica um tipo só pra passar (`^Grid`), e se um dia o
grid ganhar mais campos (tipo "lotes comprados"), ninguém muda de assinatura.

Acesso: `grid.tiles[x][y]`. **x primeiro, y depois**, sempre. Misturar a ordem é o bug mais
comum de grid: o jogo "funciona" num grid quadrado e quebra no retangular.

**Três tipos de coordenada** (entenda isso antes de escrever qualquer proc)

| Coordenada | Unidade | Exemplo | Quem usa |
|---|---|---|---|
| **Tile** | índice no grid | `(45, 32)` | `grid.tiles[x][y]`, tarefas dos ajudantes, constantes `_TILE` |
| **Mapa** | pixel do mapa inteiro (0 até 3072) | `(1440, 1024)` | posição do ajudante, tudo desenhado dentro da câmera |
| **Tela** | pixel da janela (0 até 1280) | `(400, 300)` | mouse, HUD, shop |

As conversões:
- **Tile -> mapa:** vezes `TILE`. É conta sua (`tile_to_world`).
- **Mapa -> tela:** quem faz é a câmera. Tudo desenhado entre `camera_begin` e `camera_end` é
  convertido sozinho pela raylib.
- **Tela -> mapa:** `rl.GetScreenToWorld2D(mouse, camera)`. É o caminho do mouse.
- **Mapa -> tile:** divide por `TILE`, com `floor` (`world_to_tile`).

O bug clássico: esquecer a câmera no caminho do mouse. **Com a câmera no canto do mapa
funciona**, e basta rolar um pouco pra o clique cair no tile errado.

**Procs de `grid.odin`**

- `grid_spawn :: proc() -> Grid`
  Tudo `.Grass`. Nesta etapa é só isso.
  **Onde chamar:** setup do `main`.
- `tile_to_world :: proc(x, y: int) -> rl.Vector2`
  O canto de cima-esquerda do tile **no mapa**: `{x * TILE, y * TILE}`.
  Todo `_draw` de tile passa por ela.
- `tile_center :: proc(x, y: int) -> rl.Vector2`
  O meio do tile no mapa: `tile_to_world(x, y) + TILE / 2`. É pra onde o ajudante anda.
- `world_to_tile :: proc(pos: rl.Vector2) -> (x, y: int, ok: bool)`
  O caminho inverso: de um ponto do mapa pro tile embaixo dele.
  `x = int(floor(pos.x / TILE))`, igual pro y.
  `ok = false` se caiu fora do grid (x < 0, x >= GRID_W, etc.).

  **Três retornos**, um recurso do Odin: quem chama escreve `tx, ty, ok := ...` e **tem que**
  olhar o `ok` antes de usar `tx, ty`. Índice fora do array derruba o programa.

  **Use `floor`, não só `int(...)`.** `int(-0.5)` dá 0, mas meio tile à esquerda do mapa
  não está no tile 0.
- `grid_draw :: proc(g: Grid, cam: Camera)`
  Um retângulo por tile: grama verde, canteiro marrom, cesto amarelo-palha. Uma linha fina
  mais escura em volta de cada um, pra ver o grid.
  **Desenha só os tiles que aparecem** (`camera_visible_tiles`, abaixo).
  Por valor, sem `^`: o Odin passa structs grandes por referência escondido quando o
  parâmetro não é `^`, então não tem cópia de 6144 tiles por frame.
  **Onde chamar:** primeiro no draw, dentro da câmera.

**`camera.odin`**

**Struct `Camera`**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `rl_cam` | `rl.Camera2D` | a câmera da raylib. `offset = {VIEW_X, VIEW_Y}`, `zoom = 1`, e `target` = **o ponto do mapa que aparece no canto de cima-esquerda da vista** |
| `edge_timer` | f32 | há quanto tempo o mouse está parado na borda (o `EDGE_DELAY`) |

Com `offset` no canto da vista, o `target` fica fácil de pensar: é "onde a vista começa no
mapa". `target = {0, 0}` mostra o canto de cima-esquerda do mapa.

**Procs**

- `camera_spawn :: proc() -> Camera`
  Começa centralizada no cesto: `target = tile_center(BASKET_TILE) - {VIEW_W / 2, VIEW_H / 2}`,
  e depois `camera_clamp`.
- `camera_clamp :: proc(c: ^Camera)`
  Segura o `target` dentro do mapa: x entre `0` e `GRID_W * TILE - VIEW_W`, y entre `0` e
  `GRID_H * TILE - VIEW_H`. Sem isso, a câmera sai do mapa e mostra o fundo vazio.
- `camera_update :: proc(c: ^Camera, dt: f32)`
  Soma uma direção de todas as formas de mover, anda e segura:
  1. **Teclado:** WASD e setas.
  2. **Borda do mouse:** mouse **dentro da vista** e a menos de `EDGE_MARGIN` de uma borda:
     empurra pra aquele lado. `edge_timer += dt`, e só empurra se `edge_timer >= EDGE_DELAY`.
     Mouse longe das bordas (ou fora da vista, em cima do shop): `edge_timer = 0`.
  3. `target += direção * CAMERA_SPEED * dt`.
  4. **Arrastar com o botão do meio:** `target -= rl.GetMouseDelta()`. Arrastar pra direita
     puxa o mapa junto, então a vista vai pra esquerda: por isso o sinal de menos.
  5. **Espaço:** volta pro cesto (o mesmo cálculo do `camera_spawn`).
  6. `camera_clamp`.

  **Onde chamar:** primeira linha do update. É a única proc além do `ui_update` que lê
  entrada.
- `camera_begin :: proc(c: Camera)` e `camera_end :: proc()`
  `camera_begin`: `rl.BeginScissorMode(VIEW_X, VIEW_Y, VIEW_W, VIEW_H)` e
  `rl.BeginMode2D(c.rl_cam)`. `camera_end`: `rl.EndMode2D()` e `rl.EndScissorMode()`, na
  ordem contrária.
  O **scissor** corta o desenho no retângulo da vista. Sem ele, uma árvore na borda do mapa
  aparece por baixo do HUD e do shop.
- `camera_visible_tiles :: proc(c: Camera) -> (x0, y0, x1, y1: int)`
  Quais tiles aparecem na vista: `x0 = int(target.x / TILE)`,
  `x1 = int((target.x + VIEW_W) / TILE) + 1`, igual pro y, tudo seguro entre 0 e
  `GRID_W`/`GRID_H`. **Todo `_draw_all` que passa pelo grid faz o loop só de `x0` até `x1`.**
  O mapa tem 6144 tiles e a vista mostra uns 480: sem isso, cada frame desenha 13 vezes mais
  coisa do que aparece.
- `mouse_to_tile :: proc(c: Camera) -> (x, y: int, ok: bool)`
  O caminho completo do mouse, na ordem:
  1. O mouse está **dentro da vista**? Não (em cima do shop ou do HUD): `ok = false`.
     **Pule esse passo e o mouse em cima do shop "acerta" um tile do mapa que está escondido
     embaixo do painel.** Não cai, só clica no lugar errado, e é bem pior de achar.
  2. `world := rl.GetScreenToWorld2D(rl.GetMousePosition(), c.rl_cam)`.
  3. `return world_to_tile(world)`.

**Testa:** a janela abre e o mapa aparece. Escreva na tela o tile embaixo do mouse
(`"45, 32"`). Leve o mouse pras quatro bordas e veja a câmera andar e **parar** nas bordas do
mapa. Role até o canto de baixo-direita e confira que o tile ali é `"95, 63"`. Passe o mouse
rápido da vista pro shop: a câmera **não** pode dar tranco. Mouse em cima do shop: tem que
dizer "fora".

---

### Etapa 2 - Canteiro, cesto e planta crescendo (`grid.odin` + `crop.odin`)

**Tile ganha a planta e a reserva**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `kind` | `TileKind` | `.Grass`, `.Soil`, `.Basket` |
| `crop` | `Crop` | a planta **dentro** do tile. `crop.kind == .None` = canteiro vazio |
| `reserved` | bool | um ajudante já pegou uma tarefa neste tile (Etapa 6) |

**Struct `Crop`**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `kind` | enum `CropKind` | `.None`, `.Carrot`, `.Lettuce`, `.Pumpkin` |
| `growth` | f32 | segundos de crescimento acumulados |
| `water` | f32 | 0 a 1. Entra na Etapa 4 |
| `weeds` | bool | tem mato. Entra na Etapa 4 |

**A planta mora dentro do tile, não numa lista.** Lista serve pra coisas que podem estar em
qualquer posição. A planta tem um lugar fixo, e o grid **já é** a lista: um
canteiro tem no máximo uma planta. Sem índice, sem `active`, sem busca.

**"Pronta" não é campo, é conta:** `crop.growth >= CROP_GROW_TIME[crop.kind]`. Guardar um
`ready: bool` junto seria guardar a mesma informação duas vezes, e um dia as duas discordam.

- `crop_is_ready :: proc(c: Crop) -> bool` - a conta acima (e `false` se `kind == .None`).
- `crop_can_plant :: proc(g: Grid, x, y: int) -> bool` - tile `.Soil` e `crop.kind == .None`.

**Procs**

- `grid_spawn` agora faz o cesto em `BASKET_TILE` e um bloco 3 x 2 de `.Soil` no meio da
  clareira (colunas 48 a 50, linhas 31 e 32).
- `crop_try_plant :: proc(g: ^Grid, x, y: int, kind: CropKind) -> bool`
  Se `crop_can_plant`: liga `crop = {kind = kind, water = 1}`.
  **Não mexe em semente nem em moeda.** Quem planta traz a semente na mão (o ajudante tira
  ela do inventário na Etapa 6). A planta só sabe que foi plantada.
- `crop_update_all :: proc(g: ^Grid, dt: f32)`
  Passa por todos os tiles. Planta não pronta: `growth += dt`.
  **Onde chamar:** no update, depois do `ui_update`.
- `crop_draw_all :: proc(g: Grid, cam: Camera)` (só os tiles de `camera_visible_tiles`)
  Um círculo no meio do tile, **crescendo** com `growth / tempo_total`: cenoura laranja,
  alface verde-clara, abóbora laranja-escura e maior. **Pronta: um contorno branco
  piscando**, pra ler de longe o que está esperando um ajudante.
  **Onde chamar:** no draw, logo depois do `grid_draw`.

**Debug:** no `main`, `F1` com o mouse num canteiro chama `crop_try_plant` com cenoura.

**Testa:** apertar F1 nos canteiros e ver as cenouras crescerem e piscarem depois de 20 s.
F1 na grama e no cesto: nada acontece.

---

### Etapa 3 - `inventory.odin` e `shop.odin`: o que entra, o que sai

**Struct `Inventory`**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `coins` | int | começa em 20 |
| `crops` | `[CropKind]int` | colheita guardada, esperando você vender (ou usar pra criar ajudante). Array enumerado de novo |
| `seeds` | `[CropKind]int` | sementes guardadas, esperando um ajudante plantar. Começa com `START_SEEDS` |
| `tools` | `[ToolKind]int` | nível de cada ferramenta, 0 a 3 (Etapa 8) |
| `plots_bought` | int | quantos lotes você já comprou (Etapa 10) |

**Duas prateleiras separadas: `crops` e `seeds`.** Cenoura colhida não vira semente. A única
porta entre as duas é o shop: você vende da prateleira de colheita e compra pra prateleira
de sementes. É esse vai e vem que faz o jogo.

**Procs de `inventory.odin`** (guardar e tirar, nada de preço)

- `inventory_spawn :: proc() -> Inventory` - `coins = START_COINS`, `seeds = START_SEEDS`, resto zerado.
- `inventory_spend :: proc(inv: ^Inventory, amount: int) -> bool`
  Gasta se tiver, devolve `false` se faltar.
  **A única proc que tira moeda.** Assim moeda negativa é impossível.
- `inventory_store_crop :: proc(inv: ^Inventory, kind: CropKind)` - `crops[kind] += 1`.
  Chamada quando a colheita chega no cesto.
- `inventory_take_seed :: proc(inv: ^Inventory, kind: CropKind) -> bool`
  Tira 1 semente se tiver. **A única proc que tira semente.**

**Procs de `shop.odin`** (tudo que tem preço mora aqui, e nada aqui desenha)

- `shop_sell :: proc(inv: ^Inventory, kind: CropKind)`
  `coins += crops[kind] * CROP_SELL_PRICE[kind]` e zera `crops[kind]`. Vende a prateleira
  inteira daquela planta.
- `shop_sell_all :: proc(inv: ^Inventory)` - `shop_sell` pra cada planta.
  Vender por pilha (e não uma por uma) é de propósito: a decisão é "vendo as cenouras agora
  ou guardo pra criar ajudante" (Etapa 9), não "quantas eu vendo".
- `shop_try_buy_seed :: proc(inv: ^Inventory, kind: CropKind, amount: int) -> bool`
  `inventory_spend(inv, CROP_SEED_PRICE[kind] * amount)` e, se deu, `seeds[kind] += amount`.
  **Compra tudo ou nada**: sem moeda pra 10, não compra 7.

- `crop_try_harvest :: proc(g: ^Grid, x, y: int) -> (CropKind, bool)` (em `crop.odin`)
  Planta pronta: zera o `crop` do tile (volta a `.None`) e devolve o tipo colhido.
  Não mexe no inventário: **quem colhe decide o que fazer com a planta**. O ajudante
  (Etapa 6) carrega até o cesto antes de guardar.

**Debug:** `F1` agora só planta se `crop_can_plant` **e** `inventory_take_seed` deram certo
(nessa ordem: tile inválido não gasta semente). `F2` num tile pronto colhe e chama
`inventory_store_crop`. `F3` compra 1 semente de cenoura, `F4` vende tudo.

**`hud.odin` nasce aqui:**
- `hud_draw :: proc(inv: Inventory, helper_count: int)` - moedas na barra de cima.
  Por valor: HUD não muda nada. (O inventário completo aparece no shop, Etapa 7. Até lá,
  escreva `crops` e `seeds` no HUD mesmo.)

**Testa:** o ciclo inteiro na mão, só pra conferir as contas. Plantar cenoura (semente -1),
esperar, colher (colheita +1), vender (+3), comprar semente (-1). Ver as moedas subirem.
**Este é o ciclo que os ajudantes vão rodar sozinhos**: confira que ele fecha antes de
entregar pra eles.

---

### Etapa 4 - Água e mato (`crop.odin`)

Agora a planta precisa de cuidado. Ainda não existe ajudante, então você testa com debug.

**`crop_update_all` ganha regras** (só pra plantas não prontas):
- `water -= WATER_DECAY * dt`, com piso em 0.
- **Só cresce se `water > 0` e não tem mato.** Senão, `growth` fica parado.
- Mato: `if !weeds && rand.float32() < WEED_CHANCE * dt { weeds = true }`.
  O `* dt` transforma "0.5% por segundo" em "chance neste frame". Sem ele, a 60 FPS a chance
  vira 30% por segundo e a horta vira um matagal.

**Procs novas**

- `crop_needs_water :: proc(c: Crop) -> bool` - não pronta e `water < THIRSTY_BELOW`.
- `crop_try_water :: proc(g: ^Grid, x, y: int) -> bool` - tem planta: `water = 1`.
- `crop_try_weed :: proc(g: ^Grid, x, y: int) -> bool` - tem mato: `weeds = false`.

Todas `try_`: não leem mouse. Na versão final **só o ajudante** chama.

**Desenho:**
- Uma barrinha azul embaixo da planta com o nível de água. Com sede: a planta fica mais
  apagada.
- Mato: três tracinhos verde-escuros em volta da planta.

**Debug:** `F5` num canteiro rega e tira o mato.

**Testa:** plantar abóbora, não regar e ver o crescimento parar quando a água acaba. Regar e
ver voltar. Esperar mato aparecer, e ver que ele também para o crescimento.

---

### Etapa 5 - `helper.odin`, parte 1: existir e andar

**Struct `Helper`**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `pos` | `rl.Vector2` | posição **no mapa, em pixels**, não em tile nem na tela. Ele anda liso entre os tiles |
| `state` | enum | `.Idle`, `.Going`, `.Working`, `.Delivering` |
| `task` | enum `TaskKind` | `.None`, `.Plant`, `.Water`, `.Weed`, `.Harvest` |
| `target` | `[2]int` | o tile da tarefa |
| `work_timer` | f32 | cronômetro do trabalho |
| `find_timer` | f32 | de quanto em quanto tempo ele procura tarefa (Etapa 6) |
| `seed` | `CropKind` | `.None` ou a semente que ele pegou do inventário e vai plantar |
| `carrying` | `CropKind` | `.None` ou o que ele colheu e está levando pro cesto |
| `wander_timer` | f32 | quando está à toa, de quanto em quanto tempo ele troca de lugar |
| `wander_to` | `rl.Vector2` | pra onde ele está passeando |
| `active` | bool | vivo ou não |

**Por que `pos` em pixel e `target` em tile:** o ajudante **anda** em pixel (liso), mas
**trabalha** em tile (discreto). Converter um no outro é o `tile_center` da Etapa 1.

**Por que `seed` e `carrying` separados:** um é o que ele leva **pra** horta, o outro é o
que ele traz **da** horta. Um campo só pra os dois vira um "estou levando cenoura... pra
plantar ou pra guardar?" que ninguém sabe responder.

**`utils.odin`**

- `move_towards_2d :: proc(pos: ^rl.Vector2, target: rl.Vector2, speed, dt: f32) -> bool`
  Anda até o alvo e diz se chegou:
  `d := target - pos^`, `dist := rl.Vector2Length(d)`. Chegou (`dist < 2`): `true`.
  Senão, `step := min(speed * dt, dist)` e `pos^ += d / dist * step`.
  O `min` impede passar do alvo e ficar tremendo em volta dele.
  **Divida por `dist` só depois de checar que não é zero**, senão dá `NaN` e o ajudante some
  da tela sem erro nenhum.

**Sem pathfinding.** Ele anda em linha reta por cima de tudo (grama, planta, cesto). Numa
horta pequena isso não incomoda ninguém, e economiza um A* inteiro.

**Procs**

- `helper_spawn :: proc(pos: rl.Vector2) -> Helper` - `.Idle`, `active = true`.
- `spawn_initial_helpers :: proc() -> [dynamic]Helper` - 1 ajudante ao lado do cesto.
- `helper_update_all :: proc(hs: []Helper, g: ^Grid, inv: ^Inventory, dt: f32)`
  Nesta etapa só o `.Idle`: `wander_timer -= dt`; zerou, sorteia um ponto perto do cesto e
  anda até lá com `move_towards_2d`. Parado de vez fica sem vida. Passeando parece vivo.
  **Onde chamar:** no update, depois do `crop_update_all`.
- `helper_draw_all :: proc(hs: []Helper)`
  Quadrado 12 x 12 branco (é um mini-coelho). Com semente na mão: um pontinho marrom do lado.
  Carregando colheita: um círculo da cor da planta em cima da cabeça.
  **Durante o desenvolvimento, escreva o `state` e o `task` em cima dele.**
  **Onde chamar:** no draw, depois das plantas e da decoração.

**Testa:** ver o ajudante passeando em volta do cesto sem tremer quando chega.

---

### Etapa 6 - `helper.odin`, parte 2: o ciclo do trabalho (o coração do jogo)

Agora o ajudante faz **tudo** que você fazia com as teclas de debug: planta, rega, tira mato,
colhe e guarda.

| Estado | O que ele faz | Quando troca |
|---|---|---|
| `.Idle` | passeia e, **a cada `FIND_TASK_INTERVAL` (0.5 s)**, procura tarefa com `helper_find_task` | achou -> reserva o tile (e pega a semente, se for plantar) -> `.Going` |
| `.Going` | anda até `tile_center(target)`. **Todo frame confere se a tarefa ainda faz sentido** | chegou -> `.Working` / não faz mais sentido -> `helper_release` -> `.Idle` |
| `.Working` | parado, `work_timer` corre (`PLANT_TIME`, `WATER_TIME`, `WEED_TIME`, `HARVEST_TIME`) | zerou -> faz a tarefa, `helper_release`. Colheu -> `.Delivering`. Senão -> `.Idle` |
| `.Delivering` | leva a colheita até o cesto | chegou -> `inventory_store_crop`, `carrying = .None` -> `.Idle` |

**Qual semente plantar:** o ajudante não escolhe por gosto, ele segue o que você comprou.

- `inventory_pick_seed :: proc(inv: Inventory) -> (CropKind, bool)` (em `inventory.odin`)
  **A semente mais cara que tiver no estoque.** Sem nenhuma semente: `ok = false`.

Mais cara primeiro porque, se você gastou 8 moedas numa abóbora, você quer ela na terra, não
esperando atrás de 30 cenouras. E fica previsível: **o que você compra no shop é o que vai
pra terra.** Quer só cenoura? Compre só cenoura.

**Procs**

- `helper_find_task :: proc(g: Grid, inv: Inventory, from: rl.Vector2) -> (task: TaskKind, x, y: int, ok: bool)`
  Passa pelos tiles **não reservados** e dá nota pra cada tarefa possível:

  | Tarefa | Quando existe | Prioridade |
  |---|---|---|
  | `.Harvest` | `crop_is_ready` | 4 |
  | `.Weed` | `crop.weeds` | 3 |
  | `.Water` | `crop_needs_water` | 2 |
  | `.Plant` | `crop_can_plant` **e** tem alguma semente no inventário | 1 |

  Fica com **a de maior prioridade**; empate, **a mais perto** de `from`. Nada: `ok = false`.
  Colher vem primeiro porque planta pronta parada é dinheiro parado. Mato vem antes de água
  porque planta com mato não cresce nem regada. Plantar vem por último porque canteiro vazio
  não perde nada esperando, e planta com sede perde.
- `task_still_valid :: proc(g: Grid, h: Helper) -> bool`
  A mesma pergunta da tabela, só pro tile do `target`. Pro `.Plant`, só `crop_can_plant`: a
  semente ele já tem na mão. Responde "alguém já resolveu isso enquanto eu andava?".

**A reserva (a regra nova mais importante deste jogo)**

Sem reserva, dois ajudantes veem a mesma planta com sede, os dois vão, os dois regam, e
metade do seu time trabalhou à toa. Com 8 ajudantes vira um bando correndo atrás do mesmo pé.

- Ao escolher a tarefa: `g.tiles[x][y].reserved = true`.
- `helper_find_task` **ignora** tiles reservados.
- **Tarefa `.Plant` também reserva a semente:** na hora de escolher, `inventory_pick_seed` +
  `inventory_take_seed`, e guarda em `h.seed`. Sem isso, com 1 semente no estoque, 3
  ajudantes saem pra plantar e 2 chegam de mão vazia.
- **Toda saída da tarefa solta a reserva**: terminou, desistiu no `.Going`, ou o ajudante
  foi removido. Escreva uma proc só e chame ela em todos esses lugares:

  `helper_release :: proc(h: ^Helper, g: ^Grid, inv: ^Inventory)`
  Solta o `reserved` do tile e, **se `h.seed != .None`, devolve a semente**
  (`inv.seeds[h.seed] += 1`, `h.seed = .None`). Quando o plantio dá certo, zere o `h.seed`
  **antes** de chamar a release, senão a semente plantada volta pro estoque e vira semente
  infinita.

**Um tile com a reserva presa pra sempre é o bug mais chato deste jogo:** a planta fica
com sede e ninguém vai, sem erro nenhum. Se acontecer, desenhe um "R" vermelho nos tiles
reservados e vai estar óbvio qual caminho esqueceu de soltar.

**Por que procurar tarefa a cada 0.5 s e não todo frame:** `helper_find_task` passa pelos
6144 tiles. Com 20 ajudantes a 60 FPS dá **7 milhões** de checagens por segundo pra uma
resposta que quase nunca muda. A cada 0.5 s cai pra 245 mil, que é tranquilo. O
`find_timer` resolve: só pergunte o que pode ter mudado.

**Apague o debug de plantar, regar e colher (F1, F2, F5).** A partir daqui, quem põe a mão
na terra é só o ajudante. F3 e F4 (comprar e vender) ficam até a Etapa 7.

**Testa:** começar o jogo e **não tocar em nada**. Ver o ajudante pegar as 4 sementes do
começo, plantar, regar, colher, levar pro cesto e a colheita aparecer no inventário. Quando
as sementes acabam, ele volta a passear. Apertar F3 (comprar semente) e ver ele sair pra
plantar. Se isso funciona, o jogo existe.

---

### Etapa 7 - `ui.odin`: o shop e o fim das teclas de debug

**UI de modo imediato.** Botão não é um objeto que vive numa lista. Botão é **uma proc
chamada todo frame**, que desenha e responde:

```
ui_button :: proc(rect: rl.Rectangle, label: string, enabled: bool) -> bool
```

Desenha o retângulo (mais claro com o mouse em cima, apagado se `!enabled`), escreve o
texto e devolve `true` **só no frame do clique** (`IsMouseButtonPressed(.LEFT)` com o mouse
dentro do `rect` e `enabled`). Quem chama escreve `if ui_button(...) { faz a coisa }`.

**Mas atenção:** isso mistura desenho com leitura de clique, e a regra do jogo é
"`_update` não desenha". A saída limpa é separar em dois passos com o mesmo layout:
- `ui_shop_rects :: proc() -> ShopRects` - só calcula onde cada botão fica. Uma fonte de
  verdade pro layout.
- `ui_update` usa os `rects` pra saber **o que foi clicado**. `ui_draw_shop` usa os
  **mesmos** `rects` pra desenhar.

Assim o botão nunca é desenhado num lugar e clicável em outro.

**As seções do shop** (de cima pra baixo no painel)

| Seção | O que mostra | Botões |
|---|---|---|
| Inventário | colheita e sementes de cada planta | nenhum, só leitura |
| Vender | quanto cada pilha vale agora | um por planta (`shop_sell`) e "Vender tudo" (`shop_sell_all`) |
| Sementes | preço de cada uma | um por planta: clique compra 1, **Shift + clique compra 10** (`shop_try_buy_seed`) |
| Ferramentas | nível atual e preço do próximo | Etapa 8 |
| Ajudante | custo do próximo | Etapa 9 |
| Terreno e decoração | preço de cada | Etapa 10 |

Cada botão de venda mostra **quanto você vai ganhar** ("Cenoura x12 = +36"), e cada botão
de compra o preço. Botão sem moeda suficiente (ou sem nada pra vender) desenha apagado.

**Struct `UiState`**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `holding` | enum `PlaceKind` | `.None`, e na Etapa 10 `.Plot`, `.Flower`, `.Bench`, `.Lantern` (e `.House` na Etapa 12): o que está "na mão" esperando um tile |
| `hover_x`, `hover_y` | int | o tile embaixo do mouse |
| `hover_ok` | bool | o mouse está dentro da vista, em cima de um tile (o `ok` do `mouse_to_tile`) |

**Procs**

- `ui_update :: proc(ui: ^UiState, cam: Camera, g: ^Grid, inv: ^Inventory, hs: ^[dynamic]Helper)`
  **A única proc que lê mouse e teclado**, fora a `camera_update`, que só move a vista. Na ordem:
  1. Calcula o hover com `mouse_to_tile(cam)`. Mouse fora da vista: `hover_ok = false`.
  2. Atalhos: `V` vende tudo; `1`, `2`, `3` compram uma semente de cenoura, alface, abóbora.
  3. **Clique no shop?** (mouse com `x >= PANEL_X`) Resolve o botão e **para aqui**.
     Sem esse "para", um clique em "Comprar lote" também tentaria posicionar no tile
     embaixo.
  4. **Clique no grid?** Só com `hover_ok`, e só faz alguma coisa se tiver item na mão
     (Etapa 10). **Nunca planta, rega nem colhe.**

  `hs` é `^[dynamic]` porque o botão "Criar ajudante" (Etapa 9) faz `append`.
  **Onde chamar:** primeiro no update.
- **O hover são duas procs**, uma de cada lado da câmera:
  - `ui_draw_hover_outline :: proc(ui: UiState, g: Grid, inv: Inventory)` - **dentro** da
    câmera (coordenadas do mapa): um contorno fino no tile embaixo do mouse, usando
    `tile_to_world`. (Na Etapa 10 ele fica branco ou vermelho com item na mão.)
  - `ui_draw_hover_info :: proc(ui: UiState, g: Grid)` - **fora** da câmera (coordenadas
    da tela): sem item na mão e mouse num canteiro, **uma caixinha de info** do lado do
    mouse, com a planta, quanto falta pra ficar pronta, água e mato. É o único jeito de o
    jogador "conversar" com a horta, e ele só olha.

  Por que duas: o contorno tem que andar junto com o mapa quando a câmera rola; a caixinha
  tem que ficar do lado do mouse, legível, sem rolar.
- `ui_draw_shop :: proc(ui: UiState, inv: Inventory, helper_count: int)`
  O painel inteiro, seção por seção.

**Apague as teclas de debug que sobraram** (F3, F4) do `main`.

**Testa:** jogar só com o mouse. Comprar 5 sementes de alface e ver os ajudantes plantarem
alface. Vender a pilha de cenoura e ver as moedas subirem na hora. Clicar num canteiro com o
mouse: nada acontece na planta. Passar o mouse em cima de uma abóbora e ler quanto falta.

---

### Etapa 8 - Ferramentas (`tools.odin` + `shop.odin`)

Ferramenta é o jeito de **gastar dinheiro deixando os ajudantes melhores**, sem precisar de
mais ajudantes.

**A ferramenta é de todos.** Comprou o Regador nível 1, **todos** os ajudantes regam com
ele. Não tem equipar, não tem ferramenta na mão de um e não do outro. É um número no
`Inventory` (`tools[.Can] = 1`) que as procs de cálculo leem. Ferramenta por ajudante é
ideia da Fase 2.

**`ToolKind` e o efeito de cada nível**

| Ferramenta | Enum | Efeito por nível | Nível 0 / 1 / 2 / 3 |
|---|---|---|---|
| Botas | `.Boots` | anda mais rápido | 48 / 60 / 72 / 84 px/s (+25% por nível) |
| Regador | `.Can` | a rega dura mais | água dura 30 / 45 / 60 / 75 s |
| Enxada | `.Hoe` | planta e tira mato mais rápido | mato 2.0 / 1.5 / 1.0 / 0.5 s, plantar 1.0 / 0.75 / 0.5 / 0.25 s |
| Foice | `.Sickle` | colhe mais rápido | 1.0 / 0.75 / 0.5 / 0.25 s |

Cada uma ataca um gargalo diferente: Botas ajudam horta grande (muito caminho), Regador
ajuda abóbora (muita rega), Enxada ajuda quando o mato domina, Foice ajuda cenoura (muita
colheita). **Qual comprar primeiro depende do que você está plantando**, e é essa a graça.

**Procs de `tools.odin`** (só calculam, não mudam nada)

- `tool_speed :: proc(inv: Inventory) -> f32` - `HELPER_SPEED * (1 + 0.25 * f32(inv.tools[.Boots]))`.
- `tool_water_decay :: proc(inv: Inventory) -> f32` - `WATER_DECAY / (1 + 0.5 * f32(inv.tools[.Can]))`.
- `tool_work_time :: proc(inv: Inventory, task: TaskKind) -> f32`
  O tempo base da tarefa (`PLANT_TIME`, `WATER_TIME`, `WEED_TIME`, `HARVEST_TIME`) vezes `(1 - 0.25 * nível)` da ferramenta que cuida dela (Enxada pra
  `.Plant` e `.Weed`, Foice pra `.Harvest`; `.Water` não tem desconto, o Regador ajuda de
  outro jeito).

**Quem passa a chamar elas:**
- `helper_update_all` usa `tool_speed(inv^)` no `move_towards_2d` e `tool_work_time` ao
  começar o `.Working`.
- `crop_update_all` passa a receber `inv: Inventory` (por valor, só lê) e usa
  `tool_water_decay(inv)` no lugar de `WATER_DECAY`.

**Nenhum outro lugar do código lê `inv.tools` direto.** Se amanhã a Bota passar a dar +30%,
você muda uma linha só.

**Procs de `shop.odin`**

- `tool_next_price :: proc(inv: Inventory, kind: ToolKind) -> (price: int, ok: bool)`
  `ok = false` se já está no nível 3. Senão, `TOOL_PRICE[kind][inv.tools[kind]]`.
- `shop_try_buy_tool :: proc(inv: ^Inventory, kind: ToolKind) -> bool`
  `tool_next_price`, `inventory_spend`, e `tools[kind] += 1`.

No shop, cada ferramenta vira uma linha: nome, bolinhas do nível (3 círculos, cheios até o
nível atual) e o botão com o preço do próximo. No nível 3 o botão some e escreve "Máx".

**Testa:** plantar só abóbora com 1 ajudante e ver ele não dar conta das regas. Comprar o
Regador e ver as barrinhas azuis descendo mais devagar. Comprar Botas e ver os ajudantes
andando mais rápido.

---

### Etapa 9 - Criar ajudantes (`helper.odin` + `shop.odin`)

No Tiny Terraces você **fabrica** ajudantes com a colheita. Aqui também: é o que dá um
motivo pra **guardar** colheita no inventário em vez de vender tudo.

**Custo, crescendo a cada ajudante** (sai do inventário):

| Ajudante nº | Cenoura | Alface | Abóbora | Moedas |
|---|---|---|---|---|
| 2 | 5 | - | - | 10 |
| 3 | 8 | 3 | - | 20 |
| 4 | 10 | 5 | 1 | 40 |
| 5 em diante | +3 | +2 | +1 | +20 |

- `craft_cost :: proc(helper_count: int) -> CraftCost`
  `CraftCost :: struct { crops: [CropKind]int, coins: int }`. Uma tabela pros 3 primeiros e a
  regra de crescimento pro resto.
  **As moedas crescem somando (+20), não dobrando.** Com casas (Etapa 12) dá pra ter 20, 30
  ajudantes. Dobrando, o 20º custaria mais de 2 milhões de moedas.
- `helper_try_craft :: proc(hs: ^[dynamic]Helper, inv: ^Inventory) -> bool`
  Confere o máximo (`MAX_HELPERS`; na Etapa 12 vira "tem vaga em casa?"), confere **tudo**
  (`inv.crops` de cada planta e moedas), e **só depois** desconta tudo e dá `append` de um
  ajudante novo em cima do cesto.
  **Conferir tudo antes de descontar qualquer coisa**: se descontar as cenouras e aí
  descobrir que falta moeda, você perdeu cenoura por nada.
  **Onde chamar:** do botão "Criar ajudante" no `ui_update`.

O botão mostra o custo do **próximo** ajudante, com cada item vermelho se faltar.

**Repare na decisão que isso cria no shop:** o botão "Vender tudo" agora pode atrapalhar.
Se você vende as cenouras, não cria o próximo ajudante. Por isso a seção Vender tem botão
por planta: dá pra vender a abóbora e guardar a cenoura.

**Testa:** juntar 5 cenouras no inventário e 10 moedas, criar o 2º ajudante e ver os dois
dividindo as tarefas sem nunca irem no mesmo pé (é a reserva funcionando). Com 1 semente só
no estoque, ver só um dos dois sair pra plantar.

---

### Etapa 10 - Expandir terreno e decorar (`grid.odin` + `decor.odin` + `ui.odin`)

Terreno e decoração são as únicas compras que precisam de **um lugar** (a casa, na Etapa 12,
entra nesse mesmo grupo). Então elas são as únicas que usam o grid: você compra no shop, o item fica **na mão** (`ui.holding`), e você
clica no tile onde quer. **Só paga ao posicionar.**

- Clique no botão "Lote" ou "Flor" no shop: `ui.holding = .Plot` (ou `.Flower`...).
- Clique esquerdo num tile válido: chama a `try_`, que cobra. Deu certo: **continua na
  mão**, pra comprar vários lotes seguidos sem voltar no shop.
- Clique direito, ou clicar de novo no mesmo botão: `ui.holding = .None`. Nada foi pago,
  nada é devolvido.

`ui_draw_hover_outline` ganha cor: com item na mão, **branco se dá pra posicionar ali,
vermelho se não** (lote longe da horta, decoração em cima de canteiro, moeda insuficiente).

**Comprar lote:** transforma **um tile de grama** em canteiro. O ajudante enxerga o canteiro
novo sozinho no próximo `helper_find_task` e planta nele, se tiver semente.

- `plot_price :: proc(inv: Inventory) -> int` - `10 + 5 * inv.plots_bought`. Cada lote custa
  mais que o anterior: é a curva de progressão do idle.
- `plot_try_buy :: proc(g: ^Grid, inv: ^Inventory, x, y: int) -> bool`
  Tile `.Grass`, sem decoração, e **vizinho de um canteiro** (cima, baixo, esquerda ou
  direita). A regra do vizinho faz a horta crescer como um bloco, e não salpicada pelo grid.

**Decoração:** `Tile` ganha `decor: DecorKind` (`.None`, `.Flower`, `.Bench`, `.Lantern`).

| Decoração | Preço | Desenho |
|---|---|---|
| Flor | 5 | 3 circulinhos coloridos |
| Banco | 15 | retângulo marrom baixo |
| Lanterna | 25 | poste fino + círculo amarelo |

- `decor_try_place :: proc(g: ^Grid, inv: ^Inventory, x, y: int, kind: DecorKind) -> bool`
  Só em grama sem decoração. Cobra o preço.
- `decor_remove :: proc(g: ^Grid, inv: ^Inventory, x, y: int)` - devolve **metade** do preço.
  Clique direito numa decoração, **sem nada na mão**. Metade e não tudo: senão mudar a
  decoração de lugar vira um jeito de guardar moeda.
- `decor_draw_all :: proc(g: Grid, cam: Camera)` (só os tiles visíveis)

**Nesta versão a decoração é só bonita.** No Tiny Terraces também. Dar bônus pra ela (flor
faz planta vizinha crescer mais rápido) é ideia da Fase 2: primeiro veja se o jogador
decora só por gostar.

**Testa:** comprar lotes grudados na horta e ver os ajudantes plantarem neles sozinhos;
tentar posicionar longe da horta e o contorno ficar vermelho. Pôr e tirar uma flor e ver
voltar metade. Clique direito com lote na mão: solta o lote e não cobra nada.

---

### Etapa 11 - Floresta, pedra e profissões (`grid.odin` + `resource.odin` + `helper.odin` + `ui.odin`)

Até aqui todo ajudante é fazendeiro, e o mapa grande é só grama. Agora o mapa vira uma
**floresta enorme** em volta da clareira, com **jazidas de pedra** espalhadas, e você passa a
escolher **quem faz o quê**.

**O mapa**

`TileKind` ganha `.Tree`, `.Stump` (toco), `.Rock` e `.Gravel` (cascalho). `grid_spawn` passa
a fazer, nessa ordem:
1. **Tudo `.Tree`.** O mapa inteiro começa floresta.
2. **Clareiras naturais:** sorteie 1 em cada 6 tiles pra virar `.Grass`. Sem isso a floresta
   é um bloco verde chapado, sem textura.
3. **A clareira do jogo:** o retângulo `CLEARING_X, CLEARING_Y, CLEARING_W, CLEARING_H` vira
   `.Grass`. Depois, na volta de fora dele (1 tile), sorteie 1 em cada 3 árvores pra virar
   grama. Sem isso a clareira tem bordas retas, de régua.
4. **As jazidas:** pra cada item de `ROCK_CLUSTERS`, um bloco de 3 x 3 vira `.Rock`.
5. O resto como antes: os 6 canteiros, o cesto em `BASKET_TILE`.

**O ciclo de cada tile** (é o desenho da seção 4, agora em código)

```
.Tree   --cortar-->   .Stump  --arrancar-->  .Grass     (e fica grama pra sempre)
.Rock   --quebrar-->  .Gravel --120 s----->  .Rock      (a jazida se renova sozinha)
```

**Tile ganha um campo**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `respawn` | f32 | só no `.Gravel`: segundos até virar `.Rock` de novo |

Repare no que **não** precisa de campo: árvore em pé, toco e rocha estão sempre prontos pra
trabalhar. O `TileKind` sozinho já diz o que o tile é **e** o que dá pra fazer nele. Só o
cascalho está esperando alguma coisa, e só ele tem relógio.

**O toco trava o terreno**, igual no *Stardew Valley*: lote e casa (Etapas 10 e 12) só vão
em `.Grass`, então enquanto o toco estiver lá, o tile não serve pra nada. **Cascalho também
não é grama**: ninguém constrói em cima da jazida, e ela continua sendo jazida.

**Novos enums**

- `ResourceKind`: `.None`, `.Wood`, `.Stone`.
- `Job`: `.Farmer`, `.Lumberjack`, `.Miner`.
- `TaskKind` ganha `.Chop` (derrubar árvore), `.Uproot` (arrancar toco) e `.Mine` (quebrar
  rocha).

**`Inventory` ganha:** `res: [ResourceKind]int` - madeira e pedra guardadas. Array enumerado,
igual a `crops` e `seeds`.

**`Helper` ganha:**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `job` | `Job` | a profissão. Ajudante novo nasce `.Farmer` |
| `carrying_res` | `ResourceKind` | `.None` ou o que ele está levando pro cesto: madeira ou pedra |
| `carrying_amount` | int | quanto ele está levando (árvore dá 3, toco 1, rocha 2) |

Por que não reaproveitar o `carrying`: ele é `CropKind`, e madeira não é planta. Mesma lição
do `seed` e `carrying` da Etapa 5: um campo, um significado.

**Procs de `resource.odin`**

- `resource_try_take :: proc(g: ^Grid, x, y: int) -> (kind: ResourceKind, amount: int, ok: bool)`
  Faz a transição do tile e devolve o que saiu dele:

  | Tile antes | Tile depois | Devolve |
  |---|---|---|
  | `.Tree` | `.Stump` | `.Wood`, `TREE_WOOD` |
  | `.Stump` | `.Grass` | `.Wood`, `STUMP_WOOD` |
  | `.Rock` | `.Gravel`, com `respawn = ROCK_RESPAWN_TIME` | `.Stone`, `ROCK_STONE` |
  | qualquer outro | nada muda | `ok = false` |

  Igual ao `crop_try_harvest`: **não mexe no inventário**, quem pegou leva até o cesto.
- `resource_update_all :: proc(g: ^Grid, dt: f32)`
  Passa pelos tiles `.Gravel`: `respawn -= dt`; chegou a 0, vira `.Rock`.
  **Onde chamar:** no update, logo depois do `crop_update_all`.
- `resource_draw_all :: proc(g: Grid, cam: Camera)` (só os tiles visíveis)
  - **Árvore:** tronco marrom fino + copa, um círculo verde-escuro que passa um pouco do tile
    pra cima (fica com cara de árvore vista de cima-lado, como no Stardew).
  - **Toco:** um círculo marrom baixinho, com um círculo mais claro dentro (os anéis do
    tronco cortado).
  - **Rocha:** círculo cinza grande, com um círculo cinza-claro pequeno em cima (brilho).
  - **Cascalho:** chão cinza-amarronzado com 4 ou 5 pedrinhas espalhadas. Pra elas não
    mudarem de lugar a cada frame, a posição sai de uma conta com `x` e `y` do tile (ex.:
    `(x * 7 + y * 13) % TILE`), nunca de `rand` no draw.

  **Onde chamar:** no draw, depois do `crop_draw_all`.

**Mostrando o trabalho** (o "tuc, tuc" do Stardew, sem animação de verdade)

Enquanto um ajudante está `.Working` numa árvore, toco ou rocha, o `helper_draw_all` desenha:
- Uma **barrinha de progresso** em cima do tile (`1 - work_timer / tempo_total`).
- O **ajudante batendo**: o quadradinho dele vai e volta 2 px na direção do tile,
  `sin(tempo * 20)`. Parece machadada ou picaretada, e é só uma soma na posição do desenho
  (o `pos` de verdade não muda).

Quem sabe que o tile está sendo trabalhado é o ajudante, então **isso tudo é do
`helper_draw_all`**. O `resource_draw_all` continua sem saber de ajudante nenhum.

**Procs de `inventory.odin`**

- `inventory_store_res :: proc(inv: ^Inventory, kind: ResourceKind, amount: int)` -
  `res[kind] += amount`.

**O que muda no ajudante**

**A profissão não é outra máquina de estados. É um filtro.** Os quatro estados continuam os
mesmos; o que muda é quais tarefas o `helper_find_task` enxerga:

| Profissão | Tarefas que ele enxerga | Prioridade | Tempo trabalhando |
|---|---|---|---|
| `.Farmer` | a tabela da Etapa 6 (colher, mato, regar, plantar) | a da Etapa 6 | a da Etapa 6 |
| `.Lumberjack` | `.Uproot`: tile `.Stump` | 2 | `STUMP_TIME` |
| `.Lumberjack` | `.Chop`: tile `.Tree` | 1 | `CHOP_TIME` |
| `.Miner` | `.Mine`: tile `.Rock` | 1 | `MINE_TIME` |

- `helper_find_task` ganha o parâmetro `job: Job`. Mesma regra de sempre: maior prioridade
  primeiro, empate fica com **a mais perto** de `from`. Tudo só em tile **não reservado**.
- **Toco antes de árvore:** o lenhador termina de limpar o terreno antes de derrubar outra
  árvore. Sem isso a vila fica cercada de tocos, e nenhum tile vira grama.
- **Mais perto primeiro faz a floresta recuar em volta da vila**, como no Age of Empires: os
  lenhadores comem a borda da clareira, e o espaço livre cresce pra todos os lados sozinho.
- A **reserva** vale igual: dois lenhadores nunca vão na mesma árvore.
- `task_still_valid` ganha as três: o tile do `target` ainda é `.Tree`, `.Stump` ou `.Rock`,
  conforme a tarefa.
- No `.Working`, ao zerar o `work_timer`: `resource_try_take`, guarda em `carrying_res` e
  `carrying_amount`, `helper_release`, `.Delivering`.
- No `.Delivering`, ao chegar no cesto: se `carrying_res != .None`,
  `inventory_store_res(inv, carrying_res, carrying_amount)` e zera os dois. Se
  `carrying != .None`, `inventory_store_crop` e zera. Um ajudante só leva uma coisa por vez,
  mas o código do cesto confere as duas.

**O cesto fica no meio da vila de propósito:** a floresta começa perto, mas **recua** conforme
você corta, e **a caminhada é o custo** da madeira. Com o tempo o lenhador anda cada vez mais.
Um depósito perto da floresta (como o *lumber camp* do Age of Empires) é ideia da Fase 2, e
fica mais valioso quanto mais você corta.

**Trocar a profissão** (`helper.odin`)

- `helper_try_change_job :: proc(hs: []Helper, g: ^Grid, inv: ^Inventory, from, to: Job) -> bool`
  Acha um ajudante com `job == from`, **de preferência um `.Idle`** (pra não jogar trabalho
  fora). Nenhum com essa profissão: `false`.
  Achou: chama `helper_release` (solta a reserva e devolve a semente), guarda direto no
  inventário o que ele estiver carregando (`carrying`, e `carrying_res` com o
  `carrying_amount`), põe `.Idle` e troca
  o `job`.
  **Trocar de profissão é mais uma saída da tarefa**, então passa pelo `helper_release` como
  todas as outras. Esquecer isso é o jeito mais fácil de prender uma reserva.

**No shop: seção "Profissões"** (`ui.odin`)

| Linha | Botões |
|---|---|
| Fazendeiros: 3 | nenhum, é só leitura: **fazendeiro é quem sobra** |
| Lenhadores: 1 | `[-]` volta um lenhador pra fazendeiro, `[+]` transforma um fazendeiro em lenhador |
| Mineradores: 0 | igual, com minerador |

Os botões chamam `helper_try_change_job` (`[+]` é `from = .Farmer`, `[-]` é `to = .Farmer`).
O `ui_update` pode chamar essa proc: ela mexe **no ajudante**, não na terra. A regra "`ui.odin`
nunca chama `crop_try_...`" continua valendo, e ganha a irmã: **nem `resource_try_...`**.

O `hs` do `ui_update` é `^[dynamic]Helper`, então passe `hs^[:]` (o slice do array).

`ui_draw_hover_info` ganha a info do mato: "Árvore: 3 madeira", "Toco: 1 madeira, libera o
terreno", "Rocha: 2 pedra", "Cascalho: vira rocha em 42 s".

**Desenho do ajudante:** lenhador com um risquinho marrom (machado), minerador com um
risquinho cinza (picareta), fazendeiro sem nada. Carregando madeira: tronquinhos marrons em
cima da cabeça, um por madeira. Pedra: bolinhas cinza, uma por pedra.

**Testa:** começar com 1 ajudante e transformar ele em lenhador: a horta para (ninguém rega)
e a madeira sobe no inventário. Ver a árvore virar toco, e na viagem seguinte o toco virar
grama. Comprar um lote grudado num canteiro onde antes era floresta. Voltar o lenhador pra
fazendeiro no meio de uma tarefa: o "R" da árvore some e nenhuma semente some. Escalar 5
mineradores e ver a jazida perto virar cascalho, eles irem pra uma jazida longe, e 2 minutos
depois as rochas perto voltarem.

---

### Etapa 12 - Casas: onde os ajudantes moram (`house.odin` + `ui.odin` + `helper.odin`)

Como no *Age of Empires*: **cada casa abriga `HOUSE_CAPACITY` (5) ajudantes**. Casas
cheias, o botão "Criar ajudante" apaga, e o jeito de crescer é construir outra.

**A casa é só capacidade.** Ninguém entra nela, ninguém dorme nela. Ela existe pra dar
**motivo pra madeira e pedra** e pra forçar uma decisão: cada casa ocupa um tile de grama
que podia virar canteiro.

**Casa é um tipo de tile:** `TileKind` ganha `.House`. Nada de lista de casas: **o grid já é
a lista** (seção 9), de novo.

**Procs de `house.odin`**

- `house_count :: proc(g: Grid) -> int` - conta os tiles `.House`.
- `helper_capacity :: proc(g: Grid) -> int` - `house_count(g) * HOUSE_CAPACITY`.
  **A única proc que responde "cabe mais um ajudante?".** Ninguém guarda um
  `max_helpers` num campo: se guardasse, um dia a casa existe e o campo não foi atualizado.
- `house_try_place :: proc(g: ^Grid, inv: ^Inventory, x, y: int) -> bool`
  Tile `.Grass`, sem decoração. Chama `inventory_spend_res(inv, HOUSE_COST)` e, se deu, o
  tile vira `.House`. Não precisa ser vizinha de nada.
- `house_draw_all :: proc(g: Grid, cam: Camera)` (só os tiles visíveis) - quadrado bege com um triângulo marrom em cima
  (telhado). **Onde chamar:** no draw, depois do `resource_draw_all`.

**Procs de `inventory.odin`**

- `inventory_spend_res :: proc(inv: ^Inventory, cost: [ResourceKind]int) -> bool`
  **Confere todos os recursos antes de descontar qualquer um** (mesma regra do crafting da
  Etapa 9: sem pedra, não gasta a madeira). **A única proc que tira madeira e pedra.**

**O que muda**

- `grid_spawn` põe 1 casa pronta em `START_HOUSE_TILE`. Começa cabendo 5.
- `helper_try_craft` ganha `g: Grid` e troca o `MAX_HELPERS` por
  `len(hs) < helper_capacity(g)`. **Apague o `MAX_HELPERS` do `config.odin`.**
- No shop, seção "Construir": botão "Casa (10 madeira, 5 pedra)". Clique: `ui.holding =
  .House`, e dali pra frente é **o mesmo fluxo do lote da Etapa 10**: clique esquerdo
  posiciona e cobra, clique direito solta sem cobrar, contorno branco ou vermelho.
- O botão "Criar ajudante" com as casas cheias desenha apagado e escreve "Construa uma
  casa".
- `ui_draw_hover_info` em cima de uma casa: "Casa: 5 vagas".

**Casa não se demole** nesta versão. Se desse, você teria 10 ajudantes e vaga pra 5, e aí
precisaria decidir quem vai embora. Não vale o trabalho agora.

**Testa:** criar ajudantes até 5/5 e ver o botão apagar. Escalar um lenhador e um
minerador, juntar 10 madeira e 5 pedra, pôr a casa: vira 5/10 e o botão acende. Tentar pôr a
casa sem pedra suficiente: contorno vermelho, e a madeira **não** sai do inventário.

---

### Etapa 13 - HUD e metas (`hud.odin`)

Idle sem meta vira "deixar rodando e esquecer". Metas curtas dão o próximo passo, e aqui
todas elas são **uma compra ou um resultado dos ajudantes**, nunca "faça você mesmo".

- `Goal :: struct { text: string, done: bool }` e uma lista fixa de umas 11 metas:
  "Venda 10 cenouras", "Compre sua primeira semente de alface", "Tenha 3 ajudantes",
  "Compre uma ferramenta", "Escale um lenhador", "Construa uma casa", "Colha uma abóbora",
  "Tenha 20 canteiros", "Junte 500 moedas", "Tenha 15 ajudantes", "Abra 200 tiles de
  floresta". Algumas pedem contadores novos no `Inventory` (`total_harvested: [CropKind]int`,
  `total_sold: [CropKind]int`, `total_cleared: int`, que sobe quando um toco vira grama).
- `goals_update :: proc(goals: []Goal, g: Grid, inv: Inventory, helper_count: int)`
  Só liga `done`, nunca desliga.
  **Onde chamar:** no update, depois do `helper_update_all`.
- `hud_draw` mostra moedas, madeira, pedra, ajudantes (`4/5`: quantos tem / quantos cabem nas
  casas), **a primeira meta não cumprida**, e um aviso
  de 2 s "Meta cumprida!" quando uma liga.

**Um aviso a mais no HUD: "Sem sementes!"** quando `seeds` está zerado e tem canteiro vazio.
É o jeito de o jogo te chamar pro shop. Sem ele, o jogador vê os ajudantes passeando e acha
que a horta "acabou".

**Mais dois avisos, pelo mesmo motivo:**
- **"Casas cheias!"** quando `len(helpers) == helper_capacity(grid)` e o custo do próximo
  ajudante já está no inventário. O jogador juntou tudo e não entende por que o botão não
  acende.
- **"Ninguém na horta!"** quando nenhum ajudante é `.Farmer` e tem planta crescendo. Tirar
  todo mundo da horta pra cortar árvore é permitido, mas tem que ser de propósito.

**Testa:** cumprir as três primeiras metas jogando normal, sem forçar. Deixar as sementes
acabarem e ver o aviso aparecer.

---

### Etapa 14 - `save.odin`: salvar e carregar

**Idle sem save não existe.** Fechar o jogo e perder a horta é o jeito mais rápido de o
jogador nunca mais abrir.

**Struct `SaveData`** - só o que precisa voltar:

| Campo | Tipo |
|---|---|
| `version` | int (comece com 1) |
| `tiles` | `[GRID_W][GRID_H]Tile` |
| `inv` | `Inventory` (inclui sementes e nível das ferramentas) |
| `helpers` | `[]HelperSave` - **só a posição e a profissão** (`job`) de cada ajudante |

**O que não salvar:** estado, tarefa, reserva, o que ele carrega, a câmera (ao abrir, ela
volta pro cesto). Tocos, cascalho e o `respawn` vão junto com o `Tile`, sem trabalho extra.
Ao carregar, todo
ajudante volta `.Idle` e **todos os `reserved` voltam a `false`**. Salvar reserva é salvar
um bug: o ajudante que tinha reservado não existe mais com aquele estado.

**Mas não jogue fora o que está na mão deles.** Na hora de montar o `SaveData`, some no
`inv` copiado a semente (`h.seed`), a colheita (`h.carrying`) e a madeira/pedra
(`h.carrying_res`, na quantidade `h.carrying_amount`) de cada ajudante. Semente foi
comprada com o seu dinheiro: sumir com ela ao fechar o jogo parece roubo.

**Procs**

- `save_write :: proc(g: Grid, inv: Inventory, hs: []Helper) -> bool`
  Monta o `SaveData` (com as mãos dos ajudantes devolvidas ao inventário),
  `json.marshal` (de `core:encoding/json`) e grava em `save.json`.
- `save_load :: proc(g: ^Grid, inv: ^Inventory, hs: ^[dynamic]Helper) -> bool`
  Lê o arquivo, `json.unmarshal`, confere o `version`, preenche tudo e zera as reservas.
  Sem arquivo ou arquivo quebrado: devolve `false` e o `main` começa um jogo novo.
  **Nunca deixe um save quebrado derrubar o jogo.**
- `save_autosave_update :: proc(timer: ^f32, g: Grid, inv: Inventory, hs: []Helper, dt: f32)`
  A cada 30 s chama `save_write`. Fechar pelo X do Windows às vezes não passa pelo fim do
  `main`, e o autosave garante que você perde no máximo 30 s.

**Para ler e gravar o arquivo**, use `core:os`. A API de arquivos do Odin mudou em 2025,
então confira na sua versão o nome e o retorno de `read_entire_file`/`write_entire_file`
antes de escrever.

**Um cuidado com o `version`:** toda vez que você mudar um struct que vai pro save
(adicionar um campo no `Tile` ou no `Inventory`, por exemplo), suba o `version`. Um save
antigo com versão menor pode ser ignorado (começa jogo novo) no começo. Converter save
antigo é luxo pra depois.

**Testa:** jogar 2 minutos, fechar com um ajudante indo plantar, abrir: tudo no lugar e a
semente dele de volta no estoque. Apagar metade do `save.json` na mão e abrir: começa um
jogo novo sem travar.

---

## 7. Controles

| Entrada | Ação |
|---|---|
| Clique nos botões do shop | Vender (por planta ou tudo), comprar semente, ferramenta, ajudante, lote, decoração, casa |
| `[+]` / `[-]` em Profissões | Transforma um fazendeiro em lenhador ou minerador, e volta |
| Shift + clique numa semente | Compra 10 de uma vez |
| Clique esquerdo no grid | **Só com lote, decoração ou casa na mão:** posiciona e paga |
| Clique direito no grid | Com item na mão: solta ele (não cobra). Sem nada na mão, em cima de decoração: tira ela (devolve metade) |
| Mouse em cima de um canteiro | Mostra a planta, quanto falta, água e mato |
| Mouse em cima de árvore, toco, rocha, cascalho ou casa | Quanto dá de madeira/pedra, quanto falta pro cascalho voltar, vagas da casa |
| Mouse parado na borda da vista | Move a câmera pra aquele lado |
| WASD / setas | Move a câmera |
| Botão do meio + arrastar | Arrasta o mapa |
| Espaço | Volta a câmera pro cesto |
| 1 / 2 / 3 | Compra 1 semente de cenoura / alface / abóbora |
| V | Vende tudo |
| ESC | Salva e sai |

**O player nunca põe a mão na terra.** Não existe clique que plante, regue, tire mato,
colha, corte ou quebre. Tudo o que você faz passa pelo shop: você é o dono, eles são a equipe. No começo, com
1 ajudante e 4 sementes, o jogo é lento de propósito: a primeira decisão é quando vender e o
que comprar com as primeiras moedas.

---

## 8. Tabela de números

**Plantas**

| Planta | Semente | Venda | Crescer | Regas até ficar pronta (sem Regador) |
|---|---|---|---|---|
| Cenoura | 1 | 3 | 20 s | 0 (nasce com água cheia e fica pronta antes de dar sede) |
| Alface | 3 | 8 | 40 s | 1 |
| Abóbora | 8 | 25 | 90 s | 4 (uma a cada 21 s) |

**Cuidado** (valores base, sem ferramenta)

| Coisa | Valor |
|---|---|
| Água cheia dura | 30 s (de 1.0 até 0.0) |
| Com sede abaixo de | 0.3: o ajudante vem regar. Ainda cresce, e seca em 9 s se ninguém vier |
| Chance de mato | 0.5% por segundo, por planta crescendo |
| Plantar | 1 s |
| Regar | 1 s |
| Tirar mato | 2 s |
| Colher | 1 s |
| Cortar árvore | 3 s |
| Quebrar pedra | 4 s |

**Ferramentas**

| Ferramenta | Nível 1 / 2 / 3 (preço) | Efeito por nível |
|---|---|---|
| Botas | 20 / 60 / 150 | +25% de velocidade |
| Regador | 20 / 60 / 150 | água dura +15 s |
| Enxada | 15 / 45 / 120 | plantar e tirar mato -25% do tempo base |
| Foice | 25 / 75 / 180 | colher -25% do tempo base |

**Ajudantes**

| Coisa | Valor |
|---|---|
| Velocidade | 48 px/s (1.5 tile por segundo), sem Botas |
| Procura tarefa a cada | 0.5 s |
| Semente que planta | a mais cara que tiver no inventário |
| Começa com | 1, fazendeiro |
| Máximo | 5 por casa (começa com 1 casa) |
| Criar o 5º em diante | +3 cenoura, +2 alface, +1 abóbora e +20 moedas a cada um |

**Floresta, pedra e casas**

| Coisa | Valor |
|---|---|
| Mapa | 96 x 64 tiles (6144), umas 4 x 3 telas |
| Clareira do começo | 17 x 11 tiles no meio do mapa |
| Floresta | todo o resto (~4900 árvores), com clareirinhas sorteadas |
| Árvore | derrubar 3 s, dá 3 madeira, **vira toco** |
| Toco | arrancar 2 s, dá 1 madeira, **vira grama pra sempre** |
| Jazidas | 5 blocos de 3 x 3 rochas espalhados pela floresta |
| Rocha | quebrar 4 s, dá 2 pedra, **vira cascalho** |
| Cascalho | vira rocha de novo em 120 s. Não dá pra construir em cima |
| Casa | 10 madeira + 5 pedra, abriga 5 ajudantes, não se demole |

**Madeira e pedra por minuto** (confira se mexer nos números):
- **Madeira no começo:** a árvore mais perto do cesto fica a ~6 tiles (4 s de caminhada).
  Derrubar: 8 s de ida e volta + 3 s = 3 madeira. Arrancar o toco: 8 s + 2 s = 1 madeira.
  **~11 madeira por minuto por lenhador.**
- **Madeira depois:** a floresta recua. Com a borda 10 tiles mais longe (16 tiles do cesto),
  as mesmas 4 madeiras levam ~47 s: **~5 por minuto**. É aí que o depósito da Fase 2 faz
  falta.
- **Pedra, jazida perto** (`{60, 29}`, ~16 tiles): 21 s de ida e volta + 4 s = 2 pedra.
  **~4.8 pedra por minuto por minerador.** Mas a jazida inteira (9 rochas × 2 pedras, 120 s
  pra voltar) dá no máximo **9 por minuto**. Então **2 mineradores aproveitam a jazida
  perto; o 3º já sobra** e vai pra jazida seguinte.
- **Pedra, jazida seguinte** (`{24, 14}`, ~26 tiles): 35 s de ida e volta + 4 s: **~3 pedra
  por minuto por minerador**.
- **Uma casa** com 1 lenhador e 1 minerador: ~1 minuto.

**Terreno e decoração**

| Coisa | Valor |
|---|---|
| Canteiros no começo | 6 |
| Lote novo | 10 + 5 por lote já comprado |
| Flor / Banco / Lanterna | 5 / 15 / 25 |
| Tirar decoração | devolve metade |

**Inventário inicial**

| Coisa | Valor |
|---|---|
| Moedas | 20 |
| Sementes | 4 de cenoura |
| Colheita | vazia |
| Madeira e pedra | 0 |
| Ferramentas | todas no nível 0 |

---

## 9. Seis ideias que resolvem quase tudo

**1. O grid já é a lista.** Planta, árvore, pedra, casa, decoração e reserva moram **dentro
do tile**. Se uma coisa tem um lugar fixo no grid, ela não precisa de lista, índice nem
`active`. Até "quantos ajudantes cabem" é uma conta em cima do grid.

**2. Cada coisa tem um estado.** O ajudante é uma máquina de estados: `.Idle`, `.Going`,
`.Working`, `.Delivering`. Cada estado sabe o que faz e quando troca.

**3. Delta time.** Crescer, secar, andar e a chance de mato: tudo vezes `dt`.

**4. Quem lê entrada não executa ação, e cada um tem as suas `try_`.** `ui_update` decide
e chama as `try_` do shop. O ajudante chama as `try_` da planta. As duas turmas nunca se
cruzam: o jogador mexe no inventário, o ajudante mexe na terra, e o inventário é a ponte.

**5. Profissão é filtro, não outra máquina de estados.** Fazendeiro, lenhador e minerador
andam, trabalham e entregam do mesmo jeito. A única diferença é quais tarefas o
`helper_find_task` mostra pra cada um. Um tipo de ajudante novo (pescador?) é uma linha a
mais nesse filtro, não um arquivo novo.

**6. Três coordenadas, e cada coisa mora numa só.** Tile (índice do grid), mapa (pixel do
mundo) e tela (pixel da janela). Tarefas e constantes em tile, ajudante em mapa, mouse e
shop em tela. Toda conversão passa por uma proc com nome (`tile_to_world`, `world_to_tile`,
`mouse_to_tile`), e tudo desenhado entre `camera_begin` e `camera_end` é mapa.

---

## 10. Regras que evitam dor de cabeça

- **`grid.tiles[x][y]`, x primeiro, sempre.** Teste num grid que não seja quadrado.
- **Todo `mouse_to_tile` e `world_to_tile` olha o `ok`** antes de usar o tile.
- **Mouse fora da vista não é tile.** O `mouse_to_tile` confere a vista antes de converter.
- **Mapa dentro da câmera, HUD e shop fora.** Nunca desenhe o shop entre `camera_begin` e
  `camera_end`.
- **Todo `_draw_all` do grid passa pelo `camera_visible_tiles`.** O mapa tem 6144 tiles.
- **Lote e casa só em `.Grass`.** Toco e cascalho não contam como grama.
- **Toda saída de tarefa solta a reserva e devolve a semente**, por uma proc só
  (`helper_release`). **Trocar de profissão também é saída de tarefa.**
- **Plantou? Zere o `h.seed` antes da release.** Senão a semente volta e vira infinita.
- **Clique no shop não vaza pro grid.** Resolveu o shop, pare.
- **`ui.odin` nunca chama `crop_try_...` nem `resource_try_...`.** Se chamar, o jogador
  voltou a pôr a mão na terra.
- **Uma proc só tira moeda** (`inventory_spend`). Uma só tira semente (`inventory_take_seed`).
  Uma só tira colheita (a do crafting e a de venda, ambas no `shop.odin`). Uma só tira
  madeira e pedra (`inventory_spend_res`).
- **Só `tools.odin` lê `inv.tools`.** O resto pergunta pras procs dele.
- **Só `helper_capacity` responde "cabe mais um ajudante?".** Ninguém guarda esse número.
- **Confira tudo antes de descontar qualquer coisa** em compras com mais de um custo.
- **`_update` não desenha, `_draw` não muda valor.** O botão é a tentação: veja a Etapa 7.
- **Nunca deixe o save derrubar o jogo.** Falhou ao carregar, começa do zero.

---

## 11. O que NÃO fazer agora

sprites, animação, som, pathfinding, mais de 3 plantas, processar colheita (farinha, suco),
estações do ano, clima, dia e noite, janela na borda da tela, progresso offline,
ajudante com nome ou personalidade, ferramenta por ajudante, compra automática de semente,
escolher o que plantar em cada canteiro, menu principal, várias hortas, casa maior que
1 tile, casa que demora pra construir, demolir casa, outras construções além da casa,
depósito perto da floresta, zoom da câmera, minimapa, replantar árvore, escolher onde os
lenhadores cortam.

Regra: **se ver os quadradinhos trabalhando não é gostoso, sprite não vai salvar.**
Só troque primitivas por sprite quando as 14 etapas estiverem funcionando.

---

## 12. Como achar bug sem se desesperar

- **Escreva `state`, `task` e `seed` em cima de cada ajudante**, e um "R" nos tiles
  reservados. 90% dos bugs deste jogo ficam óbvios assim.
- **Ajudante parado com trabalho sobrando:** reserva presa. Procure o caminho de saída da
  tarefa que não chama `helper_release`.
- **Ajudantes passeando com canteiro vazio:** acabou a semente (confira o inventário no shop)
  ou o `.Plant` do `helper_find_task` não está olhando `inv.seeds`.
- **Semente some do estoque e ninguém planta:** alguém pegou semente e saiu da tarefa sem
  `helper_release` devolver.
- **Semente nunca acaba:** o `h.seed` não é zerado depois de plantar, e a release devolve.
- **Dois ajudantes no mesmo pé:** a reserva não está sendo ligada, ou `helper_find_task`
  não ignora reservados.
- **Ferramenta comprada e nada muda:** alguém ainda usa a constante (`WATER_DECAY`, `HELPER_SPEED`)
  direto em vez da proc do `tools.odin`.
- **Clique no lugar errado só depois de rolar a câmera:** o `mouse_to_tile` não passa pelo
  `GetScreenToWorld2D`. Com a câmera no canto do mapa ele "funciona" por coincidência.
- **Clique no lugar errado sempre:** `world_to_tile` sem `floor`, ou `[y][x]` em algum canto.
- **Clicar no shop mexe num tile do mapa:** o `mouse_to_tile` não confere se o mouse está
  dentro da vista.
- **Árvore aparecendo por cima do HUD ou do shop:** faltou o scissor no `camera_begin`.
- **HUD ou shop rolando junto com o mapa:** foram desenhados antes do `camera_end`.
- **Câmera dá tranco quando você vai pro shop:** o `edge_timer` não está zerando, ou o
  `EDGE_DELAY` não está sendo respeitado.
- **Jogo lento com o mapa grande:** algum `_draw_all` passa pelos 6144 tiles em vez de usar
  o `camera_visible_tiles`.
- **Toco que nunca some:** o lenhador não enxerga `.Uproot`, ou a prioridade do toco está
  abaixo da árvore.
- **Jazida que nunca volta:** o `resource_update_all` não está sendo chamado, ou o
  `respawn` não é ligado quando a rocha vira cascalho.
- **Ajudante sumiu da tela:** `NaN` no `move_towards_2d` (dividiu por distância zero).
- **Horta virou matagal em segundos:** faltou `* dt` na chance de mato.
- **Moeda, semente ou colheita negativa:** alguém descontou sem passar pela proc única.

---

## 13. Se o tempo apertar

Ordem de importância:

1. Grid, câmera, mouse e planta crescendo (etapas 1 e 2)
2. Inventário, colher, vender, comprar semente (etapa 3)
3. Água e mato (etapa 4)
4. Ajudante plantando, cuidando e guardando sozinho (etapas 5 e 6)
5. Shop com botões (etapa 7)
6. Criar ajudantes (etapa 9)
7. Ferramentas (etapa 8)
8. Terreno e decoração (etapa 10)
9. Floresta, pedra e profissões (etapa 11)
10. Casas (etapa 12)
11. Save (etapa 14)
12. Metas (etapa 13)

Até o item 4 você já tem um jogo (com as teclas de debug de comprar e vender). Do 5 em
diante você tem um jogo bom.
**O save sobe na lista antes de mostrar pra alguém**: ninguém joga um idle duas vezes se
perdeu tudo na primeira.

---

## 14. Fase 2 - depois que as 14 etapas estiverem gostosas

Nada daqui entra antes. Em ordem de "mais efeito por menos código":

| Ideia | Custo | O que muda |
|---|---|---|
| **Compra automática** | Baixo: um item do shop (o "Caderninho") que recompra a mesma semente quando o estoque zera, se tiver moeda | O idle vira idle de verdade: você só volta pra trocar a estratégia |
| **Plano por canteiro** | Médio: clicar num canteiro e marcar "só abóbora aqui" | O jogador decide o layout sem pôr a mão na terra |
| **Poço e regador** | Médio: um tile `.Well`, o ajudante carrega 3 regas e volta pra encher | O lugar do poço vira decisão de layout |
| **Decoração com bônus** | Baixo: flor dá +20% de crescimento nos 4 vizinhos | Decorar passa a ter estratégia, sem deixar de ser bonito |
| **Adubo** | Baixo: item consumível do shop, o ajudante joga num canteiro e a próxima planta cresce 2x | Uma compra que se gasta, pra ter onde pôr moeda sobrando |
| **Progresso offline** | Médio: salvar a hora, e ao abrir simular o tempo fechado (limitado a 2 h) | O "volta que tem colheita te esperando no inventário" dos idles |
| **Janela na borda da tela** | Médio: raylib com `FLAG_WINDOW_UNDECORATED`, `FLAG_WINDOW_TOPMOST` e `FLAG_WINDOW_TRANSPARENT`, mais uma visão compacta | O jogo fica rodando num canto enquanto você faz outra coisa, como muitos idles de desktop |
| **Ferramenta por ajudante** | Médio: cada ajudante tem um slot, e você compra e entrega a ferramenta pra um deles | Os ajudantes ganham variedade (um rega mais rápido, outro colhe mais rápido) |
| **Depósito** | Baixo: uma construção que funciona como cesto. Posta perto da floresta ou das pedras, o lenhador anda menos | Igual ao *lumber camp* do Age of Empires: onde construir vira decisão |
| **Obra** | Médio: a casa posta vira fundação, e um ajudante leva X segundos pra construir | Construir passa a ser trabalho dos ajudantes também |
| **Machado e Picareta** | Baixo: duas linhas a mais no `ToolKind` e no `TOOL_PRICE` | Upgrade pros lenhadores e mineradores, igual às ferramentas da horta |
| **Zoom e minimapa** | Médio: roda do mouse muda o `zoom` da câmera (e o `camera_clamp` e o `camera_visible_tiles` passam a dividir por ele); minimapa num canto, um pixel por tile | Ver a vila inteira de uma vez, e achar o lenhador perdido na floresta |
| **Marcar área de corte** | Médio: arrastar um retângulo na floresta, e o lenhador só corta ali dentro | Você escolhe pra que lado a vila cresce |
| **Viveiro** | Baixo: o lenhador planta muda em grama marcada, e a muda vira árvore em X minutos | Madeira renovável, pra quando a floresta perto acabar |
| **Processar colheita** | Alto: bancada que transforma cenoura em suco, que vale mais | Uma segunda camada de economia no shop |
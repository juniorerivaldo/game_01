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
e decoração pra eles.

**Inspiração, não cópia.** Mecânica não tem dono: "bonequinhos cuidam da horta sozinhos"
é livre. Nome, arte, personagens e textos do Tiny Terraces têm dono. Este jogo tem a
identidade dele: um coelho e a horta dele.

---

## 0. Pilares do jogo

| | Horta do Coelho |
|---|---|
| Mundo | um **grid 2D** (X e Y), tela fixa, sem câmera |
| Quem você controla | **ninguém**: você é o **mouse** no shop |
| Interação | **clicar nos botões do shop**. O grid só recebe clique pra posicionar lote e decoração |
| Quem trabalha | **só os ajudantes**. Você nunca planta, rega nem colhe |
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
- **UI de modo imediato**: botão que é só uma proc que desenha e responde "fui clicado?".
- **Reserva de tarefa**: dois ajudantes não podem regar o mesmo pé nem usar a mesma semente.
- **Upgrades globais**: ferramenta comprada no shop muda um número que todos os ajudantes leem.
- **Salvar e carregar** em JSON.

---

## 1. A ideia em 5 linhas

Você cuida de uma horta vista de cima, dividida em quadradinhos, **sem tocar nela**.
Os **ajudantes** andam sozinhos pelo grid: plantam as sementes do inventário nos canteiros vazios, regam quem tem sede, arrancam o mato, colhem o que está pronto e levam pro cesto.
Tudo o que chega no cesto vai pro **inventário**.
No **shop** você vende a colheita do inventário e, com as moedas, compra **sementes** (o que eles vão plantar), **ferramentas** (eles trabalham melhor), **mais ajudantes**, **terreno** e **decoração**.
Não tem derrota. A meta é a horta crescer até ocupar o terreno inteiro.

```
+------------------------------------------------------------------------+
| Moedas 42   Ajudantes 2/8        Meta: Tenha 3 ajudantes               |  <- HUD (topo)
+---------------------------------------------+--------------------------+
|  . . . . . . . . . . . . . .                 |  INVENTÁRIO              |
|  . . . . . . . . . . . . . .                 |   colheita: Cen 5 Alf 2  |
|  . . . [C][C][A] . . . . . .                 |   sementes: Cen 3 Alf 1  |
|  . . . [C][ ][A] . . f . . .                 |  VENDER                  |
|  . [B] . . . . . . . . . . .      h          |   [Cen +15] [Tudo +31]   |
|  . . . . . . . . . . . . . .   (ajudante)    |  SEMENTES                |
|  . . . . . . . . . . . . . .                 |   [Cen 1] [Alf 3] [Abó 8]|
|  . . . . . . . . . . . . . .                 |  FERRAMENTAS             |
|                                              |   [Botas 20] [Regador 20]|
|  [B] = cesto   [C] = canteiro   . = grama    |  AJUDANTE  [Criar]       |
|  f = flor (decoração)   h = ajudante         |  TERRENO [Lote 10]       |
|                                              |  DECORAR [Flor 5] ...    |
+---------------------------------------------+--------------------------+
          grid 14 x 10, tiles de 48 px                shop (painel lateral)
```

---

## 2. Onde o código mora e mapa dos arquivos

Todo o código mora em `game-dev/horta/src/`, com `package horta`. Um package Odin só pode
ter um `main`, então nada de fora entra nessa pasta.

| Arquivo | Do que cuida | Etapa em que nasce |
|---|---|---|
| `config.odin` | Só constantes. Zero lógica. | 1 |
| `main.odin` | Abre a janela, guarda o mundo, roda o loop, chama todo mundo. | 1 |
| `grid.odin` | O grid: tiles, desenho, mouse -> tile, cesto. | 1 e 2 |
| `crop.odin` | A planta dentro do tile: plantar, crescer, água, mato, colher. | 2 e 4 |
| `inventory.odin` | Moedas, colheita guardada, sementes guardadas, nível das ferramentas. | 3 |
| `shop.odin` | A lógica do shop: vender, comprar semente, ferramenta, ajudante, lote, decoração. Sem desenho. | 3, 8, 9 e 10 |
| `helper.odin` | Ajudante: andar, achar tarefa, trabalhar, entregar, criar novo. | 5, 6 e 9 |
| `utils.odin` | `move_towards_2d` e outras procs pequenas. | 5 |
| `ui.odin` | Painel do shop, botões, item na mão, info do tile embaixo do mouse. | 7 |
| `tools.odin` | O efeito de cada ferramenta nos números dos ajudantes. | 8 |
| `decor.odin` | Decoração: colocar, tirar, desenhar. | 10 |
| `hud.odin` | Barra de cima com números e metas. | 3 em diante |
| `save.odin` | Salvar e carregar o jogo. | 12 |

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

Só constantes. Quando quiser deixar o jogo mais rápido ou mais lento, mexa **só aqui**.

**Janela e grid**
- `SCREEN_WIDTH :: 1280`, `SCREEN_HEIGHT :: 720`, `TITLE :: "Horta do Coelho"`
- `GRID_W :: 14`, `GRID_H :: 10` - tamanho do grid em tiles
- `TILE :: 48` - lado de um tile em pixels
- `GRID_X :: 40`, `GRID_Y :: 110` - canto de cima-esquerda do grid na tela
- `PANEL_X :: 740` - onde começa o painel do shop
- `BASKET_TILE :: [2]int{1, 4}` - o tile do cesto

**Tempo e velocidade** (valores base, sem ferramenta)
- Ajudante: 70 px/s
- Plantar: 1.0 s | Regar: 1.0 s | Tirar mato: 2.0 s | Colher: 1.0 s

**Água e mato**
- Água cheia dura 30 s (`WATER_DECAY :: 1.0 / 30.0` por segundo)
- Com sede: água abaixo de 0.3
- Chance de mato: 0.5% por segundo em cada planta crescendo (`WEED_CHANCE :: 0.005`)

**Economia inicial**
- Moedas: 20 | Sementes: 4 de cenoura | Ajudantes: 1 | Canteiros: 6 (um bloco 3 x 2 no meio)
- Máximo de ajudantes: 8

**As plantas** (use **array enumerado**, um recurso do Odin que casa perfeito aqui):

```
CROP_SEED_PRICE :: [CropKind]int { .None = 0, .Carrot = 1,  .Lettuce = 3,  .Pumpkin = 8  }
CROP_SELL_PRICE :: [CropKind]int { .None = 0, .Carrot = 3,  .Lettuce = 8,  .Pumpkin = 25 }
CROP_GROW_TIME  :: [CropKind]f32 { .None = 0, .Carrot = 20, .Lettuce = 40, .Pumpkin = 90 }
START_SEEDS     :: [CropKind]int { .Carrot = 4 }
```

Um array indexado pelo enum: `CROP_SELL_PRICE[.Pumpkin]` dá 25. Sem `switch`, sem
esquecer um caso: se você criar `CropKind.Tomato` e não puser o preço, o compilador reclama.
(`CropKind` nasce na Etapa 2. Até lá, deixe esses quatro comentados.)

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

**Por que esses números** (confira sempre que mexer):

| | Lucro por colheita | Tempo | Lucro por minuto por canteiro | Risco |
|---|---|---|---|---|
| Cenoura | 2 | 20 s | ~6 | quase nenhum: cresce antes de dar sede |
| Alface | 5 | 40 s | ~7.5 | precisa de 1 rega |
| Abóbora | 17 | 90 s | ~11 | 3 regas e muita chance de mato |

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
inv      : Inventory           (moedas, colheita, sementes, ferramentas)
helpers  : [dynamic]Helper
ui       : UiState             (item na mão, tile embaixo do mouse)
```

Repare no que **não** tem: câmera (a tela é fixa), player (você é o mouse), `game_over`
(não tem derrota).

**A forma do `main`**

```
main :: proc() {
    InitWindow / SetTargetFPS

    // ---- SETUP: roda uma vez ----
    if !save_load(&grid, &inv, &helpers) {       // Etapa 12. Antes dela: só o else
        grid    = grid_spawn()
        inv     = inventory_spawn()
        helpers = spawn_initial_helpers()
    }

    for !WindowShouldClose() {
        dt := GetFrameTime()

        // ---- UPDATE ----
        ui_update(&ui, &grid, &inv, &helpers)    // lê mouse e teclado, chama as try_ do shop
        crop_update_all(&grid, inv, dt)          // cresce, seca, nasce mato
        helper_update_all(helpers[:], &grid, &inv, dt)
        goals_update(goals[:], grid, inv, len(helpers))
        save_autosave_update(&autosave_timer, grid, inv, helpers[:], dt)

        // ---- DRAW ----
        BeginDrawing()
        ClearBackground(BG_COLOR)
            grid_draw(grid)              // chão: grama, canteiro, cesto
            crop_draw_all(grid)          // plantas por cima do canteiro
            decor_draw_all(grid)
            helper_draw_all(helpers[:])
            ui_draw_hover(ui, grid, inv) // item na mão ou info do tile
            ui_draw_shop(ui, inv, len(helpers))
            hud_draw(inv, len(helpers), goals[:])
        EndDrawing()
    }
    save_write(grid, inv, helpers[:])            // salva ao fechar
    CloseWindow()
}
```

Esse é o esqueleto **do fim da Etapa 12**. Nas etapas iniciais cada linha aparece só quando
o arquivo dela nasce.

**Três coisas que esse esqueleto ensina:**

1. **O `ui_update` vem primeiro.** Ele transforma clique em compra ou venda. Tudo o que vem
   depois já vê o inventário com a compra aplicada neste frame: a semente que você acabou de
   comprar já pode ser pega por um ajudante no mesmo frame.
2. **Sem `BeginMode2D`.** Não tem câmera, então tudo é coordenada de tela. A conversão entre
   tile e pixel é sua (Etapa 1), e ela é o coração do jogo.
3. **A ordem do draw é a profundidade.** Chão, planta, decoração, ajudante, contorno do mouse,
   shop. O ajudante por cima da planta, o shop por cima de tudo.

---

## 6. Fichas das etapas

Cada ficha diz: **struct**, **procs**, **onde chamar**. Siga na ordem.

**Sobre as teclas de debug:** o jogador final nunca planta nem colhe. Mas nas Etapas 2 a 4
ainda não existe ajudante, e você precisa testar a planta. Pra isso existem **teclas de
debug** provisórias (F1, F2...), todas marcadas com `// DEBUG` no código. A Etapa 7 apaga
todas.

---

### Etapa 1 - Janela, grid e mouse (`config.odin` + `main.odin` + `grid.odin`)

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

**Procs**

- `grid_spawn :: proc() -> Grid`
  Tudo `.Grass`. Nesta etapa é só isso.
  **Onde chamar:** setup do `main`.
- `tile_to_screen :: proc(x, y: int) -> rl.Vector2`
  O canto de cima-esquerda do tile na tela: `{GRID_X + x * TILE, GRID_Y + y * TILE}`.
  Todo `_draw` do jogo passa por ela.
- `tile_center :: proc(x, y: int) -> rl.Vector2`
  O meio do tile: `tile_to_screen(x, y) + TILE / 2`. É pra onde o ajudante anda.
- `screen_to_tile :: proc(pos: rl.Vector2) -> (x, y: int, ok: bool)`
  O caminho inverso: de um ponto da tela pro tile embaixo dele.
  `x = int(floor((pos.x - GRID_X) / TILE))`, igual pro y.
  `ok = false` se caiu fora do grid (x < 0, x >= GRID_W, etc.).

  **Três retornos**, um recurso do Odin: quem chama escreve
  `tx, ty, ok := screen_to_tile(rl.GetMousePosition())` e **tem que** olhar o `ok` antes de
  usar `tx, ty`. Sem ele, o mouse em cima do shop dá um índice 17 num array de 14 e o
  programa cai.

  **Use `floor`, não só `int(...)`.** `int(-0.5)` dá 0, mas o mouse meio tile à esquerda
  do grid não está no tile 0.
- `grid_draw :: proc(g: Grid)`
  Um retângulo por tile: grama verde, canteiro marrom, cesto amarelo-palha. Uma linha fina
  mais escura em volta de cada um, pra ver o grid.
  Por valor, sem `^`: o Odin passa structs grandes por referência escondido quando o
  parâmetro não é `^`, então não tem cópia de 140 tiles por frame.
  **Onde chamar:** primeiro no draw.

**Testa:** a janela abre, o grid aparece. Escreva na tela o tile embaixo do mouse
(`"3, 4"`) e confira nos quatro cantos do grid e fora dele (tem que dizer "fora").

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

- `grid_spawn` agora faz o cesto em `BASKET_TILE` e um bloco 3 x 2 de `.Soil` no meio.
- `crop_try_plant :: proc(g: ^Grid, x, y: int, kind: CropKind) -> bool`
  Se `crop_can_plant`: liga `crop = {kind = kind, water = 1}`.
  **Não mexe em semente nem em moeda.** Quem planta traz a semente na mão (o ajudante tira
  ela do inventário na Etapa 6). A planta só sabe que foi plantada.
- `crop_update_all :: proc(g: ^Grid, dt: f32)`
  Passa por todos os tiles. Planta não pronta: `growth += dt`.
  **Onde chamar:** no update, depois do `ui_update`.
- `crop_draw_all :: proc(g: Grid)`
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

- `inventory_spawn :: proc() -> Inventory` - 20 moedas, `seeds = START_SEEDS`, resto zerado.
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

- `crop_needs_water :: proc(c: Crop) -> bool` - não pronta e `water < 0.3`.
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
| `pos` | `rl.Vector2` | posição na tela, **em pixels**, não em tile. Ele anda liso entre os tiles |
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
  Quadrado 16 x 16 branco (é um mini-coelho). Com semente na mão: um pontinho marrom do lado.
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
| `.Idle` | passeia e, **a cada 0.5 s**, procura tarefa com `helper_find_task` | achou -> reserva o tile (e pega a semente, se for plantar) -> `.Going` |
| `.Going` | anda até `tile_center(target)`. **Todo frame confere se a tarefa ainda faz sentido** | chegou -> `.Working` / não faz mais sentido -> `helper_release` -> `.Idle` |
| `.Working` | parado, `work_timer` corre (plantar 1 s, regar 1 s, mato 2 s, colher 1 s) | zerou -> faz a tarefa, `helper_release`. Colheu -> `.Delivering`. Senão -> `.Idle` |
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
140 tiles. Com 8 ajudantes a 60 FPS dá 67 mil checagens por segundo pra uma resposta que
quase nunca muda. O `find_timer` resolve. (Nem seria lento, mas é um bom hábito: só
pergunte o que pode ter mudado.)

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
| `holding` | enum `PlaceKind` | `.None`, e na Etapa 10 `.Plot`, `.Flower`, `.Bench`, `.Lantern`: o que está "na mão" esperando um tile |
| `hover_x`, `hover_y` | int | o tile embaixo do mouse |
| `hover_ok` | bool | o mouse está em cima do grid |

**Procs**

- `ui_update :: proc(ui: ^UiState, g: ^Grid, inv: ^Inventory, hs: ^[dynamic]Helper)`
  **A única proc que lê mouse e teclado.** Na ordem:
  1. Calcula o hover com `screen_to_tile`.
  2. Atalhos: `V` vende tudo; `1`, `2`, `3` compram uma semente de cenoura, alface, abóbora.
  3. **Clique no shop?** (mouse com `x >= PANEL_X`) Resolve o botão e **para aqui**.
     Sem esse "para", um clique em "Comprar lote" também tentaria posicionar no tile
     embaixo.
  4. **Clique no grid?** Só faz alguma coisa se tiver item na mão (Etapa 10). **Nunca
     planta, rega nem colhe.**

  `hs` é `^[dynamic]` porque o botão "Criar ajudante" (Etapa 9) faz `append`.
  **Onde chamar:** primeiro no update.
- `ui_draw_hover :: proc(ui: UiState, g: Grid, inv: Inventory)`
  Sem item na mão e mouse num canteiro: **uma caixinha de info** com a planta, quanto falta
  pra ficar pronta, água e mato. É o único jeito de o jogador "conversar" com a horta, e ele
  só olha. (Na Etapa 10 ganha o contorno do item na mão.)
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
| Botas | `.Boots` | anda mais rápido | 70 / 88 / 105 / 123 px/s (+25% por nível) |
| Regador | `.Can` | a rega dura mais | água dura 30 / 45 / 60 / 75 s |
| Enxada | `.Hoe` | planta e tira mato mais rápido | mato 2.0 / 1.5 / 1.0 / 0.5 s, plantar 1.0 / 0.75 / 0.5 / 0.25 s |
| Foice | `.Sickle` | colhe mais rápido | 1.0 / 0.75 / 0.5 / 0.25 s |

Cada uma ataca um gargalo diferente: Botas ajudam horta grande (muito caminho), Regador
ajuda abóbora (muita rega), Enxada ajuda quando o mato domina, Foice ajuda cenoura (muita
colheita). **Qual comprar primeiro depende do que você está plantando**, e é essa a graça.

**Procs de `tools.odin`** (só calculam, não mudam nada)

- `tool_speed :: proc(inv: Inventory) -> f32` - `70 * (1 + 0.25 * f32(inv.tools[.Boots]))`.
- `tool_water_decay :: proc(inv: Inventory) -> f32` - `WATER_DECAY / (1 + 0.5 * f32(inv.tools[.Can]))`.
- `tool_work_time :: proc(inv: Inventory, task: TaskKind) -> f32`
  O tempo base da tarefa vezes `(1 - 0.25 * nível)` da ferramenta que cuida dela (Enxada pra
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
| 5 em diante | +3 | +2 | +1 | ×2 |

- `craft_cost :: proc(helper_count: int) -> CraftCost`
  `CraftCost :: struct { crops: [CropKind]int, coins: int }`. Uma tabela pros 3 primeiros e a
  regra de crescimento pro resto.
- `helper_try_craft :: proc(hs: ^[dynamic]Helper, inv: ^Inventory) -> bool`
  Confere o máximo (8), confere **tudo** (`inv.crops` de cada planta e moedas), e **só
  depois** desconta tudo e dá `append` de um ajudante novo em cima do cesto.
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

Terreno e decoração são as únicas compras que precisam de **um lugar**. Então elas são as
únicas que usam o grid: você compra no shop, o item fica **na mão** (`ui.holding`), e você
clica no tile onde quer. **Só paga ao posicionar.**

- Clique no botão "Lote" ou "Flor" no shop: `ui.holding = .Plot` (ou `.Flower`...).
- Clique esquerdo num tile válido: chama a `try_`, que cobra. Deu certo: **continua na
  mão**, pra comprar vários lotes seguidos sem voltar no shop.
- Clique direito, ou clicar de novo no mesmo botão: `ui.holding = .None`. Nada foi pago,
  nada é devolvido.

`ui_draw_hover` ganha o contorno: com item na mão, **branco se dá pra posicionar ali,
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
- `decor_draw_all :: proc(g: Grid)`

**Nesta versão a decoração é só bonita.** No Tiny Terraces também. Dar bônus pra ela (flor
faz planta vizinha crescer mais rápido) é ideia da Fase 2: primeiro veja se o jogador
decora só por gostar.

**Testa:** comprar lotes grudados na horta e ver os ajudantes plantarem neles sozinhos;
tentar posicionar longe da horta e o contorno ficar vermelho. Pôr e tirar uma flor e ver
voltar metade. Clique direito com lote na mão: solta o lote e não cobra nada.

---

### Etapa 11 - HUD e metas (`hud.odin`)

Idle sem meta vira "deixar rodando e esquecer". Metas curtas dão o próximo passo, e aqui
todas elas são **uma compra ou um resultado dos ajudantes**, nunca "faça você mesmo".

- `Goal :: struct { text: string, done: bool }` e uma lista fixa de umas 8 metas:
  "Venda 10 cenouras", "Compre sua primeira semente de alface", "Tenha 3 ajudantes",
  "Compre uma ferramenta", "Colha uma abóbora", "Tenha 20 canteiros", "Junte 500 moedas",
  "Encha o terreno". Algumas pedem contadores novos no `Inventory`
  (`total_harvested: [CropKind]int`, `total_sold: [CropKind]int`).
- `goals_update :: proc(goals: []Goal, g: Grid, inv: Inventory, helper_count: int)`
  Só liga `done`, nunca desliga.
  **Onde chamar:** no update, depois do `helper_update_all`.
- `hud_draw` mostra moedas, ajudantes (`2/8`), **a primeira meta não cumprida**, e um aviso
  de 2 s "Meta cumprida!" quando uma liga.

**Um aviso a mais no HUD: "Sem sementes!"** quando `seeds` está zerado e tem canteiro vazio.
É o jeito de o jogo te chamar pro shop. Sem ele, o jogador vê os ajudantes passeando e acha
que a horta "acabou".

**Testa:** cumprir as três primeiras metas jogando normal, sem forçar. Deixar as sementes
acabarem e ver o aviso aparecer.

---

### Etapa 12 - `save.odin`: salvar e carregar

**Idle sem save não existe.** Fechar o jogo e perder a horta é o jeito mais rápido de o
jogador nunca mais abrir.

**Struct `SaveData`** - só o que precisa voltar:

| Campo | Tipo |
|---|---|
| `version` | int (comece com 1) |
| `tiles` | `[GRID_W][GRID_H]Tile` |
| `inv` | `Inventory` (inclui sementes e nível das ferramentas) |
| `helpers` | `[]HelperSave` - **só a posição** de cada ajudante |

**O que não salvar:** estado, tarefa, reserva, o que ele carrega. Ao carregar, todo
ajudante volta `.Idle` e **todos os `reserved` voltam a `false`**. Salvar reserva é salvar
um bug: o ajudante que tinha reservado não existe mais com aquele estado.

**Mas não jogue fora o que está na mão deles.** Na hora de montar o `SaveData`, some no
`inv` copiado a semente (`h.seed`) e a colheita (`h.carrying`) de cada ajudante. Semente foi
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
| Clique nos botões do shop | Vender (por planta ou tudo), comprar semente, ferramenta, ajudante, lote, decoração |
| Shift + clique numa semente | Compra 10 de uma vez |
| Clique esquerdo no grid | **Só com lote ou decoração na mão:** posiciona e paga |
| Clique direito no grid | Com item na mão: solta ele (não cobra). Sem nada na mão, em cima de decoração: tira ela (devolve metade) |
| Mouse em cima de um canteiro | Mostra a planta, quanto falta, água e mato |
| 1 / 2 / 3 | Compra 1 semente de cenoura / alface / abóbora |
| V | Vende tudo |
| ESC | Salva e sai |

**O player nunca põe a mão na terra.** Não existe clique que plante, regue, tire mato ou
colha. Tudo o que você faz passa pelo shop: você é o dono, eles são a equipe. No começo, com
1 ajudante e 4 sementes, o jogo é lento de propósito: a primeira decisão é quando vender e o
que comprar com as primeiras moedas.

---

## 8. Tabela de números

**Plantas**

| Planta | Semente | Venda | Crescer | Regas até ficar pronta (sem Regador) |
|---|---|---|---|---|
| Cenoura | 1 | 3 | 20 s | 0 (nasce com água cheia, que dura 30 s) |
| Alface | 3 | 8 | 40 s | 1 |
| Abóbora | 8 | 25 | 90 s | 3 |

**Cuidado** (valores base, sem ferramenta)

| Coisa | Valor |
|---|---|
| Água cheia dura | 30 s |
| Com sede abaixo de | 0.3 (uns 9 s antes de secar) |
| Chance de mato | 0.5% por segundo, por planta crescendo |
| Plantar | 1 s |
| Regar | 1 s |
| Tirar mato | 2 s |
| Colher | 1 s |

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
| Velocidade | 70 px/s (~1.5 tile por segundo), sem Botas |
| Procura tarefa a cada | 0.5 s |
| Semente que planta | a mais cara que tiver no inventário |
| Começa com | 1 |
| Máximo | 8 |

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
| Ferramentas | todas no nível 0 |

---

## 9. Quatro ideias que resolvem quase tudo

**1. O grid já é a lista.** Planta, decoração e reserva moram **dentro do tile**. Se uma
coisa tem um lugar fixo no grid, ela não precisa de lista, índice nem `active`.

**2. Cada coisa tem um estado.** O ajudante é uma máquina de estados: `.Idle`, `.Going`,
`.Working`, `.Delivering`. Cada estado sabe o que faz e quando troca.

**3. Delta time.** Crescer, secar, andar e a chance de mato: tudo vezes `dt`.

**4. Quem lê entrada não executa ação, e cada um tem as suas `try_`.** `ui_update` decide
e chama as `try_` do shop. O ajudante chama as `try_` da planta. As duas turmas nunca se
cruzam: o jogador mexe no inventário, o ajudante mexe na terra, e o inventário é a ponte.

---

## 10. Regras que evitam dor de cabeça

- **`grid.tiles[x][y]`, x primeiro, sempre.** Teste num grid que não seja quadrado.
- **Todo `screen_to_tile` olha o `ok`** antes de usar o tile.
- **Toda saída de tarefa solta a reserva e devolve a semente**, por uma proc só
  (`helper_release`).
- **Plantou? Zere o `h.seed` antes da release.** Senão a semente volta e vira infinita.
- **Clique no shop não vaza pro grid.** Resolveu o shop, pare.
- **`ui.odin` nunca chama `crop_try_...`.** Se chamar, o jogador voltou a plantar.
- **Uma proc só tira moeda** (`inventory_spend`). Uma só tira semente (`inventory_take_seed`).
  Uma só tira colheita (a do crafting e a de venda, ambas no `shop.odin`).
- **Só `tools.odin` lê `inv.tools`.** O resto pergunta pras procs dele.
- **Confira tudo antes de descontar qualquer coisa** em compras com mais de um custo.
- **`_update` não desenha, `_draw` não muda valor.** O botão é a tentação: veja a Etapa 7.
- **Nunca deixe o save derrubar o jogo.** Falhou ao carregar, começa do zero.

---

## 11. O que NÃO fazer agora

sprites, animação, som, pathfinding, mais de 3 plantas, processar colheita (farinha, suco),
estações do ano, clima, dia e noite, janela na borda da tela, progresso offline,
ajudante com nome ou personalidade, ferramenta por ajudante, compra automática de semente,
escolher o que plantar em cada canteiro, menu principal, várias hortas.

Regra: **se ver os quadradinhos trabalhando não é gostoso, sprite não vai salvar.**
Só troque primitivas por sprite quando as 12 etapas estiverem funcionando.

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
- **Ferramenta comprada e nada muda:** alguém ainda usa a constante (`WATER_DECAY`, `70`)
  direto em vez da proc do `tools.odin`.
- **Clique no lugar errado:** `screen_to_tile` sem `floor`, ou `[y][x]` em algum canto.
- **Ajudante sumiu da tela:** `NaN` no `move_towards_2d` (dividiu por distância zero).
- **Horta virou matagal em segundos:** faltou `* dt` na chance de mato.
- **Moeda, semente ou colheita negativa:** alguém descontou sem passar pela proc única.

---

## 13. Se o tempo apertar

Ordem de importância:

1. Grid, mouse e planta crescendo (etapas 1 e 2)
2. Inventário, colher, vender, comprar semente (etapa 3)
3. Água e mato (etapa 4)
4. Ajudante plantando, cuidando e guardando sozinho (etapas 5 e 6)
5. Shop com botões (etapa 7)
6. Criar ajudantes (etapa 9)
7. Ferramentas (etapa 8)
8. Terreno e decoração (etapa 10)
9. Save (etapa 12)
10. Metas (etapa 11)

Até o item 4 você já tem um jogo (com as teclas de debug de comprar e vender). Do 5 em
diante você tem um jogo bom.
**O save sobe na lista antes de mostrar pra alguém**: ninguém joga um idle duas vezes se
perdeu tudo na primeira.

---

## 14. Fase 2 - depois que as 12 etapas estiverem gostosas

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
| **Processar colheita** | Alto: bancada que transforma cenoura em suco, que vale mais | Uma segunda camada de economia no shop |
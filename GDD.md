# Horta do Coelho — GDD

**Gênero:** idle de horta visto de cima (inspirado no *Tiny Terraces*)
**Engine:** Odin + Raylib
**Visual:** só retângulos e círculos. Sprite fica pra depois.
**Package:** `game_01`, todo o código em `src/`

---

## Como usar este documento

O documento tem duas partes:

- **Parte 1, O jogo:** o que é o jogo, como se joga e os números. Sem nada de programação.
  Leia uma vez, inteira, antes de começar.
- **Parte 2, Como construir:** os arquivos, as regras do código e as **17 etapas**. Siga
  as etapas **na ordem**, uma por vez.

Cada etapa tem sempre as mesmas partes:

| Parte | O que diz |
|---|---|
| **Objetivo** | o que vai existir quando a etapa terminar |
| **Arquivos** | quais arquivos você cria ou mexe |
| **Dados** | os structs e enums novos, campo por campo |
| **Procs** | cada proc: o nome, o que recebe, o que devolve e **o passo a passo em português** do que ela faz |
| **No main** | onde chamar as procs novas |
| **Teste** | uma lista do que conferir com o jogo rodando |
| **Se der errado** | os erros mais comuns daquela etapa e a causa |

**Regra de ouro:** só passe pra próxima etapa quando o teste da atual funcionar. Cada etapa
termina com o jogo **compilando e rodando**.

Este documento não tem o jogo pronto: você escreve o código. Quando a sintaxe do Odin tiver
pegadinha, aparece um exemplo pequeno, só da sintaxe.

---

# PARTE 1 — O JOGO

## 1. A ideia

Você é o dono de uma horta e **nunca põe a mão na terra**. Quem trabalha são os
**ajudantes** (mini-coelhos): eles plantam, regam, tiram o mato, colhem e levam tudo pro
**cesto**. O que chega no cesto vai pro **inventário**.

Você fica no **shop**: vende a colheita, compra sementes (é o que os ajudantes vão
plantar), ferramentas (deixam os ajudantes melhores), mais ajudantes, terreno e decoração.

Em volta da horta tem uma **floresta enorme** com **jazidas de pedra**. Você pode pôr
ajudantes como **lenhador** ou **minerador**. Com madeira e pedra você constrói **casas**,
e cada casa abriga 5 ajudantes. Sem casa nova, não cabe ajudante novo.

Não tem derrota. A graça é ver a horta crescer e decidir o que comprar.

## 2. O que o jogador faz e o que ele não faz

| O jogador FAZ | O jogador NÃO FAZ |
|---|---|
| vende colheita no shop | plantar, regar, tirar mato, colher |
| compra sementes, ferramentas, ajudantes | cortar árvore, quebrar pedra |
| escolhe a profissão dos ajudantes | mover os ajudantes |
| põe lote, decoração e casa no mapa | |
| move a câmera pra ver o mapa | |

O único clique no mapa é pra **posicionar** lote, decoração ou casa. Todo o resto é no shop.

## 3. A tela

```
+------------------------------------------------------------------------+
| Moedas 42   Madeira 12   Pedra 3   Ajudantes 4/5                       |  HUD
| Meta: Construa uma casa                          Sem sementes!         |
+---------------------------------------------+--------------------------+
|  T T T T T T T T T T T T T T T T T T T T T   |  INVENTARIO              |
|  T T T . T T T T T T T T T . T T T T T T T   |   Colheita / Sementes    |
|  T T . o . . . . . . . . . . . . . . . T T   |  VENDER                  |
|  T o . . . . . . . . . . . . . . . . . . T   |   [Cen] [Alf] [Abo]      |
|  T T . . . . . . . . [C][C][C]. . . . . T T   |  SEMENTES                |
|  T T h . . . [B] . . [C][C][C]. . f . . T T   |   [Cen] [Alf] [Abo]      |
|  T T . . . . . . . . . . . . . . h . . . T   |  FERRAMENTAS             |
|  T T . . . . [H] . . . . . . . . . . . P :   |   [Botas] [Regador] ...  |
|  T T . . . . . . . . . . . . . . . . . P P   |  AJUDANTES 4/5           |
|  T T T T T T T T T T T T T T T T T T P : P   |   [Criar ajudante]       |
|  T T T T T T T T T T T T T T T T T T T T T   |   Lenhadores 1  [-] [+]  |
|                                              |   Mineradores 0 [-] [+]  |
|                                              |  CONSTRUIR               |
|                                              |   [Lote] [Casa]          |
|                                              |   [Flor] [Banco] [Lant.] |
+---------------------------------------------+--------------------------+
   a VISTA: mostra só um pedaço do mapa              o PAINEL do shop

   [B] cesto   [C] canteiro   [H] casa   T árvore   o toco
   P rocha     : cascalho     . grama    f flor     h ajudante
```

- **HUD** (em cima): números e a próxima meta.
- **Vista** (esquerda): um pedaço do mapa. O mapa é maior que a tela, e a câmera anda.
- **Painel** (direita): o shop. É metade do jogo.

## 4. O mapa

O mapa tem **96 x 64 quadradinhos** (tiles) de 32 px. São umas 4 telas de largura por 3 de
altura. O jogo começa numa **clareira** no meio de uma floresta:

```
   TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
   TTTTTTTTPTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTPTTTT     P = jazida de pedra
   TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT     T = floresta
   TTTTTTTTTTTTTTTTTT.........TTTTTTTTTTTTTTTTT     . = clareira (onde o jogo começa)
   TTTTTTTTTTTTTTTTTT.........P TTTTTTTTTTTTTTT
   TTTTTTTTTTTTTTTTTT.........TTTTTTTTTTTTTTTTT
   TTTTPTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
   TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTPTTTT
```

**Como a vila cresce:** o lenhador corta a árvore, que vira **toco**. Depois ele arranca o
toco, que vira **grama pra sempre**. Na grama cabem canteiros e casas. Então **cortar
floresta é abrir espaço**.

```
ÁRVORE:  árvore --cortar (3 s, +3 madeira)-->   toco  --arrancar (2 s, +1 madeira)--> grama
PEDRA:   rocha  --quebrar (4 s, +2 pedra)--> cascalho --espera 120 s----------------> rocha
```

- Toco e cascalho **não** são grama: não dá pra construir em cima.
- A árvore não volta. A pedra volta: a jazida nunca acaba, mas demora pra se recuperar.

## 5. Os elementos do jogo

### Plantas

| Planta | Semente custa | Vende por | Tempo pra crescer |
|---|---|---|---|
| Cenoura | 1 | 3 | 20 s |
| Alface | 3 | 8 | 40 s |
| Abóbora | 8 | 25 | 90 s |

Cada planta tem **água** (de 1, regada, até 0, seca). A água desce sozinha e acaba em 30 s.

- Abaixo de **0.3** a planta está **com sede**: ainda cresce, mas o ajudante vai querer
  regar. Desenhada mais apagada.
- Com água **0** (seca) ela **para de crescer** até alguém regar.
- Às vezes nasce **mato** (0.5% de chance por segundo). Com mato ela **para de crescer** até
  alguém tirar.
- Pronta: fica piscando, esperando ser colhida. Pronta não perde água nem pega mato.

**A decisão central do jogo:** abóbora rende mais por minuto, mas precisa de 4 regas e fica
90 s exposta ao mato. Com poucos ajudantes ela fica parada com sede e perde pra cenoura.
Com muitos ajudantes (ou com Regador e Enxada) ela ganha. Que semente comprar depende de
quantos ajudantes você tem.

### Ajudantes

O ajudante tem sempre um destes **4 estados**:

```
        achou tarefa                   chegou                   terminou
 PARADO -----------> INDO ATÉ O TILE --------> TRABALHANDO ----------------> PARADO
   ^                     |                         |
   |   tarefa sumiu      |                         | colheu (ou pegou madeira/pedra)
   +---------------------+                         v
   |                                        ENTREGANDO NO CESTO
   +------------------------------------------------+   chegou no cesto: vai pro inventário
```

- **Parado:** passeia perto do cesto. A cada meio segundo procura uma tarefa.
- **Indo:** anda em linha reta até o tile. Se alguém já resolveu a tarefa no caminho, desiste.
- **Trabalhando:** fica parado um tempo (plantar 1 s, regar 1 s, tirar mato 2 s, colher 1 s).
- **Entregando:** leva o que colheu até o cesto.

**Qual tarefa o fazendeiro escolhe** (a mais importante primeiro; empate, a mais perto):

| Prioridade | Tarefa | Por quê |
|---|---|---|
| 1º | Colher | planta pronta parada é dinheiro parado |
| 2º | Tirar mato | planta com mato não cresce nem regada |
| 3º | Regar (só quem está com sede) | planta com sede vai parar logo |
| 4º | Plantar (se tiver semente) | canteiro vazio não perde nada esperando |

**Qual semente ele planta:** a **mais cara** que tiver no inventário. O que você compra é o
que vai pra terra.

**Reserva:** quando um ajudante escolhe uma tarefa, o tile fica **reservado** e nenhum outro
vai lá. Se a tarefa é plantar, ele já **tira a semente do inventário e leva na mão**. Assim
dois ajudantes nunca vão no mesmo pé, e 3 ajudantes não saem pra plantar com 1 semente só.

### Profissões

| Profissão | O que faz | Prioridade |
|---|---|---|
| Fazendeiro | colhe, tira mato, rega, planta | a tabela acima |
| Lenhador | 1º arranca toco, 2º corta árvore | a mais perto |
| Minerador | quebra rocha | a mais perto |

Todo ajudante nasce fazendeiro. No shop, `[+]` transforma um fazendeiro em lenhador ou
minerador, e `[-]` volta. **Fazendeiro é quem sobra.**

O lenhador arranca toco antes de cortar outra árvore pra terminar de abrir o terreno. Como
ele vai sempre na mais perto, a floresta **recua em volta da vila** sozinha.

### Ferramentas

As ferramentas são **de todos os ajudantes**. Comprou o Regador, todo mundo rega com ele.
Cada uma tem 3 níveis.

| Ferramenta | Efeito por nível | Preço nível 1 / 2 / 3 |
|---|---|---|
| Botas | anda 25% mais rápido | 20 / 60 / 150 |
| Regador | a água dura +15 s (30 → 45 → 60 → 75 s) | 20 / 60 / 150 |
| Enxada | plantar e tirar mato 25% mais rápido | 15 / 45 / 120 |
| Foice | colher 25% mais rápido | 25 / 75 / 180 |

Cada uma resolve um problema diferente: Botas pra horta grande, Regador pra abóbora,
Enxada pra muito mato, Foice pra muita cenoura.

### Criar ajudante

Custa **cenouras + moedas**, e fica mais caro a cada ajudante:

| Você tem | O próximo custa |
|---|---|
| 1 ajudante | 5 cenouras + 10 moedas |
| 2 ajudantes | 8 cenouras + 30 moedas |
| 3 ajudantes | 11 cenouras + 50 moedas |
| n ajudantes | `5 + 3 × (n - 1)` cenouras + `10 + 20 × (n - 1)` moedas |

Isso cria uma decisão: **vender as cenouras agora ou guardar pra criar ajudante?** Por isso
o shop vende cada planta separada.

### Terreno, decoração e casa

Essas são as compras que precisam de **um lugar** no mapa. Você clica no botão do shop, o
item fica **na mão**, e você clica no tile. **Só paga quando posiciona.** Continua na mão
pra pôr outro. Clique direito solta (não cobra nada).

| Item | Preço | Onde pode |
|---|---|---|
| Lote (vira canteiro) | 10, +5 a cada lote comprado | grama **vizinha** de um canteiro |
| Flor / Banco / Lanterna | 5 / 15 / 25 | qualquer grama sem decoração |
| Casa (+5 vagas de ajudante) | 10 madeira + 5 pedra | qualquer grama sem decoração |

- O contorno do tile embaixo do mouse fica **vermelho** se não dá pra pôr ali.
- Clique direito numa decoração (sem nada na mão) tira ela e devolve **metade** do preço.
- O jogo começa com **1 casa** pronta (5 vagas). Casa não se demole.
- A decoração é só bonita nesta versão.

### Metas

Uma lista fixa. O HUD mostra a primeira que falta e avisa "Meta cumprida!".

1. Venda 10 colheitas
2. Colha uma alface
3. Tenha 3 ajudantes
4. Compre uma ferramenta
5. Escale um lenhador
6. Construa uma casa
7. Colha uma abóbora
8. Junte 500 moedas
9. Tenha 10 ajudantes
10. Abra 100 tiles de floresta (tocos arrancados)

**Avisos do HUD**, pra chamar o jogador pro shop:
- "Sem sementes!" quando tem canteiro vazio e nenhuma semente.
- "Ninguém na horta!" quando tem planta crescendo e nenhum fazendeiro.
- "Casas cheias!" quando não cabe mais ajudante.

### Save

O jogo **salva sozinho a cada 30 s** e ao fechar. Ao abrir, carrega. Save quebrado ou de
outra versão: começa um jogo novo, sem travar.

## 6. Começo do jogo

| Coisa | Valor |
|---|---|
| Moedas | 20 |
| Sementes | 4 de cenoura |
| Ajudantes | 1, fazendeiro |
| Canteiros | 6 (um bloco 3 x 2 perto do cesto) |
| Casas | 1 (5 vagas) |
| Madeira, pedra, ferramentas | nada |

## 7. Controles

| Entrada | Ação |
|---|---|
| Clique nos botões do shop | vender, comprar, criar ajudante, trocar profissão, pegar item pra posicionar |
| Shift + clique numa semente | compra 10 |
| Clique esquerdo no mapa | só com item na mão: posiciona e paga |
| Clique direito no mapa | com item na mão: solta. Sem nada na mão, numa decoração: tira |
| Mouse em cima de um tile | caixinha de info (planta, água, mato, quanto falta...) |
| Mouse parado na borda da vista | move a câmera |
| WASD / setas | move a câmera |
| Espaço | volta a câmera pro cesto |
| 1 / 2 / 3 | compra 1 semente de cenoura / alface / abóbora |
| V | vende tudo |
| ESC ou fechar a janela | salva e sai |

------------------------------------------------------------
-------------------------------------------------------------
COMEÇAR AQUIIIIIIIIIIIIIIIIIIIIIIIIIIII

# PARTE 2 — COMO CONSTRUIR

## 8. Os 7 arquivos

| Arquivo | O que mora nele | Nasce na etapa |
|---|---|---|
| `config.odin` | **só constantes e tabelas de números.** Zero lógica | 1 |
| `main.odin` | o struct `Game`, a variável global `game`, o `main` (janela e loop) | 1 |
| `grid.odin` | **tudo que está no chão:** tiles, criar o mapa, coordenadas, câmera, plantas, árvore, pedra, casa, decoração e o desenho de tudo isso | 2 |
| `ui.odin` | **tudo que o jogador vê por cima e clica:** clique no mapa, HUD, painel do shop, botões, caixinha de info, metas | 3 |
| `shop.odin` | **tudo que tem preço:** inventário, vender, comprar, ferramentas, criar ajudante, posicionar lote/decoração/casa | 6 |
| `helper.odin` | **os ajudantes:** andar, achar tarefa, trabalhar, entregar, profissão, desenho | 7 |
| `save.odin` | salvar e carregar | 17 |

E um arquivo de testes, `game_test.odin`, que nasce na Etapa 8 (seção 12).

O `config.odin` e o `grid.odin` que você já tem: o `config.odin` vai ser **trocado** na
Etapa 1 (os números são quase os mesmos, mas ele vai crescendo etapa por etapa). O
`grid.odin` pode ficar como está até a Etapa 2.

## 9. O Odin que este jogo usa

Só o necessário. Volte aqui sempre que travar numa sintaxe.

**Declarar**

```odin
NOME :: 10             // constante (nunca muda)
x := 10                // variável, o tipo vem do valor (int)
y: f32                 // variável com tipo, começa ZERADA (0)
minha_proc :: proc(a: int) -> bool { ... }
```

Em Odin **tudo começa zerado**: número 0, bool `false`, enum no primeiro valor, struct com
todos os campos zerados. O jogo usa muito isso.

**Enum e struct**

```odin
CropKind :: enum { None, Carrot, Lettuce, Pumpkin }
k := CropKind.Carrot   // ou só .Carrot quando o tipo já é conhecido

Crop :: struct {
	kind:   CropKind,
	growth: f32,
}
c := Crop{kind = .Carrot}   // o que você não escreve fica zerado
```

**Array enumerado**: um array com uma casa pra cada valor do enum.

```odin
seeds: [CropKind]int
seeds[.Carrot] += 1
```

**Pegadinha importante: tabela de números indexada por variável.** Isto **não compila**:

```odin
CROP_SELL_PRICE :: [CropKind]int{ .None = 0, .Carrot = 3, ... }   // "::" = constante
preco := CROP_SELL_PRICE[kind]    // ERRO: "Cannot index a constant" (kind é variável)
```

Constante só pode ser lida com índice fixo (`CROP_SELL_PRICE[.Carrot]`). Como o jogo lê as
tabelas com variável o tempo todo, **toda tabela vira variável global somente leitura**:

```odin
@(rodata)
CROP_SELL_PRICE := [CropKind]int{ .None = 0, .Carrot = 3, ... }   // ":=" com @(rodata)
```

`@(rodata)` diz "ninguém muda isso": se algum código tentar escrever nela, o programa
avisa. Use assim pra **toda** tabela indexada por enum (preço, tempo, cor, nome).

O Odin exige que o array enumerado liste **todos** os valores do enum. Se você criar
`CropKind.Tomato` e esquecer o preço, ele reclama. Quando faltar valor for de propósito,
use `#partial`: `#partial [CropKind]int{ .Carrot = 4 }` (o resto vira 0).

**Ponteiro**

```odin
p := &game.tiles[x][y]   // & pega o endereço
p.kind = .Soil           // mexe no tile de verdade (o Odin entende p.kind sozinho)
c := p^                  // ^ depois do nome = o valor apontado (cópia)
mexe :: proc(h: ^Helper) // ^ antes do tipo = "recebe um ponteiro" (vai mudar o ajudante)
```

Sem o `&`, `t := game.tiles[x][y]` é uma **cópia**: mudar o `t` não muda o mapa. Use cópia
quando só vai **ler**, e ponteiro quando vai **mudar**.

**Laços**

```odin
for x in 0 ..< GRID_W { }      // 0, 1, ..., GRID_W - 1
for x in 48 ..= 50 { }         // 48, 49, 50 (inclui o fim)
for h in game.helpers { }      // cada ajudante (cópia, só leitura)
for &h in game.helpers { }     // cada ajudante (pode mudar)
for h, i in game.helpers { }   // com o índice
for kind in CropKind { }       // cada valor do enum
```

**Vários retornos**

```odin
world_to_tile :: proc(pos: rl.Vector2) -> (x, y: int, ok: bool) { ... }
tx, ty, ok := world_to_tile(p)
if kind, ok := crop_harvest(x, y); ok { ... }   // declara e testa na mesma linha
```

**switch**: tem que cobrir **todos** os casos do enum, senão não compila. Isso é bom: quando
você acrescenta um valor no enum, o compilador mostra cada lugar que precisa tratar ele.
Pra tratar só alguns de propósito, use `#partial switch`.

**Atalhos de escrita**

```odin
if x > 0 do y = 1            // if de uma linha só
cor := pronto ? rl.WHITE : rl.GRAY
```

**Array dinâmico** (`[dynamic]Helper`): `append(&arr, item)`, `len(arr)`, `clear(&arr)`.

**Texto com números pra raylib**: `fmt.ctprintf("Moedas %d", n)` devolve um `cstring`. Ele
usa uma memória temporária, então no **fim de cada frame** chame
`free_all(context.temp_allocator)`, senão a memória cresce sem parar.

**Conversão**: `f32(x)`, `int(x)`, `i32(x)`. As procs de desenho da raylib pedem `i32` ou
`f32`, o grid usa `int`.

## 10. As regras do projeto

1. **Um global só: `game`.** Tudo o que o jogo lembra (mapa, inventário, ajudantes, câmera)
   fica dentro do struct `Game`, numa variável global `game`. Qualquer proc lê e escreve
   `game.alguma_coisa` sem precisar receber parâmetro. As procs pequenas de conta
   (`tile_to_world`, `move_towards`) recebem parâmetros normais.

2. **Update mexe, draw desenha.** No loop, primeiro todas as procs `_update` (mudam os
   dados), depois todas as `_draw` (só desenham). Desenho nunca muda dado.
   **Uma exceção, de propósito:** o painel do shop desenha os botões e responde ao clique na
   mesma proc (Etapa 9 explica por quê).

3. **Todo número do jogo mora no `config.odin`.** Nenhum outro arquivo escreve `20`, `0.3`
   ou `48` solto. Quer o jogo mais rápido? Mexa só no config.

4. **O jogador nunca mexe na terra.** As procs que plantam, regam, tiram mato, colhem,
   cortam e quebram (`crop_plant`, `crop_water`, `crop_weed`, `crop_harvest`,
   `resource_take`) **só o ajudante chama**. O `ui.odin` só chama as procs do shop. Se um
   dia o `ui.odin` chamar `crop_...`, o jogo mudou de gênero.

5. **Uma proc só tira cada coisa.** Só `spend_coins` tira moeda. Só `take_seed` tira
   semente. Assim nunca fica negativo.

6. **Confira tudo antes de descontar qualquer coisa.** Compra com dois custos (cenoura +
   moeda, madeira + pedra): primeiro confere os dois, depois desconta os dois. Senão você
   perde cenoura numa compra que falhou por falta de moeda.

7. **`grid.tiles[x][y]`: x primeiro, sempre.** Misturar é o bug mais comum de grid, e ele
   só aparece em mapa que não é quadrado.

## 11. As três coordenadas

Leia antes da Etapa 2. Metade dos bugs de jogo com câmera é misturar estas três:

| Coordenada | Unidade | Exemplo | Quem usa |
|---|---|---|---|
| **Tile** | índice no grid | `(45, 32)` | `game.tiles[x][y]`, tarefas, constantes `_TILE` |
| **Mapa** | pixel do mapa inteiro (0 a 3072) | `(1440, 1024)` | posição do ajudante, tudo desenhado dentro da câmera |
| **Tela** | pixel da janela (0 a 1280) | `(400, 300)` | mouse, HUD, shop |

As conversões, cada uma numa proc com nome:

```
tile ----(× TILE)----------------> mapa      tile_to_world
mapa ----(÷ TILE, arredonda p/ baixo)--> tile  world_to_tile
mapa ----(câmera, automático)----> tela      tudo entre BeginMode2D e EndMode2D
tela ----(GetScreenToWorld2D)----> mapa      o caminho do mouse (mouse_to_tile)
```

---

## 12. As etapas

| Parte | Etapas | No fim você tem |
|---|---|---|
| **A. O mapa** | 1 a 5 | mapa com câmera, plantas crescendo, água e mato (testando com teclas de debug) |
| **B. A economia** | 6 a 9 | ajudantes trabalhando sozinhos e o shop com botões. **Aqui o jogo já existe** |
| **C. Crescer** | 10 a 12 | ferramentas, criar ajudantes, lotes e decoração |
| **D. A floresta** | 13 a 15 | floresta, lenhador, minerador e casas |
| **E. Acabamento** | 16 e 17 | metas, avisos e save |

**Teclas de debug:** nas Etapas 4 a 7 ainda não tem ajudante, mas você precisa testar as
plantas. Pra isso existem teclas provisórias (F1, F2, F3), todas com um comentário
`// DEBUG`. A Etapa 8 apaga todas.

---

## PARTE A — O MAPA

### Etapa 1 — Janela e o desenho da tela

**Objetivo:** a janela abre com os três pedaços da tela marcados: HUD em cima, a vista do
mapa à esquerda e o painel do shop à direita.

**Arquivos:** `config.odin` (troque o seu inteiro), `main.odin`.

**O que você vai aprender:** a forma do loop de jogo, e a ideia de dividir a tela em áreas
com constantes.

**config.odin**

Apague o conteúdo atual e comece com estas seções (só constantes):

| Constante | Valor | Pra que serve |
|---|---|---|
| `SCREEN_WIDTH`, `SCREEN_HEIGHT` | 1280, 720 | tamanho da janela |
| `TITLE` | `"Game 01"` | texto da barra da janela |
| `VIEW_X`, `VIEW_Y` | 20, 80 | canto de cima-esquerda da **vista** (onde o mapa aparece), em pixels da tela |
| `VIEW_W`, `VIEW_H` | 700, 620 | tamanho da vista |
| `PANEL_X` | 740 | daqui pra direita é o painel do shop |
| `BG_COLOR` | `rl.Color{30, 30, 36, 255}` | fundo da janela |
| `PANEL_COLOR` | `rl.Color{44, 44, 52, 255}` | fundo do painel |

As cores usam `rl.Color`, então o config precisa de `import rl "vendor:raylib"`.

Confira que tudo cabe (refaça a conta se mudar algum número):
- `VIEW_X + VIEW_W = 720`: termina antes do `PANEL_X` (740).
- `VIEW_Y + VIEW_H = 700`: termina antes do fim da tela (720).

Escreva um comentário curto do lado de cada constante dizendo pra que ela serve. Daqui a um
mês você não vai lembrar o que é `VIEW_Y`.

**main.odin**

1. Um struct vazio `Game :: struct {}`. Ele vai ganhando campos nas próximas etapas.
2. Fora de qualquer proc, a variável global `game: Game`.
3. A proc `main`:
   1. `rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, TITLE)` e `rl.SetTargetFPS(60)`.
   2. O loop `for !rl.WindowShouldClose() { ... }`. Dentro dele:
      - um comentário `// ---- UPDATE ----` (vazio por enquanto);
      - `rl.BeginDrawing()`, `rl.ClearBackground(BG_COLOR)`;
      - um retângulo verde-escuro no lugar da vista (`rl.DrawRectangle(VIEW_X, VIEW_Y, VIEW_W, VIEW_H, rl.DARKGREEN)`);
      - um texto "HUD" em `(VIEW_X, 14)`;
      - o fundo do painel: retângulo de `PANEL_X - 10` até a borda direita, altura inteira;
      - um texto "SHOP" no painel;
      - `rl.EndDrawing()`.
   3. Depois do loop, `rl.CloseWindow()`.

**Por que o `Game` global:** o jogo tem uma horta só. Em vez de passar o mapa, o
inventário e os ajudantes de proc em proc, todo mundo enxerga `game`. Fica bem mais simples
de escrever e de ler.

**Teste**
- [ ] F5 abre a janela, com fundo escuro, um retângulo verde à esquerda e o painel à direita.
- [ ] O verde não encosta no painel (sobra uma faixa de 20 px).

**Se der errado**
- *"Undeclared name: rl"*: faltou `import rl "vendor:raylib"` no arquivo.
- *A janela abre e fecha:* o `rl.CloseWindow()` ficou dentro do loop.

---

### Etapa 2 — O grid na tela, com câmera parada

**Objetivo:** o mapa de grama aparece dentro da vista, com os 6 canteiros e o cesto no
meio. A câmera ainda não anda.

**Arquivos:** `config.odin`, `grid.odin`, `main.odin`.

**O que você vai aprender:** array 2D fixo, conversão de tile pra pixel, e a câmera 2D da
raylib.

**config.odin**: acrescente

| Constante | Valor | Pra que serve |
|---|---|---|
| `GRID_W`, `GRID_H` | 96, 64 | tamanho do mapa em tiles |
| `TILE` | 32 | lado de um tile, em pixels |
| `BASKET_TILE` | `[2]int{45, 32}` | onde fica o cesto, em tiles |
| `GRASS_COLOR` | `{106, 168, 79, 255}` | grama |
| `SOIL_COLOR` | `{121, 85, 58, 255}` | canteiro |
| `BASKET_COLOR` | `{222, 184, 105, 255}` | cesto |

**Dados** (em `grid.odin`)

- `TileKind :: enum { Grass, Soil, Basket }`. Nas próximas etapas ganha árvore, pedra e
  casa.
- `Tile :: struct { kind: TileKind }`. Vai ganhar campos (a planta, a reserva...).

**No `Game`** (main.odin), dois campos:

| Campo | Tipo | Pra que serve |
|---|---|---|
| `tiles` | `[GRID_W][GRID_H]Tile` | o mapa inteiro. Array **fixo**: o mapa nunca muda de tamanho |
| `cam` | `rl.Camera2D` | que pedaço do mapa aparece na vista |

**Procs** (em `grid.odin`)

`grid_generate :: proc()`: cria o mapa.
1. Passa por todos os tiles (`for x`, dentro `for y`). Em cada um: zera o tile
   (`game.tiles[x][y] = Tile{}`) e põe `kind = .Grass`. Zerar é importante pro "jogo novo"
   da Etapa 6 apagar tudo do jogo anterior.
2. Os 6 canteiros: x de 48 a 50 e y de 31 a 32 (use `..=`) viram `.Soil`.
3. O tile `BASKET_TILE` vira `.Basket`. Um `[2]int` tem `.x` e `.y`:
   `game.tiles[BASKET_TILE.x][BASKET_TILE.y]`.

`tile_to_world :: proc(x, y: int) -> rl.Vector2`: o canto de cima-esquerda do tile, em
pixels do **mapa**: `{f32(x * TILE), f32(y * TILE)}`.

`tile_center :: proc(x, y: int) -> rl.Vector2`: o meio do tile: `tile_to_world(x, y) + TILE / 2`.
(Somar um número num `Vector2` soma nos dois lados, x e y.) É pra onde o ajudante vai andar.

`camera_init :: proc()`: prepara a câmera.
1. `game.cam.offset = {VIEW_X, VIEW_Y}`: o canto da vista na **tela**.
2. `game.cam.zoom = 1`.
3. Chama `camera_go_to_basket()`.

**Como pensar na câmera:** com o `offset` no canto da vista, o `target` é **o ponto do
mapa que aparece no canto de cima-esquerda da vista**. `target = {0, 0}` mostra o canto
do mapa.

`camera_go_to_basket :: proc()`: centraliza no cesto.
1. `game.cam.target = tile_center(cesto) - {VIEW_W / 2, VIEW_H / 2}` (o cesto no meio da vista).
2. Chama `camera_clamp()`.

`camera_clamp :: proc()`: segura a câmera dentro do mapa.
- `target.x` entre `0` e `GRID_W * TILE - VIEW_W`; `target.y` entre `0` e
  `GRID_H * TILE - VIEW_H`. Use a função `clamp(valor, min, max)` do Odin.
- Sem isso, a câmera sai do mapa e mostra o fundo vazio.

`visible_tiles :: proc() -> (x0, y0, x1, y1: int)`: quais tiles aparecem na vista.
- `x0 = int(target.x) / TILE`, `x1 = (int(target.x) + VIEW_W) / TILE + 1`, igual pro y.
- Segure dentro do grid: `x0` no mínimo 0 (`max`), `x1` no máximo `GRID_W` (`min`).
- **Por que existe:** o mapa tem 6144 tiles e a vista mostra uns 480. Desenhar só os
  visíveis é 13 vezes menos trabalho por frame.

`ground_color :: proc(kind: TileKind) -> rl.Color`: um `switch` que devolve a cor de cada
tipo de chão.

`grid_draw :: proc()`: desenha o chão.
1. `x0, y0, x1, y1 := visible_tiles()`.
2. Pra cada x de `x0` até `x1` (`..<`) e cada y de `y0` até `y1`:
   - `pos := tile_to_world(x, y)` e `rect := rl.Rectangle{pos.x, pos.y, TILE, TILE}`;
   - `rl.DrawRectangleRec(rect, ground_color(...))`;
   - uma linha fina por cima, pra ver o grid: `rl.DrawRectangleLinesEx(rect, 1, {0, 0, 0, 25})`.

**No main**
- Antes do loop (é o **setup**, roda uma vez): `grid_generate()` e `camera_init()`.
- No draw, troque o retângulo verde por:

```odin
rl.BeginScissorMode(VIEW_X, VIEW_Y, VIEW_W, VIEW_H)
rl.BeginMode2D(game.cam)
	grid_draw()
rl.EndMode2D()
rl.EndScissorMode()
```

- **`BeginMode2D`/`EndMode2D`**: tudo desenhado entre os dois está em coordenadas do
  **mapa**, e a câmera leva pro lugar certo da tela.
- **`BeginScissorMode`**: corta qualquer desenho que sair da vista. Sem ele, o mapa
  aparece por baixo do HUD e do shop.
- HUD e painel ficam **depois** do `EndScissorMode`: são coordenadas da tela, não andam
  com o mapa.

**Teste**
- [ ] A vista mostra grama quadriculada, com o bloco marrom de 3 x 2 e o cesto amarelo
      perto do meio.
- [ ] Nada do mapa aparece por cima do painel nem do HUD.

**Se der errado**
- *O cesto aparece no lugar errado ou deitado:* algum `[y][x]` no lugar de `[x][y]`.
- *O mapa aparece por cima do painel:* faltou o scissor, ou o painel foi desenhado antes do mapa.
- *Tela preta na vista:* o `zoom` ficou 0 (todo campo começa zerado, lembra?).

---

### Etapa 3 — Câmera andando e mouse no tile

**Objetivo:** a câmera anda com o teclado e com o mouse parado na borda. O tile embaixo
do mouse ganha um contorno, e o HUD escreve qual é.

**Arquivos:** `grid.odin`, `ui.odin` (novo), `main.odin`.

**O que você vai aprender:** o caminho do mouse da tela até o tile, e delta time.

**No `Game`**

| Campo | Tipo | Pra que serve |
|---|---|---|
| `edge_timer` | f32 | há quanto tempo o mouse está parado na borda |
| `hover` | `[2]int` | o tile embaixo do mouse |
| `hover_ok` | bool | o mouse está em cima de um tile do mapa? |

**config.odin**: acrescente `CAMERA_SPEED :: 600` (px por segundo), `EDGE_MARGIN :: 24`
(px perto da borda que empurram a câmera) e `EDGE_DELAY :: 0.25` (segundos parado na borda
antes de andar).

**Por que o `EDGE_DELAY`:** o shop fica colado na borda direita da vista. Todo caminho do
mouse até o shop passa por essa borda. Sem a espera, a câmera daria um tranco pra direita
toda vez que você fosse comprar algo. Com 0.25 s, **passar** rápido não move; **parar** move.

**Procs** (em `grid.odin`, precisa de `import "core:math"`)

`world_to_tile :: proc(pos: rl.Vector2) -> (x, y: int, ok: bool)`: de um ponto do mapa
pro tile.
1. `x = int(math.floor(pos.x / TILE))`, igual pro y.
2. `ok` é verdadeiro só se `x` e `y` estão dentro do grid (0 até `GRID_W - 1`, 0 até `GRID_H - 1`).
- **Use `floor`:** `int(-0.5)` dá 0, mas meio tile à esquerda do mapa não é o tile 0.
- **Quem chama sempre olha o `ok`** antes de usar `x, y`. Índice fora do array derruba o jogo.

`mouse_in_view :: proc() -> bool`: o mouse está dentro do retângulo da vista?
(`rl.GetMousePosition()` comparado com `VIEW_X`, `VIEW_Y`, `VIEW_W`, `VIEW_H`.)

`camera_update :: proc(dt: f32)`: soma todas as formas de mover e anda.
1. `dir: rl.Vector2` (começa `{0, 0}`).
2. **Teclado:** A ou seta esquerda, `dir.x -= 1`; D ou seta direita, `+= 1`; W/cima e S/baixo
   no `dir.y`. Use `rl.IsKeyDown(.A)`.
3. **Borda:** se `mouse_in_view()`, monte um `edge: rl.Vector2`: mouse a menos de
   `EDGE_MARGIN` da borda esquerda, `edge.x = -1`; da direita, `+1`; igual em cima e embaixo.
4. **A espera:** se `edge` não é `{0, 0}`, `game.edge_timer += dt`, e só se
   `edge_timer >= EDGE_DELAY` faz `dir += edge`. Se `edge` é `{0, 0}`, zera o `edge_timer`.
5. `game.cam.target += dir * CAMERA_SPEED * dt`.
6. Espaço (`rl.IsKeyPressed(.SPACE)`): `camera_go_to_basket()`.
7. `camera_clamp()`.

**`dt` (delta time):** o tempo do último frame, em segundos (uns 0.016 a 60 FPS). Tudo que
anda ou muda com o tempo é `velocidade * dt`. Assim o jogo tem a mesma velocidade a 30 ou
a 144 FPS.

`mouse_to_tile :: proc() -> (x, y: int, ok: bool)`: o caminho completo do mouse.
1. Se `!mouse_in_view()`: devolve `0, 0, false`. **Não pule isso:** sem ele, o mouse em
   cima do shop "acerta" um tile do mapa escondido embaixo do painel.
2. `world := rl.GetScreenToWorld2D(rl.GetMousePosition(), game.cam)`: tela pra mapa.
3. `return world_to_tile(world)`.

**Procs** (em `ui.odin`, arquivo novo, com `import "core:fmt"` e o raylib)

Escreva no topo do arquivo um comentário: *a fonte padrão da raylib não tem acento, então
texto na tela vai sem acento* ("Abobora", "Arvore"). Com acento aparece `?`.

`map_input_update :: proc()`: por enquanto só uma linha:
`game.hover.x, game.hover.y, game.hover_ok = mouse_to_tile()`.
Nas próximas etapas ela responde aos cliques no mapa.

`hover_outline_draw :: proc()`: se `game.hover_ok`, desenha um contorno branco meio
transparente (`{255, 255, 255, 160}`, espessura 2) no tile `game.hover`. Usa
`tile_to_world`: é chamada **dentro** da câmera.

`hud_draw :: proc()`: escreve em `(VIEW_X, 14)` o tile do mouse
(`fmt.ctprintf("Tile: %d, %d", ...)`) ou "Mouse fora do mapa".

`shop_panel :: proc()`: por enquanto só o fundo do painel e o texto "SHOP" (tire esse
desenho do main e traga pra cá).

**No main**

```
SETUP:   grid_generate(), camera_init()
LOOP:
  dt := min(rl.GetFrameTime(), 0.1)
  UPDATE:  camera_update(dt), map_input_update()
  DRAW:    BeginDrawing, ClearBackground
           Scissor + Mode2D:  grid_draw(), hover_outline_draw()
           fora da câmera:    hud_draw(), shop_panel()
           EndDrawing
           free_all(context.temp_allocator)
```

- **`min(..., 0.1)`:** se você arrastar a janela, o jogo congela e o próximo `dt` vem com
  vários segundos. Sem o limite, tudo "pula" de uma vez.
- **`camera_update` antes do `map_input_update`:** o tile do mouse é calculado com a câmera
  já na posição deste frame. Na ordem contrária, o clique cai onde a câmera estava antes.
- **`free_all(context.temp_allocator)`:** libera os textos do `fmt.ctprintf` do frame.

**Teste**
- [ ] WASD e setas movem o mapa. Espaço volta pro cesto.
- [ ] Mouse parado na borda move a câmera, e ela **para** nas bordas do mapa.
- [ ] Passar o mouse rápido da vista pro shop **não** dá tranco.
- [ ] O contorno segue o mouse. No canto de baixo-direita do mapa o HUD diz `95, 63`.
- [ ] Mouse em cima do shop: "Mouse fora do mapa".

**Se der errado**
- *O clique/contorno fica no tile errado só depois de rolar a câmera:* faltou o
  `GetScreenToWorld2D`. Com a câmera no canto do mapa ele "funciona" por coincidência.
- *O tile está sempre um pouco errado:* `world_to_tile` sem `floor`, ou `[y][x]`.
- *A câmera dá tranco ao ir pro shop:* o `edge_timer` não zera quando o mouse sai da borda.
- *O HUD treme ou anda com o mapa:* ele foi desenhado antes do `EndMode2D`.

---

### Etapa 4 — Plantas crescendo

**Objetivo:** com F1 você planta uma cenoura no canteiro embaixo do mouse. Ela cresce (o
círculo aumenta) e, pronta, pisca. F2 colhe.

**Arquivos:** `config.odin`, `grid.odin`, `ui.odin`, `main.odin`.

**O que você vai aprender:** guardar coisas **dentro do tile** em vez de numa lista, e
tabela de números por enum.

**Dados** (em `grid.odin`)

- `CropKind :: enum { None, Carrot, Lettuce, Pumpkin }`. `.None` = canteiro vazio.
- `Crop :: struct`:

| Campo | Tipo | Pra que serve |
|---|---|---|
| `kind` | `CropKind` | que planta é |
| `growth` | f32 | segundos de crescimento acumulados |
| `water` | f32 | 0 a 1. Começa a valer na Etapa 5 |
| `weeds` | bool | tem mato. Começa a valer na Etapa 5 |

- `Tile` ganha `crop: Crop`.

**A planta mora dentro do tile, não numa lista.** Um canteiro tem no máximo uma planta, e
ela nunca sai do lugar. O grid já **é** a lista: nada de índice, busca nem `active`.

**"Pronta" não é campo, é conta:** `growth >= tempo da planta`. Se você guardasse um
`ready: bool` junto, um dia os dois iam discordar.

**config.odin**: as tabelas das plantas (lembre do `@(rodata)` da seção 9):

| Tabela | Tipo | .None / Cenoura / Alface / Abóbora |
|---|---|---|
| `CROP_GROW_TIME` | `[CropKind]f32` | 0 / 20 / 40 / 90 |
| `CROP_COLOR` | `[CropKind]rl.Color` | `{}` / laranja `{237,145,33,255}` / verde-claro `{150,220,90,255}` / laranja-escuro `{205,95,20,255}` |
| `CROP_NAME` | `[CropKind]cstring` | `""` / `"Cenoura"` / `"Alface"` / `"Abobora"` |

**Procs** (em `grid.odin`)

`crop_is_ready :: proc(c: Crop) -> bool`: `kind != .None` **e** `growth >= CROP_GROW_TIME[c.kind]`.

`can_plant :: proc(x, y: int) -> bool`: o tile é `.Soil` **e** `crop.kind == .None`.

`crop_plant :: proc(x, y: int, kind: CropKind) -> bool`
1. Se `!can_plant(x, y)` ou `kind == .None`: `false`.
2. O `crop` do tile vira `Crop{kind = kind, water = 1}` (nasce regada).
3. `true`.
- **Não mexe em semente nem moeda.** Quem planta traz a semente (o ajudante, na Etapa 8).

`crop_harvest :: proc(x, y: int) -> (kind: CropKind, ok: bool)`
1. Pegue um ponteiro: `c := &game.tiles[x][y].crop`.
2. Se não está pronta: `.None, false`.
3. Guarde o `kind`, zere a planta (`c^ = Crop{}`, volta a canteiro vazio) e devolva o `kind, true`.
- **Não mexe no inventário.** Quem colhe decide o que fazer com a colheita.

`grid_update :: proc(dt: f32)`: passa por **todos** os tiles (não só os visíveis: a horta
cresce mesmo fora da tela).
1. `c := &game.tiles[x][y].crop` (ponteiro, porque vai mudar).
2. Se `kind == .None` ou já pronta: `continue`.
3. `c.growth += dt`.

`crop_draw :: proc(c: Crop, center: rl.Vector2)`
1. Se `kind == .None`, não desenha nada.
2. `progress := min(c.growth / CROP_GROW_TIME[c.kind], 1)` (de 0 a 1).
3. Raio: começa em 3 e vai até 10 (abóbora até 13): `3 + (raio_max - 3) * progress`.
4. `rl.DrawCircleV(center, raio, CROP_COLOR[c.kind])`.
5. Pronta: um contorno branco **piscando**. Truque pra piscar:
   `if int(rl.GetTime() * 3) % 2 == 0 { desenha o contorno }`.

`grid_draw` ganha uma **segunda passada**, depois da do chão, com os mesmos loops: em cada
tile `.Soil`, `crop_draw(tile.crop, tile_center(x, y))`. Duas passadas porque, nas próximas
etapas, a copa da árvore passa um pouco do tile, e o chão do vizinho não pode cobrir ela.

**Debug** (em `map_input_update`, depois de calcular o hover, só se `hover_ok`):
- `F1`: `crop_plant(x, y, .Carrot)` `// DEBUG`
- `F2`: `crop_harvest(x, y)` `// DEBUG`

**No main**: no update, `grid_update(dt)` depois do `map_input_update()`.

**Teste**
- [ ] F1 nos canteiros: aparece um pontinho laranja que cresce.
- [ ] Depois de 20 s a cenoura pisca. F2 nela: some.
- [ ] F1 na grama e no cesto: nada acontece. F2 numa cenoura que ainda cresce: nada.
- [ ] Rolar a câmera pra longe e voltar: ela continuou crescendo.

**Se der errado**
- *"Cannot index a constant":* a tabela foi declarada com `::`. Veja a pegadinha na seção 9.
- *A planta não cresce:* no `grid_update` o `c` é uma cópia (faltou o `&`).
- *Cresce rápido demais ou devagar demais:* o `growth` não está somando `dt`.

---

### Etapa 5 — Água e mato

**Objetivo:** a planta perde água com o tempo e pode ganhar mato. Seca ou com mato, ela
para de crescer. F3 rega e tira o mato.

**Arquivos:** `config.odin`, `grid.odin` (precisa de `import "core:math/rand"`), `ui.odin`.

**config.odin**

| Constante | Valor | Pra que serve |
|---|---|---|
| `WATER_DECAY` | `1.0 / 30.0` | água perdida **por segundo**: cheia (1) chega a 0 em 30 s. Escrito como divisão pra ler "30 s" |
| `THIRSTY_BELOW` | 0.3 | abaixo disso a planta está **com sede** |
| `WEED_CHANCE` | 0.005 | 0.5% de chance **por segundo** de nascer mato |

**Com sede não é seca.** Com sede (abaixo de 0.3) a planta **continua crescendo**: o limite
só serve pro ajudante saber quem regar e pro desenho mostrar. Quem para a planta é a água
chegar a **0**. De 0.3 até 0 são 9 s: é a folga pro ajudante chegar a tempo.

```
t = 0 s    água 1.0   plantou (nasce regada)
t = 21 s   água 0.3   COM SEDE: o ajudante já pode vir. Continua crescendo
t = 30 s   água 0.0   SECA: parou de crescer até alguém regar
```

**Procs novas** (em `grid.odin`)

- `crop_needs_water :: proc(c: Crop) -> bool`: tem planta, não está pronta e `water < THIRSTY_BELOW`.
- `crop_water :: proc(x, y: int) -> bool`: tem planta: `water = 1`, `true`.
- `crop_weed :: proc(x, y: int) -> bool`: tem mato: `weeds = false`, `true`.

**`grid_update` muda** (só pra planta que existe e não está pronta):
1. `c.water = max(c.water - WATER_DECAY * dt, 0)` (nunca abaixo de 0).
2. Mato: `if !c.weeds && rand.float32() < WEED_CHANCE * dt { c.weeds = true }`.
3. **Só cresce se `water > 0` e sem mato.**

**O `* dt` na chance de mato é obrigatório.** `WEED_CHANCE` é "por segundo". O frame dura
1/60 s, então a chance **neste frame** é `WEED_CHANCE * dt`. Sem o `dt`, a 60 FPS a chance
vira 30% por segundo e a horta vira um matagal.

**`crop_draw` ganha:**
- Com sede: a cor mais apagada (`rl.ColorAlpha(cor, 0.5)`).
- Uma barrinha azul (`rl.SKYBLUE`) embaixo da planta, com largura `24 * water`. (Não
  desenhe na planta pronta.)
- Mato: três tracinhos verde-escuros (`rl.DrawLineEx`) em volta da planta.

**Debug:** `F3` no tile: `crop_water` e `crop_weed` `// DEBUG`.

**Teste**
- [ ] Plantar e ver a barrinha azul descer. Abaixo de 30% a planta fica apagada.
- [ ] Troque o F1 pra plantar `.Pumpkin` (a cenoura fica pronta em 20 s, antes de secar, e
      não serve pra este teste). Plante duas abóboras juntas e regue (F3) só uma, sempre
      que a barra baixar. A que ficou seca demora bem mais pra piscar.
- [ ] Esperar o mato aparecer (pode demorar uns minutos; pra testar, aumente o
      `WEED_CHANCE` no config e depois volte). Com mato não cresce. F3 limpa.

**Se der errado**
- *Matagal em segundos:* faltou o `* dt` na chance.
- *Água negativa:* faltou o `max(..., 0)`.

---

## PARTE B — A ECONOMIA

### Etapa 6 — Inventário e shop pelo teclado

**Objetivo:** existe dinheiro. O ciclo completo funciona na mão (com debug): plantar
gasta semente, colher guarda no inventário, V vende, 1/2/3 compram sementes.

**Arquivos:** `config.odin`, `shop.odin` (novo), `main.odin`, `ui.odin`.

**O que você vai aprender:** separar "guardar" de "tem preço", e a regra da proc única.

**config.odin**

| Constante | Valor |
|---|---|
| `CROP_SEED_PRICE` (tabela, `@(rodata)`) | 0 / 1 / 3 / 8 |
| `CROP_SELL_PRICE` (tabela, `@(rodata)`) | 0 / 3 / 8 / 25 |
| `START_COINS` | 20 |
| `START_SEEDS` | `#partial [CropKind]int{.Carrot = 4}` (essa pode ser `::`: ela é copiada inteira, nunca indexada por variável) |

**Dados** (em `shop.odin`)

`Inventory :: struct`:

| Campo | Tipo | Pra que serve |
|---|---|---|
| `coins` | int | moedas |
| `crops` | `[CropKind]int` | **colheita** guardada, esperando você vender |
| `seeds` | `[CropKind]int` | **sementes**, esperando um ajudante plantar |

**Duas prateleiras separadas.** Cenoura colhida não vira semente. A única porta entre as
duas é o shop: você vende da prateleira de colheita e compra pra prateleira de sementes.

**No `Game`:** `inv: Inventory`.

**Procs** (em `shop.odin`. Nada aqui desenha nem lê mouse)

- `inventory_new :: proc() -> Inventory`: `coins = START_COINS`, `seeds = START_SEEDS`.
- `spend_coins :: proc(amount: int) -> bool`: tem moeda suficiente? Desconta e `true`.
  Senão `false` e não mexe. **A única proc que tira moeda.**
- `take_seed :: proc(kind: CropKind) -> bool`: tira 1 semente se tiver. **A única que tira semente.**
- `pick_seed :: proc() -> (kind: CropKind, ok: bool)`: a semente **mais cara** que tiver:
  confere abóbora, depois alface, depois cenoura. Nenhuma: `.None, false`.
- `sell :: proc(kind: CropKind)`: `coins += crops[kind] * CROP_SELL_PRICE[kind]` e zera
  `crops[kind]`. Vende a pilha inteira.
- `sell_all :: proc()`: `sell` pra cada `kind in CropKind`.
- `buy_seed :: proc(kind: CropKind, amount: int) -> bool`: `spend_coins(preço × amount)`;
  deu certo, `seeds[kind] += amount`. **Tudo ou nada:** sem moeda pra 10, não compra 7.

**No main**: uma proc nova `new_game :: proc()` que chama `grid_generate()` e faz
`game.inv = inventory_new()`. No setup, troque o `grid_generate()` por `new_game()`.

**`map_input_update` muda**
1. **Antes** do `if !hover_ok return`, os atalhos (funcionam com o mouse em qualquer lugar):
   `V` chama `sell_all()`; `1`, `2`, `3` (`.ONE`, `.TWO`, `.THREE`) chamam `buy_seed` de
   cenoura, alface e abóbora, 1 de cada vez.
2. `F1` agora: se `can_plant`, pega `pick_seed()`; se tem e `take_seed` deu certo, planta.
   **Nessa ordem:** conferir o tile antes, senão gasta semente num tile inválido.
3. `F2` agora: se `crop_harvest` deu certo, `game.inv.crops[kind] += 1`.

**`hud_draw` muda:** mostra as moedas, e numa segunda linha (y = 44) as colheitas e
sementes de cada planta.

**Teste**
- [ ] O ciclo na mão: F1 (semente -1), esperar, F2 (colheita +1), V (+3 moedas), 1
      (moeda -1, semente +1).
- [ ] Sem sementes, F1 não faz nada.
- [ ] Com 0 moedas, 3 (abóbora) não compra nada e não deixa moeda negativa.

**Este é o ciclo que os ajudantes vão rodar sozinhos.** Confira que ele fecha antes de
passar pra eles.

---

### Etapa 7 — O ajudante passeando

**Objetivo:** um coelhinho branco passeia em volta do cesto, andando liso e parando sem
tremer.

**Arquivos:** `config.odin`, `helper.odin` (novo, com `fmt`, `core:math/rand` e raylib), `main.odin`.

**config.odin**: `HELPER_SPEED :: 48` (px por segundo, 1.5 tile/s), `START_HELPERS :: 1`,
`SHOW_DEBUG :: true` (escreve o estado em cima de cada ajudante; desligue no fim).

**Dados** (em `helper.odin`)

`HelperState :: enum { Idle, Going, Working, Delivering }`: parado, indo, trabalhando,
entregando (o desenho da seção 5).

`Helper :: struct`, começa pequeno:

| Campo | Tipo | Pra que serve |
|---|---|---|
| `pos` | `rl.Vector2` | posição em pixels do **mapa**. Ele anda liso entre os tiles |
| `state` | `HelperState` | |
| `wander_timer` | f32 | quanto falta pra escolher outro lugar pra passear |
| `wander_to` | `rl.Vector2` | pra onde está passeando |

**No `Game`:** `helpers: [dynamic]Helper`.

**Procs**

`helper_add :: proc(pos: rl.Vector2)`: `append` de um `Helper{pos = pos, wander_to = pos}`.

`move_towards :: proc(pos: ^rl.Vector2, target: rl.Vector2, speed, dt: f32) -> bool`: anda
até o alvo e diz se chegou.
1. `diff := target - pos^` e `dist := rl.Vector2Length(diff)`.
2. Se `dist < 2`: chegou, `true`.
3. `step := min(speed * dt, dist)` e `pos^ += diff / dist * step`. `false`.
- O `min` impede passar do alvo e ficar tremendo em volta dele.
- O `dist < 2` vem **antes** da divisão: dividir por 0 dá `NaN`, e o ajudante some da tela
  sem erro nenhum.
- **Sem pathfinding:** ele anda em linha reta por cima de tudo. Numa horta, ninguém liga.

`helper_wander :: proc(h: ^Helper, dt: f32)`
1. `h.wander_timer -= dt`. Zerou: sorteia de novo (`rand.float32_range(2, 5)` segundos) e
   escolhe um ponto até 3 tiles pra cada lado do centro do cesto.
2. `move_towards` até `wander_to`, com metade da velocidade (passeio é devagar).

`helper_update :: proc(h: ^Helper, dt: f32)`: por enquanto, um `#partial switch h.state`
só com `case .Idle: helper_wander(h, dt)`.

`helpers_update :: proc(dt: f32)`: `for &h in game.helpers { helper_update(&h, dt) }`.

`helpers_draw :: proc()`: pra cada ajudante:
- um quadrado branco 12 x 12 centrado no `pos`, com contorno cinza;
- duas bolinhas brancas em cima (as orelhas);
- se `SHOW_DEBUG`: o estado embaixo dele (`fmt.ctprintf("%v", h.state)` escreve o nome do enum).

**No main**
- `new_game` ganha: `clear(&game.helpers)` e um `for` que chama `helper_add` no centro do
  cesto `START_HELPERS` vezes.
- Update: `helpers_update(dt)` depois do `grid_update`.
- Draw, dentro da câmera: `helpers_draw()` depois do `grid_draw()` (ajudante por cima da
  planta) e antes do `hover_outline_draw()`.

**Teste**
- [ ] O coelho passeia em volta do cesto, para, espera e sai de novo.
- [ ] Quando chega, ele para **sem tremer**.

---

### Etapa 8 — O ajudante trabalhando (o coração do jogo)

**Objetivo:** você não aperta mais nada. O ajudante pega as 4 sementes do começo, planta,
rega, tira mato, colhe e leva pro cesto, e a colheita aparece no inventário.

**Arquivos:** `config.odin`, `grid.odin`, `helper.odin` (agora com `core:math` também),
`ui.odin`, `game_test.odin` (novo).

**O que você vai aprender:** máquina de estados e **reserva de tarefa**.

**config.odin**
- `FIND_TASK_INTERVAL :: 0.5`: de quanto em quanto tempo o ajudante parado procura tarefa.
- `TASK_TIME` (tabela `@(rodata)`, `[TaskKind]f32`): quanto tempo o ajudante fica parado
  fazendo cada tarefa: None 0, Plant 1, Water 1, Weed 2, Harvest 1.

**Dados**

- `Tile` ganha `reserved: bool`: um ajudante já pegou uma tarefa aqui.
- `TaskKind :: enum { None, Plant, Water, Weed, Harvest }` (a Etapa 14 acrescenta as do
  lenhador e do minerador).
- `Job :: enum { Farmer }`: só fazendeiro por enquanto; a Etapa 14 acrescenta os outros.
- `Helper` ganha:

| Campo | Tipo | Pra que serve |
|---|---|---|
| `job` | `Job` | a profissão |
| `task` | `TaskKind` | o que ele vai fazer |
| `target` | `[2]int` | o tile da tarefa |
| `work_timer` | f32 | quanto falta pra terminar o trabalho |
| `work_total` | f32 | quanto o trabalho dura (pra barrinha de progresso) |
| `find_timer` | f32 | quanto falta pra procurar tarefa de novo |
| `seed` | `CropKind` | semente na mão, indo plantar |
| `carry_crop` | `CropKind` | colheita na mão, indo pro cesto |

**Por que `pos` em pixel e `target` em tile:** ele **anda** liso (pixel) mas **trabalha**
num tile (índice). A ponte é o `tile_center`.

**Por que `seed` e `carry_crop` separados:** um vai **pra** horta, o outro vem **da**
horta. Um campo só pros dois vira "estou levando cenoura... pra plantar ou pra guardar?".

**Procs** (em `helper.odin`)

`task_for_tile :: proc(job: Job, x, y: int) -> (task: TaskKind, priority: int)`: que tarefa
esse ajudante faria nesse tile, e com que prioridade (maior = mais urgente). Um
`switch job`; no `case .Farmer`, na ordem:
1. Pronta: `.Harvest, 4`.
2. Tem mato: `.Weed, 3`.
3. Com sede (`crop_needs_water`): `.Water, 2`.
4. `can_plant` **e** tem alguma semente (`has_any_seed`): `.Plant, 1`.
5. Nada: `.None, 0`.

`has_any_seed :: proc() -> bool`: o `ok` do `pick_seed()`.

`helper_find_task :: proc(h: Helper) -> (task: TaskKind, x, y: int, ok: bool)`: a melhor
tarefa do mapa.
1. Guarde a melhor prioridade (começa 0) e a menor distância (começa `math.F32_MAX`).
2. Passe por todos os tiles. **Pule os reservados.**
3. `task_for_tile`. Se `.None`, pule.
4. `dist := rl.Vector2Distance(h.pos, tile_center(tx, ty))`.
5. Se a prioridade é **maior** que a melhor, **ou igual e mais perto**: esse vira o melhor.
6. Devolve o melhor (ou `ok = false` se não achou nada).

`task_still_valid :: proc(h: Helper) -> bool`: "alguém já resolveu isso enquanto eu
andava?". Um `switch h.task`: `.Plant` é `can_plant` (a semente ele já tem na mão),
`.Water` é `crop_needs_water`, `.Weed` é `weeds`, `.Harvest` é `crop_is_ready`, `.None` é
`false`.

**A reserva (a regra mais importante deste jogo)**

Sem reserva, dois ajudantes veem a mesma planta com sede, os dois vão, os dois regam, e
metade do time trabalhou à toa.

`helper_release :: proc(h: ^Helper)`: **toda** saída de tarefa passa por aqui.
1. Se tem tarefa: `reserved = false` no tile do `target`.
2. Se tem semente na mão: devolve (`game.inv.seeds[h.seed] += 1`, `h.seed = .None`).
3. `h.task = .None`.

`helper_start_task :: proc(h: ^Helper)`
1. `helper_find_task`. Nada: volta.
2. Se a tarefa é `.Plant`: `pick_seed` + `take_seed`, e guarda em `h.seed`. **A semente sai
   do inventário agora**, na hora de escolher. Senão, com 1 semente, 3 ajudantes saem pra
   plantar e 2 chegam de mão vazia.
3. Guarda `task` e `target`, marca `reserved = true` no tile, `state = .Going`.

`helper_finish_task :: proc(h: ^Helper)`: faz a tarefa (um `switch h.task`):
- `.Plant`: se `crop_plant(x, y, h.seed)` deu certo, `h.seed = .None`. **Zere antes do
  release:** senão a release devolve a semente que já foi plantada, e vira semente infinita.
- `.Water`: `crop_water`. `.Weed`: `crop_weed`.
- `.Harvest`: se `crop_harvest` deu certo, guarda em `h.carry_crop`.
- Depois: `helper_release(h)`. Se está carregando algo, `.Delivering`; senão `.Idle`.

`helper_deliver :: proc(h: ^Helper)`: se `carry_crop != .None`, soma 1 em
`game.inv.crops[...]` e zera o `carry_crop`.

`helper_update` vira o `switch` completo (sem `#partial`):

| Estado | O que faz |
|---|---|
| `.Idle` | `helper_wander`. `find_timer -= dt`; zerou: volta pra `FIND_TASK_INTERVAL` e `helper_start_task` |
| `.Going` | **primeiro** `task_still_valid`; não vale: `helper_release`, `.Idle`, `return`. Depois `move_towards` até o `tile_center` do alvo; chegou: `work_total = TASK_TIME[h.task]`, `work_timer = work_total`, `.Working` |
| `.Working` | `work_timer -= dt`; zerou: `helper_finish_task` |
| `.Delivering` | `move_towards` até o cesto; chegou: `helper_deliver`, `.Idle` |

**Por que procurar a cada 0.5 s e não todo frame:** `helper_find_task` passa pelos 6144
tiles. Com 20 ajudantes a 60 FPS seriam 7 milhões de checagens por segundo, pra uma
resposta que quase nunca muda.

**Desenho**
- `helpers_draw` ganha: um pontinho marrom do lado se tem semente; um círculo da cor da
  planta em cima da cabeça se está carregando colheita; quando `.Working`, uma barrinha de
  progresso em cima do tile (`1 - work_timer / work_total`) e o corpo balançando 2 px
  (`pos.y += sin(rl.GetTime() * 20) * 2`, só no desenho, o `pos` de verdade não muda). O
  debug passa a escrever `state` e `task`.
- `grid_draw`, na segunda passada: se `SHOW_DEBUG` e o tile está reservado, um "R" vermelho
  pequeno. **Reserva presa é o bug mais chato deste jogo**, e com o "R" ele fica óbvio.

**Apague as teclas F1, F2 e F3.** A partir daqui, só o ajudante põe a mão na terra. Os
atalhos V e 1/2/3 ficam.

**Testes automáticos** (`game_test.odin`, `package game_01`, `import "core:testing"`)

O Odin roda testes sem abrir janela: `odin test src -define:ODIN_TEST_THREADS=1`.
- `-define:ODIN_TEST_THREADS=1` é **obrigatório** aqui: os testes mexem no mesmo `game`
  global, e rodando ao mesmo tempo um bagunça o outro.
- Escreva uma proc `simulate :: proc(seconds: f32)` que roda `grid_update` e
  `helpers_update` com `dt = 1.0/60.0` várias vezes (o jogo rodando "no escuro").
- Escreva uma proc `reset_game :: proc()` que faz `delete(game.helpers)` e depois
  `game = {}`. Chame com `defer reset_game()` no começo de cada teste. **Sem o `game = {}`**,
  o próximo teste usa um array de ajudantes que já foi liberado, e dá erro estranho.
- Uma proc `@(test)` recebe `t: ^testing.T` e usa `testing.expect_value(t, valor, esperado)`.

Testes desta etapa:
1. **Ciclo completo:** `new_game()`, `simulate(150)`. Esperado: 0 sementes de cenoura, 4
   cenouras na colheita, nenhum tile reservado.
2. **Reserva de semente:** `new_game()`, mais um `helper_add`, deixe só 1 semente,
   `simulate(1)`. Esperado: exatamente **um** ajudante com semente na mão, e 0 no inventário.

**Teste com o jogo rodando**
- [ ] Começar o jogo e **não tocar em nada.** O ajudante planta as 4 cenouras, rega quando
      precisa, colhe e leva pro cesto. O inventário mostra 4 cenouras.
- [ ] Acabaram as sementes: ele volta a passear. Aperte 1: ele sai pra plantar.
- [ ] Nenhum "R" fica preso num tile sem ajudante indo pra lá.

**Se der errado**
- *Ajudante parado com trabalho sobrando:* reserva presa. Algum caminho de saída não chama
  `helper_release`.
- *Semente nunca acaba:* o `h.seed` não foi zerado depois de plantar.
- *Semente some e ninguém planta:* saiu da tarefa sem `helper_release` devolver.
- *Dois ajudantes no mesmo pé:* a reserva não é marcada, ou o `find_task` não pula reservados.

**Se isso funciona, o jogo existe.**

---

### Etapa 9 — O painel do shop e a caixinha de info

**Objetivo:** jogar só com o mouse. O painel mostra o inventário e tem botões de vender e
comprar sementes. Passar o mouse num canteiro mostra a planta, quanto falta, água e mato.

**Arquivos:** `ui.odin`, `main.odin`.

**O que você vai aprender:** UI de **modo imediato**.

**Botão de modo imediato:** o botão não é um objeto guardado numa lista. É **uma proc
chamada todo frame** que desenha o botão e diz se ele foi clicado:

```odin
if button(retangulo, "Vender", tem_algo_pra_vender) {
	sell(.Carrot)
}
```

É o mesmo jeito do `raygui`, que vem com a raylib. **Por isso o painel quebra a regra
"draw não muda nada":** separar o desenho do clique exigiria calcular o layout duas
vezes, uma no update e outra no draw. Aqui a exceção é só o painel, e o resto do jogo segue
a regra.

O clique no painel **não vaza** pro mapa: o `mouse_to_tile` já devolve `ok = false` com o
mouse fora da vista.

**Procs** (em `ui.odin`)

`button :: proc(rect: rl.Rectangle, text: cstring, enabled := true) -> bool`
1. `hover := rl.CheckCollisionPointRec(rl.GetMousePosition(), rect)`.
2. Cor do fundo: apagada se `!enabled`, mais clara se `hover`, normal no resto.
3. Desenha o retângulo, um contorno e o texto (cinza se `!enabled`).
4. Devolve `enabled && hover && rl.IsMouseButtonPressed(.LEFT)`: `true` só no frame do clique.

**Montando o painel.** O painel é uma coluna: cada coisa desenhada empurra o `y` pra baixo.
Pra isso, as procs recebem `y: ^f32` (ponteiro, porque mudam ele).

| Proc | O que faz |
|---|---|
| `title :: proc(y: ^f32, text: cstring)` | espaço de 8, texto dourado tamanho 16, `y^ += 22` |
| `line :: proc(y: ^f32, text: cstring)` | texto branco tamanho 14, `y^ += 18` |
| `cell :: proc(y: f32, i, n: int) -> rl.Rectangle` | o retângulo do botão número `i` numa linha com `n` botões. Largura: `(largura do painel - espaços) / n` |

Constantes do painel no topo do `ui.odin` (são de layout, não de jogo): `ROW_H :: 28`
(altura do botão) e `GAP :: 6` (espaço entre botões).

Uma lista das plantas que aparecem no shop, pra fazer `for kind, i in PLANTS`:
`@(rodata) PLANTS := [3]CropKind{.Carrot, .Lettuce, .Pumpkin}`.

**Uma proc por seção do painel.** Cada uma recebe `y: ^f32`. Assim cada etapa só acrescenta
uma seção, sem mexer nas outras:

| Seção | O que mostra |
|---|---|
| `panel_inventory` | título "INVENTARIO" e duas linhas: colheita e sementes de cada planta |
| `panel_sell` | título "VENDER (V = tudo)". Um botão por planta: `"Cenoura x12  +36"` (quantidade e quanto vai ganhar). Apagado se a pilha é 0. Clique: `sell(kind)` |
| `panel_seeds` | título "SEMENTES (Shift = 10)". Um botão por planta com o preço. Com Shift apertado, compra 10 (`rl.IsKeyDown(.LEFT_SHIFT)`). Apagado sem moeda. Clique: `buy_seed` |

Depois de cada linha de botões, `y^ += ROW_H + GAP`.

`shop_panel` vira: o fundo do painel, `y: f32 = 4`, e a chamada de cada seção na ordem.

`hover_info_draw :: proc()`: a caixinha de info, **fora** da câmera.
1. Se `!hover_ok`, nada.
2. Monte até 4 linhas de texto (`lines: [4]cstring` e um contador `n`) com um `switch` no
   tipo do tile:
   - Canteiro vazio: "Canteiro vazio".
   - Canteiro com planta: o nome; "Pronta pra colher!" ou "Falta 12 s"; "Agua 45%"; "Tem
     mato!" ou "Sem mato".
   - Cesto: "Cesto: tudo chega aqui".
   - Grama: nada.
3. Se `n == 0`, nada. Senão, uma caixa preta meio transparente do lado do mouse (16 px pra
   direita e pra baixo) com as linhas.

Dica: separe as linhas numa proc própria, `tile_info :: proc(t: Tile) -> (lines: [4]cstring, n: int)`,
e o `hover_info_draw` só desenha. As Etapas 13 e 15 acrescentam árvore, pedra e casa só no
`tile_info`.

Formatação útil: `"%.0f"` escreve um f32 sem casas decimais; `"%%"` escreve o `%`.

`hud_draw` muda: só as moedas e o número de ajudantes (o resto está no painel).

**No main:** `hover_info_draw()` logo depois do `EndScissorMode()` e antes do `hud_draw()`.

**Teste**
- [ ] Comprar 5 sementes de alface pelo botão e ver o ajudante plantar alface.
- [ ] Shift + clique compra 10.
- [ ] Vender a pilha de cenoura e ver as moedas subirem na hora.
- [ ] Clicar num canteiro com o mouse: **nada** acontece com a planta.
- [ ] Mouse numa abóbora: a caixinha diz quanto falta e a água.

**Se der errado**
- *Texto com `?` no lugar de letras:* acento. A fonte padrão não tem.
- *Um clique compra duas vezes:* usou `IsMouseButtonDown` em vez de `IsMouseButtonPressed`.
- *A caixinha anda com o mapa:* foi desenhada dentro da câmera.

---

## PARTE C — CRESCER

### Etapa 10 — Ferramentas

**Objetivo:** comprar ferramentas no shop deixa todos os ajudantes melhores.

**Arquivos:** `config.odin`, `shop.odin`, `grid.odin`, `helper.odin`, `ui.odin`.

**config.odin**
- `TOOL_MAX_LEVEL :: 3`.
- `TOOL_PRICE` (`@(rodata)`, `[ToolKind][TOOL_MAX_LEVEL]int`): Botas `{20, 60, 150}`,
  Regador `{20, 60, 150}`, Enxada `{15, 45, 120}`, Foice `{25, 75, 180}`. Um array
  enumerado **de arrays**: a tabela inteira numa constante só.
- `TOOL_NAME` (`@(rodata)`, `[ToolKind]cstring`): "Botas", "Regador", "Enxada", "Foice".

**Dados**
- `ToolKind :: enum { Boots, Can, Hoe, Sickle }` (em `shop.odin`).
- `Inventory` ganha `tools: [ToolKind]int`: o nível de cada uma, de 0 (não tem) a 3.

**A ferramenta é de todos.** Não tem ferramenta na mão de um ajudante só. É um número no
inventário que as contas leem.

**Procs** (em `shop.odin`)

- `tool_next_price :: proc(kind: ToolKind) -> (price: int, ok: bool)`: se o nível já é o
  máximo, `ok = false`. Senão, `TOOL_PRICE[kind][nível atual]`. **O índice é o nível atual:**
  no nível 0 o próximo preço é o `[0]`. No nível 3, ler `[3]` sai do array: por isso confere
  o máximo antes.
- `buy_tool :: proc(kind: ToolKind) -> bool`: `tool_next_price`, `spend_coins`, nível + 1.
- **As contas** (só estas três procs leem `game.inv.tools`):

| Proc | Conta |
|---|---|
| `tool_speed :: proc() -> f32` | `HELPER_SPEED * (1 + 0.25 * nível das Botas)` |
| `tool_water_decay :: proc() -> f32` | `WATER_DECAY / (1 + 0.5 * nível do Regador)`: a água dura 30, 45, 60, 75 s |
| `tool_work_time :: proc(task: TaskKind) -> f32` | `TASK_TIME[task] * (1 - 0.25 * nível)`, onde o nível é da Enxada pra `.Plant` e `.Weed`, da Foice pra `.Harvest`, e 0 pro resto (`#partial switch`) |

**Quem passa a usar as contas** (troque a constante pela proc):
- `grid_update`: `tool_water_decay()` no lugar de `WATER_DECAY`. Calcule uma vez, **antes**
  dos loops, e não 6144 vezes.
- `helper_update`: `tool_speed()` no `move_towards`, `tool_work_time(h.task)` ao começar a trabalhar.
- `helper_wander`: `tool_speed() * 0.5`.

**Se amanhã a Bota der +30%, você muda uma linha só.**

**Painel:** seção `panel_tools`. Título "FERRAMENTAS", 4 botões em duas linhas de 2 (use
`cell(y, i % 2, 2)` e desça uma linha quando `i` é 2). Texto: `"Botas 1/3  $60"`, ou
`"Botas  MAX"` no nível 3. Apagado se não tem moeda ou está no máximo.

Dica: `for kind, i in ToolKind` dá o enum e o índice (o índice vem como enum; use `int(i)`).

**Teste**
- [ ] Plantar só abóbora com 1 ajudante e ver ele não dar conta das regas.
- [ ] Comprar o Regador: a barrinha azul desce mais devagar.
- [ ] Comprar Botas: os ajudantes andam mais rápido.
- [ ] No nível 3 o botão diz MAX e não cobra.

**Se der errado**
- *Comprei e nada mudou:* algum lugar ainda usa a constante (`HELPER_SPEED`, `WATER_DECAY`)
  direto, em vez da proc.

---

### Etapa 11 — Criar ajudantes

**Objetivo:** um botão no shop cria um novo ajudante pagando cenouras e moedas.

**Arquivos:** `config.odin`, `shop.odin`, `ui.odin`, `game_test.odin`.

**config.odin**: `MAX_HELPERS :: 8`. **É provisório:** na Etapa 15 ele some e quem manda é o
número de casas.

**Procs** (em `shop.odin`)

- `helper_capacity :: proc() -> int`: por enquanto, só devolve `MAX_HELPERS`. **Todo
  mundo pergunta pra ela** "quantos ajudantes cabem?". Na Etapa 15 ela muda de arquivo e
  passa a contar casas, e ninguém mais precisa mudar.
- `helper_cost :: proc() -> (carrots, coins: int)`: com `n := len(game.helpers)`:
  `5 + 3 * (n - 1)` cenouras e `10 + 20 * (n - 1)` moedas. **Cresce somando, não
  dobrando:** dobrando, o 20º ajudante custaria milhões.
- `buy_helper :: proc() -> bool`
  1. Já tem `helper_capacity()` ou mais: `false`.
  2. `helper_cost()`.
  3. **Confere os dois** (cenouras e moedas). Faltou um: `false`, sem descontar nada.
  4. Desconta os dois e `helper_add` no centro do cesto. `true`.

**Painel:** seção `panel_helpers`. Título `"AJUDANTES 3/8"` (tem / cabem). Um botão largo
(`cell(y, 0, 1)`) `"Criar ajudante: 8 cenouras + $30"`, apagado se faltar algo. Se não tem
vaga, o texto vira "Sem vaga pra mais ajudantes".

**HUD:** "Ajudantes 3/8".

**Teste automático:** `buy_helper` tudo ou nada. 5 cenouras e 9 moedas: `buy_helper` dá
`false` e as 5 cenouras continuam lá. Com 10 moedas: dá `true`, 2 ajudantes, 0 cenouras,
0 moedas.

**Teste com o jogo**
- [ ] Juntar 5 cenouras e 10 moedas, criar o 2º ajudante.
- [ ] Os dois dividem as tarefas e **nunca** vão no mesmo pé (a reserva funcionando).
- [ ] Repare na decisão nova: "Vender tudo" agora pode atrapalhar, porque a cenoura é o
      custo do ajudante.

---

### Etapa 12 — Lotes e decoração

**Objetivo:** comprar lotes (novos canteiros) e decoração, posicionando no mapa com o mouse.

**Arquivos:** `config.odin`, `grid.odin`, `shop.odin`, `ui.odin`, `main.odin`.

**O que você vai aprender:** item "na mão" e conferir antes de cobrar.

**config.odin**
- `PLOT_BASE_PRICE :: 10` e `PLOT_PRICE_STEP :: 5`: o lote custa `10 + 5 × lotes já comprados`.
- `DECOR_PRICE` (`@(rodata)`, `[DecorKind]int`): None 0, Flor 5, Banco 15, Lanterna 25.

**Dados**
- `DecorKind :: enum { None, Flower, Bench, Lantern }` (em `grid.odin`). `Tile` ganha
  `decor: DecorKind`.
- `PlaceKind :: enum { None, Plot, Flower, Bench, Lantern }` (em `shop.odin`): o que pode
  estar na mão. (A casa entra na Etapa 15.)
- `Inventory` ganha `plots_bought: int`.
- `Game` ganha `holding: PlaceKind`.

**Como funciona o "na mão"**
1. Clique no botão "Lote" do shop: `game.holding = .Plot`. Clicar de novo no mesmo botão
   solta.
2. O contorno do mouse fica **branco** onde dá pra pôr e **vermelho** onde não dá.
3. Clique esquerdo num tile: tenta pôr. Deu certo: **cobra e continua na mão** (pra pôr
   vários seguidos).
4. Clique direito: solta. **Nada foi pago.**

**Procs** (em `shop.odin`)

- `plot_price :: proc() -> int`.
- `place_to_decor :: proc(kind: PlaceKind) -> DecorKind`: `.Flower` vira `.Flower` etc.
  (são dois enums diferentes; esta proc é a ponte).
- `has_soil_neighbor :: proc(x, y: int) -> bool`: algum dos 4 vizinhos (cima, baixo,
  esquerda, direita) é `.Soil`? **Confira se o vizinho está dentro do grid** antes de ler.
  Dica: um array `{{1, 0}, {-1, 0}, {0, 1}, {0, -1}}` e um `for`.
- `can_place :: proc(kind: PlaceKind, x, y: int) -> bool`: **só pergunta, não muda nada.**
  1. O tile tem que ser `.Grass` e sem decoração. Senão `false`.
  2. Um `switch kind`: `.Plot` precisa de vizinho canteiro e moeda pro `plot_price`;
     decoração precisa de moeda pro preço dela; `.None` é `false`.
- `place :: proc(kind: PlaceKind, x, y: int) -> bool`
  1. `!can_place`: `false`.
  2. Cobra e muda o tile: lote vira `.Soil` e `plots_bought += 1`; decoração grava no `decor`.
- `decor_remove :: proc(x, y: int) -> bool`: tem decoração? Devolve **metade** do preço e
  apaga. Metade, e não tudo: senão mudar decoração de lugar vira cofre de moeda.

**Por que `can_place` e `place` separados:** o contorno vermelho/branco precisa perguntar
"dá?" todo frame sem cobrar nada. E o `place` usa a mesma pergunta, então os dois nunca
discordam.

**A regra do vizinho** faz a horta crescer como um bloco, e não salpicada pelo mapa. O
ajudante enxerga o canteiro novo sozinho, no próximo `find_task`.

**Desenho** (em `grid.odin`): `decor_draw :: proc(kind: DecorKind, center: rl.Vector2)`.
Flor: 3 bolinhas coloridas. Banco: retângulo marrom baixo. Lanterna: poste fino cinza e um
círculo amarelo em cima. Chame no `grid_draw`, na segunda passada, em todo tile.

**`map_input_update` muda** (depois do `if !hover_ok return`):
- Com algo na mão: clique esquerdo, `place(game.holding, x, y)`; clique direito, `holding = .None`.
- Sem nada na mão: clique direito, `decor_remove(x, y)`.

**Contorno** (`hover_outline_draw`): vermelho se `holding != .None` e `!can_place(...)`.

**Caixinha de info:** não aparece com algo na mão (atrapalha posicionar).

**Painel:** seção `panel_build`. Título "CONSTRUIR (clique direito solta)". Uma linha com
"Lote $10"; outra com Flor, Banco e Lanterna. Escreva uma proc
`place_button :: proc(rect: rl.Rectangle, kind: PlaceKind, text: cstring)`: desenha uma
moldura dourada em volta se `game.holding == kind`; clique: se já está na mão, solta; senão,
põe na mão.

**Teste**
- [ ] Lote grudado num canteiro: vira canteiro, cobra, e o ajudante planta nele sozinho.
- [ ] Lote longe da horta: contorno vermelho, clique não faz nada.
- [ ] Pôr uma flor (5), tirar com clique direito: volta 2.
- [ ] Clique direito com lote na mão: solta e não cobra.
- [ ] Clicar no botão do shop com algo na mão **não** posiciona nada no mapa.

---

## PARTE D — A FLORESTA

### Etapa 13 — Floresta e pedra no mapa

**Objetivo:** o mapa vira uma floresta em volta da clareira, com jazidas de pedra. Ninguém
corta nada ainda: é só o mundo.

**Arquivos:** `config.odin`, `grid.odin`, `ui.odin`.

**config.odin**

| Constante | Valor |
|---|---|
| `CLEARING_X`, `CLEARING_Y` | 40, 27 (canto da clareira, em tiles) |
| `CLEARING_W`, `CLEARING_H` | 17, 11 |
| `ROCK_CLUSTERS` | `[?][2]int{{60, 29}, {24, 14}, {74, 50}, {14, 48}, {82, 10}}`: o canto de cada jazida 3 x 3. O `[?]` deixa o Odin contar o tamanho |
| `TREE_WOOD`, `STUMP_WOOD`, `ROCK_STONE` | 3, 1, 2 |
| `ROCK_RESPAWN_TIME` | 120.0 |
| `GRAVEL_COLOR` | `{140, 128, 112, 255}` |

O cesto (45, 32) tem que estar **dentro** da clareira. Mudou a clareira? Confira.

**Dados**
- `TileKind` ganha `Tree`, `Stump` (toco), `Rock`, `Gravel` (cascalho).
- `Tile` ganha `respawn: f32`: só o cascalho usa, segundos até virar rocha.

**Repare no que não precisa de campo:** árvore, toco e rocha estão sempre prontos. O
`TileKind` sozinho já diz o que o tile é e o que dá pra fazer nele.

**`grid_generate` muda**, nesta ordem:
1. Tudo `.Tree` (zerando o tile antes, como já fazia). E 1 em cada 6 vira `.Grass`
   (`rand.int_max(6) == 0`): clareirinhas, pra floresta não ser um bloco chapado.
2. O retângulo da clareira vira `.Grass`.
3. A **volta** da clareira (1 tile pra fora, `CLEARING_X - 1 ..= CLEARING_X + CLEARING_W`):
   1 em cada 3 árvores vira grama. Sem isso a clareira tem borda de régua.
4. Cada jazida de `ROCK_CLUSTERS`: um bloco 3 x 3 de `.Rock` a partir do canto.
5. Canteiros e cesto, como antes.

**`grid_update` ganha** (antes da parte da planta, pra todo tile): se é `.Gravel`,
`respawn -= dt`; chegou a 0, vira `.Rock`.

Cuidado: hoje o loop faz `continue` quando não tem planta. Ponha a parte do cascalho
**antes** desse `continue`, senão ela nunca roda.

**Desenho** (procs pequenas que recebem o `center` do tile, chamadas na segunda passada do
`grid_draw` com um `#partial switch` no tipo):
- **Árvore:** tronco marrom fino e uma copa verde-escura, um círculo de raio 15 um pouco
  **acima** do centro (passa do tile pra cima: parece árvore vista de cima-lado).
- **Toco:** círculo marrom pequeno com um mais claro dentro (os anéis).
- **Rocha:** círculo cinza grande e um cinza-claro pequeno em cima (brilho).
- **Cascalho:** o chão é `GRAVEL_COLOR` (no `ground_color`) com 5 pedrinhas. **A posição
  das pedrinhas sai de uma conta com x e y**, tipo `(x * 7 + y * 13 + i * 11) % 26 + 3`,
  nunca de `rand` no desenho. Com `rand`, elas pulam de lugar todo frame.

`ground_color`: árvore, toco e rocha ficam em cima de grama.

**Caixinha de info** (`tile_info`): "Arvore: 3 madeira"; "Toco: 1 madeira" e "Arrancar
libera o terreno"; "Rocha: 2 pedra"; "Cascalho: vira rocha em 42 s".

**Teste**
- [ ] O jogo abre na clareira cercada de árvores, com borda irregular.
- [ ] Rolando a câmera, aparecem as 5 jazidas.
- [ ] O FPS continua 60 (se caiu, algum desenho não está usando `visible_tiles`).
- [ ] Lote e decoração **não** vão em cima de árvore (o `can_place` já exige grama).

**Se der errado:** *"switch não cobre todos os casos":* o compilador está mostrando cada
`switch` que precisa dos tipos novos. É exatamente pra isso que ele serve.

---

### Etapa 14 — Lenhador e minerador

**Objetivo:** no shop você transforma fazendeiros em lenhadores e mineradores. Eles cortam,
arrancam tocos, quebram pedra e levam madeira e pedra pro cesto.

**Arquivos:** `config.odin`, `shop.odin`, `grid.odin`, `helper.odin`, `ui.odin`, `game_test.odin`.

**A ideia mais importante desta etapa: profissão é um filtro, não outra máquina de
estados.** Os 4 estados continuam os mesmos. Lenhador anda, trabalha e entrega igualzinho
ao fazendeiro. A única diferença é **quais tarefas o `task_for_tile` mostra pra ele**. Um
pescador, um dia, seria só mais um `case` lá.

**Dados**
- `ResourceKind :: enum { None, Wood, Stone }` (em `shop.odin`).
- `Inventory` ganha `res: [ResourceKind]int` (madeira e pedra) e `cleared: int` (quantos
  tocos já foram arrancados, pra meta da Etapa 16).
- `Job` ganha `Lumberjack` e `Miner`.
- `TaskKind` ganha `Chop` (cortar árvore), `Uproot` (arrancar toco) e `Mine` (quebrar rocha).
- `TASK_TIME` ganha Chop 3, Uproot 2, Mine 4.
- `Helper` ganha `carry_res: ResourceKind` e `carry_amount: int` (árvore dá 3, toco 1, rocha 2).
  Não reaproveite o `carry_crop`: ele é planta, e madeira não é planta.

**Procs**

`resource_take :: proc(x, y: int) -> (kind: ResourceKind, amount: int, ok: bool)` (em
`grid.odin`): faz a transição do tile e diz o que saiu.

| Tile antes | Tile depois | Devolve |
|---|---|---|
| `.Tree` | `.Stump` | `.Wood, TREE_WOOD` |
| `.Stump` | `.Grass` (e `cleared += 1`) | `.Wood, STUMP_WOOD` |
| `.Rock` | `.Gravel` com `respawn = ROCK_RESPAWN_TIME` | `.Stone, ROCK_STONE` |
| outro | nada muda | `ok = false` |

Igual ao `crop_harvest`: **não mexe no inventário**, quem pegou leva até o cesto.

**O que muda no ajudante**
- `task_for_tile`: `case .Lumberjack`: toco é `.Uproot, 2`; árvore é `.Chop, 1`.
  `case .Miner`: rocha é `.Mine, 1`.
  **Toco antes de árvore:** senão a vila fica cercada de tocos e nenhum tile vira grama.
- `task_still_valid`: `.Chop` vale se o tile ainda é árvore; `.Uproot`, toco; `.Mine`, rocha.
- `helper_finish_task`: `case .Chop, .Uproot, .Mine`: `resource_take`; deu certo, guarda em
  `carry_res` e `carry_amount`. Se está carregando colheita **ou** recurso: `.Delivering`.
- `helper_deliver`: também entrega o recurso (`res[carry_res] += carry_amount`, zera os dois).

`helper_change_job :: proc(from, to: Job) -> bool`
1. Ache um ajudante com `job == from`, **de preferência um parado** (pra não jogar trabalho
   fora): percorra todos, guarde o índice do último que achou, e pare (`break`) se achar um `.Idle`.
2. Nenhum: `false`.
3. **`helper_release`** (trocar de profissão também é sair da tarefa!), **`helper_deliver`**
   (o que estava na mão vai direto pro inventário), `.Idle` e troca o `job`.

`count_job :: proc(job: Job) -> int`: quantos ajudantes têm essa profissão.

**Painel:** a seção `panel_helpers` ganha, embaixo do botão de criar, duas linhas:
`"Lenhadores: 1"` com `[-]` e `[+]` à direita (use `cell(y, 2, 4)` e `cell(y, 3, 4)`), e
igual pra mineradores. `[+]` chama `helper_change_job(.Farmer, job)` (apagado sem fazendeiro);
`[-]` chama `helper_change_job(job, .Farmer)` (apagado se não tem nenhum). Depois, uma
linha "Fazendeiros: 3 (quem sobra)".

Repare: o `ui.odin` chama `helper_change_job`, e tudo bem: ela mexe **no ajudante**, não na
terra. A regra "o `ui.odin` nunca chama `crop_...`" ganha a irmã: **nem `resource_take`**.

**Desenho do ajudante:** lenhador com um risquinho marrom do lado (o machado), minerador
com um cinza (a picareta). Carregando madeira: quadradinhos marrons em cima da cabeça, um
por madeira; pedra, cinzas.

**HUD:** "Moedas 42    Madeira 12    Pedra 3    Ajudantes 4/8".

**Teste automático:** trocar de profissão devolve a semente. `new_game()`, `simulate(0.6)`
(ele já pegou uma semente). Confira que ele tem a semente na mão, chame
`helper_change_job(.Farmer, .Lumberjack)`, e confira: 4 sementes de volta no inventário e
nenhum tile reservado.

**Teste com o jogo**
- [ ] Com 1 ajudante, transforme ele em lenhador: a horta para (ninguém rega) e a madeira sobe.
- [ ] A árvore vira toco, e logo depois o toco vira grama.
- [ ] Compre um lote grudado num canteiro onde antes era floresta.
- [ ] Volte o lenhador pra fazendeiro no meio de uma tarefa: o "R" some e nenhuma semente some.
- [ ] Ponha 5 mineradores: a jazida perto vira cascalho, eles vão pra uma longe, e 2
      minutos depois a perto volta.

**Se der errado**
- *Toco que nunca some:* o lenhador não enxerga `.Uproot`, ou a prioridade dele está abaixo da árvore.
- *Jazida que nunca volta:* o cascalho não é tratado no `grid_update`, ou o `respawn` não é ligado.
- *"R" preso depois de trocar profissão:* faltou `helper_release` no `helper_change_job`.

---

### Etapa 15 — Casas

**Objetivo:** cada casa abriga 5 ajudantes. Casas cheias, não dá pra criar ajudante. Casa
custa madeira e pedra.

**Arquivos:** `config.odin`, `grid.odin`, `shop.odin`, `ui.odin`.

**A casa é só capacidade.** Ninguém entra nem dorme nela. Ela dá motivo pra madeira e
pedra, e ocupa um tile de grama que podia ser canteiro.

**config.odin**: `HOUSE_CAPACITY :: 5`, `HOUSE_WOOD :: 10`, `HOUSE_STONE :: 5`,
`START_HOUSE_TILE :: [2]int{45, 34}` (2 tiles abaixo do cesto). **Apague o `MAX_HELPERS`.**

**Dados**
- `TileKind` ganha `House`. **Casa é tipo de tile:** nada de lista de casas, o grid já é a lista.
- `PlaceKind` ganha `House`.

**Procs**

Em `grid.odin`:
- `house_count :: proc() -> int`: conta os tiles `.House`.
- `helper_capacity :: proc() -> int`: `house_count() * HOUSE_CAPACITY`. **Apague a versão
  provisória do `shop.odin`.** Ninguém guarda esse número num campo: se guardasse, um dia a
  casa existe e o campo não foi atualizado.
- `grid_generate`: no fim, o tile `START_HOUSE_TILE` vira `.House`. Começa cabendo 5.
- Desenho: parede bege, um triângulo marrom de telhado (`rl.DrawTriangle`; os 3 pontos em
  **sentido anti-horário**, senão a raylib não desenha) e uma porta.

Em `shop.odin`:
- `can_place`, `case .House`: tem madeira **e** pedra suficientes.
- `place`, `case .House`: desconta os dois e o tile vira `.House`.

O fluxo de posicionar é **o mesmo do lote**: na mão, contorno branco/vermelho, clique
esquerdo põe, clique direito solta. Você não escreveu nada novo pra isso: só um `case`.

**Painel:** `panel_build` ganha o botão "Casa 10 mad. 5 pedra" do lado do Lote.
**Info:** "Casa: 5 vagas".

**Casa não se demole.** Se desse, você teria 10 ajudantes e vaga pra 5, e precisaria
decidir quem vai embora. Não vale o trabalho agora.

**Teste**
- [ ] O jogo começa com uma casinha perto do cesto e "Ajudantes 1/5".
- [ ] Criar ajudantes até 5/5: o botão apaga e diz "Sem vaga".
- [ ] Juntar 10 madeira e 5 pedra, pôr a casa: vira 5/10 e o botão acende.
- [ ] Sem pedra suficiente: contorno vermelho, e a madeira **não** sai do inventário.
- [ ] Casa só em grama: em cima de toco ou cascalho, vermelho.

---

## PARTE E — ACABAMENTO

### Etapa 16 — Metas e avisos

**Objetivo:** o HUD mostra a próxima meta e avisa quando falta algo.

**Arquivos:** `shop.odin`, `helper.odin`, `ui.odin`, `main.odin`.

Idle sem meta vira "deixar rodando e esquecer". As metas dão o próximo passo, e todas são
**uma compra ou um resultado dos ajudantes**, nunca "faça você mesmo".

**Dados**
- `Inventory` ganha dois contadores: `total_sold: int` (quantas colheitas você já vendeu) e
  `total_harvested: [CropKind]int` (quantas de cada já chegaram no cesto).
  - `sell` soma a quantidade vendida no `total_sold`.
  - `helper_deliver` soma 1 no `total_harvested` da planta entregue.
- `Goal :: enum` com as 10 metas da seção 5 (em `ui.odin`).
- `GOAL_TEXT` (`@(rodata)`, `[Goal]cstring`): o texto de cada uma.
- `Game` ganha `goals_done: [Goal]bool` e `goal_flash: f32` (tempo restante do aviso).

**Procs** (em `ui.odin`)

- `goal_check :: proc(goal: Goal) -> bool`: um `switch` com a condição de cada meta.
  "Compre uma ferramenta" = algum nível de ferramenta > 0. "Construa uma casa" =
  `house_count() >= 2` (a primeira já vem pronta). "Abra 100 tiles" = `cleared >= 100`.
- `goals_update :: proc(dt: f32)`: diminui o `goal_flash` (até 0). Pra cada meta não
  cumprida que agora dá `true`: marca como cumprida e `goal_flash = 2`. **Só liga, nunca
  desliga.**
- `warning_text :: proc() -> cstring`: passe pelo mapa uma vez e descubra se tem canteiro
  vazio e se tem planta crescendo. Devolve o primeiro que valer, ou `nil`:
  1. canteiro vazio e sem semente: "Sem sementes! Compre no shop."
  2. planta crescendo e nenhum fazendeiro: "Ninguem na horta!"
  3. sem vaga pra ajudante: "Casas cheias!"
- `hud_draw`: linha 1 com moedas, madeira, pedra e ajudantes. Linha 2: "Meta: ..." (a
  primeira não cumprida) e, à direita, "Meta cumprida!" em verde se `goal_flash > 0`, senão
  o aviso em laranja.

**No main:** `goals_update(dt)` no update, depois do `helpers_update`.

**Teste**
- [ ] As três primeiras metas se cumprem jogando normal, sem forçar.
- [ ] Deixar as sementes acabarem: aparece "Sem sementes!".
- [ ] Pôr todo mundo de lenhador com planta crescendo: "Ninguem na horta!".

---

### Etapa 17 — Salvar e carregar

**Objetivo:** fechar e abrir o jogo continua de onde parou.

**Arquivos:** `config.odin`, `save.odin` (novo, com `core:mem`, `core:os` e raylib),
`main.odin`, `game_test.odin`.

**Idle sem save não existe.** Fechar e perder a horta é o jeito mais rápido de o jogador
nunca mais abrir.

**Como o save funciona:** em vez de JSON, o save é **uma cópia dos bytes de um struct**
gravada num arquivo. É o jeito mais simples: gravar é uma linha, carregar é uma linha, e o
arquivo tem sempre o mesmo tamanho. Se o tamanho do arquivo não bate com o do struct, é um
save de outra versão do jogo (ou quebrado), e você começa um jogo novo.

**config.odin**: `SAVE_FILE :: "save.dat"`, `SAVE_VERSION :: 1`,
`AUTOSAVE_INTERVAL :: 30.0`, `MAX_SAVED_HELPERS :: 256`.

**Dados** (em `save.odin`)

- `HelperSave :: struct { pos: rl.Vector2, job: Job }`: **só a posição e a profissão** de
  cada ajudante.
- `SaveData :: struct`:

| Campo | Tipo |
|---|---|
| `version` | int |
| `size` | int: o `size_of(SaveData)` na hora de salvar |
| `tiles` | `[GRID_W][GRID_H]Tile` |
| `inv` | `Inventory` |
| `goals_done` | `[Goal]bool` |
| `helper_count` | int |
| `helpers` | `[MAX_SAVED_HELPERS]HelperSave` (array fixo: struct com array dinâmico não dá pra copiar em bytes) |

- `Game` ganha `autosave_timer: f32`.

**O que não vai pro save:** estado, tarefa e o que o ajudante carrega, as reservas e a
câmera. Ao abrir, todo ajudante volta parado, nenhum tile reservado, e a câmera no cesto.
Salvar uma reserva é salvar um bug: o ajudante que reservou não existe mais com aquele estado.

**Mas não jogue fora o que está na mão deles.** Semente foi comprada com o seu dinheiro:
sumir com ela ao fechar o jogo parece roubo.

**Procs**

`save_write :: proc() -> bool`
1. `data := new(SaveData)` e `defer free(data)`. **No heap, não na pilha:** o struct tem uns
   600 KB, e a pilha do Windows é pequena (estoura e fecha o jogo sem mensagem).
2. Preencha `version`, `size`, `tiles`, `inv`, `goals_done`.
3. Pra cada ajudante: some no `data.inv` a semente na mão, a colheita na mão e a
   madeira/pedra na mão.
4. Copie posição e profissão dos ajudantes (no máximo `MAX_SAVED_HELPERS`).
5. Zere o `reserved` de todos os tiles **do `data`** (não do jogo!).
6. Grave: `err := os.write_entire_file(SAVE_FILE, mem.ptr_to_bytes(data))`.
   `mem.ptr_to_bytes` transforma o ponteiro do struct numa fatia de bytes. Deu certo se
   `err == nil`.

`save_load :: proc() -> bool`
1. `bytes, err := os.read_entire_file(SAVE_FILE, context.allocator)`. Se `err != nil`: não
   tem save, `false`. Senão `defer delete(bytes)`.
2. Se `len(bytes) != size_of(SaveData)`: `false`.
3. `data := new(SaveData)`, `defer free(data)`, e copie os bytes pra dentro:
   `mem.copy(data, raw_data(bytes), size_of(SaveData))`.
4. Confira `version` e `size`. Diferente: `false`.
5. Copie `tiles`, `inv` e `goals_done` pro `game`. `clear(&game.helpers)` e, pra cada
   ajudante salvo, `helper_add` na posição e ponha o `job`.

**A API de arquivos do Odin mudou em 2025.** Na sua versão (dev-2026-05),
`read_entire_file` recebe o allocator e devolve `(data, err)`, e `write_entire_file`
devolve só o erro. Se um dia atualizar o Odin e não compilar, confira em
`C:\odin\core\os\file_util.odin`.

`autosave_update :: proc(dt: f32)`: soma `dt` no timer; passou de `AUTOSAVE_INTERVAL`,
zera e `save_write()`.

**Mudou um struct que vai pro save** (campo novo no `Tile`, no `Inventory`...)? Suba o
`SAVE_VERSION`. Na maioria das vezes o tamanho já muda e o save velho é ignorado sozinho,
mas o `version` garante.

**No main**
- Setup: `if !save_load() { new_game() }` e depois `camera_init()`.
- Update: `autosave_update(dt)` por último.
- Depois do loop, antes do `CloseWindow`: `save_write()`. (ESC e o X da janela fazem o
  `WindowShouldClose` dar `true`, então os dois salvam.)

**Teste automático** (precisa de `import "core:os"` no arquivo de teste): `new_game()`,
ponha 123 moedas e o primeiro ajudante como minerador, `save_write()`, `new_game()` de novo
(bagunça tudo), `save_load()`. Confira 123 moedas e o minerador. Use
`defer os.remove(SAVE_FILE)` pra não deixar o arquivo do teste pra trás.

**Teste com o jogo**
- [ ] Jogar 2 minutos, fechar com um ajudante indo plantar, abrir: tudo no lugar, e a
      semente dele de volta no estoque.
- [ ] Apagar o `save.dat`: começa jogo novo.
- [ ] Abrir o `save.dat` num editor, apagar um pedaço, salvar e abrir o jogo: começa jogo
      novo **sem travar**.

**Pronto: as 17 etapas estão feitas.** Desligue o `SHOW_DEBUG` e jogue.

---

## 13. Como achar bug sem se desesperar

**Primeiro:** deixe o `SHOW_DEBUG` ligado. Estado e tarefa escritos em cima de cada
ajudante e o "R" nos tiles reservados resolvem 90% dos bugs deste jogo.

| Sintoma | Causa provável |
|---|---|
| Ajudante parado com trabalho sobrando | reserva presa: um caminho de saída sem `helper_release` |
| Ajudantes passeando com canteiro vazio | acabou a semente, ou o `.Plant` não confere semente |
| Semente some e ninguém planta | saiu da tarefa sem `helper_release` devolver |
| Semente nunca acaba | `h.seed` não zerado depois de plantar |
| Dois ajudantes no mesmo pé | reserva não marcada, ou `find_task` não pula reservados |
| Ferramenta comprada e nada muda | alguém usa a constante direto em vez da proc do `tools` |
| Clique errado só depois de rolar a câmera | faltou `GetScreenToWorld2D` |
| Clique sempre um pouco errado | `world_to_tile` sem `floor`, ou `[y][x]` |
| Clicar no shop mexe no mapa | `mouse_to_tile` não confere se o mouse está na vista |
| Mapa por cima do HUD ou do shop | faltou o scissor |
| HUD ou shop andando com o mapa | desenhados antes do `EndMode2D` |
| Câmera dá tranco indo pro shop | `edge_timer` não zera |
| Jogo lento | algum desenho passa pelos 6144 tiles em vez de usar `visible_tiles` |
| Ajudante sumiu da tela | `NaN`: dividiu por distância zero no `move_towards` |
| Horta virou matagal em segundos | faltou `* dt` na chance de mato |
| Moeda ou semente negativa | alguém descontou sem passar pela proc única |
| Texto com `?` | acento na fonte padrão |
| "Cannot index a constant" | tabela declarada com `::` em vez de `@(rodata) :=` |
| Teste falha só às vezes | rodou sem `-define:ODIN_TEST_THREADS=1` |
| Teste dá "bad free" ou valor estranho | faltou o `game = {}` no `reset_game` |

## 14. Se o tempo apertar

Ordem de importância:

1. Mapa, câmera e plantas (Etapas 1 a 5)
2. Inventário e ajudante trabalhando sozinho (6 a 8)
3. Painel do shop (9)
4. Criar ajudantes (11)
5. Save (17). **Suba ele na lista antes de mostrar o jogo pra alguém:** ninguém joga um idle
   duas vezes se perdeu tudo na primeira.
6. Ferramentas (10)
7. Lotes e decoração (12)
8. Floresta, profissões e casas (13 a 15)
9. Metas (16)

Até o item 2 você já tem um jogo. Até o 4, um jogo bom.

## 15. O que NÃO fazer agora

Sprites, animação, som, pathfinding, mais de 3 plantas, estações, clima, dia e noite,
progresso offline, ajudante com nome, ferramenta por ajudante, compra automática de
semente, escolher o que plantar em cada canteiro, menu principal, casa maior que 1 tile,
demolir casa, zoom e minimapa.

**Se ver os quadradinhos trabalhando não é gostoso, sprite não vai salvar.** Só troque
primitivas por sprite quando as 17 etapas estiverem funcionando.

## 16. Fase 2: ideias pra depois

Em ordem de "mais efeito por menos código":

| Ideia | O que muda |
|---|---|
| **Compra automática** (um item do shop que recompra a semente quando acaba) | o idle vira idle de verdade |
| **Decoração com bônus** (flor faz os vizinhos crescerem 20% mais rápido) | decorar vira estratégia |
| **Adubo** (consumível: a próxima planta do canteiro cresce 2x) | lugar pra gastar moeda sobrando |
| **Machado e Picareta** (mais duas ferramentas) | upgrade pra lenhador e minerador |
| **Depósito** (um segundo cesto, posto perto da floresta) | o lenhador anda menos; onde construir vira decisão |
| **Plano por canteiro** (marcar "só abóbora aqui") | o jogador decide o layout sem pôr a mão na terra |
| **Progresso offline** (ao abrir, simular o tempo fechado, até 2 h) | a "colheita te esperando" dos idles |
| **Zoom e minimapa** | ver a vila inteira |
| **Viveiro** (o lenhador planta muda que vira árvore) | madeira que não acaba |
| **Processar colheita** (cenoura vira suco, que vale mais) | uma segunda camada de economia |

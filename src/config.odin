package game_01

// Só constantes. Zero lógica. As explicações de cada número estão no GDD, seção 4.

// ---- Janela (Etapa 1) ----
SCREEN_WIDTH :: 1280
SCREEN_HEIGHT :: 720
TITLE :: "Game 01"

// ---- Mapa (Etapa 1) ----
GRID_W :: 96 // tiles na horizontal
GRID_H :: 64 // tiles na vertical
TILE :: 32 // lado de um tile, em pixels

// A clareira do começo, em TILES
CLEARING_X :: 40
CLEARING_Y :: 27
CLEARING_W :: 17
CLEARING_H :: 11

BASKET_TILE :: [2]int{45, 32} // em TILES, dentro da clareira
START_HOUSE_TILE :: [2]int{45, 34} // Etapa 12

// ---- Tela: vista do mapa, HUD e shop, em PIXELS DE TELA (Etapa 1) ----
VIEW_X :: 20
VIEW_Y :: 80
VIEW_W :: 700
VIEW_H :: 620
PANEL_X :: 740

// ---- Câmera (Etapa 1) ----
CAMERA_SPEED :: 600 // px por segundo
EDGE_MARGIN :: 24 // px da borda da vista que empurram a câmera
EDGE_DELAY :: 0.25 // segundos parado na borda antes de andar

// ---- Ajudante (Etapas 5, 6 e 11) ----
HELPER_SPEED :: 48 // px por segundo (1.5 tile/s)

// Duração de cada tarefa, em SEGUNDOS
PLANT_TIME :: 1.0
WATER_TIME :: 1.0
WEED_TIME :: 2.0
HARVEST_TIME :: 1.0
CHOP_TIME :: 3.0
STUMP_TIME :: 2.0
MINE_TIME :: 4.0

FIND_TASK_INTERVAL :: 0.5 // de quanto em quanto tempo o ajudante .Idle procura tarefa

// ---- Água e mato (Etapa 4) ----
WATER_DECAY :: 1.0 / 30.0 // água perdida por segundo: cheia seca em 30 s
THIRSTY_BELOW :: 0.3 // abaixo disso o ajudante vem regar (a planta ainda cresce)
WEED_CHANCE :: 0.005 // 0.5% por segundo, sempre usada como WEED_CHANCE * dt

// ---- Começo do jogo (Etapas 3, 5 e 9) ----
START_COINS :: 20
START_HELPERS :: 1
MAX_HELPERS :: 8 // Etapas 9 a 11. Na Etapa 12 sai, e quem manda é a casa

// ---- Plantas (Etapa 2: descomente quando o enum CropKind existir) ----
// CROP_SEED_PRICE :: [CropKind]int{.None = 0, .Carrot = 1, .Lettuce = 3, .Pumpkin = 8}
// CROP_SELL_PRICE :: [CropKind]int{.None = 0, .Carrot = 3, .Lettuce = 8, .Pumpkin = 25}
// CROP_GROW_TIME  :: [CropKind]f32{.None = 0, .Carrot = 20, .Lettuce = 40, .Pumpkin = 90}
// START_SEEDS     :: #partial [CropKind]int{.Carrot = 4}

// ---- Ferramentas (Etapa 8: descomente quando o enum ToolKind existir) ----
// TOOL_MAX_LEVEL :: 3
// TOOL_PRICE :: [ToolKind][TOOL_MAX_LEVEL]int {
// 	.Boots  = {20, 60, 150},
// 	.Can    = {20, 60, 150},
// 	.Hoe    = {15, 45, 120},
// 	.Sickle = {25, 75, 180},
// }

// ---- Floresta e pedra (Etapa 11) ----
// Jazidas: blocos de 3 x 3 rochas, canto de cima-esquerda em TILES
ROCK_CLUSTERS :: [?][2]int{{60, 29}, {24, 14}, {74, 50}, {14, 48}, {82, 10}}

TREE_WOOD :: 3 // madeira quando a árvore cai (vira toco)
STUMP_WOOD :: 1 // madeira quando o toco é arrancado (vira grama)
ROCK_STONE :: 2 // pedra quando a rocha quebra (vira cascalho)
ROCK_RESPAWN_TIME :: 120.0 // segundos até o cascalho virar rocha de novo

// ---- Casas (Etapa 12: descomente o custo quando o enum ResourceKind existir) ----
HOUSE_CAPACITY :: 5
// HOUSE_COST :: #partial [ResourceKind]int{.Wood = 10, .Stone = 5}

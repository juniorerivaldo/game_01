package game_01

import rl "vendor:raylib"
Game :: struct {}


game: Game

main :: proc() {


	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, TITLE)
	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {


		rl.BeginDrawing()

		rl.ClearBackground(BG_COLOR)
		rl.DrawRectangle(VIEW_X, VIEW_Y, VIEW_W, VIEW_W, rl.DARKGREEN)
		rl.DrawText("HUD", VIEW_W, 14, 18, rl.WHITE)
		rl.DrawRectangle(PANEL_X - 10, VIEW_Y, VIEW_W, SCREEN_HEIGHT, rl.BLUE)

		rl.EndDrawing()
	}

	rl.CloseWindow()

}

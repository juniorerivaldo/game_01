package game_01

import rl "vendor:raylib"

main :: proc() {

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, TITLE)
	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {


		rl.BeginDrawing()

		rl.ClearBackground(rl.DARKGRAY)

		rl.EndDrawing()
	}

	rl.CloseWindow()

}

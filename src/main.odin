package horta

import rl "vendor:raylib"

main :: proc() {

	rl.InitWindow(1280, 720, "Horta")
	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {


		rl.BeginDrawing()

		rl.ClearBackground(rl.DARKGRAY)

		rl.EndDrawing()
	}

	rl.CloseWindow()

}

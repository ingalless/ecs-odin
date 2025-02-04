package ecs

import "core:fmt"
import rl "vendor:raylib"

width: i32 : 200
height: i32 : 200
velocity: f32 = 2.0

// An entity, which is just an ID
Entity :: distinct i32
MAX_ENTITIES: Entity = 5000
MAX_SYSTEMS: i32 = 20

GameComponent :: enum {
	PLAYING,
	END,
}

Direction :: enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

Tile :: enum {
	// Empty
	EMPTY,
	// Player 1
	P1,
	// Player 2 [NOT USED]
	P2,
}

GridComponent :: distinct [height / 2][width / 2]Tile

PositionComponent :: struct {
	pos:       rl.Vector2,
	direction: Direction,
}

position_system :: proc(c: ^PositionComponent) {
	using c

	keyPressed := rl.GetKeyPressed()
	if keyPressed == rl.KeyboardKey.L && direction != Direction.RIGHT {
		direction = Direction.LEFT
	} else if keyPressed == rl.KeyboardKey.H && direction != Direction.LEFT {
		direction = Direction.RIGHT
	} else if keyPressed == rl.KeyboardKey.J && direction != Direction.UP {
		direction = Direction.DOWN
	} else if keyPressed == rl.KeyboardKey.K && direction != Direction.DOWN {
		direction = Direction.UP
	}

	if direction == Direction.LEFT {
		pos = {pos[0] + velocity, pos[1]}
	} else if direction == Direction.RIGHT {
		pos = {pos[0] - velocity, pos[1]}
	} else if direction == Direction.UP {
		pos = {pos[0], pos[1] - velocity}
	} else if direction == Direction.DOWN {
		pos = {pos[0], pos[1] + velocity}
	}
}

grid_system :: proc(g: ^GridComponent, p: PositionComponent) {
	g[i32(p.pos.x) / 2][i32(p.pos.y) / 2] = Tile.P1
}

render_system :: proc(g: GridComponent, c: PositionComponent) {
	using c
	rl.DrawRectangleV(pos, {10.0, 10.0}, rl.BLACK)
	for col, x in g {
		for row, y in col {
			if row == Tile.P1 {
				rl.DrawRectangleV({f32(x * 2), f32(y * 2)}, {10.0, 10.0}, rl.BLACK)
			}
		}
	}
}

update_game_system :: proc(
	game: ^GameComponent,
	grid: GridComponent,
	position: PositionComponent,
) {
	using position

	// Check for out of bounds
	if i32(pos.x) < 1 || i32(pos.x) > width - 10 || i32(pos.y) < 1 || i32(pos.y) > height - 10 {
		game^ = GameComponent.END
	}

	// Check if we crashed into ourself
	for col, x in grid {
		for row, y in col {
			if row == Tile.P1 && i32(pos.x / 2.0) == i32(x) && i32(pos.y / 2.0) == i32(y) {
				game^ = GameComponent.END
			}
		}
	}
}

main :: proc() {
	p := PositionComponent{{50.0, 50.0}, Direction.UP}
	g := GridComponent{}
	game := GameComponent.PLAYING

	rl.InitWindow(width, height, "Garden")
	defer rl.CloseWindow()

	rl.SetTargetFPS(30)


	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		// Setup the scene
		rl.ClearBackground(rl.Color{78, 126, 107, 255})

		// Update systems
		switch game {
		case .PLAYING:
			position_system(&p)
			update_game_system(&game, g, p)
			render_system(g, p)
			grid_system(&g, p)
		case .END:
			rl.ClearBackground(rl.Color{78, 126, 107, 255})
			rl.DrawText("Loser!", 80, 80, 20, rl.BLACK)
		}
	}
}

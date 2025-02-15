package ecs

import "core:fmt"
import rl "vendor:raylib"

width: i32 : 600
height: i32 : 600
velocity: f32 : 1.0
line_size: i32 : 2
fline_size: f32 : f32(line_size)
middle_of_screen: i32 : (height / 2) - (line_size / 2)
font_size: i32 : 40

// An entity, which is just an ID
Entity :: distinct i32

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
	// Player 2
	P2,
}

GridComponent :: distinct [width][height]Tile

PositionComponent :: struct {
	pos:       rl.Vector2,
	direction: Direction,
}

PlayerComponent :: struct {
	color:    rl.Color,
	controls: struct {
		left:  rl.KeyboardKey,
		right: rl.KeyboardKey,
		up:    rl.KeyboardKey,
		down:  rl.KeyboardKey,
	},
}

position_system :: proc(players: [2]PlayerComponent, positions: ^[2]PositionComponent) {
	p1_pos, p2_pos := positions[0], positions[1]
	p1, p2 := players[0], players[1]

	// This does technically mean that only one player registers one click per frame...
	// Maybe rl.IskeyPressed() solves that
	keyPressed := rl.GetKeyPressed()
	for i in 0 ..< MAX_PLAYERS {
		player := players[i]
		pos := &positions[i]

		if keyPressed == player.controls.left && pos.direction != Direction.RIGHT {
			pos.direction = Direction.LEFT
		} else if keyPressed == player.controls.right && pos.direction != Direction.LEFT {
			pos.direction = Direction.RIGHT
		} else if keyPressed == player.controls.down && pos.direction != Direction.UP {
			pos.direction = Direction.DOWN
		} else if keyPressed == player.controls.up && pos.direction != Direction.DOWN {
			pos.direction = Direction.UP
		}


		if pos.direction == Direction.LEFT {
			pos.pos = {pos.pos[0] - velocity, pos.pos[1]}
		} else if pos.direction == Direction.RIGHT {
			pos.pos = {pos.pos[0] + velocity, pos.pos[1]}
		} else if pos.direction == Direction.UP {
			pos.pos = {pos.pos[0], pos.pos[1] - velocity}
		} else if pos.direction == Direction.DOWN {
			pos.pos = {pos.pos[0], pos.pos[1] + velocity}
		}
	}
}

grid_system :: proc(g: ^GridComponent, positions: [2]PositionComponent) {
	p1, p2 := positions[0], positions[1]
	g[i32(p1.pos.x)][i32(p1.pos.y)] = Tile.P1
	g[i32(p2.pos.x)][i32(p2.pos.y)] = Tile.P2
}

render_system :: proc(
	g: GridComponent,
	players: [MAX_PLAYERS]PlayerComponent,
	positions: [MAX_PLAYERS]PositionComponent,
) {
	for i in 0 ..< MAX_PLAYERS {
		color := players[i].color
		position := positions[i].pos
		rl.DrawRectangleV(position, {fline_size, fline_size}, color)
	}
	for col, x in g {
		for row, y in col {
			switch row {
			case .P1:
				rl.DrawRectangleV({f32(x), f32(y)}, {fline_size, fline_size}, players[0].color)
			case .P2:
				rl.DrawRectangleV({f32(x), f32(y)}, {fline_size, fline_size}, players[1].color)
			case .EMPTY:
			// Do nothing
			}
		}
	}
}

is_oob :: proc(bounds: [2]i32, pos: rl.Vector2) -> bool {
	h, w := bounds[0], bounds[1]

	if i32(pos.x) < 1 ||
	   i32(pos.x) > width - line_size ||
	   i32(pos.y) < 1 ||
	   i32(pos.y) > height - line_size {
		fmt.println("OOB", pos)
		return true
	}

	return false
}


update_game_system :: proc(
	game: ^GameComponent,
	grid: GridComponent,
	positions: [MAX_PLAYERS]PositionComponent,
) {
	for position, i in positions {
		if is_oob({height, width}, position.pos) {
			game^ = GameComponent.END
			return
		}

		tile_to_move_into := grid[i32(position.pos.x)][i32(position.pos.y)]
		switch tile_to_move_into {
		case .P1:
			fmt.println("PLAYER COLLISION", i, position.pos, tile_to_move_into)
			game^ = GameComponent.END
		case .P2:
			fmt.println("PLAYER COLLISION", i, position.pos, tile_to_move_into)
			game^ = GameComponent.END
		case .EMPTY:
		}
	}
}

main :: proc() {
	players: [MAX_PLAYERS]PlayerComponent = {
		PlayerComponent {
			color = rl.GREEN,
			controls = {
				left = rl.KeyboardKey.H,
				right = rl.KeyboardKey.L,
				up = rl.KeyboardKey.K,
				down = rl.KeyboardKey.J,
			},
		},
		PlayerComponent {
			color = rl.BLUE,
			controls = {
				left = rl.KeyboardKey.A,
				right = rl.KeyboardKey.D,
				up = rl.KeyboardKey.W,
				down = rl.KeyboardKey.S,
			},
		},
	}
	p1_pos := PositionComponent{{1.0, f32(middle_of_screen)}, Direction.RIGHT}
	p2_pos := PositionComponent{{f32(width) - 20.0, f32(middle_of_screen)}, Direction.LEFT}
	world := World {
		grid      = GridComponent{},
		positions = {p1_pos, p2_pos},
		game      = GameComponent.PLAYING,
		players   = players,
	}

	rl.InitWindow(width, height, "Tron")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)


	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		defer rl.EndDrawing()

		// Setup the scene
		rl.ClearBackground(rl.BLACK)

		// Update systems
		switch world.game {
		case .PLAYING:
			grid_system(&world.grid, world.positions)
			position_system(world.players, &world.positions)
			update_game_system(&world.game, world.grid, world.positions)
			render_system(world.grid, world.players, world.positions)
		case .END:
			rl.ClearBackground(rl.BLACK)
			offset := rl.MeasureText("Loser!", font_size) / 2
			rl.DrawText("Loser!", middle_of_screen - offset, middle_of_screen, font_size, rl.WHITE)
		}
	}
}

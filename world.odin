package ecs

import rl "vendor:raylib"

MAX_ENTITIES: Entity : 5000
MAX_SYSTEMS: i32 : 20
MAX_PLAYERS: i32 : 2

INIT_P1_POS: PositionComponent : PositionComponent{{1.0, f32(middle_of_screen)}, Direction.RIGHT}
INIT_P2_POS: PositionComponent : PositionComponent {
	{f32(width) - 1.0, f32(middle_of_screen)},
	Direction.LEFT,
}

World :: struct {
	entities:  [dynamic]Entity,
	grid:      GridComponent,
	game:      GameComponent,
	positions: [MAX_PLAYERS]PositionComponent,
	players:   [MAX_PLAYERS]PlayerComponent,
	winner:    i8,
}

init_world :: proc() -> World {
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
	return World {
		grid = GridComponent{},
		positions = {INIT_P1_POS, INIT_P2_POS},
		game = GameComponent.PLAYING,
		players = players,
	}
}

add_entity :: proc(w: ^World, e: Entity) {
	append(&w.entities, e)
}

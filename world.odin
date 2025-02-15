package ecs

MAX_ENTITIES: Entity : 5000
MAX_SYSTEMS: i32 : 20
MAX_PLAYERS: i32 : 2

World :: struct {
	entities:  [dynamic]Entity,
	grid:      GridComponent,
	game:      GameComponent,
	positions: [MAX_PLAYERS]PositionComponent,
	players:   [MAX_PLAYERS]PlayerComponent,
	winner:    i8,
}

// init_world :: proc() -> World {
// 	w := World{}
//
// 	return w
// }

add_entity :: proc(w: ^World, e: Entity) {
	append(&w.entities, e)
}

extends TileMapLayer

@export var player_path: NodePath = "../Player"
@export var walls_path: NodePath = "../WallsTileMapLayer"
@export var vision_area_path: NodePath = "VisionArea2D"  # relative to player
@export var wall_reveal_radius_tiles: int = 3  # radius of walls revealed around each newly-revealed floor tile
@onready var player: CharacterBody2D = get_node(player_path)
@onready var walls: TileMapLayer = get_node(walls_path)
@onready var vision_collision_shape: CollisionShape2D = player.get_node(vision_area_path).get_node("CollisionShape2D")

var _space_state: PhysicsDirectSpaceState2D
var _last_player_tile: Vector2i = Vector2i(1 << 30, 1 << 30)  # sentinel forces first reveal

const PHYSICS_WARMUP_FRAMES: int = 2
var _physics_frames_elapsed: int = 0

func _ready() -> void:
	_space_state = get_world_2d().direct_space_state
	_initialize_fog()

func _initialize_fog() -> void:
	clear()  # discard any stale hand-painted editor data, start from a clean slate
	var used_rect: Rect2i = walls.get_used_rect()
	for y in range(used_rect.position.y, used_rect.position.y + used_rect.size.y):
		for x in range(used_rect.position.x, used_rect.position.x + used_rect.size.x):
			var world_pos: Vector2 = walls.to_global(walls.map_to_local(Vector2i(x, y)))
			var fog_coord: Vector2i = local_to_map(to_local(world_pos))
			set_cell(fog_coord, 0, Vector2i(0, 0))

func _physics_process(_delta: float) -> void:
	if _physics_frames_elapsed < PHYSICS_WARMUP_FRAMES:
		# Give the physics server a couple of frames to finish registering
		# WallsTileMapLayer's collision shapes before the first raycast-based
		# reveal, otherwise intersect_ray() can miss walls that exist visually
		# but aren't live in the physics world yet, causing the very first
		# reveal at the player's start position to ignore walls.
		_physics_frames_elapsed += 1
		return
	var player_tile: Vector2i = local_to_map(to_local(player.global_position))
	if player_tile == _last_player_tile:
		return  # only recompute when the player crosses into a new tile
	_last_player_tile = player_tile
	_reveal_around(player_tile)

func _reveal_around(center: Vector2i) -> void:
	_force_reveal(center)
	_force_reveal(center + Vector2i.UP)
	_force_reveal(center + Vector2i.DOWN)
	_force_reveal(center + Vector2i.LEFT)
	_force_reveal(center + Vector2i.RIGHT)

	var vision_radius := _vision_radius_tiles()
	var r := int(ceil(vision_radius))
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var coord := center + Vector2i(dx, dy)
			if get_cell_source_id(coord) == -1:
				continue  # already revealed, or was never painted as fog
			if dx * dx + dy * dy > vision_radius * vision_radius:
				continue  # circular radius filter, no sqrt needed
			if _has_line_of_sight(coord):
				erase_cell(coord)
				if not _is_wall(coord):
					_reveal_walls_around(coord)

func _vision_radius_tiles() -> float:
	var shape := vision_collision_shape.shape as CircleShape2D
	assert(shape != null, "VisionArea2D/CollisionShape2D must use a CircleShape2D")
	var radius_px: float = shape.radius * vision_collision_shape.global_scale.x
	return radius_px / tile_set.tile_size.x

func _reveal_walls_around(floor_coord: Vector2i) -> void:
	var r := wall_reveal_radius_tiles
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dy * dy > r * r:
				continue  # circular radius filter, no sqrt needed
			var coord := floor_coord + Vector2i(dx, dy)
			if get_cell_source_id(coord) == -1:
				continue  # already revealed, or was never painted as fog
			if not _is_wall(coord):
				continue  # this pass only ever reveals walls
			erase_cell(coord)

func _is_wall(coord: Vector2i) -> bool:
	var tile_data := walls.get_cell_tile_data(coord)
	return tile_data != null and tile_data.get_collision_polygons_count(0) > 0

func _force_reveal(coord: Vector2i) -> void:
	if get_cell_source_id(coord) == -1:
		return
	erase_cell(coord)
	if not _is_wall(coord):
		_reveal_walls_around(coord)

func _has_line_of_sight(coord: Vector2i) -> bool:
	var target_world: Vector2 = to_global(map_to_local(coord))
	var query := PhysicsRayQueryParameters2D.create(
		player.global_position, target_world, 1  # mask = 1, matches walls' physics_layer_0/collision_layer
	)
	query.exclude = [player.get_rid()]
	var result := _space_state.intersect_ray(query)
	return result.is_empty()

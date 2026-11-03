class_name Utils


static func dir_to_string(dir: Vector2i, default_dir: String = "down") -> String:
	match dir:
		Vector2i.UP: return "up"
		Vector2i.DOWN: return "down"
		Vector2i.LEFT: return "left"
		Vector2i.RIGHT: return "right"
	return default_dir


static func string_to_dir(dir_str: String) -> Vector2i:
	match dir_str:
		"up": return Vector2i.UP
		"down": return Vector2i.DOWN
		"left": return Vector2i.LEFT
		"right": return Vector2i.RIGHT
	return Vector2i.DOWN


static func vector_to_cardinal(diff: Vector2i, default_dir: String) -> String:
	if diff == Vector2i.ZERO:
		return default_dir
	if absi(diff.x) >= absi(diff.y):
		return "right" if diff.x > 0 else "left"
	return "down" if diff.y > 0 else "up"


static func chebyshev_distance(pos_a: Vector2i, pos_b: Vector2i) -> int:
	var diff: Vector2i = (pos_a - pos_b).abs()
	return maxi(diff.x, diff.y)


# --- Grid ---
static func get_base_layer(layers: Array[TileMapLayer]) -> TileMapLayer:
	if layers.is_empty():
		return null
	return layers[0]


static func grid_to_world(cell: Vector2i, layers: Array[TileMapLayer]) -> Vector2:
	var base_layer: TileMapLayer = get_base_layer(layers)
	return base_layer.to_global(base_layer.map_to_local(cell))


static func world_to_grid(world_pos: Vector2, layers: Array[TileMapLayer]) -> Vector2i:
	var base_layer: TileMapLayer = get_base_layer(layers)
	if base_layer == null:
		return Vector2i.ZERO
	var local_pos: Vector2 = base_layer.to_local(world_pos)
	return base_layer.local_to_map(local_pos)


static func align_to_grid(node: Node2D, cell: Vector2i, layers: Array[TileMapLayer]) -> void:
	node.global_position = grid_to_world(cell, layers)


static func is_tile_walkable(cell: Vector2i, layers: Array[TileMapLayer]) -> bool:
	var base_layer: TileMapLayer = get_base_layer(layers)
	if base_layer == null:
		return true
	if base_layer.get_cell_source_id(cell) == -1:
		return false

	for layer in layers:
		if layer == null:
			continue
		var tile_data: TileData = layer.get_cell_tile_data(cell)
		if tile_data != null and tile_data.get_custom_data("is_walkable") == false:
			return false
	return true


static func has_line_of_sight(from: Vector2i, to: Vector2i, layers: Array[TileMapLayer]) -> bool:
	var delta: Vector2i = to - from
	var steps_x: int = absi(delta.x)
	var steps_y: int = absi(delta.y)
	var sign_x: int = 1 if delta.x > 0 else -1
	var sign_y: int = 1 if delta.y > 0 else -1
	var cell: Vector2i = from
	var done_x: int = 0
	var done_y: int = 0

	while done_x < steps_x or done_y < steps_y:
		var decision: int = (1 + 2 * done_x) * steps_y - (1 + 2 * done_y) * steps_x

		if decision == 0:
			var side_a: Vector2i = cell + Vector2i(sign_x, 0)
			var side_b: Vector2i = cell + Vector2i(0, sign_y)
			if not is_tile_walkable(side_a, layers) and not is_tile_walkable(side_b, layers):
				return false
			cell += Vector2i(sign_x, sign_y)
			done_x += 1
			done_y += 1
		elif decision < 0:
			cell.x += sign_x
			done_x += 1
		else:
			cell.y += sign_y
			done_y += 1

		if cell != to and not is_tile_walkable(cell, layers):
			return false
	return true


# --- Animation ---
static func play_animation(sprite: AnimatedSprite2D, state: String, facing_dir: String) -> void:
	var anim_name: String = state + "_" + facing_dir
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

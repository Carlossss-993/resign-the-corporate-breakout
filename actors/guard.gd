class_name Guard
extends GridActor

signal vision_changed

enum State { PATROL, CHASE, RETURN }

const DIRS_4: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT
]
const DIRS_8: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
	Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)
]
const FLASHLIGHT_ROTATION: Dictionary = {"up": 0, "right": 90, "down": 180, "left": 270}

@export_group("Patrol")
@export var patrol_waypoints: Array[Vector2i] = []
@export var loop_patrol: bool = true

@export_group("AI & Difficulty")
@export_range(2, 10) var diagonal_interval: int = 2

@export_group("Vision")
@export var vision_range: int = 6
@export var vision_half_width_patrol: int = 1
@export var vision_half_width_chase: int = 2
@export var debug_draw_vision: bool = true

@export_group("Visuals & Lighting")
@export var patrol_color: Color = Color("fff4a3")
@export var chase_color: Color = Color("4ac6ff")
@export var spotted_color: Color = Color("ff3333")

var current_state: State = State.PATROL
var current_waypoint_index: int = 0
var patrol_direction: int = 1
var turns_since_diagonal: int = 0
var turns_lost_sight: int = 0
var is_player_in_sight: bool = false
var last_known_position: Vector2i = Vector2i(-1, -1)
var last_known_facing: Vector2i = Vector2i.DOWN
var start_position: Vector2i = Vector2i.ZERO
var last_completed_grid_pos: Vector2i = Vector2i.ZERO
var flashlight_wide: bool = false

@onready var alert_icon: StatusIcon = %AlertIcon
@onready var flashlight: PointLight2D = %Flashlight
@onready var question_icon: StatusIcon = get_node_or_null("%QuestionIcon")


func _ready() -> void:
	super()
	last_completed_grid_pos = grid_position
	vision_changed.connect(queue_redraw)
	if question_icon:
		question_icon.top_level = true
	start_position = grid_position
	update_flashlight()


func finish_move() -> void:
	last_completed_grid_pos = grid_position
	update_flashlight()
	super()


func _draw() -> void:
	if not debug_draw_vision:
		return

	var tile_size: Vector2 = Vector2(Utils.get_base_layer(obstacle_layers).tile_set.tile_size)
	var draw_color: Color

	if is_player_in_sight:
		draw_color = Color(spotted_color.r, spotted_color.g, spotted_color.b, 0.4)
	elif current_state == State.CHASE:
		draw_color = Color(chase_color.r, chase_color.g, chase_color.b, 0.35)
	else:
		draw_color = Color(patrol_color.r, patrol_color.g, patrol_color.b, 0.3)

	for cell: Vector2i in get_vision_tiles():
		var center: Vector2 = to_local(Utils.grid_to_world(cell, obstacle_layers))
		draw_rect(Rect2(center - tile_size / 2.0, tile_size), draw_color)


func take_turn() -> void:
	match current_state:
		State.PATROL:
			process_patrol_turn()
		State.CHASE:
			process_chase_turn()
		State.RETURN:
			process_return_turn()


# --- Turns by state ---
func process_patrol_turn() -> void:
	turns_since_diagonal = 0
	if patrol_waypoints.is_empty():
		return

	var target: Vector2i = patrol_waypoints[current_waypoint_index]
	if grid_position == target:
		advance_waypoint()
		target = patrol_waypoints[current_waypoint_index]
		if grid_position == target:
			return

	if not move_towards(target, false, false):
		update_flashlight()
		Utils.play_animation(animated_sprite, "idle", facing_direction)


func process_chase_turn() -> void:
	if last_known_position == Vector2i(-1, -1):
		return

	if grid_position == last_known_position:
		face_last_known_direction()
		return

	if not move_towards(last_known_position, true, true):
		face_last_known_direction()


func process_return_turn() -> void:
	if patrol_waypoints.is_empty():
		return_to_start()
		return

	var target_index: int = get_nearest_waypoint_index()
	var target: Vector2i = patrol_waypoints[target_index]

	if grid_position == target:
		current_waypoint_index = target_index
		current_state = State.PATROL
		process_patrol_turn()
		return

	if not move_towards(target, true, false):
		current_waypoint_index = target_index
		current_state = State.PATROL


func return_to_start() -> void:
	if grid_position == start_position:
		current_state = State.PATROL
		return

	if not move_towards(start_position, true, false):
		current_state = State.PATROL


func advance_waypoint() -> void:
	if patrol_waypoints.size() <= 1:
		return

	if loop_patrol:
		current_waypoint_index = (current_waypoint_index + 1) % patrol_waypoints.size()
		return

	current_waypoint_index += patrol_direction
	if current_waypoint_index >= patrol_waypoints.size():
		patrol_direction = -1
		current_waypoint_index = patrol_waypoints.size() - 2
	elif current_waypoint_index < 0:
		patrol_direction = 1
		current_waypoint_index = 1


func get_nearest_waypoint_index() -> int:
	var nearest_index: int = 0
	var min_dist: int = Utils.chebyshev_distance(grid_position, patrol_waypoints[0])

	for i: int in range(1, patrol_waypoints.size()):
		var dist: int = Utils.chebyshev_distance(grid_position, patrol_waypoints[i])
		if dist < min_dist:
			min_dist = dist
			nearest_index = i

	return nearest_index


# --- Movement ---
func move_towards(target: Vector2i, uses_diagonals: bool, is_chasing: bool) -> bool:
	var allow_diagonal: bool = false
	if uses_diagonals:
		turns_since_diagonal += 1
		allow_diagonal = turns_since_diagonal >= diagonal_interval

	var step_dir: Vector2i = get_next_path_step(target, allow_diagonal, is_chasing)
	if step_dir == Vector2i.ZERO:
		return false

	if step_dir.x != 0 and step_dir.y != 0:
		turns_since_diagonal = 0

	var look_dir: Vector2i = target - grid_position if is_chasing else step_dir
	move_to_cell(grid_position + step_dir, Utils.vector_to_cardinal(look_dir, facing_direction))
	return true


func face_last_known_direction() -> void:
	facing_direction = Utils.vector_to_cardinal(last_known_facing, facing_direction)
	update_flashlight()
	Utils.play_animation(animated_sprite, "idle", facing_direction)


# --- Pathfinding ---
func is_step_walkable(from_cell: Vector2i, dir: Vector2i) -> bool:
	if not Utils.is_tile_walkable(from_cell + dir, obstacle_layers):
		return false

	if dir.x != 0 and dir.y != 0:
		var side_x: Vector2i = from_cell + Vector2i(dir.x, 0)
		var side_y: Vector2i = from_cell + Vector2i(0, dir.y)
		if not Utils.is_tile_walkable(side_x, obstacle_layers) and not Utils.is_tile_walkable(side_y, obstacle_layers):
			return false
	return true


func get_next_path_step(target: Vector2i, allow_diagonal: bool, greedy: bool) -> Vector2i:
	if grid_position == target:
		return Vector2i.ZERO

	var diff: Vector2i = target - grid_position
	var dx: int = clampi(diff.x, -1, 1)
	var dy: int = clampi(diff.y, -1, 1)

	if allow_diagonal and dx != 0 and dy != 0:
		var diagonal: Vector2i = Vector2i(dx, dy)
		if is_step_walkable(grid_position, diagonal) and (greedy or is_diagonal_on_shortest_path(diagonal, target)):
			return diagonal

	if greedy:
		var greedy_step: Vector2i = get_greedy_step(diff)
		if greedy_step != Vector2i.ZERO:
			return greedy_step

	return get_bfs_path_step(target, allow_diagonal)


func get_greedy_step(diff: Vector2i) -> Vector2i:
	var dx: int = clampi(diff.x, -1, 1)
	var dy: int = clampi(diff.y, -1, 1)
	var step_x: Vector2i = Vector2i(dx, 0)
	var step_y: Vector2i = Vector2i(0, dy)
	var can_step_x: bool = dx != 0 and is_step_walkable(grid_position, step_x)
	var can_step_y: bool = dy != 0 and is_step_walkable(grid_position, step_y)

	if absi(diff.x) >= absi(diff.y):
		if can_step_x:
			return step_x
		if can_step_y:
			return step_y
	else:
		if can_step_y:
			return step_y
		if can_step_x:
			return step_x
	return Vector2i.ZERO


func is_diagonal_on_shortest_path(diagonal: Vector2i, target: Vector2i) -> bool:
	var full_path: Array[Vector2i] = find_bfs_path(grid_position, target, true)
	var path_after: Array[Vector2i] = find_bfs_path(grid_position + diagonal, target, true)
	return not full_path.is_empty() and path_after.size() == full_path.size() - 1


func get_bfs_path_step(target: Vector2i, allow_diagonal: bool) -> Vector2i:
	var path: Array[Vector2i] = find_bfs_path(grid_position, target, allow_diagonal)
	if path.size() < 2:
		return get_fallback_step(target, allow_diagonal)
	return path[1] - grid_position


func find_bfs_path(start: Vector2i, target: Vector2i, allow_diagonal: bool) -> Array[Vector2i]:
	var directions: Array[Vector2i] = DIRS_8 if allow_diagonal else DIRS_4
	var queue: Array[Vector2i] = [start]
	var came_from: Dictionary = {start: start}

	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == target:
			break

		for dir: Vector2i in directions:
			var next_cell: Vector2i = current + dir
			if came_from.has(next_cell):
				continue
			if is_step_walkable(current, dir) or next_cell == target:
				came_from[next_cell] = current
				queue.push_back(next_cell)

	if not came_from.has(target):
		return []

	var path: Array[Vector2i] = []
	var cell: Vector2i = target
	while cell != start:
		path.push_front(cell)
		cell = came_from[cell]
	path.push_front(start)
	return path


func get_fallback_step(target: Vector2i, allow_diagonal: bool) -> Vector2i:
	var directions: Array[Vector2i] = DIRS_8 if allow_diagonal else DIRS_4
	var best_dir: Vector2i = Vector2i.ZERO
	var min_dist: float = INF

	for dir: Vector2i in directions:
		if not is_step_walkable(grid_position, dir):
			continue
		var dist: float = (grid_position + dir).distance_to(target)
		if dist < min_dist:
			min_dist = dist
			best_dir = dir
	return best_dir


# --- Vision ---
func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	return Utils.has_line_of_sight(from, to, obstacle_layers)


func get_vision_tiles() -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var forward: Vector2i = Utils.string_to_dir(facing_direction)
	var right: Vector2i = Vector2i(-forward.y, forward.x)
	var half_width: int = vision_half_width_chase if current_state == State.CHASE else vision_half_width_patrol

	for side: Vector2i in [right, -right]:
		var side_cell: Vector2i = last_completed_grid_pos + side
		if Utils.is_tile_walkable(side_cell, obstacle_layers):
			tiles.append(side_cell)

	for distance in range(1, vision_range + 1):
		for offset in range(-half_width, half_width + 1):
			var cell: Vector2i = last_completed_grid_pos + forward * distance + right * offset
			if Utils.is_tile_walkable(cell, obstacle_layers) and has_line_of_sight(last_completed_grid_pos, cell):
				tiles.append(cell)

	return tiles


# --- Alerts ---
func show_alert() -> void:
	if alert_icon:
		alert_icon.flash(1.2)


func update_question_marker() -> void:
	if question_icon == null:
		return

	var is_searching: bool = current_state == State.CHASE and not is_player_in_sight
	if not is_searching:
		question_icon.hide_icon()
		return

	var cell_center: Vector2 = Utils.grid_to_world(last_known_position, obstacle_layers)
	question_icon.global_position = cell_center + Vector2(0, -28)
	if not question_icon.visible:
		question_icon.show_icon()


# --- Flashlight ---
func update_flashlight() -> void:
	update_flashlight_width()
	update_flashlight_rotation()
	update_flashlight_color()
	vision_changed.emit()


func update_flashlight_width() -> void:
	var wide: bool = current_state == State.CHASE
	if wide == flashlight_wide:
		return
	flashlight_wide = wide

	var patrol_width: float = vision_half_width_patrol * 2 + 1
	var chase_width: float = vision_half_width_chase * 2 + 1
	var target_scale: float = chase_width / patrol_width if wide else 1.0
	create_tween().tween_property(flashlight, "scale:x", target_scale, 0.15)


func update_flashlight_rotation() -> void:
	flashlight.rotation_degrees = FLASHLIGHT_ROTATION[facing_direction]


func update_flashlight_color() -> void:
	if is_player_in_sight:
		flashlight.color = spotted_color
	elif current_state == State.CHASE:
		flashlight.color = chase_color
	else:
		flashlight.color = patrol_color

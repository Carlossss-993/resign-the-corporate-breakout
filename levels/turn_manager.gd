class_name TurnManager
extends Node

signal turn_updated(turns_taken: int)
signal level_completed(turns_taken: int)
signal player_captured

@export_group("Entities")
@export var player: Player
@export var guards: Array[Guard] = []

@export_group("Level Goals")
@export var exit_cell: Vector2i = Vector2i(-1, -1)
@export var exit_cells: Array[Vector2i] = []

@export_group("Difficulty & Stealth Rules")
@export var max_turns_lost_sight: int = 7
@export var max_hidden_detect_distance: int = 2
@export var guard_alert_radius: int = 8

var turns_taken: int = 0


func _ready() -> void:
	if player == null:
		push_error("TurnManager needs a reference to the Player node.")
		return
	player.player_moved.connect(on_player_moved)


func on_player_moved(_new_grid_pos: Vector2i) -> void:
	turns_taken += 1
	turn_updated.emit(turns_taken)

	player.input_locked = true
	var player_prev: Vector2i = player.previous_grid_position
	var guard_prev_positions: Dictionary = {}

	for guard: Guard in guards:
		guard_prev_positions[guard] = guard.grid_position
		if guard.current_state == Guard.State.CHASE:
			check_guard_vision(guard, false, player.just_entered_plant)

	for guard: Guard in guards:
		guard.take_turn()

	if player.is_moving:
		await player.move_finished

	for guard: Guard in guards:
		if guard.is_moving:
			await guard.move_finished

	if check_any_capture(player_prev, guard_prev_positions):
		return

	if check_win(guard_prev_positions):
		return

	for guard: Guard in guards:
		check_guard_vision(guard)

	player.unlock_input()


func is_exit_cell(cell: Vector2i) -> bool:
	if cell == exit_cell and exit_cell != Vector2i(-1, -1):
		return true
	return exit_cells.has(cell)


func check_win(guard_prev_positions: Dictionary) -> bool:
	if not is_exit_cell(player.grid_position):
		return false

	for guard: Guard in guards:
		var guard_prev: Vector2i = guard_prev_positions.get(guard, guard.grid_position)
		var guard_was_already_at_exit: bool = is_exit_cell(guard_prev) and guard.grid_position == player.grid_position
		var swapped: bool = guard.current_state == Guard.State.CHASE \
			and guard.grid_position == player.previous_grid_position \
			and guard_prev == player.grid_position

		if guard_was_already_at_exit or swapped:
			return false

	player.input_locked = true
	level_completed.emit(turns_taken)
	return true


func check_any_capture(player_prev: Vector2i, guard_prev_positions: Dictionary) -> bool:
	for guard: Guard in guards:
		var guard_prev: Vector2i = guard_prev_positions.get(guard, guard.grid_position)
		var same_tile: bool = player.grid_position == guard.grid_position
		var swapped: bool = guard.current_state == Guard.State.CHASE \
			and guard.grid_position == player_prev \
			and guard_prev == player.grid_position

		if swapped:
			trigger_capture()
			return true

		if same_tile:
			if is_exit_cell(player.grid_position) and not is_exit_cell(guard_prev):
				continue
			trigger_capture()
			return true

	return false


func trigger_capture() -> void:
	player.input_locked = true
	player_captured.emit()


func can_guard_see_player(guard: Guard, ignore_hiding: bool) -> bool:
	var vision_tiles: Array[Vector2i] = guard.get_vision_tiles()
	if not vision_tiles.has(player.grid_position):
		return false

	if player.is_hidden and not ignore_hiding:
		var distance: int = Utils.chebyshev_distance(guard.grid_position, player.grid_position)
		return distance <= max_hidden_detect_distance
	return true


func check_guard_vision(guard: Guard, count_lost_turn: bool = true, ignore_hiding: bool = false) -> void:
	var was_in_sight: bool = guard.is_player_in_sight
	var in_sight: bool = can_guard_see_player(guard, ignore_hiding)
	guard.is_player_in_sight = in_sight

	if in_sight:
		if not was_in_sight:
			guard.show_alert()
			alert_nearby_guards(guard)
		guard.last_known_position = player.grid_position
		guard.last_known_facing = Utils.string_to_dir(player.facing_direction)
		guard.turns_lost_sight = 0
		guard.current_state = Guard.State.CHASE
	elif count_lost_turn and guard.current_state == Guard.State.CHASE:
		guard.turns_lost_sight += 1
		if guard.turns_lost_sight >= max_turns_lost_sight:
			guard.current_state = Guard.State.RETURN
			guard.turns_lost_sight = 0

	guard.update_flashlight()
	guard.update_question_marker()


func alert_nearby_guards(spotter: Guard) -> void:
	for other_guard: Guard in guards:
		if other_guard == spotter:
			continue

		var dist: int = Utils.chebyshev_distance(spotter.grid_position, other_guard.grid_position)
		if dist <= guard_alert_radius:
			other_guard.last_known_position = player.grid_position
			other_guard.turns_lost_sight = 0
			other_guard.current_state = Guard.State.CHASE
			other_guard.show_alert()
class_name Player
extends GridActor

signal player_moved(new_grid_pos: Vector2i)

const MOVE_ACTIONS: Dictionary = {
	"move_right": Vector2i.RIGHT,
	"move_left": Vector2i.LEFT,
	"move_down": Vector2i.DOWN,
	"move_up": Vector2i.UP,
}

@export_group("Stealth Settings")
@export var plants_layer: TileMapLayer
@export var hidden_opacity: float = 0.5
@export var opacity_tween_duration: float = 0.2

var previous_grid_position: Vector2i
var buffered_dir: Vector2i = Vector2i.ZERO
var buffered_wait: bool = false
var input_locked: bool = false
var is_hidden: bool = false
var just_entered_plant: bool = false

@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	super()
	set_camera_limits()
	check_hiding_status()


func set_camera_limits() -> void:
	var base_layer: TileMapLayer = Utils.get_base_layer(obstacle_layers)
	if camera == null or base_layer == null:
		return

	var used_rect: Rect2i = base_layer.get_used_rect()
	var tile_size: Vector2i = base_layer.tile_set.tile_size

	camera.limit_left = used_rect.position.x * tile_size.x
	camera.limit_top = used_rect.position.y * tile_size.y
	camera.limit_right = used_rect.end.x * tile_size.x
	camera.limit_bottom = used_rect.end.y * tile_size.y


# --- Input ---
func _unhandled_input(event: InputEvent) -> void:
	var dir: Vector2i = read_direction(event)
	var wants_wait: bool = event.is_action_pressed("wait")
	if dir == Vector2i.ZERO and not wants_wait:
		return

	if is_moving or input_locked:
		buffered_dir = dir
		buffered_wait = wants_wait
		return

	act(dir, wants_wait)


func read_direction(event: InputEvent) -> Vector2i:
	for action in MOVE_ACTIONS:
		if event.is_action_pressed(action):
			return MOVE_ACTIONS[action]
	return Vector2i.ZERO


func held_direction() -> Vector2i:
	for action in MOVE_ACTIONS:
		if Input.is_action_pressed(action):
			return MOVE_ACTIONS[action]
	return Vector2i.ZERO


func unlock_input() -> void:
	input_locked = false

	if buffered_wait or buffered_dir != Vector2i.ZERO:
		var dir: Vector2i = buffered_dir
		var wants_wait: bool = buffered_wait
		buffered_dir = Vector2i.ZERO
		buffered_wait = false
		act(dir, wants_wait)
		return

	var held: Vector2i = held_direction()
	if held != Vector2i.ZERO:
		try_move(held)


# --- Actions ---
func act(dir: Vector2i, wants_wait: bool) -> void:
	if wants_wait:
		wait_turn()
	else:
		try_move(dir)


func wait_turn() -> void:
	previous_grid_position = grid_position
	just_entered_plant = false
	Utils.play_animation(animated_sprite, "idle", facing_direction)
	player_moved.emit(grid_position)


func try_move(dir: Vector2i) -> void:
	facing_direction = Utils.dir_to_string(dir, facing_direction)
	var target_cell: Vector2i = grid_position + dir

	if not Utils.is_tile_walkable(target_cell, obstacle_layers):
		Utils.play_animation(animated_sprite, "idle", facing_direction)
		return

	previous_grid_position = grid_position
	just_entered_plant = false
	move_to_cell(target_cell)
	check_hiding_status()
	player_moved.emit(grid_position)


# --- Stealth ---
func check_hiding_status() -> void:
	var in_plant: bool = plants_layer != null and plants_layer.get_cell_source_id(grid_position) != -1
	if in_plant == is_hidden:
		return

	is_hidden = in_plant
	just_entered_plant = in_plant

	var target_alpha: float = hidden_opacity if is_hidden else 1.0
	create_tween().tween_property(self, "modulate:a", target_alpha, opacity_tween_duration)

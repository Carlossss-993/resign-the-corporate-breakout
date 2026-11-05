class_name Player
extends GridActor

signal player_moved(new_grid_pos: Vector2i)
signal cups_changed(amount: int)

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

@export_group("Items & Throw")
@export var max_cups: int = 2
@export var throw_range: int = 5
@export var cup_scene: PackedScene = preload("res://actors/cup.tscn")
@export var error_sound: AudioStream = preload("res://assets/audio/denied.mp3")

@export_group("Visual Highlights")
@export var range_color: Color = Color(0.2, 0.8, 1.0, 0.3)

var current_cups: int = 0:
	set(value):
		current_cups = clampi(value, 0, max_cups)
		cups_changed.emit(current_cups)

var previous_grid_position: Vector2i
var buffered_dir: Vector2i = Vector2i.ZERO
var buffered_wait: bool = false
var input_locked: bool = false
var is_hidden: bool = false
var just_entered_plant: bool = false
var is_aiming: bool = false

@onready var camera: Camera2D = $Camera2D
@onready var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready() -> void:
	super()
	add_to_group("player") 
	add_child(audio_player)
	set_camera_limits()
	check_hiding_status()


func set_camera_limits() -> void:
	if camera == null or obstacle_layers.is_empty():
		return

	var combined_rect: Rect2i = Rect2i()
	var has_rect: bool = false
	var tile_size: Vector2i = Vector2i.ZERO

	for layer in obstacle_layers:
		if layer == null:
			continue
		var rect: Rect2i = layer.get_used_rect()
		if rect.size == Vector2i.ZERO:
			continue
		
		tile_size = layer.tile_set.tile_size
		if not has_rect:
			combined_rect = rect
			has_rect = true
		else:
			combined_rect = combined_rect.merge(rect)

	if not has_rect:
		return

	camera.limit_left = combined_rect.position.x * tile_size.x
	camera.limit_top = combined_rect.position.y * tile_size.y
	camera.limit_right = combined_rect.end.x * tile_size.x
	camera.limit_bottom = combined_rect.end.y * tile_size.y


func clear_input_buffer() -> void:
	buffered_dir = Vector2i.ZERO
	buffered_wait = false


func _unhandled_input(event: InputEvent) -> void:
	var dir: Vector2i = read_direction(event)
	var wants_wait: bool = event.is_action_pressed("wait")

	if input_locked or is_moving:
		if dir != Vector2i.ZERO:
			buffered_dir = dir
			buffered_wait = false
		elif wants_wait:
			buffered_dir = Vector2i.ZERO
			buffered_wait = true
		return

	if event.is_action_pressed("interact"):
		if try_interact_coffee():
			return

	if event.is_action_pressed("throw"):
		if current_cups <= 0:
			play_error_sound()
			return
		is_aiming = true
		queue_redraw()
		return

	elif event.is_action_released("throw") and is_aiming:
		is_aiming = false
		queue_redraw()
		try_throw_cup()
		return

	elif is_aiming and event is InputEventMouseMotion:
		queue_redraw()
		return

	if dir == Vector2i.ZERO and not wants_wait:
		return

	act(dir, wants_wait)


func try_interact_coffee() -> bool:
	var pickups: Array[Node] = get_tree().get_nodes_in_group("coffee_pickups")
	for pickup in pickups:
		if pickup is CoffeePickup:
			var dist: int = Utils.chebyshev_distance(grid_position, pickup.grid_position)
			if dist <= 1:
				return pickup.try_collect(self)
	return false


func _draw() -> void:
	if not is_aiming or current_cups <= 0:
		return

	var base_layer: TileMapLayer = Utils.get_base_layer(obstacle_layers)
	if base_layer == null:
		return

	var tile_size: Vector2 = Vector2(base_layer.tile_set.tile_size)
	var hovered_cell: Vector2i = Utils.world_to_grid(get_global_mouse_position(), obstacle_layers)

	for x in range(-throw_range, throw_range + 1):
		for y in range(-throw_range, throw_range + 1):
			var cell: Vector2i = grid_position + Vector2i(x, y)
			
			if grid_position.distance_to(cell) <= throw_range:
				if Utils.is_tile_walkable(cell, obstacle_layers) and Utils.has_line_of_sight(grid_position, cell, obstacle_layers):
					var center: Vector2 = to_local(Utils.grid_to_world(cell, obstacle_layers))
					var color: Color = range_color
					
					if cell == hovered_cell:
						color.a = 0.65 

					draw_rect(Rect2(center - tile_size / 2.0, tile_size), color)


func try_throw_cup() -> void:
	var target_cell: Vector2i = Utils.world_to_grid(get_global_mouse_position(), obstacle_layers)

	var in_range: bool = grid_position.distance_to(target_cell) <= throw_range
	var is_walkable: bool = Utils.is_tile_walkable(target_cell, obstacle_layers)
	var has_los: bool = Utils.has_line_of_sight(grid_position, target_cell, obstacle_layers)

	if not in_range or not is_walkable or not has_los or target_cell == grid_position:
		play_error_sound()
		return

	execute_throw(target_cell)


func execute_throw(target_cell: Vector2i) -> void:
	current_cups -= 1
	input_locked = true 

	if cup_scene:
		var cup_instance = cup_scene.instantiate()
		get_parent().add_child(cup_instance)
		
		var start_pos: Vector2 = global_position
		var target_pos: Vector2 = Utils.grid_to_world(target_cell, obstacle_layers)
		
		cup_instance.launch(start_pos, target_pos, target_cell, obstacle_layers)
		
		if cup_instance.has_signal("impacted"):
			await cup_instance.impacted

	previous_grid_position = grid_position
	just_entered_plant = false
	
	player_moved.emit(grid_position)


func add_cup() -> void:
	if current_cups < max_cups:
		current_cups += 1
	else:
		play_error_sound()


func play_error_sound() -> void:
	if error_sound:
		audio_player.stream = error_sound
		audio_player.play()


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
		clear_input_buffer()
		act(dir, wants_wait)
		return

	var held: Vector2i = held_direction()
	if held != Vector2i.ZERO:
		try_move(held)


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


func check_hiding_status() -> void:
	var in_plant: bool = plants_layer != null and plants_layer.get_cell_source_id(grid_position) != -1
	if in_plant == is_hidden:
		return

	is_hidden = in_plant
	just_entered_plant = in_plant

	var target_alpha: float = hidden_opacity if is_hidden else 1.0
	create_tween().tween_property(self, "modulate:a", target_alpha, opacity_tween_duration)

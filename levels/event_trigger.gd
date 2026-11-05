class_name EventTrigger
extends Node2D

signal event_finished

@export_group("Trigger Area")
@export var event_id: String = "" 
@export var trigger_cells: Array[Vector2i] = []
@export var one_shot: bool = true
@export var prevent_entry: bool = false

@export_group("Camera & Cinematic")
@export var target_camera_cell: Vector2i = Vector2i(-1, -1)
@export var target_zoom: Vector2 = Vector2(1.4, 1.4)
@export var transition_duration: float = 0.8

@export_group("Dialogue")
@export var dialogue_lines: Array[Dictionary] = []
@export var dialogue_lines_pool: Array = []

var has_triggered: bool = false
var last_random_index: int = -1


func _ready() -> void:
	add_to_group("event_triggers")


func get_effective_event_id() -> String:
	if not event_id.is_empty():
		return event_id
	return "trigger_%s" % str(trigger_cells)


func is_triggered_by(cell: Vector2i) -> bool:
	if not trigger_cells.has(cell):
		return false

	if one_shot:
		if has_triggered:
			return false
		var level = get_tree().current_scene
		if "level_id" in level and GameState.is_event_seen(level.level_id, get_effective_event_id()):
			return false

	return true


func execute_event(player: Player, dialogue_ui: DialogueUI) -> void:
	has_triggered = true
	var level = get_tree().current_scene
	if one_shot and "level_id" in level:
		GameState.mark_event_seen(level.level_id, get_effective_event_id())
	
	if player == null:
		event_finished.emit()
		return

	if player.has_method("clear_input_buffer"):
		player.clear_input_buffer()

	if prevent_entry:
		player.grid_position = player.previous_grid_position
		player.global_position = Utils.grid_to_world(player.previous_grid_position, player.obstacle_layers)

	var camera: Camera2D = player.camera
	var original_zoom: Vector2 = Vector2.ONE
	var obstacle_layers: Array[TileMapLayer] = player.obstacle_layers

	if camera:
		original_zoom = camera.zoom

	if camera and target_camera_cell != Vector2i(-1, -1) and not obstacle_layers.is_empty():
		var target_world_pos: Vector2 = Utils.grid_to_world(target_camera_cell, obstacle_layers)
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(camera, "global_position", target_world_pos, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "zoom", target_zoom, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tween.finished

	var lines_to_show: Array[Dictionary] = dialogue_lines

	if not dialogue_lines_pool.is_empty():
		var idx: int = randi() % dialogue_lines_pool.size()
		if dialogue_lines_pool.size() > 1 and idx == last_random_index:
			idx = (idx + 1) % dialogue_lines_pool.size()
		last_random_index = idx

		var chosen = dialogue_lines_pool[idx]
		if chosen is String:
			lines_to_show = [DialogueLines.player(chosen)]
		elif chosen is Array:
			lines_to_show = chosen

	if dialogue_ui and not lines_to_show.is_empty():
		dialogue_ui.start_dialogue(lines_to_show)
		await dialogue_ui.dialogue_finished

	if camera and target_camera_cell != Vector2i(-1, -1):
		var return_tween: Tween = create_tween().set_parallel(true)
		return_tween.tween_property(camera, "global_position", player.global_position, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return_tween.tween_property(camera, "zoom", original_zoom, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await return_tween.finished
		camera.position = Vector2.ZERO

	event_finished.emit()

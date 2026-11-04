class_name EventTrigger
extends Node2D

signal event_finished

@export_group("Trigger Area")
@export var trigger_cells: Array[Vector2i] = []
@export var one_shot: bool = true

@export_group("Camera & Cinematic")
@export var target_camera_cell: Vector2i = Vector2i(-1, -1)
@export var target_zoom: Vector2 = Vector2(1.4, 1.4)
@export var transition_duration: float = 0.8

@export_group("Dialogue")
@export var dialogue_lines: Array[Dictionary] = []

var has_triggered: bool = false


func _ready() -> void:
	add_to_group("event_triggers")


func is_triggered_by(cell: Vector2i) -> bool:
	if one_shot and has_triggered:
		return false
	return trigger_cells.has(cell)


func execute_event(player: Player, dialogue_ui: DialogueUI) -> void:
	has_triggered = true
	
	if player == null:
		event_finished.emit()
		return

	var camera: Camera2D = player.camera
	var original_zoom: Vector2 = Vector2.ONE
	var obstacle_layers: Array[TileMapLayer] = player.obstacle_layers

	if camera:
		original_zoom = camera.zoom

	# 1. Desplazar la cámara hacia la celda objetivo con zoom
	if camera and target_camera_cell != Vector2i(-1, -1) and not obstacle_layers.is_empty():
		var target_world_pos: Vector2 = Utils.grid_to_world(target_camera_cell, obstacle_layers)
		
		# Desvincular temporalmente la cámara de la posición local del Player
		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(camera, "global_position", target_world_pos, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "zoom", target_zoom, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		await tween.finished

	# 2. Reproducir diálogo si hay líneas configuradas
	if dialogue_ui and not dialogue_lines.is_empty():
		dialogue_ui.start_dialogue(dialogue_lines)
		await dialogue_ui.dialogue_finished

	# 3. Retornar la cámara a la posición del jugador y restaurar el zoom
	if camera:
		var return_tween: Tween = create_tween().set_parallel(true)
		return_tween.tween_property(camera, "global_position", player.global_position, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		return_tween.tween_property(camera, "zoom", original_zoom, transition_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		await return_tween.finished
		
		# Reordenar posición relativa
		camera.position = Vector2.ZERO

	event_finished.emit()

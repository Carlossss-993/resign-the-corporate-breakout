class_name LevelBase
extends Node2D

@export_group("Level Info")
@export var floor_number: int = 1
@export var floor_name: String = "Piso 1"
@export var exit_cells: Array[Vector2i] = []
@export var entry_lines: Array[Dictionary] = []

@export_group("Event Triggers - Stairs Down")
@export var stairs_down_cells: Array[Vector2i] = []
@export var stairs_down_lines: Array[String] = [
	"No necesito bajar más, debo ir hacia arriba.",
	"Abajo no hay nada útil, mi objetivo está en los pisos superiores.",
	"No tiene sentido volver a bajar ahora."
]
@export var stairs_down_one_shot: bool = false

@export_group("Node References")
@export var turn_manager: TurnManager
@export var player: Player
@export var end_screen: EndScreen
@export var hud: HUD
@export var dialogue_ui: DialogueUI

var level_id: String:
	get:
		if scene_file_path.is_empty():
			return "level_%d" % floor_number
		return scene_file_path.get_file().get_basename()


func _ready() -> void:
	setup_level_base()


func setup_level_base() -> void:
	# --- Sincronización del índice de nivel ---
	GameState.sync_level_index(scene_file_path)

	if turn_manager == null and has_node("%TurnManager"):
		turn_manager = %TurnManager
	if player == null and has_node("%Player"):
		player = %Player
	if end_screen == null and has_node("%EndScreen"):
		end_screen = %EndScreen
	if hud == null and has_node("%HUD"):
		hud = %HUD
	if dialogue_ui == null and has_node("%DialogueUI"):
		dialogue_ui = %DialogueUI

	if turn_manager:
		turn_manager.turn_updated.connect(_on_turn_updated)
		turn_manager.level_completed.connect(_on_level_completed)
		turn_manager.player_captured.connect(_on_player_captured)

		if not exit_cells.is_empty():
			turn_manager.exit_cells = exit_cells

	# --- Inicialización del HUD ---
	if hud:
		hud.visible = true
		hud.update_floor_info(floor_number, floor_name)

	if player and hud:
		player.cups_changed.connect(hud.update_cups)
		hud.update_cups(player.current_cups)

	# Evento automático para escaleras hacia abajo
	setup_default_stairs_down()

	# --- Reproducción de líneas de entrada automáticas ---
	call_deferred("play_entry_lines")


func setup_default_stairs_down() -> void:
	if not stairs_down_cells.is_empty():
		create_event(
			stairs_down_cells,
			Vector2i(-1, -1),
			[],
			Vector2(1.4, 1.4),
			stairs_down_one_shot,
			true, # prevent_entry: rebota al jugador sin dejarlo avanzar
			stairs_down_lines
		)


func play_entry_lines() -> void:
	if entry_lines.is_empty() or dialogue_ui == null:
		return

	if player:
		player.set_process_unhandled_input(false)
		if player.has_method("clear_input_buffer"):
			player.clear_input_buffer()

	dialogue_ui.start_dialogue(entry_lines)
	await dialogue_ui.dialogue_finished

	if player:
		player.set_process_unhandled_input(true)


func create_event(
	trigger_cells: Array[Vector2i],
	target_cell: Vector2i,
	lines: Array[Dictionary],
	zoom: Vector2 = Vector2(2, 2),
	one_shot: bool = true,
	prevent_entry: bool = false,
	lines_pool: Array = []
) -> EventTrigger:
	if trigger_cells.is_empty():
		return null

	var trigger: EventTrigger = EventTrigger.new()
	trigger.trigger_cells = trigger_cells
	trigger.target_camera_cell = target_cell
	trigger.dialogue_lines = lines
	trigger.dialogue_lines_pool = lines_pool
	trigger.one_shot = one_shot
	trigger.prevent_entry = prevent_entry
	trigger.target_zoom = zoom
	trigger.transition_duration = 0.8
	add_child(trigger)
	return trigger


func _on_turn_updated(turns: int) -> void:
	if hud:
		hud.update_turns(turns)


func _on_level_completed(turns_taken: int) -> void:
	if player:
		player.set_process_unhandled_input(false)

	var is_new_record: bool = GameState.save_level_record(level_id, turns_taken)
	var best_record: int = GameState.get_best_record(level_id)

	if end_screen:
		end_screen.show_victory(turns_taken, best_record, is_new_record)


func _on_player_captured() -> void:
	if player:
		player.set_process_unhandled_input(false)

	if end_screen:
		end_screen.show_defeat()

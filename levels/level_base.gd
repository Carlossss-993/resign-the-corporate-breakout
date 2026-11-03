class_name LevelBase
extends Node2D

@export_group("Level Info")
@export var floor_number: int = 1
@export var floor_name: String = "Piso 1"
@export var exit_cell: Vector2i = Vector2i(-1, -1)
@export var entry_lines: Array[Dictionary] = []

@export_group("Node References")
@export var turn_manager: TurnManager
@export var player: Player
@export var end_screen: EndScreen
@export var hud: HUD

var level_id: String:
	get:
		if scene_file_path.is_empty():
			return "level_%d" % floor_number
		return scene_file_path.get_file().get_basename()


func _ready() -> void:
	setup_level_base()


func setup_level_base() -> void:
	if turn_manager == null and has_node("%TurnManager"):
		turn_manager = %TurnManager
	if player == null and has_node("%Player"):
		player = %Player
	if end_screen == null and has_node("%EndScreen"):
		end_screen = %EndScreen
	if hud == null and has_node("%HUD"):
		hud = %HUD

	if turn_manager:
		turn_manager.turn_updated.connect(_on_turn_updated)
		turn_manager.level_completed.connect(_on_level_completed)
		turn_manager.player_captured.connect(_on_player_captured)

		if exit_cell != Vector2i(-1, -1):
			turn_manager.exit_cell = exit_cell


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

extends Node2D

const LEVEL_ID: String = "level_1"
const BOSS_SPEED: float = 240.0
const BOSS_SPAWN_CELL: Vector2i = Vector2i(5, 14)
const BOSS_PORTRAIT: Texture2D = preload("res://assets/portraits/Boss_Portrait.png")
const PLAYER_PORTRAIT: Texture2D = preload("res://assets/portraits/Player_Portrait.png")

const PATH_TO_PLAYER: Array[Vector2i] = [
	Vector2i(5, 15), Vector2i(9, 15), Vector2i(9, 11),
	Vector2i(6, 11), Vector2i(6, 7), Vector2i(8, 7),
]
const PATH_TO_ELEVATOR: Array[Vector2i] = [
	Vector2i(6, 7), Vector2i(6, 11), Vector2i(9, 11),
	Vector2i(9, 15), Vector2i(5, 15), Vector2i(5, 14),
]

@export var skip_intro_debug: bool = false

var boss_intro: Array[Dictionary] = [
	{
		"name": "Jefe",
		"text": "¡Vaya, vaya! Veo que sigues aquí. Excelente compromiso con la empresa.",
		"side": "right",
		"portrait_right": BOSS_PORTRAIT,
	},
	{
		"name": "Jefe",
		"text": "Necesito que te quedes toda la noche revisando los servidores. ¡Hay que sudar la camiseta!",
		"side": "right",
		"portrait_right": BOSS_PORTRAIT,
	},
]

var player_intro: Array[Dictionary] = [
	{
		"name": "Jugador",
		"text": "A la mierda, me voy a casa. ¡No pienso quedarme toda la noche!",
		"side": "left",
		"portrait_left": PLAYER_PORTRAIT,
	},
	{
		"name": "Jugador",
		"text": "¡Y que se joda el jefe!",
		"side": "left",
		"portrait_left": PLAYER_PORTRAIT,
	},
]

@onready var player: Player = %Player
@onready var camera: Camera2D = player.camera
@onready var boss: Node2D = %Boss
@onready var boss_sprite: AnimatedSprite2D = boss.get_node("AnimatedSprite2D")
@onready var elevator_sprite: AnimatedSprite2D = %Elevator
@onready var elevator_audio: AudioStreamPlayer2D = %ElevatorAudio
@onready var dialogue_ui: DialogueUI = %DialogueUI
@onready var base_layer: TileMapLayer = %BaseLayer
@onready var turn_manager: TurnManager = %TurnManager
@onready var end_screen: EndScreen = %EndScreen
@onready var hud: HUD = %HUD

func _ready() -> void:
	boss.visible = false
	elevator_sprite.play("closed")

	if turn_manager:
		turn_manager.turn_updated.connect(_on_turn_updated)
		turn_manager.level_completed.connect(_on_level_completed)
		turn_manager.player_captured.connect(_on_player_captured)

	if hud:
		hud.visible = true

	if GameState.intro_seen or skip_intro_debug:
		return

	player.set_process_unhandled_input(false)
	get_tree().create_timer(0.5).timeout.connect(run_intro_cutscene)


func _on_turn_updated(turns: int) -> void:
	if hud:
		hud.update_turns(turns)


func _on_level_completed(turns_taken: int) -> void:
	player.set_process_unhandled_input(false)
	var is_new_record: bool = GameState.save_level_record(LEVEL_ID, turns_taken)
	var best_record: int = GameState.get_best_record(LEVEL_ID)
	end_screen.show_victory(turns_taken, best_record, is_new_record)
	if hud:
		hud.visible = false


func _on_player_captured() -> void:
	player.set_process_unhandled_input(false)
	end_screen.show_defeat()
	if hud:
		hud.visible = false


func run_intro_cutscene() -> void:
	var spawn_pos: Vector2 = cell_to_world(BOSS_SPAWN_CELL)

	move_camera_to(spawn_pos, 1.0)
	await open_elevator()
	boss.global_position = spawn_pos
	boss_sprite.play("idle_down")
	boss.visible = true
	await close_elevator()

	await walk_boss(PATH_TO_PLAYER)
	boss_sprite.play("idle_right")
	dialogue_ui.start_dialogue(boss_intro)
	await dialogue_ui.dialogue_finished

	await walk_boss(PATH_TO_ELEVATOR)
	boss_sprite.play("idle_up")
	await open_elevator()
	boss.visible = false
	await close_elevator()

	await move_camera_to(player.global_position, 1.0).finished
	dialogue_ui.start_dialogue(player_intro)
	await dialogue_ui.dialogue_finished

	GameState.intro_seen = true
	player.set_process_unhandled_input(true)


func cell_to_world(cell: Vector2i) -> Vector2:
	return base_layer.to_global(base_layer.map_to_local(cell))


func open_elevator() -> void:
	elevator_audio.play()
	elevator_sprite.play("opening")
	await elevator_sprite.animation_finished


func close_elevator() -> void:
	elevator_sprite.play("closing")
	await elevator_sprite.animation_finished
	elevator_sprite.play("closed")


func move_camera_to(target: Vector2, duration: float) -> Tween:
	var tween: Tween = create_tween()
	tween.tween_property(camera, "global_position", target, duration)
	return tween


func walk_boss(path: Array[Vector2i]) -> void:
	for cell in path:
		var target: Vector2 = cell_to_world(cell)
		var direction: Vector2 = target - boss.global_position
		var duration: float = direction.length() / BOSS_SPEED

		boss_sprite.play("walk_" + Utils.vector_to_cardinal(Vector2i(direction), "down"))

		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(boss, "global_position", target, duration)
		tween.tween_property(camera, "global_position", target, duration)
		await tween.finished

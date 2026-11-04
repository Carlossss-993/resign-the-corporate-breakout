extends LevelBase

const BOSS_SPEED: float = 240.0
const BOSS_SPAWN_CELL: Vector2i = Vector2i(5, 14)

const PATH_TO_PLAYER: Array[Vector2i] = [
	Vector2i(5, 15), Vector2i(9, 15), Vector2i(9, 11),
	Vector2i(6, 11), Vector2i(6, 7), Vector2i(8, 7),
]
const PATH_TO_ELEVATOR: Array[Vector2i] = [
	Vector2i(6, 7), Vector2i(6, 11), Vector2i(9, 11),
	Vector2i(9, 15), Vector2i(5, 15), Vector2i(5, 14),
]

@export_group("Debug Flags")
@export var skip_intro_debug: bool = true
@export var skip_events_debug: bool = false

@export_group("Event Triggers - Stairs Down")
@export var stairs_down_trigger_cells: Array[Vector2i] = []
@export var stairs_down_target_cell: Vector2i = Vector2i.ZERO

@export_group("Event Triggers - Elevator")
@export var elevator_trigger_cells: Array[Vector2i] = []
@export var elevator_target_cell: Vector2i = Vector2i.ZERO

@export_group("Event Triggers - Stairs Up")
@export var stairs_up_trigger_cells: Array[Vector2i] = []
@export var stairs_up_target_cell: Vector2i = Vector2i.ZERO

@export_group("Event Triggers - Guard")
@export var guard_trigger_cells: Array[Vector2i] = []
@export var guard_target_cell: Vector2i = Vector2i.ZERO

@export_group("Event Triggers - Plant")
@export var plant_trigger_cells: Array[Vector2i] = []
@export var plant_target_cell: Vector2i = Vector2i.ZERO

var boss_intro: Array[Dictionary] = [
	DialogueLines.boss("¡Vaya, vaya! Veo que sigues aquí. Excelente compromiso con la empresa."),
	DialogueLines.boss("Necesito que te quedes toda la noche revisando los servidores. ¡Hay que sudar la camiseta!")
]

var player_intro: Array[Dictionary] = [
	DialogueLines.player("A la mierda, me voy a casa. ¡No pienso quedarme toda la noche!"),
	DialogueLines.player("¡Y que se joda el jefe!")
]

@onready var boss: Node2D = %Boss
@onready var boss_sprite: AnimatedSprite2D = boss.get_node("AnimatedSprite2D")
@onready var elevator_sprite: AnimatedSprite2D = %Elevator
@onready var elevator_audio: AudioStreamPlayer2D = %ElevatorAudio
@onready var base_layer: TileMapLayer = %BaseLayer


func _ready() -> void:
	super()
	boss.visible = false
	elevator_sprite.play("closed")

	if not skip_events_debug:
		setup_narrative_events()

	if GameState.intro_seen or skip_intro_debug:
		hud.visible = true
		return

	if hud:
		hud.visible = false

	if player:
		player.set_process_unhandled_input(false)
	get_tree().create_timer(0.5).timeout.connect(run_intro_cutscene)


func setup_narrative_events() -> void:
	create_event(
		stairs_down_trigger_cells,
		stairs_down_target_cell,
		[DialogueLines.player("Las escaleras hacia abajo están fuera de servicio por mantenimiento desde hace 7 meses...")]
	)

	create_event(
		elevator_trigger_cells,
		elevator_target_cell,
		[DialogueLines.player("El ascensor no se moverá a menos que tenga la tarjeta de acceso de alta seguridad.")]
	)

	create_event(
		stairs_up_trigger_cells,
		stairs_up_target_cell,
		[DialogueLines.player("Tendré que subir hasta el piso 10 para robarle la tarjeta de acceso al jefe si quiero escapar.")]
	)

	create_event(
		guard_trigger_cells,
		guard_target_cell,
		[DialogueLines.player("Hay un guardia patrullando este sector... Tendré que vigilar el alcance de su linterna para esquivarlo.")]
	)

	create_event(
		plant_trigger_cells,
		plant_target_cell,
		[DialogueLines.player("Si se acerca demasiado o viene en mi dirección, puedo meterme en las plantas para no ser visto.")]
	)


func run_intro_cutscene() -> void:
	var spawn_pos: Vector2 = cell_to_world(BOSS_SPAWN_CELL)
	var camera: Camera2D = player.camera if player else null

	if camera:
		move_camera_to(camera, spawn_pos, 1.0)

	await open_elevator()
	boss.global_position = spawn_pos
	boss_sprite.play("idle_down")
	boss.visible = true
	await close_elevator()

	await walk_boss(camera, PATH_TO_PLAYER)
	boss_sprite.play("idle_right")
	dialogue_ui.start_dialogue(boss_intro)
	await dialogue_ui.dialogue_finished

	await walk_boss(camera, PATH_TO_ELEVATOR)
	boss_sprite.play("idle_up")
	await open_elevator()
	boss.visible = false
	await close_elevator()

	if camera and player:
		await move_camera_to(camera, player.global_position, 1.0).finished

	dialogue_ui.start_dialogue(player_intro)
	await dialogue_ui.dialogue_finished

	GameState.intro_seen = true
	if player:
		player.set_process_unhandled_input(true)
		hud.visible = true


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


func move_camera_to(camera: Camera2D, target: Vector2, duration: float) -> Tween:
	var tween: Tween = create_tween()
	tween.tween_property(camera, "global_position", target, duration)
	return tween


func walk_boss(camera: Camera2D, path: Array[Vector2i]) -> void:
	for cell in path:
		var target: Vector2 = cell_to_world(cell)
		var direction: Vector2 = target - boss.global_position
		var duration: float = direction.length() / BOSS_SPEED

		boss_sprite.play("walk_" + Utils.vector_to_cardinal(Vector2i(direction), "down"))

		var tween: Tween = create_tween().set_parallel(true)
		tween.tween_property(boss, "global_position", target, duration)
		if camera:
			tween.tween_property(camera, "global_position", target, duration)
		await tween.finished

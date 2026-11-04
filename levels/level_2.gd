extends LevelBase

const PLAYER_PORTRAIT: Texture2D = preload("res://assets/portraits/Player_Portrait.png")

@export_group("Debug Flags")
@export var skip_events_debug: bool = false

@export_group("Event Triggers - Coffee Spot")
@export var coffee_trigger_cells: Array[Vector2i] = []
@export var coffee_target_cell: Vector2i = Vector2i.ZERO


func _ready() -> void:
	super()

	if not skip_events_debug:
		setup_narrative_events()


func setup_narrative_events() -> void:
	# Evento de enfoque hacia la cafetera/taza al entrar a la zona
	create_event(
		coffee_trigger_cells,
		coffee_target_cell,
		[
			{
				"name": "Jugador",
				"text": "Una taza de café caliente... Podría lanzarla cerca de un guardia para distraerlo con el ruido.",
				"side": "left",
				"portrait_left": PLAYER_PORTRAIT,
			}
		]
	)


func create_event(trigger_cells: Array[Vector2i], target_cell: Vector2i, lines: Array[Dictionary]) -> void:
	if trigger_cells.is_empty():
		return

	var trigger: EventTrigger = EventTrigger.new()
	trigger.trigger_cells = trigger_cells
	trigger.target_camera_cell = target_cell
	trigger.dialogue_lines = lines
	trigger.one_shot = true
	trigger.target_zoom = Vector2(1.4, 1.4)
	trigger.transition_duration = 0.8
	add_child(trigger)

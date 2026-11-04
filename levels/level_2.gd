extends LevelBase

@export_group("Debug Flags")
@export var skip_events_debug: bool = false

@export_group("Event Triggers - Coffee Spot")
@export var coffee_trigger_cells: Array[Vector2i] = []
@export var coffee_target_cell: Vector2i = Vector2i.ZERO


func _ready() -> void:
	entry_lines = [
		DialogueLines.player("Piso 2... Las cosas empiezan a ponerse complicadas.")
	]
	super()

	if not skip_events_debug:
		setup_narrative_events()


func setup_narrative_events() -> void:
	create_event(
		coffee_trigger_cells,
		coffee_target_cell,
		[DialogueLines.player("Una taza de café caliente... Podría lanzarla cerca de un guardia para distraerlo con el ruido.")]
	)

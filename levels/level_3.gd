extends LevelBase

@export_group("Debug Flags")
@export var skip_events_debug: bool = false

@export_group("Event Triggers - Guard Spot")
@export var guard_trigger_cells: Array[Vector2i] = []
@export var guard_target_cell: Vector2i = Vector2i.ZERO


func _ready() -> void:
	entry_lines = [
		DialogueLines.player("Ugh... ¿por qué la enfermería huele literalmente a cadáveres?"),
		DialogueLines.player("Definitivamente las negligencias de esta empresa sobrepasaron todos los límites.")
	]
	super()

	if not skip_events_debug:
		setup_narrative_events()


func setup_narrative_events() -> void:
	create_event(
		guard_trigger_cells,
		guard_target_cell,
		[
			DialogueLines.player("Ese guardia no piensa moverse y está tapando el acceso a las escaleras..."),
			DialogueLines.player("Tendré que hacer algo para obligarlo a alejarse de su posición.")
		]
	)

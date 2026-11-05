extends LevelBase

@export_group("Debug Flags")
@export var skip_events_debug: bool = false


func _ready() -> void:
	entry_lines = [
		DialogueLines.player("Uff... Aquí se tomaron demasiado en serio la fiesta de Halloween."),
		DialogueLines.player("¿Eso es sangre real y un pentagrama en el piso...? Qué carajos pasó en esta oficina.")
	]
	super()

	if not skip_events_debug:
		setup_narrative_events()


func setup_narrative_events() -> void:
	# Aquí puedes agregar los triggers o eventos específicos del Piso 4 más adelante
	pass

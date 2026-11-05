extends Control

@onready var start_button: Button = %StartButton


func _ready() -> void:
	# Asegura que el juego no empiece pausado
	get_tree().paused = false
	
	if start_button:
		start_button.grab_focus() # Para que se pueda navegar con teclado/mando
		start_button.pressed.connect(_on_start_button_pressed)


func _on_start_button_pressed() -> void:
	# Reinicia el estado global (tazas desbloqueadas, etc.)
	GameState.intro_seen = false
	GameState.cups_unlocked = false
	GameState.current_level_index = 0
	
	# Carga el Nivel 1 (primer elemento de GameState.levels)
	get_tree().change_scene_to_file(GameState.levels[0])

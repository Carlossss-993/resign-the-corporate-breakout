extends Control

@onready var start_button: Button = %StartButton
@onready var credits_button: Button = get_node_or_null("%CreditsButton")


func _ready() -> void:
	get_tree().paused = false
	
	MusicPlayer.play_track("menu")

	if credits_button:
		credits_button.visible = GameState.game_completed
		credits_button.pressed.connect(_on_credits_button_pressed)

	if start_button:
		start_button.grab_focus()
		start_button.pressed.connect(_on_start_button_pressed)


func _on_start_button_pressed() -> void:
	GameState.intro_seen = false
	GameState.current_level_index = 0
	get_tree().change_scene_to_file(GameState.levels[0])


func _on_credits_button_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/credits.tscn")

extends Control

@export var display_duration: float = 5.0
@export var credits_scene_path: String = "res://ui/credits.tscn"


func _ready() -> void:
	MusicPlayer.play_track("chase")

	get_tree().create_timer(display_duration).timeout.connect(_on_timeout)


func _on_timeout() -> void:
	GameState.mark_game_completed()
	get_tree().change_scene_to_file(credits_scene_path)

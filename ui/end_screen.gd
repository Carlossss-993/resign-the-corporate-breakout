class_name EndScreen
extends CanvasLayer

@export var defeat_sound: AudioStream
@export var victory_sound: AudioStream

@onready var overlay: ColorRect = $Overlay
@onready var banner: Panel = $Banner
@onready var title_label: Label = $Banner/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $Banner/VBoxContainer/SubtitleLabel
@onready var action_button: Button = $Banner/VBoxContainer/ActionButton

var audio_player: AudioStreamPlayer
var is_victory: bool = false


func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

	action_button.pressed.connect(_on_action_button_pressed)

	overlay.modulate.a = 0.0
	banner.modulate.a = 0.0
	visible = false


func show_defeat() -> void:
	is_victory = false
	title_label.text = "TE HAN ATRAPADO"
	title_label.add_theme_color_override("font_color", Color(0.85, 0.15, 0.15, 1.0))
	subtitle_label.text = "El guardia te descubrió antes de alcanzar la salida."
	action_button.text = "Reintentar"

	if defeat_sound:
		audio_player.stream = defeat_sound
		audio_player.play()

	animate_appearance()


func show_victory(turns_taken: int, best_record: int, is_new_record: bool) -> void:
	is_victory = true
	title_label.text = "PISO COMPLETADO"
	title_label.add_theme_color_override("font_color", Color(0.2, 0.85, 0.35, 1.0))

	var record_text: String = ""
	if is_new_record:
		record_text = "\n¡NUEVO RÉCORD!"
	else:
		record_text = "\nMejor récord: %d turnos" % best_record

	subtitle_label.text = "Resumen: Lograste escapar en %d turnos.%s" % [turns_taken, record_text]
	action_button.text = "Siguiente"

	if victory_sound:
		audio_player.stream = victory_sound
		audio_player.play()

	animate_appearance()


func animate_appearance() -> void:
	visible = true
	overlay.modulate.a = 0.0
	banner.modulate.a = 0.0

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.75, 0.4)
	tween.tween_property(banner, "modulate:a", 1.0, 0.4)


func _on_action_button_pressed() -> void:
	if is_victory:
		GameState.go_to_next_level()
	else:
		GameState.restart_level()
extends Control

@export var scroll_duration: float = 40.0
@export var extra_padding: float = 100.0

@onready var credits_container: Control = $MarginContainer/CreditsContainer
@onready var vbox: VBoxContainer = $MarginContainer/CreditsContainer/VBoxContainer
@onready var return_prompt_label: Label = get_node_or_null("%ReturnPrompt") 

var scroll_tween: Tween
var is_finished: bool = false


func _ready() -> void:
	MusicPlayer.play_track("credits")

	if return_prompt_label:
		return_prompt_label.visible = false

	start_credits_scroll()


func start_credits_scroll() -> void:
	await get_tree().process_frame

	var viewport_height: float = get_viewport_rect().size.y
	var total_height: float = vbox.size.y

	credits_container.position.y = viewport_height
	var target_y: float = -(total_height + extra_padding)

	scroll_tween = create_tween()
	scroll_tween.tween_property(credits_container, "position:y", target_y, scroll_duration)\
		.set_trans(Tween.TRANS_LINEAR)

	scroll_tween.finished.connect(_on_scroll_completed)


func _unhandled_input(event: InputEvent) -> void:
	if is_finished:
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
			GameState.go_to_menu()
		return

	if event.is_action("ui_accept") or event.is_action("interact"):
		if scroll_tween and scroll_tween.is_running():
			if event.is_pressed():
				scroll_tween.set_speed_scale(2.5) 
			elif event.is_released():
				scroll_tween.set_speed_scale(1.0)


func _on_scroll_completed() -> void:
	is_finished = true
	if return_prompt_label:
		return_prompt_label.visible = true
	else:
		var prompt: Label = Label.new()
		prompt.text = "Presiona Enter o Espacio para volver al menú principal"
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.anchors_preset = Control.PRESET_BOTTOM_WIDE
		prompt.position.y -= 50.0
		add_child(prompt)

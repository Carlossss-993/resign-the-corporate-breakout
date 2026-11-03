class_name DialogueUI
extends CanvasLayer

signal dialogue_finished

const ACTIVE_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const DIMMED_COLOR: Color = Color(0.4, 0.4, 0.4, 0.7)
const SPEAKER_MARGIN: float = 40.0
const FADE_TIME: float = 0.3

@export var text_speed: float = 0.03

var dialogue_queue: Array[Dictionary] = []
var current_line_index: int = 0
var is_active: bool = false
var is_typing: bool = false
var text_tween: Tween
var prompt_tween: Tween

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var portrait_left: TextureRect = $PortraitLeft
@onready var portrait_right: TextureRect = $PortraitRight
@onready var text_box: Control = $TextBox
@onready var speaker_box: Control = $SpeakerBox
@onready var speaker_name_label: Label = $SpeakerBox/SpeakerName
@onready var dialogue_text: RichTextLabel = $TextBox/MarginContainer/VBoxContainer/DialogueText
@onready var next_prompt: Control = $TextBox/MarginContainer/VBoxContainer/NextPrompt


func _ready() -> void:
	reset_ui()
	visible = false


func reset_ui() -> void:
	stop_prompt_animation()
	dim_overlay.color.a = 0.0
	for node: CanvasItem in [text_box, speaker_box, portrait_left, portrait_right]:
		node.modulate = Color(1.0, 1.0, 1.0, 0.0)
	portrait_left.texture = null
	portrait_right.texture = null
	dialogue_text.text = ""
	dialogue_text.visible_ratio = 0.0


func start_dialogue(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		return

	dialogue_queue = lines
	current_line_index = 0
	reset_ui()
	speaker_name_label.text = lines[0].get("name", "")
	visible = true

	await get_tree().process_frame
	speaker_box.global_position = get_speaker_box_target(lines[0].get("side", "left"))

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "color:a", 0.65, FADE_TIME)
	tween.tween_property(text_box, "modulate:a", 1.0, FADE_TIME)
	tween.tween_property(speaker_box, "modulate:a", 1.0, FADE_TIME)
	await tween.finished

	is_active = true
	show_current_line()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not event.is_action_pressed("interact"):
		return

	get_viewport().set_input_as_handled()
	if is_typing:
		skip_typing()
	else:
		advance_dialogue()


func show_current_line() -> void:
	stop_prompt_animation()

	var line: Dictionary = dialogue_queue[current_line_index]
	var side: String = line.get("side", "left")

	speaker_name_label.text = line.get("name", "")
	dialogue_text.text = line.get("text", "")
	dialogue_text.visible_ratio = 0.0

	update_portraits(line, side)
	move_speaker_box(side)

	var total_chars: int = dialogue_text.get_total_character_count()
	if total_chars == 0:
		total_chars = dialogue_text.text.length()

	is_typing = true
	text_tween = create_tween()
	text_tween.tween_property(dialogue_text, "visible_ratio", 1.0, total_chars * text_speed)
	text_tween.tween_callback(on_typing_finished)


func update_portraits(line: Dictionary, side: String) -> void:
	var tween: Tween = create_tween().set_parallel(true)
	portrait_right.flip_h = line.get("flip_right", true)
	fade_portrait(portrait_left, line.get("portrait_left"), side == "left", tween)
	fade_portrait(portrait_right, line.get("portrait_right"), side == "right", tween)


func fade_portrait(portrait: TextureRect, texture: Texture2D, is_speaking: bool, tween: Tween) -> void:
	if texture == null:
		tween.tween_property(portrait, "modulate:a", 0.0, 0.2)
		return

	portrait.texture = texture
	var target_color: Color = ACTIVE_COLOR if is_speaking else DIMMED_COLOR
	tween.tween_property(portrait, "modulate", target_color, 0.2)


func get_speaker_box_target(side: String) -> Vector2:
	var x: float = text_box.global_position.x + SPEAKER_MARGIN
	if side != "left":
		x = text_box.global_position.x + text_box.size.x - speaker_box.size.x - SPEAKER_MARGIN
	var y: float = text_box.global_position.y - (speaker_box.size.y * 0.6)
	return Vector2(x, y)


func move_speaker_box(side: String) -> void:
	if current_line_index == 0:
		return
	await get_tree().process_frame
	create_tween().tween_property(speaker_box, "global_position", get_speaker_box_target(side), 0.15)


func on_typing_finished() -> void:
	is_typing = false
	start_prompt_animation()


func start_prompt_animation() -> void:
	stop_prompt_animation()
	next_prompt.visible = true
	next_prompt.modulate.a = 1.0
	prompt_tween = create_tween().set_loops()
	prompt_tween.tween_property(next_prompt, "modulate:a", 0.2, 0.5).set_trans(Tween.TRANS_SINE)
	prompt_tween.tween_property(next_prompt, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE)


func stop_prompt_animation() -> void:
	if prompt_tween and prompt_tween.is_running():
		prompt_tween.kill()
	next_prompt.visible = false
	next_prompt.modulate.a = 1.0


func skip_typing() -> void:
	if text_tween and text_tween.is_running():
		text_tween.kill()
	dialogue_text.visible_ratio = 1.0
	on_typing_finished()


func advance_dialogue() -> void:
	current_line_index += 1
	if current_line_index < dialogue_queue.size():
		show_current_line()
	else:
		close_dialogue()


func close_dialogue() -> void:
	is_active = false
	stop_prompt_animation()

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(dim_overlay, "color:a", 0.0, FADE_TIME)
	tween.tween_property(text_box, "modulate:a", 0.0, FADE_TIME)
	tween.tween_property(speaker_box, "modulate:a", 0.0, FADE_TIME)
	tween.tween_property(portrait_left, "modulate:a", 0.0, 0.2)
	tween.tween_property(portrait_right, "modulate:a", 0.0, 0.2)
	await tween.finished

	visible = false
	dialogue_finished.emit()

class_name StatusIcon
extends Sprite2D

@export var bob_height: float = 6.0
@export var bob_time: float = 0.35
@export var sound: AudioStream

var base_scale: Vector2
var base_offset_y: float
var tween: Tween
var audio: AudioStreamPlayer
var request_id: int = 0


func _ready() -> void:
	base_scale = scale
	base_offset_y = offset.y
	z_index = 10
	visible = false

	if sound:
		audio = AudioStreamPlayer.new()
		audio.stream = sound
		add_child(audio)


func show_icon() -> void:
	request_id += 1
	appear()


func flash(duration: float = 1.0) -> void:
	request_id += 1
	var my_id: int = request_id
	appear()
	await get_tree().create_timer(duration).timeout
	if my_id == request_id:
		disappear()


func hide_icon() -> void:
	request_id += 1
	disappear()


func appear() -> void:
	if tween:
		tween.kill()

	visible = true
	modulate.a = 1.0
	offset.y = base_offset_y
	scale = Vector2.ZERO

	tween = create_tween()
	tween.tween_property(self, "scale", base_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(start_bobbing)

	if audio:
		audio.play()


func start_bobbing() -> void:
	tween = create_tween().set_loops()
	tween.tween_property(self, "offset:y", base_offset_y - bob_height, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "offset:y", base_offset_y, bob_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func disappear() -> void:
	if not visible:
		return
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func(): visible = false)

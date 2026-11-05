extends Node2D

signal impacted

@export var fly_duration: float = 0.55
@export var arc_height: float = -70.0
@export var noise_radius: int = 8

var target_cell: Vector2i
var obstacle_layers: Array[TileMapLayer] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $BreakParticles
@onready var audio: AudioStreamPlayer2D = $BreakAudio


func launch(start_pos: Vector2, target_pos: Vector2, p_target_cell: Vector2i, p_layers: Array[TileMapLayer]) -> void:
	global_position = start_pos
	target_cell = p_target_cell
	obstacle_layers = p_layers
	
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, fly_duration).set_trans(Tween.TRANS_LINEAR)
	
	var sprite_tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sprite_tween.tween_property(sprite, "position:y", arc_height, fly_duration * 0.5)
	sprite_tween.tween_property(sprite, "position:y", 0.0, fly_duration * 0.5).set_ease(Tween.EASE_IN)
	
	tween.tween_property(sprite, "rotation_degrees", 360.0, fly_duration)
	tween.chain().tween_callback(impact)


func impact() -> void:
	sprite.visible = false
	
	if particles:
		particles.restart()
		particles.emitting = true
		
	if audio:
		audio.play()
		
	spawn_coffee_puddle()
	alert_guards_nearby()

	impacted.emit()

	var clean_tween: Tween = create_tween()
	clean_tween.tween_interval(max(particles.lifetime if particles else 0.5, audio.stream.get_length() if audio and audio.stream else 0.8))
	clean_tween.tween_callback(queue_free)


func spawn_coffee_puddle() -> void:
	var puddle: Sprite2D = Sprite2D.new()
	puddle.texture = load("res://assets/items/puddle.png")
	puddle.centered = true
	puddle.y_sort_enabled = true
	get_parent().add_child(puddle)
	puddle.global_position = Utils.grid_to_world(target_cell, obstacle_layers)
	
	puddle.modulate.a = 0.0
	var fade: Tween = create_tween()
	fade.tween_property(puddle, "modulate:a", 1.0, 0.25)


func alert_guards_nearby() -> void:
	var turn_manager = get_tree().get_first_node_in_group("turn_manager")
	if turn_manager and turn_manager.has_method("make_noise"):
		turn_manager.make_noise(target_cell, noise_radius)

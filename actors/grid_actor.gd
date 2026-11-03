class_name GridActor
extends Node2D

signal move_finished

@export_group("Grid & Movement")
@export var obstacle_layers: Array[TileMapLayer] = []
@export var move_duration: float = 0.25
@export var start_cell: Vector2i = Vector2i.ZERO

var grid_position: Vector2i
var facing_direction: String = "down"
var is_moving: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	grid_position = start_cell
	Utils.align_to_grid(self, grid_position, obstacle_layers)
	Utils.play_animation(animated_sprite, "idle", facing_direction)


func move_to_cell(cell: Vector2i, face_dir: String = "") -> void:
	if face_dir == "":
		face_dir = Utils.vector_to_cardinal(cell - grid_position, facing_direction)
	facing_direction = face_dir
	grid_position = cell
	is_moving = true
	play_walk_animation()

	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", Utils.grid_to_world(cell, obstacle_layers), move_duration)
	tween.tween_callback(finish_move)


func play_walk_animation() -> void:
	var anim_name: String = "walk_" + facing_direction
	var frames: SpriteFrames = animated_sprite.sprite_frames

	if frames != null and frames.has_animation(anim_name):
		var fps: float = frames.get_animation_speed(anim_name)
		var frame_count: int = frames.get_frame_count(anim_name)
		if fps > 0 and frame_count > 0:
			animated_sprite.speed_scale = (float(frame_count) / fps) / move_duration

	Utils.play_animation(animated_sprite, "walk", facing_direction)


func finish_move() -> void:
	is_moving = false
	animated_sprite.speed_scale = 1.0
	Utils.play_animation(animated_sprite, "idle", facing_direction)
	move_finished.emit()

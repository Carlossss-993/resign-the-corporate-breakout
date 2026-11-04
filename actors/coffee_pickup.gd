class_name CoffeePickup
extends Node2D

@export var grid_position: Vector2i
@export var float_distance: float = 2.5
@export var float_duration: float = 0.8

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group("coffee_pickups")
	call_deferred("align_to_grid_cell")
	setup_visual_highlight()


func setup_visual_highlight() -> void:
	if sprite == null:
		return

	# 1. Hacer que ignire la oscuridad del mapa (NightEffect / CanvasModulate)
	var canvas_material: CanvasItemMaterial = CanvasItemMaterial.new()
	canvas_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sprite.material = canvas_material

	# 2. Animación combinada: Flotado Y + Pulso de resplandor brillante
	var start_y: float = sprite.position.y
	var tween: Tween = create_tween().set_loops().set_parallel(true).set_trans(Tween.TRANS_SINE)
	
	# Flotado continuo
	tween.tween_property(sprite, "position:y", start_y - float_distance, float_duration)
	tween.tween_property(sprite, "position:y", start_y + float_distance, float_duration).set_delay(float_duration)

	# Pulso de brillo (resalta contra el fondo oscuro)
	tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.3, 1.0), float_duration)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), float_duration).set_delay(float_duration)


func align_to_grid_cell() -> void:
	var layers: Array[TileMapLayer] = []
	var player: Player = get_tree().get_first_node_in_group("player") as Player

	if player and not player.obstacle_layers.is_empty():
		layers = player.obstacle_layers
	else:
		var base_layer = get_tree().current_scene.find_child("*Layer*", true, false)
		if base_layer is TileMapLayer:
			layers.append(base_layer)

	if not layers.is_empty():
		Utils.align_to_grid(self, grid_position, layers)


func try_collect(player: Player) -> bool:
	if player.current_cups >= player.max_cups:
		player.play_error_sound()
		return false

	player.add_cup()

	var fade_tween: Tween = create_tween().set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	fade_tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.2)
	fade_tween.chain().tween_callback(queue_free)

	return true

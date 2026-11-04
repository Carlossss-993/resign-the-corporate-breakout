class_name Hint
extends CanvasLayer

enum HintType { ACTION_ONESHOT, PLAYER_STATE, NEARBY_GROUP }

@export_group("Content")
@export var text: String = "Presiona WASD para moverte":
	set(val):
		text = val
		if label:
			label.text = text

@export_group("Behavior")
@export var hint_type: HintType = HintType.ACTION_ONESHOT
@export_enum("any_move", "wait", "interact", "throw") var required_action: String = "any_move"

@export_group("Contextual Trigger Settings")
@export var state_property: String = "is_hidden" # Propiedad del Player a evaluar (ej: "is_hidden" o "current_cups")
@export var target_group: String = "coffee_pickups" # Grupo de objetos adyacentes
@export var fade_duration: float = 0.3

var is_visible_hint: bool = false
var has_been_completed: bool = false
var player: Player

@onready var panel: PanelContainer = $PanelContainer
@onready var label: Label = %Label


func _ready() -> void:
	if label:
		label.text = text
	
	panel.modulate.a = 0.0
	visible = true

	call_deferred("connect_to_player")


func connect_to_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Player

	if player:
		player.player_moved.connect(_on_player_moved)
		
		if hint_type == HintType.ACTION_ONESHOT:
			fade_in()
		else:
			evaluate_context_hint()


func _unhandled_input(event: InputEvent) -> void:
	if has_been_completed or not is_visible_hint or player == null:
		return

	# Permite completar el hint al realizar la acción configurada (incluyendo "throw")
	var action_detected: bool = false
	match required_action:
		"wait":
			action_detected = event.is_action_pressed("wait")
		"interact":
			action_detected = event.is_action_pressed("interact")
		"throw":
			action_detected = event.is_action_released("throw") # Se completa al soltar el lanzamiento

	if action_detected:
		has_been_completed = true
		fade_out()


func _on_player_moved(_new_grid_pos: Vector2i) -> void:
	if player == null:
		return

	if hint_type == HintType.ACTION_ONESHOT:
		if not has_been_completed and is_visible_hint and required_action == "any_move":
			has_been_completed = true
			fade_out()
	else:
		evaluate_context_hint()


func evaluate_context_hint() -> void:
	if player == null or has_been_completed:
		return

	var should_show: bool = false

	match hint_type:
		HintType.PLAYER_STATE:
			if state_property in player:
				var val = player.get(state_property)
				if val is bool:
					should_show = val
				elif val is int or val is float:
					should_show = val > 0 # Muestra la pista si la propiedad (ej: current_cups) es mayor a 0

		HintType.NEARBY_GROUP:
			should_show = is_near_group_entity() and player.current_cups < player.max_cups

	if should_show and not is_visible_hint:
		fade_in()
	elif not should_show and is_visible_hint:
		fade_out()


func is_near_group_entity() -> bool:
	if player == null or target_group.is_empty():
		return false

	var nodes: Array[Node] = get_tree().get_nodes_in_group(target_group)
	for node in nodes:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			if "grid_position" in node:
				var dist: int = Utils.chebyshev_distance(player.grid_position, node.grid_position)
				if dist <= 1:
					return true
	return false


func fade_in() -> void:
	if is_visible_hint or has_been_completed:
		return
	is_visible_hint = true
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, fade_duration)


func fade_out() -> void:
	if not is_visible_hint:
		return
	is_visible_hint = false
	var tween: Tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, fade_duration)

class_name HUD
extends CanvasLayer

@onready var turn_label: Label = %TurnLabel
@onready var floor_label: Label = get_node_or_null("%FloorLabel")
@onready var cups_label: Label = get_node_or_null("%CupsLabel")
@onready var cups_container: Control = get_node_or_null("%CupsContainer")


func _ready() -> void:
	update_turns(0)
	refresh_cups_visibility(0)


func refresh_cups_visibility(amount: int) -> void:
	var container: CanvasItem = cups_container
	if container == null and cups_label != null:
		container = cups_label.get_parent() as CanvasItem
		
	if container:
		container.visible = amount > 0


func update_turns(turns: int) -> void:
	if turn_label:
		turn_label.text = "Turnos: %d" % turns


func update_floor_info(floor_number: int, floor_name: String) -> void:
	if floor_label:
		floor_label.text = "PISO %d · %s" % [floor_number, floor_name]


func update_cups(amount: int) -> void:
	if cups_label:
		cups_label.text = "x%d" % amount

	refresh_cups_visibility(amount)

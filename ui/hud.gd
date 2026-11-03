class_name HUD
extends CanvasLayer

@onready var turn_label: Label = %TurnLabel
@onready var floor_label: Label = get_node_or_null("%FloorLabel")
@onready var cups_label: Label = get_node_or_null("%CupsLabel")


func _ready() -> void:
	update_turns(0)


func update_turns(turns: int) -> void:
	if turn_label:
		turn_label.text = "Turnos: %d" % turns


func update_floor_info(floor_number: int, floor_name: String) -> void:
	if floor_label:
		floor_label.text = "PISO %d · %s" % [floor_number, floor_name]


func update_cups(amount: int) -> void:
	if cups_label:
		cups_label.text = "x%d" % amount

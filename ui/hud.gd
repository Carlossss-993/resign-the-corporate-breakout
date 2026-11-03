class_name HUD
extends CanvasLayer

@onready var turn_label: Label = %TurnLabel


func _ready() -> void:
	update_turns(0)


func update_turns(turns: int) -> void:
	turn_label.text = "Turnos: %d" % turns

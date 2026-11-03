extends Node

const SAVE_PATH: String = "user://save_data.cfg"
const MAIN_MENU_PATH: String = "res://ui/main_menu.tscn"

var intro_seen: bool = false
var level_records: Dictionary = {}

@export var levels: Array[String] = [
	"res://levels/level_1.tscn",
	"res://levels/level_2.tscn",
]
var current_level_index: int = 0


func _ready() -> void:
	load_records()


func go_to_next_level() -> void:
	current_level_index += 1
	if current_level_index < levels.size():
		get_tree().change_scene_to_file(levels[current_level_index])
	else:
		go_to_menu()


func restart_level() -> void:
	if current_level_index < levels.size():
		get_tree().change_scene_to_file(levels[current_level_index])
	else:
		get_tree().reload_current_scene()


func go_to_menu() -> void:
	current_level_index = 0
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func get_best_record(level_id: String) -> int:
	return level_records.get(level_id, 0)


func save_level_record(level_id: String, turns: int) -> bool:
	var current_best: int = get_best_record(level_id)
	var is_new_record: bool = current_best == 0 or turns < current_best

	if is_new_record:
		level_records[level_id] = turns
		save_to_disk()

	return is_new_record


func save_to_disk() -> void:
	var config: ConfigFile = ConfigFile.new()
	for level_id: String in level_records:
		config.set_value("records", level_id, level_records[level_id])
	config.save(SAVE_PATH)


func load_records() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return

	if config.has_section("records"):
		for key: String in config.get_section_keys("records"):
			level_records[key] = config.get_value("records", key, 0)

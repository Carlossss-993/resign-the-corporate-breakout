extends Node

const SAVE_PATH: String = "user://save_data.cfg"

var intro_seen: bool = false
var level_records: Dictionary = {}


func _ready() -> void:
	load_records()


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

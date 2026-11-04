class_name DialogueLines

const PLAYER_PORTRAIT: Texture2D = preload("res://assets/portraits/Player_Portrait.png")
const BOSS_PORTRAIT: Texture2D = preload("res://assets/portraits/Boss_Portrait.png")


static func player(text: String) -> Dictionary:
	return speaker("Jugador", text, "left", PLAYER_PORTRAIT)


static func guard(text: String, portrait: Texture2D = null) -> Dictionary:
	return speaker("Guardia", text, "right", portrait)


static func boss(text: String) -> Dictionary:
	return speaker("Jefe", text, "right", BOSS_PORTRAIT)


static func speaker(name: String, text: String, side: String = "left", portrait: Texture2D = null, pitch: float = 0.0) -> Dictionary:
	var dict: Dictionary = {
		"name": name,
		"text": text,
		"side": side
	}
	if side == "left":
		dict["portrait_left"] = portrait
	else:
		dict["portrait_right"] = portrait

	if pitch > 0.0:
		dict["pitch"] = pitch

	return dict

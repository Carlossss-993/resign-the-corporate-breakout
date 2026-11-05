extends Node

var tracks: Dictionary = {
	"menu": preload("res://assets/audio/chiptune_menu.mp3"),
	"game": preload("res://assets/audio/chiptune_game.mp3"),
	"chase": preload("res://assets/audio/chiptune_chase.mp3"),
	"credits": preload("res://assets/audio/credits.mp3"),
}

const DEFAULT_VOLUME_DB: float = -6.0

var player_a: AudioStreamPlayer
var player_b: AudioStreamPlayer
var current_player: AudioStreamPlayer
var current_stream: AudioStream
var fade_tween: Tween
var _web_audio_unlocked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	player_a = AudioStreamPlayer.new()
	player_b = AudioStreamPlayer.new()
	add_child(player_a)
	add_child(player_b)

	player_a.volume_db = DEFAULT_VOLUME_DB
	player_b.volume_db = DEFAULT_VOLUME_DB

	player_a.finished.connect(_on_player_finished.bind(player_a))
	player_b.finished.connect(_on_player_finished.bind(player_b))

	current_player = player_a


func _input(event: InputEvent) -> void:
	if _web_audio_unlocked:
		return
	if event is InputEventMouseButton or event is InputEventKey:
		if event.is_pressed():
			_web_audio_unlocked = true
			if current_player and current_player.stream and not current_player.is_playing():
				current_player.play()


func _on_player_finished(player: AudioStreamPlayer) -> void:
	if player == current_player and current_stream != null:
		player.play()


func play_track(track_key: String, fade_duration: float = 0.6) -> void:
	if not tracks.has(track_key):
		return
	play(tracks[track_key], fade_duration)


func play(stream: AudioStream, fade_duration: float = 0.6) -> void:
	if stream == null or current_stream == stream:
		return

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	current_stream = stream

	var old_player: AudioStreamPlayer = current_player
	var new_player: AudioStreamPlayer = player_b if current_player == player_a else player_a
	current_player = new_player

	new_player.stream = stream
	new_player.volume_db = -80.0
	new_player.play()

	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(new_player, "volume_db", DEFAULT_VOLUME_DB, fade_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if old_player.is_playing():
		fade_tween.tween_property(old_player, "volume_db", -80.0, fade_duration)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		fade_tween.chain().tween_callback(old_player.stop)

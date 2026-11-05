extends Control

@export var scroll_duration: float = 40.0 # Tiempo en segundos que tardan en subir los créditos
@export var extra_padding: float = 100.0   # Margen extra al terminar para que pase todo el texto

@onready var credits_container: Control = $MarginContainer/CreditsContainer
@onready var vbox: VBoxContainer = $MarginContainer/CreditsContainer/VBoxContainer

var scroll_tween: Tween


func _ready() -> void:
	start_credits_scroll()


func start_credits_scroll() -> void:
	await get_tree().process_frame # Espera un frame para que Godot calcule el tamaño real del VBox
	
	var viewport_height: float = get_viewport_rect().size.y
	var total_height: float = vbox.size.y

	# Posiciona los créditos justo abajo de la pantalla visible
	credits_container.position.y = viewport_height

	# El destino final es mover hacia arriba todo el texto hasta que salga por completo
	var target_y: float = -(total_height + extra_padding)

	scroll_tween = create_tween()
	scroll_tween.tween_property(credits_container, "position:y", target_y, scroll_duration)\
		.set_trans(Tween.TRANS_LINEAR)

	# Al terminar la animación, regresa al menú principal
	scroll_tween.finished.connect(_on_credits_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed():
		# Si presiona espacio/enter/clic o tecla de interactuar, salta los créditos inmediatamente
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
			_on_credits_finished()


func _on_credits_finished() -> void:
	if scroll_tween and scroll_tween.is_running():
		scroll_tween.kill()

	# Carga el menú principal cargando la escena desde GameState
	GameState.go_to_menu()

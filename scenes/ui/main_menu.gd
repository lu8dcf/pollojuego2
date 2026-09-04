extends CanvasLayer

@onready var button_join: Button = %ButtonJoin
@onready var button_quit: Button = %ButtonQuit

@onready var line_edit_session: LineEdit = %LineEditSession
@onready var line_edit_username: LineEdit = %LineEditUsername
@onready var button_join_tube: Button = %ButtonJoinTube
@onready var button_quit_tube: Button = %ButtonQuitTube
@onready var button_create_tube: Button = %ButtonCreateTube

@onready var enet_menu: VBoxContainer = %EnetMenu
@onready var tube_menu: VBoxContainer = %TubeMenu

const WORLD_FOREST = preload("uid://yubh30707eb7") 
const PLAYER = preload("uid://dbcqeo103wau6")

@onready var world_forest: Node3D = %WorldForest
@onready var menu_camera: MenuCameraController = %WorldForest.get_node("Camera3D")

@onready var temp_world_forest: Node3D = %WorldForest


func _ready() -> void:
	if Network.tube_enabled:
		enet_menu.hide()
	else:
		tube_menu.hide()

	button_join.pressed.connect(on_join)
	button_quit.pressed.connect(func(): get_tree().quit())

	line_edit_session.text_changed.connect(update_session)
	line_edit_username.text_changed.connect(update_username)
	button_join_tube.disabled = true
	button_join_tube.pressed.connect(on_join_tube)
	button_quit_tube.pressed.connect(func(): get_tree().quit())
	button_create_tube.pressed.connect(on_create_tube)
	
	Network.tube_client.error_raised.connect(on_error_raised)
	_activate_menu_camera()
	
	if OS.has_feature('server'):
		temp_world_forest.queue_free()
		Network.start_server()
		await get_tree().create_timer(0.1).timeout
		add_world()

func _activate_menu_camera() -> void:
	"""Configurar la cámara para el modo menú"""
	if world_forest and world_forest.has_method("enable_menu_mode"):
		world_forest.enable_menu_mode()
	
	# Ajustes adicionales de la cámara para el menú
	if menu_camera:
		menu_camera.activate_menu_camera()

func _deactivate_menu_camera() -> void:
	"""Restaurar la cámara cuando se sale del menú"""
	if world_forest and world_forest.has_method("disable_menu_mode"):
		world_forest.disable_menu_mode()

func on_join():
	_deactivate_menu_camera()
	temp_world_forest.queue_free()  # colocar animacion  de fondo
	Network.join_server()
	add_world()

func add_world():
	#temp_world_forest.queue_free()
	var new_world = WORLD_FOREST.instantiate()
	get_tree().current_scene.add_child(new_world)
	hide()

func on_join_tube():
	_deactivate_menu_camera()
	temp_world_forest.queue_free()
	Network.tube_join(line_edit_session.text)
	multiplayer.connected_to_server.connect(add_world)

func on_create_tube():
	_deactivate_menu_camera()
	temp_world_forest.queue_free()
	Network.tube_create()
	add_world()

func update_session(new_text: String):
	button_join_tube.disabled = new_text == ""
	var caret_pos: int = line_edit_session.caret_column
	line_edit_session.text = new_text.to_upper()
	line_edit_session.caret_column = caret_pos

func update_username(new_text: String):
	Global.username = new_text

func on_error_raised(_code, _message):
	line_edit_session.text = ''
	button_join_tube.add_theme_color_override('font_disabled_color', Color.DARK_RED)
	button_join_tube.disabled = true
	Network.clean_up_signals()
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and menu_camera:
		# Efecto parallax: la cámara reacciona sutilmente al mouse
		var mouse_offset = (event.position - get_viewport().size * 0.5) * 0.001
		menu_camera.sway_offset += mouse_offset.x * 0.01

extends CanvasLayer

@onready var button_join: Button = %ButtonJoin
@onready var button_quit: Button = %ButtonQuit

@onready var edit_sesion: LineEdit = %EditSesion
@onready var edit_nombre_usuario: LineEdit = %EditNombreUsuario

@onready var boton_unirse_tube: Button = %BotonUnirseTube
@onready var boton_crear_partida_tube: Button = %BotonCrearPartidaTube
@onready var boton_salir: TextureButtonAnimado = %BotonSalir

@onready var panel_un_jugador: PanelContainer = %PanelUnJugador
@onready var panel_multijugador: PanelContainer = %PanelMultijugador
@onready var panel_opciones: PanelContainer = %PanelOpciones

@onready var enet_menu: VBoxContainer = %EnetMenu
@onready var tube_menu: VBoxContainer = %TubeMenu

const MUNDO = preload("uid://yubh30707eb7")
const PLAYER = preload("uid://bc1ek0bvbgna2")

@onready var mundo: Node3D = %Mundo
@onready var menu_camera: MenuCameraController = %Mundo.get_node("Camera3D")

@onready var temp_mundo: Node3D = %Mundo


func _ready() -> void:
	ocultar_todo()
	if Network.tube_enabled:
		enet_menu.hide()
	else:
		tube_menu.hide()

	button_join.pressed.connect(on_join)
	button_quit.pressed.connect(func(): get_tree().quit())

	edit_sesion.text_changed.connect(update_session)
	edit_nombre_usuario.text_changed.connect(update_username)
	boton_unirse_tube.disabled = true
	boton_unirse_tube.pressed.connect(on_unirse_tube)
	boton_salir.pressed.connect(func(): get_tree().quit())
	boton_crear_partida_tube.pressed.connect(on_crear_partida_tube)
	
	Network.tube_client.error_raised.connect(on_error_raised)
	_activate_menu_camera()
	
	if OS.has_feature('server'):
		temp_mundo.queue_free()
		Network.start_server()
		await get_tree().create_timer(0.1).timeout
		add_world()

func _activate_menu_camera() -> void:
	"""Configurar la cámara para el modo menú"""
	if mundo and mundo.has_method("enable_menu_mode"):
		mundo.enable_menu_mode()
	if menu_camera:
		menu_camera.activate_menu_camera()

func _deactivate_menu_camera() -> void:
	"""Restaurar la cámara cuando se sale del menú"""
	if mundo and mundo.has_method("disable_menu_mode"):
		mundo.disable_menu_mode()

func on_join():
	_deactivate_menu_camera()
	temp_mundo.queue_free()
	Network.join_server()
	add_world()

func add_world():
	#temp_mundo.queue_free()
	var nuevo_mundo = MUNDO.instantiate()
	get_tree().current_scene.add_child(nuevo_mundo)
	hide()

func on_unirse_tube():
	_deactivate_menu_camera()
	temp_mundo.queue_free()
	Network.tube_join(edit_sesion.text)
	multiplayer.connected_to_server.connect(add_world)

func on_crear_partida_tube():
	_deactivate_menu_camera()
	Global.un_jugador = false
	temp_mundo.queue_free()
	Network.tube_create()
	add_world()

func update_session(new_text: String):
	boton_unirse_tube.disabled = new_text == ""
	var caret_pos: int = edit_sesion.caret_column
	edit_sesion.text = new_text.to_upper()
	edit_sesion.caret_column = caret_pos

func update_username(new_text: String):
	Global.username = new_text

func on_error_raised(_code, _message):
	edit_sesion.text = ''
	boton_unirse_tube.add_theme_color_override('font_disabled_color', Color.DARK_RED)
	boton_unirse_tube.disabled = true
	Network.clean_up_signals()
	


func ocultar_todo():
	panel_un_jugador.visible=false
	panel_multijugador.visible=false
	panel_opciones.visible=false
	
func _on_un_jugador_pressed() -> void:
	ocultar_todo()
	if panel_un_jugador.visible:
		pass
	else:
		panel_un_jugador.visible=true
	


func _on_multijugador_pressed() -> void:
	ocultar_todo()
	if panel_multijugador.visible:
		pass
	else:
		panel_multijugador.visible=true
	


func _on_opciones_pressed() -> void:
	ocultar_todo()
	if panel_opciones.visible:
		pass
	else:
		panel_opciones.visible=true


func _on_creditos_pressed() -> void:
	ocultar_todo()
	


func _on_empezar_solo_pressed() -> void:
	_deactivate_menu_camera()
	if temp_mundo:
		temp_mundo.queue_free()
		await  get_tree().process_frame
	var nuevo_mundo = MUNDO.instantiate()
	get_tree().current_scene.add_child(nuevo_mundo)
	await  get_tree().process_frame
	
	if nuevo_mundo.has_method("partida_unsolojugador"):
		nuevo_mundo.partida_unsolojugador() # preparar mundo y partida para un solo jugador
	_crear_jugador_local(nuevo_mundo)
	hide() # ocultar menu

func _crear_jugador_local(mundo_instancia:Node3D):

	# crear jugador
	var jugador = PLAYER.instantiate()
	jugador.name="1" # el host debe tener numero 1 para jugar pero es solo un id, el user name se agrega con el edit
	var spawn_container = mundo_instancia.get_node_or_null("SpawnContainer")
	jugador.global_position = Vector3(22, 2, 22)
	Global.un_jugador = true
	# agregar el jguador  al mundo
	mundo_instancia.add_child(jugador)
	

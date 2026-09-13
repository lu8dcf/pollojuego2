extends CanvasLayer


@onready var edit_sesion: LineEdit = %EditSesion
@onready var edit_nombre_usuario: LineEdit = %EditNombreUsuario
# para un solo jugador
@onready var nombre_usuario: LineEdit = %nombre_usuario

@onready var boton_unirse_tube: Button = %BotonUnirseTube
@onready var boton_crear_partida_tube: Button = %BotonCrearPartidaTube
@onready var boton_salir: TextureButtonAnimado = %BotonSalir

@onready var panel_un_jugador: PanelContainer = %PanelUnJugador
@onready var panel_multijugador: PanelContainer = %PanelMultijugador
@onready var panel_opciones: PanelContainer = %PanelOpciones

@onready var tube_menu: VBoxContainer = %TubeMenu

const MUNDO = preload("uid://yubh30707eb7")
const PLAYER = preload("uid://bc1ek0bvbgna2")
const LOBBY = preload("uid://oegdxwge86nk")

@onready var mundo: Node3D = %Mundo
@onready var menu_camera: MenuCameraController = %Mundo.get_node("Camera3D")

@onready var temp_mundo: Node3D = %Mundo

var lobby_actual :CanvasLayer = null
var mundo_creado: bool = false

func _ready() -> void:
	ocultar_todo() # ocultar toso los menus 


	edit_sesion.text_changed.connect(update_session)
	edit_nombre_usuario.text_changed.connect(update_username)
	nombre_usuario.text_changed.connect(update_username)
	boton_unirse_tube.disabled = true
	boton_unirse_tube.pressed.connect(on_unirse_tube)
	boton_salir.pressed.connect(func(): get_tree().quit())
	boton_crear_partida_tube.pressed.connect(on_crear_partida_tube)
	
	Network.tube_client.error_raised.connect(on_error_raised)
	
	_activate_menu_camera() # activa la camara tipo cine del menu
	# si es servidor dedicado, iniciar servidor automáticamente
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
	_mostrar_lobby()

func add_world():
	#temp_mundo.queue_free()
	_limpiar_lobby() 
	var nuevo_mundo = MUNDO.instantiate()
	get_tree().current_scene.add_child(nuevo_mundo)
	hide()

func _mostrar_lobby():
	hide() # se esconde el menu principal
	_limpiar_lobby() # se limpia el lobby por si queda guardado
	if LOBBY:
		lobby_actual = LOBBY.instantiate()
		get_tree().current_scene.add_child(lobby_actual)
		if lobby_actual.has_signal("partida_iniciada"):
			lobby_actual.partida_iniciada.connect(_on_partida_iniciada_desde_lobby)
	else:
		print("ERROR: No se pudo cargar la escena del lobby")
		# crear mundo directamente, pero fue un error de falta de lobby
		add_world()
		
func _limpiar_lobby():
	if lobby_actual and is_instance_valid(lobby_actual):
		lobby_actual.queue_free()
	lobby_actual = null
	
func _on_partida_iniciada_desde_lobby():
	if mundo_creado:
		print("El mundo ya fue creado, ignorando...")
		return
	
	mundo_creado = true
	
	print("Partida iniciada desde el lobby")
	_deactivate_menu_camera()
	
	if temp_mundo:
		temp_mundo.queue_free()
		await get_tree().process_frame
	
	# Crear el mundo LOCALMENTE en cada cliente
	var nuevo_mundo = MUNDO.instantiate()
	nuevo_mundo.name = "Mundo"
	nuevo_mundo.add_to_group("mundo")
	get_tree().current_scene.add_child(nuevo_mundo)
	
	await get_tree().create_timer(0.5).timeout
	
	if multiplayer.is_server():
		print("HOST: Creando jugadores...")
		Network.crear_todos_los_jugadores()
	else:
		print("CLIENTE: Esperando jugadores del host...")
	
	hide()
	
	
func on_unirse_tube():
	_deactivate_menu_camera()
	GlobalJuego.un_jugador = false
	temp_mundo.queue_free()
	Network.tube_join(edit_sesion.text)
	#multiplayer.connected_to_server.connect(add_world)
	# esperar a estar conectado y luego mostrar el lobby
	multiplayer.connected_to_server.connect(_on_conectado_para_lobby)

func _on_conectado_para_lobby():
	if multiplayer.connected_to_server.is_connected(_on_conectado_para_lobby):
		multiplayer.connected_to_server.disconnect(_on_conectado_para_lobby)
	
	_mostrar_lobby()
	
func on_crear_partida_tube():
	_deactivate_menu_camera()
	GlobalJuego.un_jugador = false
	temp_mundo.queue_free()
	if edit_nombre_usuario.text != "":
		GlobalJuego.nombre_jugador = edit_nombre_usuario.text
	elif nombre_usuario.text != "":
		GlobalJuego.nombre_jugador = nombre_usuario.text 
	print("Creando partida con nombre: ", GlobalJuego.nombre_jugador)
	Network.tube_create()
	_mostrar_lobby()

func update_session(new_text: String):
	boton_unirse_tube.disabled = new_text == ""
	var caret_pos: int = edit_sesion.caret_column
	edit_sesion.text = new_text.to_upper()
	edit_sesion.caret_column = caret_pos

func update_username(new_text: String):
	GlobalJuego.nombre_jugador = new_text
	print("Nombre actualizado: ", GlobalJuego.nombre_jugador)
	
func on_error_raised(_code, _message):
	edit_sesion.text = ''
	boton_unirse_tube.add_theme_color_override('font_disabled_color', Color.DARK_RED)
	boton_unirse_tube.disabled = true
	#Network.clean_up_signals()
	
	show()
	_limpiar_lobby()


func ocultar_todo():
	panel_un_jugador.visible=false
	panel_multijugador.visible=false
	panel_opciones.visible=false
	
func _on_un_jugador_pressed() -> void:
	ocultar_todo()
	panel_un_jugador.visible = not panel_un_jugador.visible
	
func _on_multijugador_pressed() -> void:
	ocultar_todo()
	panel_multijugador.visible = not panel_multijugador.visible

func _on_opciones_pressed() -> void:
	ocultar_todo()
	panel_opciones.visible =  not panel_opciones.visible

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
	GlobalJuego.un_jugador = true
	# agregar el jguador  al mundo
	mundo_instancia.add_child(jugador)
	

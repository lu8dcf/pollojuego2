extends CanvasLayer

# referencia a los botones
@onready var un_jugador: TextureButtonAnimado = %un_jugador
@onready var multijugador: TextureButtonAnimado = %multijugador
@onready var opciones: TextureButtonAnimado = %opciones
@onready var creditos: TextureButtonAnimado = %creditos
@onready var boton_salir: TextureButtonAnimado = %BotonSalir
# Botones de selección
@onready var boton_online: TextureButton = %BotonOnline
@onready var boton_local: TextureButton = %BotonLocal
# gaficos 
@onready var check_button: CheckButton = %CheckButton

# Referencias a paneles
@onready var panel_un_jugador: Control = %PanelUnJugador
@onready var panel_multijugador: Control = %PanelMultijugador
@onready var panel_opciones: Control = %PanelOpciones
#@onready var panel_creditos: Control = %PanelCreditos

# Pantalla de carga
var pantalla_carga_actual: CanvasLayer = null


@onready var temp_mundo: Node3D = %MundoTemporal
@onready var menu_camera: MenuCameraController = %MundoTemporal.get_node("Camera3D")

# Preloads
const MUNDO = preload("uid://yubh30707eb7")
const PLAYER = preload("uid://bc1ek0bvbgna2")
const LOBBY = preload("uid://oegdxwge86nk")
const PANTALLA_CARGA = preload("uid://bym6i52jnwycp")

var lobby_actual: CanvasLayer = null

# bandera de creasionde sesion
var _creando_tube:bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_ocultar_todos_los_paneles()
	conectar_botones()
	
	# Conectar señales de los paneles
	#GlobalSignal.solicitar_empezar.connect(_on_empezar_un_jugador)
	GlobalSignal.solicitar_unirse_lan.connect(_on_unirse_lan)
	GlobalSignal.solicitar_crear_lan.connect(_on_crear_lan)
	GlobalSignal.solicitar_unirse_tube.connect(_on_unirse_tube)
	GlobalSignal.solicitar_crear_partida_un_jugador.connect(_crear_partida_un_jugador)
	if not GlobalSignal.solicitar_crear_tube.is_connected(_on_crear_tube):
		GlobalSignal.solicitar_crear_tube.connect(_on_crear_tube)
	GlobalSignal.solicitar_cerrar.connect(_ocultar_todos_los_paneles)
	
	# Errores de red
	GlobalSignal.error_conexion.connect(_on_error_conexion)
	Network.tube_client.error_raised.connect(_on_error_conexion)
	
	# SEÑALES PARA LOS ERRORES ESPECIFICOS
	GlobalSignal.error_conexion.connect(_on_error_generico)
	GlobalSignal.error_sala_llena.connect(_on_error_sala_llena)
	GlobalSignal.error_timeout_conexion.connect(_on_error_timeout)
	GlobalSignal.error_ip_invalida.connect(_on_error_ip_invalida)
	GlobalSignal.error_host_desconectado.connect(_on_error_host_desconectado)
	GlobalSignal.error_sesion_invalida.connect(_on_error_sesion_invalida)
	GlobalSignal.error_puerto_en_uso.connect(_on_error_puerto_en_uso)

	# Pantalla de carga
	GlobalSignal.cancelado.connect(_on_pantalla_carga_cancelada)
	
	# Activamos cámara del menú
	_activate_menu_camera()
	

func conectar_botones()->void:
	un_jugador.pressed.connect(_mostrar_un_jugador)
	multijugador.pressed.connect(_mostrar_multijugador)
	opciones.pressed.connect(_mostrar_opciones)
	boton_salir.pressed.connect(_boton_salir)
	check_button.toggled.connect(_boton_requisitos)


func _boton_requisitos(tongle:bool):
	GlobalJuego.carga_mapa_simple =tongle
# ------------------------------------------------------------
# NAVEGACIÓN ENTRE PANELES
# ------------------------------------------------------------

func _ocultar_todos_los_paneles() -> void:
	panel_un_jugador.visible = false
	panel_multijugador.visible = false
	panel_opciones.visible = false
	boton_local.visible = false
	boton_online.visible = false
	
	#panel_creditos.visible = false

func mostrar_panel(panel: Control) -> void:
	_ocultar_todos_los_paneles()
	panel.visible = true
	
# ------------------------------------------------------------
# PANTALLA DE CARGA
# ------------------------------------------------------------

func _mostrar_pantalla_carga(mensaje: String = "Cargando...") -> CanvasLayer:
	# Si ya hay una abierta, la eliminamos antes
	_ocultar_pantalla_carga()
	
	pantalla_carga_actual = PANTALLA_CARGA.instantiate()
	add_child(pantalla_carga_actual)
	
	# Configurar mensaje
	if pantalla_carga_actual.has_method("mensaje"):
		pantalla_carga_actual.mensaje(mensaje)
	
	# Conectar señal de cancelar
	if pantalla_carga_actual.has_signal("cancelado"):
		pantalla_carga_actual.cancelado.connect(_on_pantalla_carga_cancelada)
	
	return pantalla_carga_actual

func _ocultar_pantalla_carga() -> void:
	if pantalla_carga_actual and is_instance_valid(pantalla_carga_actual):
		pantalla_carga_actual.queue_free()
	pantalla_carga_actual = null

func _on_pantalla_carga_cancelada() -> void:
	_ocultar_pantalla_carga()
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	show()
	_ocultar_todos_los_paneles()
	_limpiar_lobby()
	_activate_menu_camera()


# ------------------------------------------------------------
# PANEL UN JUGADOR
# ------------------------------------------------------------
func _mostrar_un_jugador():
	mostrar_panel(panel_un_jugador)

func _crear_partida_un_jugador() -> void:
	GlobalJuego.un_jugador = true
	_deactivate_menu_camera()
	
	_mostrar_pantalla_carga("Creando Juego para un solo jugador...")
	
	if temp_mundo:
		temp_mundo.queue_free()
	
	await get_tree().create_timer(0.3).timeout
	_ocultar_pantalla_carga()
	_ir_al_lobby()

func _on_empezar_un_jugador() -> void:
	_deactivate_menu_camera()
	GlobalJuego.un_jugador = true
	
	if temp_mundo:
		temp_mundo.queue_free()
		await get_tree().process_frame
	
	var nuevo_mundo = MUNDO.instantiate()
	get_tree().current_scene.add_child(nuevo_mundo)
	await get_tree().process_frame
	
	if nuevo_mundo.has_method("partida_unsolojugador"):
		nuevo_mundo.partida_unsolojugador()
	
	_crear_jugador_local(nuevo_mundo)
	hide()

func _crear_jugador_local(mundo_instancia: Node3D) -> void:
	var jugador = PLAYER.instantiate()
	jugador.name = "1"
	mundo_instancia.add_child(jugador)
	jugador.global_position = Vector3(22, 2, 22)

func _crear_mundo_un_jugador():
	var nuevo_mundo = MUNDO.instantiate()
	get_tree().current_scene.add_child(nuevo_mundo)
	await get_tree().process_frame
	
	if nuevo_mundo.has_method("partida_unsolojugador"):
		nuevo_mundo.partida_unsolojugador()
	
	_crear_jugador_local(nuevo_mundo)
	_limpiar_lobby()

# ------------------------------------------------------------
# MULTIJUGADOR LAN
# ------------------------------------------------------------
func _mostrar_multijugador():
	_ocultar_todos_los_paneles()
	
	boton_local.visible = true
	boton_online.visible = true

func _on_unirse_lan(ip: String, puerto: int, nombre: String) -> void:
	GlobalJuego.nombre_jugador = nombre
	
	GlobalJuego.un_jugador = false
	_deactivate_menu_camera()
	
	_mostrar_pantalla_carga("Conectando a " + ip + ":" + str(puerto) + "...")
	
	if not multiplayer.connected_to_server.is_connected(_on_conectado_para_lobby):
		multiplayer.connected_to_server.connect(_on_conectado_para_lobby)
	
	if not Network.unirse_servidor_lan(ip, puerto):
		return

func _on_crear_lan(puerto: int, nombre: String) -> void:
	GlobalJuego.nombre_jugador = nombre
	GlobalJuego.un_jugador = false
	_deactivate_menu_camera()
	
	_mostrar_pantalla_carga("Creando servidor en puerto " + str(puerto) + "...")
	
	if temp_mundo:
		temp_mundo.queue_free()
	
	if not await Network.empezar_servidor_lan(puerto):
		_ocultar_pantalla_carga()
		return
	
	await get_tree().create_timer(0.3).timeout
	_ocultar_pantalla_carga()
	_ir_al_lobby()

# ------------------------------------------------------------
# MULTIJUGADOR TUBE
# ------------------------------------------------------------

func _on_unirse_tube(session_id: String, nombre: String) -> void:
	GlobalJuego.nombre_jugador = nombre
	GlobalJuego.un_jugador = false
	_deactivate_menu_camera()
	
	_mostrar_pantalla_carga("Buscando sesión " + session_id + "...")
	
	if not multiplayer.connected_to_server.is_connected(_on_conectado_para_lobby):
		multiplayer.connected_to_server.connect(_on_conectado_para_lobby)
	
	Network.tube_join(session_id)

func _on_crear_tube(nombre: String) -> void:
	if _creando_tube:
		return
	_creando_tube = true
	GlobalJuego.nombre_jugador = nombre
	GlobalJuego.un_jugador = false
	_deactivate_menu_camera()
	
	_mostrar_pantalla_carga("Creando partida...")

	# Conectar la señal ANTES de crear la sesión
	if not Network.tube_client.session_created.is_connected(_on_tube_session_created):
		Network.tube_client.session_created.connect(_on_tube_session_created)

	Network.tube_create()

func _on_tube_session_created():
	_creando_tube = false
	if Network.tube_client.session_created.is_connected(_on_tube_session_created):
		Network.tube_client.session_created.disconnect(_on_tube_session_created)
	var peer_listo = await Network._esperar_peer_listo(5.0)
	if not peer_listo:
		_ocultar_pantalla_carga()
		_on_error_conexion("No se pudo inicializar la sesión de Tube.")
		return
	_ocultar_pantalla_carga()
	_ir_al_lobby()
# ------------------------------------------------------------
# TRANSICIÓN AL LOBBY
# ------------------------------------------------------------

func _on_conectado_para_lobby() -> void:
	if multiplayer.connected_to_server.is_connected(_on_conectado_para_lobby):
		multiplayer.connected_to_server.disconnect(_on_conectado_para_lobby)
	_ocultar_pantalla_carga()
	_ir_al_lobby()

func _ir_al_lobby() -> void:
	if temp_mundo and is_instance_valid(temp_mundo):
		temp_mundo.queue_free()
		await get_tree().process_frame
	_mostrar_lobby()

func _mostrar_lobby() -> void:
	hide()
	_limpiar_lobby()
	if not LOBBY:
		print("ERROR: No se pudo cargar el lobby")
		return
	
	lobby_actual = LOBBY.instantiate()
	lobby_actual.name = "Lobby"
	get_tree().current_scene.add_child(lobby_actual)
	if lobby_actual.has_signal("partida_iniciada"):
		lobby_actual.partida_iniciada.connect(_on_partida_iniciada_desde_lobby)

func _limpiar_lobby() -> void:
	if lobby_actual and is_instance_valid(lobby_actual):
		lobby_actual.queue_free()
	lobby_actual = null

func _on_partida_iniciada_desde_lobby() -> void:
	_deactivate_menu_camera()
	hide()
	if temp_mundo and is_instance_valid(temp_mundo):
		if menu_camera:
			menu_camera.current = false
		temp_mundo.queue_free()
		
	if GlobalJuego.un_jugador:
		_crear_mundo_un_jugador()
	#_limpiar_lobby()  # libera el lobby para no consumir recursos

# ------------------------------------------------------------
# MANEJO DE OPCIONES
# ------------------------------------------------------------

func _mostrar_opciones()->void:
	mostrar_panel(panel_opciones)

# A FUTURO

# ------------------------------------------------------------
# MANEJO DE CREDITOS
# ------------------------------------------------------------

# A FUTURO


# ------------------------------------------------------------
# SALIR
# ------------------------------------------------------------

func _boton_salir()->void:
	# a fututro preguntar si quiere salir
	get_tree().quit()


# ------------------------------------------------------------
# CÁMARA DEL MENÚ
# ------------------------------------------------------------

func _activate_menu_camera() -> void:
	if temp_mundo and temp_mundo.has_method("enable_menu_mode"):
		temp_mundo.enable_menu_mode()
	if menu_camera:
		menu_camera.current = true
		menu_camera.activate_menu_camera()

func _deactivate_menu_camera() -> void:
	if temp_mundo and temp_mundo.has_method("disable_menu_mode"):
		temp_mundo.disable_menu_mode()
	if menu_camera:
		menu_camera.current = false

# ------------------------------------------------------------
# MANEJO DE ERRORES
# ------------------------------------------------------------

func _on_error_conexion(mensaje: String,titulo:String = "Error") -> void:
	if not pantalla_carga_actual or not is_instance_valid(pantalla_carga_actual):
		_mostrar_pantalla_carga("Error")
	
	if pantalla_carga_actual and pantalla_carga_actual.has_method("mostrar_error"):
		pantalla_carga_actual.mostrar_error(mensaje,titulo)

func _on_error_generico(mensaje: String) -> void:
	_mostrar_error(mensaje, "Error")

func _on_error_sala_llena() -> void:
	_mostrar_error(
		"La sala ya tiene 4 jugadores. Probá con otra sesión.",
		"Sala llena"
	)

func _on_error_timeout() -> void:
	_mostrar_error(
		"El servidor no respondió a tiempo.\nVerificá la IP y el puerto.",
		"Tiempo agotado"
	)

func _on_error_ip_invalida() -> void:
	_mostrar_error(
		"La dirección IP no es válida.\nEjemplo: 192.168.1.42",
		"IP inválida"
	)

func _on_error_host_desconectado() -> void:
	_mostrar_error(
		"El host se desconectó de la partida.",
		"Host desconectado"
	)

func _on_error_sesion_invalida() -> void:
	_mostrar_error(
		"El ID de sesión no existe o expiró.\nVerificá el código.",
		"Sesión inválida"
	)

func _on_error_puerto_en_uso() -> void:
	_mostrar_error(
		"El puerto ya está en uso.\nProbá con otro número.",
		"Puerto en uso"
	)
func _mostrar_error(mensaje: String, titulo: String = "Error de conexión") -> void:
	if not pantalla_carga_actual or not is_instance_valid(pantalla_carga_actual):
		_mostrar_pantalla_carga("Error")
	
	if pantalla_carga_actual and pantalla_carga_actual.has_method("mostrar_error"):
		pantalla_carga_actual.mostrar_error(mensaje, titulo)

extends CanvasLayer

# para un solo jugador
@onready var nombre_usuario: LineEdit = %nombre_usuario

# para el multijugador tube
@onready var boton_unirse_tube: Button = %BotonUnirseTube
@onready var boton_crear_partida_tube: Button = %BotonCrearPartidaTube
@onready var boton_salir: TextureButtonAnimado = %BotonSalir
@onready var edit_sesion: LineEdit = %EditSesion
@onready var edit_nombre_usuario: LineEdit = %EditNombreUsuario

#para el multijugador lan
@onready var edit_nombre_usuario_enet: LineEdit = $Control/PanelMultijugadorEnet/MarginContainer/HBoxContainer/TubeMenu/EditNombreUsuarioEnet
@onready var edit_ip: LineEdit = $Control/PanelMultijugadorEnet/MarginContainer/HBoxContainer/TubeMenu/EditIp
@onready var edit_puerto: LineEdit = $Control/PanelMultijugadorEnet/MarginContainer/HBoxContainer/TubeMenu/EditPuerto
@onready var boton_unirse_enet: Button = $Control/PanelMultijugadorEnet/MarginContainer/HBoxContainer/TubeMenu/BotonUnirseEnet
@onready var boton_crear_partida_enet: Button = $Control/PanelMultijugadorEnet/MarginContainer/HBoxContainer/TubeMenu/BotonCrearPartidaEnet


@onready var panel_un_jugador: PanelContainer = %PanelUnJugador
@onready var panel_multijugador: PanelContainer = %PanelMultijugador
@onready var panel_opciones: PanelContainer = %PanelOpciones
@onready var panel_multijugador_enet: PanelContainer = %PanelMultijugadorEnet

@onready var tube_menu: VBoxContainer = %TubeMenu

# botones de multijugador opiciones de local y online
@onready var boton_online: TextureButtonAnimado = %BotonOnline
@onready var boton_local: TextureButtonAnimado = %BotonLocal


# Referencia al ColorRect con el shader de aberración cromática
@export var color_rect_shader: ColorRect

const MUNDO = preload("uid://yubh30707eb7")
const PLAYER = preload("uid://bc1ek0bvbgna2")
const LOBBY = preload("uid://oegdxwge86nk")

@onready var mundo: Node3D = %Mundo
@onready var menu_camera: MenuCameraController = %Mundo.get_node("Camera3D")

@onready var temp_mundo: Node3D = %Mundo

var lobby_actual: CanvasLayer = null
var mundo_creado: bool = false
var offset_original_layer: Vector2 = Vector2.ZERO

func _ready() -> void:
	offset_original_layer = offset
	ocultar_todo() # ocultar todos los menus 
	
	#online
	edit_sesion.text_changed.connect(update_session)
	edit_nombre_usuario.text_changed.connect(update_username)
	nombre_usuario.text_changed.connect(update_username)
	
	boton_unirse_tube.disabled = true
	boton_unirse_tube.pressed.connect(on_unirse_tube)
	boton_salir.pressed.connect(func(): get_tree().quit())
	boton_crear_partida_tube.pressed.connect(on_crear_partida_tube)
	
	# lan
	boton_unirse_enet.disabled = true
	edit_ip.text_changed.connect(update_ip)
	boton_unirse_enet.pressed.connect(on_join_enet)
	boton_crear_partida_enet.pressed.connect(on_crear_partida_enet)
	
	# Conectar efecto de impacto/shake a los botones
	_conectar_efectos_botones()
	
	Network.tube_client.error_raised.connect(on_error_raised)
	
	_activate_menu_camera() # activa la camara tipo cine del menu
	
	# si es servidor dedicado, iniciar servidor automáticamente
	if OS.has_feature('server'):
		temp_mundo.queue_free()
		Network.start_server()
		await get_tree().create_timer(0.1).timeout
		add_world()

func _conectar_efectos_botones() -> void:
	"""Conecta la sacudida y aberración cromática a los clics de los botones"""
	var botones = [
		boton_unirse_tube, 
		boton_crear_partida_tube, 
		boton_salir
	]
	
	for boton in botones:
		if boton and is_instance_valid(boton):
			if not boton.pressed.is_connected(_on_boton_presionado):
				boton.pressed.connect(_on_boton_presionado)

func _on_boton_presionado() -> void:
	aplicar_impacto(12.0, 0.05, 0.25)

func aplicar_impacto(intensidad_shake: float = 12.0, intensidad_aberracion: float = 0.05, duracion: float = 0.25) -> void:
	"""Aplica el efecto de sacudida en la interfaz y el pulso de aberración cromática"""
	# 1. Animación del Shader de Aberración Cromática (Asignación directa)
	if color_rect_shader and color_rect_shader.material is ShaderMaterial:
		var mat = color_rect_shader.material as ShaderMaterial
		mat.set_shader_parameter("intensidad", intensidad_aberracion)
		
		var tween_shader = create_tween()
		tween_shader.tween_property(mat, "shader_parameter/intensidad", 0.0, duracion)

	# 2. Sacudida visual (Shake) sobre el CanvasLayer
	var tween_shake = create_tween().set_parallel(true)
	var pasos = 6
	var tiempo_paso = duracion / pasos
	
	for i in range(pasos):
		var offset_aleatorio = Vector2(
			randf_range(-intensidad_shake, intensidad_shake),
			randf_range(-intensidad_shake, intensidad_shake)
		)
		var factor_decreciente = 1.0 - (float(i) / pasos)
		
		tween_shake.tween_property(
			self, 
			"offset", 
			offset_original_layer + (offset_aleatorio * factor_decreciente), 
			tiempo_paso
		).set_delay(i * tiempo_paso)
			
	# Restaurar offset original al finalizar
	tween_shake.tween_property(self, "offset", offset_original_layer, 0.05).set_delay(duracion)

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

func on_join_enet():
	var ip = edit_ip.text.strip_edges()
	var puerto_str = edit_puerto.text.strip_edges()
	
	if ip == "":
		print("ERROR: Debes escribir una IP")
		return
	if puerto_str == "" or not puerto_str.is_valid_int():
		print("ERROR: Puerto inválido")
		return
	
	var puerto = int(puerto_str)
	
	if edit_nombre_usuario_enet.text != "":
		GlobalJuego.nombre_jugador = edit_nombre_usuario_enet.text
	
	_deactivate_menu_camera()
	GlobalJuego.un_jugador = false
	
	if temp_mundo:
		temp_mundo.queue_free()
	
	# Conectar
	var ok = Network.join_server(ip, puerto)
	if not ok:
		print("No se pudo conectar al servidor LAN")
		return
	
	_mostrar_lobby()

func on_crear_partida_enet():
	var puerto_str = edit_puerto.text.strip_edges()
	var ip_str = edit_ip.text.strip_edges()
	if puerto_str == "" or not puerto_str.is_valid_int():
		#print("ERROR: Debes escribir un puerto válido")
		return
	if ip_str != "":
		Network.otro_ip = true
		Network.ip_local = ip_str
	var puerto = int(puerto_str)
	
	if edit_nombre_usuario_enet.text != "":
		GlobalJuego.nombre_jugador = edit_nombre_usuario_enet.text
	
	_deactivate_menu_camera()
	GlobalJuego.un_jugador = false
	
	if temp_mundo:
		temp_mundo.queue_free()
	
	# Crear servidor
	
	var ok = Network.start_server(puerto)
	if not ok:
		print("No se pudo crear el servidor LAN en el puerto ", puerto)
		return
	
	_mostrar_lobby()

func add_world():
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

func update_ip(nuevo_texto:String):
	boton_unirse_enet.disabled = nuevo_texto == ""

func update_session(nuevo_texto: String):
	boton_unirse_tube.disabled = nuevo_texto == ""
	var caret_pos: int = edit_sesion.caret_column
	edit_sesion.text = nuevo_texto.to_upper()
	edit_sesion.caret_column = caret_pos

func update_username(nuevo_texto: String):
	GlobalJuego.nombre_jugador = nuevo_texto
	print("Nombre actualizado: ", GlobalJuego.nombre_jugador)
	
func on_error_raised(_code, _message):
	edit_sesion.text = ''
	boton_unirse_tube.add_theme_color_override('font_disabled_color', Color.DARK_RED)
	boton_unirse_tube.disabled = true
	show()
	_limpiar_lobby()

func ocultar_todo():
	boton_local.visible = false
	boton_online.visible = false
	panel_un_jugador.visible = false
	panel_multijugador.visible = false
	panel_opciones.visible = false
	panel_multijugador_enet.visible = false
	
func _on_un_jugador_pressed() -> void:
	aplicar_impacto()
	ocultar_todo()
	panel_un_jugador.visible = not panel_un_jugador.visible
	
func _on_multijugador_pressed() -> void:
	aplicar_impacto()
	ocultar_todo()
	boton_local.visible = not boton_local.visible
	boton_online.visible = not boton_online.visible
	
	


func _on_boton_online_pressed() -> void:
	panel_multijugador.visible = not panel_multijugador.visible
	panel_multijugador_enet.visible = false
	

func _on_boton_local_pressed() -> void:
	panel_multijugador_enet.visible = not panel_multijugador_enet.visible
	panel_multijugador.visible = false

func _on_opciones_pressed() -> void:
	aplicar_impacto()
	ocultar_todo()
	
	panel_opciones.visible = not panel_opciones.visible

func _on_creditos_pressed() -> void:
	aplicar_impacto()
	ocultar_todo()

func _on_empezar_solo_pressed() -> void:
	aplicar_impacto()
	_deactivate_menu_camera()
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

func _crear_jugador_local(mundo_instancia: Node3D):
	var jugador = PLAYER.instantiate()
	jugador.name = "1"
	var spawn_container = mundo_instancia.get_node_or_null("SpawnContainer")
	jugador.global_position = Vector3(22, 2, 22)
	GlobalJuego.un_jugador = true
	mundo_instancia.add_child(jugador)

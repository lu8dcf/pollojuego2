extends CanvasLayer

class_name PlayerUI

@onready var menu: Control = %Menu

# PANEL ARRIBA DERECHA - MENU Y SALIR
@onready var boton_pausa: TextureButton = %BotonPausa
@onready var boton_salir: TextureButton = %BotonSalir # para salir del servidor

# PANEL DE PAUSA
@onready var pausa_panel: MarginContainer = %Pausa
@onready var boton_regresar: TextureButton = %BotonRegresar
@onready var label_texto_informa: Label = %LabelTextoInforma
# estados de pausa
var yo_pause: bool = false
var peer_que_pauso: int = 0

# PANEL DE USUARIOS AMIGOS
# lista de los conectados en el servidor, y barra de vida de ellos con forma de circulo
@onready var usuarios_vida: MarginContainer = $UsuariosVida
@onready var lista_usuarios: HBoxContainer = %ListaUsuarios  # esta lista esta dentro del margin container de usuarios vida
const PANEL_USUARIO = preload("uid://cjpe82p33f0c6")
var paneles_usuarios:Dictionary = {}

# tiempo
@onready var label_tiempo: Label = %LabelTiempo


# vida barra experiencia, monedas
@onready var control_vida: VBoxContainer = %ControlVida
@onready var etiqueta_nombre: Label = %EtiquetaNombre
@onready var etiqueta_salud: Label = %EtiquetaSalud
@onready var barra_salud: ProgressBar = %BarraSalud
@onready var barra_experiencia: ProgressBar = %BarraExperiencia

@onready var controls_root: VBoxContainer = %ControlsRoot

var COLORS: Array[Color] =[ # colores de la barra de vida
	Color.MAGENTA,
	Color.CRIMSON,
	Color.GREEN,
	Color.SKY_BLUE
]

func _ready() -> void:
	if OS.has_feature("mobile"):
		await get_tree().process_frame 
		menu.show()
	else:
		menu.hide() # los botones de salir y pausa
		
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	# BOTON SALIR
	boton_salir.pressed.connect(func(): Network.leave_server())
	#BOTON PAUSA
	boton_pausa.pressed.connect(_on_boton_pausa_pressed)
	# BOTON REGRESAR
	boton_regresar.pressed.connect(_on_boton_regresar_pressed)
	pausa_panel.visible = false # NO MOSTRAR LA PAUSA
	
	if GlobalSignal.has_signal("pausa_cambiada"):
		GlobalSignal.pausa_cambiada.connect(_on_pausa_cambiada)
		

	for single_color in COLORS:
		var new_texture = GradientTexture2D.new()
		var gradient = Gradient.new()
		gradient.add_point(0, single_color)
		gradient.remove_point(1)
		new_texture.gradient = gradient	

	
	#salud perosanje
	barra_salud.max_value = GlobalJuego.salud_maxima
	barra_salud.value = GlobalJuego.salud_jugador
	# señales de salud
	GlobalSignal.salud_jugador_cambiada.connect(_actualizar_barra_salud)
	GlobalSignal.sesion_actualizada.connect(_actualizar_info_sesion)
	GlobalSignal.jugador_recibio_daño.connect(_mostrar_daño)
	#experiencia  perosanje
	barra_experiencia.max_value = GlobalJuego.experiencia_maxima
	barra_experiencia.value = GlobalJuego.experiencia
	GlobalSignal.experiencia_jugador_cambiada.connect(_actualizar_experiencia)

	if GlobalJuego.nombre_jugador:
		etiqueta_nombre.text = GlobalJuego.nombre_jugador
	
	# señales
	GlobalSignal.sesion_actualizada.connect(_actualizar_paneles_aliados)
	if GlobalSignal.has_signal("jugador_recibio_daño"):
		GlobalSignal.jugador_recibio_daño.connect(_on_jugador_recibio_daño)
	
	# Y para cuando la salud cambia:
	if GlobalSignal.has_signal("salud_jugador_cambiada"):
		GlobalSignal.salud_jugador_cambiada.connect(_on_salud_jugador_cambiada)
	
	_actualizar_barra_salud(GlobalJuego.salud_jugador)
	
	_verificar_si_es_mobile()
	await get_tree().create_timer(0.5).timeout
	_actualizar_paneles_aliados(GlobalJuego.session_info)
	
	process_mode = Node.PROCESS_MODE_ALWAYS # ESTO HARA QUE SIGA PROCESANDO EL CANVAS LAYER, NO SE QUE TAN BUENO SEA


func _verificar_si_es_mobile() -> void:
	if OS.has_feature("mobile"):
		var ui_movil = preload("uid://wsf5ahon4ims")
		var ui_movil_actual = ui_movil.instanciate()
		add_child(ui_movil_actual)

	
func _actualizar_paneles_aliados(info:Dictionary)-> void:
	if not lista_usuarios:
		print("ERROR: contenedor_aliados no está configurado")
		return
	var mi_id = multiplayer.get_unique_id()
	var ids_remotos: Array = []
	
	for peer_id in info.keys(): # recorrer todos los jugadores de la sesión
		if peer_id == mi_id:
			continue  # no mostrar el status del mismo jugador
		
		ids_remotos.append(peer_id)
		var player_info = info[peer_id]
		var nombre = player_info.get("username", "Jugador " + str(peer_id))
		var salud = player_info.get("salud", GlobalJuego.SALUD_DEFAULT)
		var personaje = player_info.get("personaje", 1)
		
		if paneles_usuarios.has(peer_id): # si ya existe el usuario en los panelees, solo lo actualiza
			var panel = paneles_usuarios[peer_id]
			if is_instance_valid(panel):
				panel.actualizar_salud(salud)
				panel.actualizar_personaje(personaje)
		else:
			# Crear panel nuevo
			_crear_panel_aliado(peer_id, nombre, salud, GlobalJuego.SALUD_DEFAULT, personaje)
	
	# Eliminar paneles de jugadores que ya no están
	for peer_id in paneles_usuarios.keys():
		if not peer_id in ids_remotos:
			var panel = paneles_usuarios[peer_id]
			if is_instance_valid(panel):
				panel.queue_free()
			paneles_usuarios.erase(peer_id)

func _crear_panel_aliado(peer_id: int, nombre: String, salud: int, salud_max: int, personaje: int) -> void:
	var panel = PANEL_USUARIO.instantiate()
	lista_usuarios.add_child(panel) # agregarlo antes de configurar
	await  get_tree().process_frame
	panel.configurar(peer_id, salud, salud_max, personaje)
	paneles_usuarios[peer_id] = panel
	#print("session info: ", GlobalJuego.session_info)

func _actualizar_barra_salud(nueva_salud: int):
	barra_salud.value = nueva_salud
	etiqueta_salud.text = str(nueva_salud) + " / " + str(barra_salud.max_value)
	
	# cambiar color según la salud
	if nueva_salud > barra_salud.max_value * 0.5:
		barra_salud.modulate = Color.GREEN
	elif nueva_salud > barra_salud.max_value * 0.25:
		barra_salud.modulate = Color.YELLOW
	else:
		barra_salud.modulate = Color.RED

func _actualizar_experiencia(nueva_exp:int):
	barra_experiencia.value = nueva_exp

func _actualizar_info_sesion(info: Dictionary):
	var jugador_local_id = multiplayer.get_unique_id()
	
	if info.has(jugador_local_id):
		var mi_info = info[jugador_local_id]
		_actualizar_barra_salud(mi_info["salud"])

func _mostrar_daño(peer_id: int, cantidad: int):
	if peer_id == multiplayer.get_unique_id():
		# seria genial mostrar efecto de daño en pantalla
		print("Recibiste ", cantidad, " de daño")

# SEÑALES FUNCIONEs
func _on_jugador_recibio_daño(peer_id: int, cantidad: int):
	# Refrescar el panel de ese jugador específico
	if paneles_usuarios.has(peer_id):
		var info = GlobalJuego.session_info.get(peer_id, {})
		var nueva_salud = info.get("salud", GlobalJuego.SALUD_DEFAULT)
		paneles_usuarios[peer_id].actualizar_salud(nueva_salud)

func _on_salud_jugador_cambiada(nueva_salud: int):
	# Este es del jugador local, pero por si acaso refrescamos todos
	_actualizar_paneles_aliados(GlobalJuego.session_info)

# PAUSA
# para manejar la pausa se debe usar el rpc en network
func _on_boton_pausa_pressed() -> void:
	# Si ya está pausado y NO soy el que pausó, no permitir
	if Network.pausa_activa and not yo_pause:
		return
	
	# Si está pausado y soy yo, despausar
	if Network.pausa_activa and yo_pause:
		Network.solicitar_pausa.rpc(false)
		return
	
	# Pausar
	Network.solicitar_pausa.rpc(true)

func _on_boton_regresar_pressed() -> void:
	# Solo puede despausar quien pausó
	if not yo_pause:
		return
	Network.solicitar_pausa.rpc(false)
	
	menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_pausa_cambiada(esta_pausado: bool, quien_pauso: int) -> void:
	peer_que_pauso = quien_pauso
	yo_pause = (quien_pauso == multiplayer.get_unique_id())
	
	pausa_panel.visible = esta_pausado
	
	if esta_pausado:
		# Actualizar el texto
		var nombre_pausador = "Alguien"
		if GlobalJuego.session_info.has(quien_pauso):
			nombre_pausador = GlobalJuego.session_info[quien_pauso].get("username", "Jugador " + str(quien_pauso))
		
		if yo_pause:
			label_texto_informa.text = "Pausaste el juego.\nPresiona el botón para continuar."
			boton_regresar.visible = true
		else:
			label_texto_informa.text = nombre_pausador + " ha pausado el juego.\nEspera a que continúe."
			boton_regresar.visible = false
	else:
		label_texto_informa.text = ""
		boton_regresar.visible = false

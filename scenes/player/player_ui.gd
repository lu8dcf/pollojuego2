extends CanvasLayer

class_name PlayerUI

@onready var menu: Control = %Menu
@onready var button_copy_session: Button = %ButtonCopySession
@onready var boton_salir: Button = %BotonSalir # para salir del servidor

# lista de los conectados en el servidor, y barra de vida de ellos
@onready var lista_usuarios: ItemList = %ListaUsuarios

# vida
@onready var control_vida: VBoxContainer = %ControlVida
@onready var etiqueta_nombre: Label = %EtiquetaNombre
@onready var etiqueta_salud: Label = %EtiquetaSalud
@onready var barra_salud: ProgressBar = %BarraSalud
@onready var boton_empezar_ronda: Button = %BotonEmpezarRonda
@onready var label_session: Label = %LabelSession
@onready var barra_experiencia: ProgressBar = %BarraExperiencia

@onready var controls_root: VBoxContainer = %ControlsRoot

var COLORS: Array[Color] =[ # colores de la barra de vida
	Color.MAGENTA,
	Color.CRIMSON,
	Color.GREEN,
	Color.SKY_BLUE
]

func _ready() -> void:
	#menu.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	boton_salir.pressed.connect(func(): Network.leave_server())
	button_copy_session.pressed.connect(func(): DisplayServer.clipboard_set(Network.tube_client.session_id))
	DisplayServer.clipboard_set(Network.tube_client.session_id)
	if !GlobalJuego.un_jugador:
		label_session.text = "ID Sesion: "+Network.tube_client.session_id

	for single_color in COLORS:
		var new_texture = GradientTexture2D.new()
		var gradient = Gradient.new()
		gradient.add_point(0, single_color)
		gradient.remove_point(1)
		new_texture.gradient = gradient	

	# username, score
	lista_usuarios.max_columns = 2
	lista_usuarios.same_column_width = true
	lista_usuarios.auto_height = true
	lista_usuarios.auto_width = true
	
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
		
	GlobalSignal.sesion_actualizada.connect(render_lista_usuarios)
	_actualizar_barra_salud(GlobalJuego.salud_jugador)
#
#
	#boton_empezar_ronda.pressed.connect(Global.crystal_game_start)


func render_lista_usuarios(new_info: Dictionary):
	lista_usuarios.clear()
	for peer_id in new_info.keys():
		var player_info = new_info[peer_id]
		
		lista_usuarios.add_item(player_info.username)
		lista_usuarios.add_item(str(player_info.score))

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

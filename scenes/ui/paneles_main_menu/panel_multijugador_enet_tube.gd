extends PanelContainer
# panel multijugador enet_tube


# subpaneles
@onready var sub_panel_online: Control = %PanelMultijugador
@onready var sub_panel_local: Control = %PanelMultijugadorEnet

# Botones de selección
@onready var boton_online: TextureButton = %BotonOnline
@onready var boton_local: TextureButton = %BotonLocal
#@onready var boton_volver: Button = %BotonVolver

# online tube
@onready var edit_nombre_tube: LineEdit = %EditNombreTube
@onready var edit_sesion: LineEdit = %EditSesion
@onready var boton_unirse_tube: Button = %BotonUnirseTube
@onready var boton_crear_tube: Button = %BotonCrearPartidaTube

# local
@onready var edit_ip: LineEdit = %EditIp
@onready var edit_puerto: LineEdit = %EditPuerto
@onready var edit_nombre_enet: LineEdit = %EditNombreEnet
@onready var boton_unirse_lan: Button = %BotonUnirseEnet
@onready var boton_crear_lan: Button = %BotonCrearPartidaEnet
# solo en caso de ser web, esconder modo enet
@onready var label_web: Label = %LabelWeb
@onready var h_box_container: HBoxContainer = %HBoxContainer

func _ready() -> void:
	sub_panel_online.visible = false
	sub_panel_local.visible = false
	
	label_web.visible = false
	if OS.has_feature("web"):
		label_web.visible= true
		h_box_container.visible=false
	# botones de modo
	boton_online.pressed.connect(_mostrar_online)
	boton_local.pressed.connect(_mostrar_local)
	#boton_volver.pressed.connect(func(): solicitar_volver.emit())
	
	# Online
	boton_unirse_tube.disabled = true
	edit_sesion.text_changed.connect(_on_sesion_text_changed)

	boton_unirse_tube.pressed.connect(_on_unirse_tube)
	if not boton_crear_tube.pressed.is_connected(_on_crear_tube):
		boton_crear_tube.pressed.connect(_on_crear_tube)
	
	# parte local
	boton_unirse_lan.disabled = true
	edit_ip.text_changed.connect(_validar_lan)
	edit_puerto.text_changed.connect(_validar_lan)
	boton_unirse_lan.pressed.connect(_on_unirse_lan)
	boton_crear_lan.pressed.connect(_on_crear_lan)

func _validar_lan(_t: String) -> void:
	boton_unirse_lan.disabled = edit_ip.text.strip_edges() == "" or edit_puerto.text.strip_edges() == ""

func _mostrar_online() -> void:
	sub_panel_online.visible = true
	sub_panel_local.visible = false

func _mostrar_local() -> void:
	sub_panel_online.visible = false
	sub_panel_local.visible = true

# NOMBRE Y UNIRSE O CREAR SESION DE TUBE
func _nombre_actual_tube() -> String:
	if edit_nombre_tube.text.strip_edges() != "":
		return edit_nombre_tube.text.strip_edges()
	var nombre_azar = obtener_nombre_azar()
	
	return GlobalJuego.nombre_jugador if GlobalJuego.nombre_jugador != "" else nombre_azar


func _on_sesion_text_changed(texto:String)->void:
	var mayus = texto.to_upper()
	if mayus != texto:
		var caret := edit_sesion.caret_column
		edit_sesion.text = mayus
		edit_sesion.caret_column = caret
	boton_unirse_tube.disabled = mayus.strip_edges() == ""



func _on_unirse_tube() -> void:
	var session = edit_sesion.text.strip_edges().to_upper()
	if session == "":
		return
	GlobalSignal.solicitar_unirse_tube.emit(session, _nombre_actual_tube())

func _on_crear_tube() -> void:
	GlobalSignal.solicitar_crear_tube.emit(_nombre_actual_tube())

# NOMBRE Y UNIRSE O CREAR SESION DE ENET

func _nombre_actual_enet() -> String:
	if edit_nombre_enet.text.strip_edges() != "":
		return edit_nombre_enet.text.strip_edges()
	var nombre_azar = obtener_nombre_azar()
	
	return GlobalJuego.nombre_jugador if GlobalJuego.nombre_jugador != "" else nombre_azar

func _on_unirse_lan() -> void:
	var ip = edit_ip.text.strip_edges()
	var puerto_str = edit_puerto.text.strip_edges()
	#if ip == "" or not puerto_str.is_valid_int():
		#return
	GlobalSignal.solicitar_unirse_lan.emit(ip, int(puerto_str), _nombre_actual_enet())

func _on_crear_lan() -> void:
	var puerto_str = edit_puerto.text.strip_edges()
	if not puerto_str.is_valid_int():
		return
	GlobalSignal.solicitar_crear_lan.emit(int(puerto_str), _nombre_actual_enet())


func obtener_nombre_azar():
	var nombres = ["Iku","Len","Yue","Zaci","Vati","Babu","Michu","Blacky","Sanson","Violeta"]
	return nombres.pick_random()

extends CanvasLayer
# pantalla perder
const PANEL_PUNTAJE = preload("res://scenes/ui/panel_puntaje.tscn")
@onready var label_titulo: Label = %LabelTitulo
@onready var h_box_contenedor_puntajes: HBoxContainer = %HBoxContenedorPuntajes
#@onready var boton_lobby: TextureButtonAnimado = %BotonLobby
#@onready var boton_menu: TextureButtonAnimado = %BotonMenu
@onready var boton_lobby: TouchScreenButton = %BotonLobbyTouch
@onready var boton_menu: TouchScreenButton = %BotonMenuTouch


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # siempre se procesa aunque el arbol este en pausa
	hide() # se muestra solo cuano llega la señal
	if not GlobalSignal.partida_perdida.is_connected(_on_partida_perdida):
		GlobalSignal.partida_perdida.connect(_on_partida_perdida)
	
	# conectar botones
	boton_menu.pressed.connect(_on_boton_menu_pressed)
	boton_lobby.pressed.connect(_on_boton_lobby_pressed)
	
	
	
func _on_partida_perdida(puntajes:Array):
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_configurar_botones()
	for child in h_box_contenedor_puntajes.get_children():
		h_box_contenedor_puntajes.remove_child(child)
		child.queue_free()
	var mi_id:=1
	if multiplayer.has_multiplayer_peer():
		mi_id = multiplayer.get_unique_id() # si es multijugador entonces cambia el 1 por el peer del mutiplayer
	var posicion:=1
	for datos in puntajes:
		var panel = PANEL_PUNTAJE.instantiate()
		h_box_contenedor_puntajes.add_child(panel)
		var es_local:bool =(datos.get("peer_id",1)==mi_id) #devuelve true o false para saber si es su panel
		panel.configurar(posicion, datos,es_local)
		posicion+=1

func _on_boton_menu_pressed():
	# volver al menu principal y cerrar conexion
	Network.leave_server() 
	

func _on_boton_lobby_pressed():
	# quedarse 
	if not multiplayer.has_multiplayer_peer():
		return
	if not multiplayer.is_server():
		return
	Network.host_volver_al_lobby()


func _configurar_botones() -> void:
	# Single player
	if GlobalJuego.un_jugador:
		boton_lobby.hide()
		boton_menu.show()
		boton_menu.disabled = false
		return

	# Multijugador: hay peer?
	var hay_peer := multiplayer.has_multiplayer_peer()
	var soy_host := hay_peer and multiplayer.is_server()

	if soy_host:
		# hostt: puede ir al lobby, ir al menu cortaria la partida
		boton_lobby.cambiar_texto("Ir al lobby")
		boton_lobby.disabled = false
		boton_lobby.show()

		#boton_menu.hide() 
		boton_menu.show()
		# boton_menu.disabled = false
	else:
		# Cliente: no puede ir al lobby (lo decide el host)
		boton_lobby.cambiar_texto("Esperar al HOST")
		boton_lobby.disabled = true
		boton_lobby.show()

		boton_menu.show()
		boton_menu.disabled = false

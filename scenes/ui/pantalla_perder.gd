extends CanvasLayer

const PANEL_PUNTAJE = preload("res://scenes/ui/panel_puntaje.tscn")
@onready var label_titulo: Label = %LabelTitulo
@onready var v_box_contenedor_puntajes: VBoxContainer = %VBoxContenedorPuntajes
@onready var boton_lobby: TextureButtonAnimado = %BotonLobby
@onready var boton_menu: TextureButtonAnimado = %BotonMenu


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
	for child in v_box_contenedor_puntajes.get_children():
		child.queue_free()
	var mi_id:=1
	if multiplayer.has_multiplayer_peer():
		mi_id = multiplayer.get_unique_id() # si es multijugador entonces cambia el 1 por el peer del mutiplayer
		var posicion:=1
		for datos in puntajes:
			var panel = PANEL_PUNTAJE.instantiate()
			v_box_contenedor_puntajes.add_child(panel)
			var es_local:bool =(datos.get("peer_id",1)==mi_id) #devuelve true o false para saber si es su panel
			panel.configurar(posicion, datos,es_local)
			posicion+=1

func _on_boton_menu_pressed():
	Network.leave_server()

func _on_boton_lobby_pressed():
	hide()

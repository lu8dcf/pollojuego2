extends Control
@onready var v_box_contenedor_puntajes: VBoxContainer = %VBoxContenedorPuntajes

const PANEL_TIENDA_ALIADOS = preload("res://scenes/ui/panel_tienda_aliados.tscn")

func _ready() -> void:
	hide() # se muestra solo cuano llega la señal
	if not GlobalSignal.tienda_abierta.is_connected(_on_oleada_terminada_tienda):
		GlobalSignal.tienda_abierta.connect(_on_oleada_terminada_tienda)
	if not GlobalSignal.cambia_oleada.is_connected(_on_cambia_oleada):
		GlobalSignal.cambia_oleada.connect(_on_cambia_oleada)


func _on_oleada_terminada_tienda(puntajes:Array):
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	for child in v_box_contenedor_puntajes.get_children():
		v_box_contenedor_puntajes.remove_child(child)
		child.queue_free()
	var mi_id:=1
	if multiplayer.has_multiplayer_peer():
		mi_id = multiplayer.get_unique_id() # si es multijugador entonces cambia el 1 por el peer del mutiplayer
	var posicion:=1
	for datos in puntajes:
		var panel = PANEL_TIENDA_ALIADOS.instantiate()
		v_box_contenedor_puntajes.add_child(panel)
		var es_local:bool =(datos.get("peer_id",1)==mi_id) #devuelve true o false para saber si es su panel
		panel.configurar(posicion, datos,es_local)
		posicion+=1


func _on_cambia_oleada() -> void:
	hide()

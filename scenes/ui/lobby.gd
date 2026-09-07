extends CanvasLayer

@onready var label_id: Label = %LabelId

#contenedor general de jugadores 
@onready var margin_contenedor_jugadores: MarginContainer = %MarginContenedorJugadores

#contenedor de jugadores
@onready var h_box_jugadores: HBoxContainer = %HBoxJugadores
@onready var jugador_1: Panel = %Jugador1

func _ready() -> void:
	mostrar_usuarios()

func mostrar_usuarios():
	if GlobalJuego.un_jugador:
		label_id.hide() # no mostrar el id porque no existira.
	else:
		label_id.text = "ID: "+Network.tube_client.session_id

extends CanvasLayer


signal cancelado
@onready var label_cargando: Label = %LabelCargando
@onready var progreso: ProgressBar = %Progreso
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var boton_cancelar: AnimatedButton = %BotonCancelar
@onready var label_estado_jugadores: Label = %LabelEstadoJugadores
@onready var jugadores: HBoxContainer = %Jugadores

var jugadores_listos :Dictionary = {}
var total_jugadores :int = 1
func _ready() -> void:
	visible = true
	animated_sprite_2d.play("cargando")
	boton_cancelar.pressed.connect(_on_cancelar_pressed)
	
	label_estado_jugadores.text = "0/" + str(total_jugadores) + " listos"
	progreso.max_value = 100
	progreso.value = 0

func configurar_jugadores(lista_peers_ids:Array) -> void:
	total_jugadores = lista_peers_ids.size()
	jugadores_listos.clear()
	
	for c in jugadores.get_children():
		c.queue_free()
	
	# crear un label por jugador
	for peer_id in lista_peers_ids:
		var label = Label.new()
		label.name = "Jugador_" + str(peer_id)
		label.text = "⏳ " + str(peer_id)
		jugadores.add_child(label)
		jugadores_listos[peer_id] = false
	
	_actualizar_contador()

func marcar_jugador_listo(peer_id: int) -> void:
	if jugadores_listos.has(peer_id):
		jugadores_listos[peer_id] = true
		
		# Actualizar el label visual
		var label = jugadores.get_node_or_null("Jugador_" + str(peer_id))
		if label:
			label.text = "✅ " + str(peer_id)
	
	_actualizar_contador()

func _actualizar_contador() -> void:
	var listos = 0
	for v in jugadores_listos.values():
		if v:
			listos += 1
	
	label_estado_jugadores.text = str(listos) + "/" + str(total_jugadores) + " listos"
	progreso.value = (float(listos) / float(total_jugadores)) * 100.0
	
	if listos >= total_jugadores:
		label_cargando.text = "¡Todos listos!"


func mensaje(texto: String) -> void:
	if label_cargando:
		label_cargando.text = texto

func _on_cancelar_pressed() -> void:
	cancelado.emit()

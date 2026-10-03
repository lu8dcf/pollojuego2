extends CanvasLayer
#pantalla de carga

signal cancelado
@onready var label_cargando: Label = %LabelCargando
@onready var progreso: ProgressBar = %Progreso
@onready var animated_sprite_2d: AnimatedSprite2D = %AnimatedSprite2D
@onready var boton_cancelar: AnimatedButton = %BotonCancelar
@onready var label_estado_jugadores: Label = %LabelEstadoJugadores
@onready var jugadores: HBoxContainer = %Jugadores

# panel de error - manejo de errores
@onready var panel_error: PanelContainer = %PanelError
@onready var label_titulo_error: Label = %LabelTituloError
@onready var label_info_error: Label = %LabelInfoError
@onready var boton_volver: AnimatedButton = %BotonVolver

var jugadores_listos :Dictionary = {}
var total_jugadores :int = 1

func _ready() -> void:
	layer=100
	visible = true
	panel_error.visible = false
	animated_sprite_2d.play("cargando")
	# conectar señales de botonces
	boton_cancelar.pressed.connect(_on_cancelar_pressed)
	boton_volver.pressed.connect(_on_boton_volver_pressed)
	
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

# botones funciones
func _on_cancelar_pressed() -> void:
	cancelado.emit()
	
func _on_boton_volver_pressed() -> void:
	cancelado.emit()

func ocultar()->void:
	hide()


# ------------------------------------------------------------
# MOSTRAR ERROR
# ------------------------------------------------------------
func mostrar_error(mensaje1:String,titulo:String = "Error") -> void:
	# Ocultar todo lo de carga
	animated_sprite_2d.visible = false
	label_cargando.visible = false
	progreso.visible = false
	label_estado_jugadores.visible = false
	jugadores.visible = false
	boton_cancelar.visible = false
	
	# Mostrar el panel de error
	panel_error.visible = true
	label_titulo_error.text = titulo
	label_info_error.text = mensaje1
	

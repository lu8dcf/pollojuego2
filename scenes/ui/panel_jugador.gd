extends Panel

@onready var nombre_usuario: Label = $NombreUsuario
@onready var estoy_listo_boton: TextureButtonAnimado = $ContenedorBoton/EstoyListoBoton
@onready var indicador_listo: Label = $IndicadorListo  # Necesitas crear este Label en la escena

#botones adelante y atras
@onready var cambiar_atras_personaje: TextureButton = %CambiarAtrasPersonaje
@onready var cambiar_adelante_personaje: TextureButton = %CambiarAdelantePersonaje

# personaje
@onready var sprite_personaje: AnimatedSprite2D = %SpritePersonaje
var id_personaje:int=1
var cant_personajes:int = 2
var indice_personaje :int = 1
var peer_id: int = 0

# cada perosnjae tiene vida, ataque y defensa, 0 = nada, y 3 al maximo
var personajes : Dictionary ={
	1: [1,1,1],
	2: [2,3,0]
}
@onready var vida: TextureRect = $HabilidadesPersonaje/HBoxContainer/Vida
@onready var ataque: TextureRect = $HabilidadesPersonaje/HBoxContainer/Ataque
@onready var defensa: TextureRect = $HabilidadesPersonaje/HBoxContainer/Defensa



var nombre: String = ""
var esta_listo: bool = false
var es_mi_panel: bool = false

func _ready() -> void:

	sprite_personaje.play("sapo1")
	_actualizar_habilidades(1)
	if estoy_listo_boton:
		estoy_listo_boton.disabled = true
	
	# Configurar indicador visual
	if indicador_listo:
		indicador_listo.text = ""
		indicador_listo.visible = false
	
	# los botones deben ser seleccionados solo para su panel
	conectar_verificar_botones()

func conectar_verificar_botones() -> void:
	await get_tree().create_timer(1.0).timeout

	if cambiar_adelante_personaje:
		cambiar_adelante_personaje.disabled = not es_mi_panel
		cambiar_adelante_personaje.visible = es_mi_panel
	
	if cambiar_atras_personaje:
		cambiar_atras_personaje.disabled = not es_mi_panel
		cambiar_atras_personaje.visible = es_mi_panel
	if not cambiar_adelante_personaje.pressed.is_connected(cambiar_personaje):
		cambiar_adelante_personaje.pressed.connect(cambiar_personaje.bind(1))
	if not cambiar_atras_personaje.pressed.is_connected(cambiar_personaje):
		cambiar_atras_personaje.pressed.connect(cambiar_personaje.bind(-1))
	

func cambiar_personaje(direccion:int):
	
	id_personaje += direccion
	if id_personaje > cant_personajes:
		id_personaje = 1
	elif id_personaje < 1:
		id_personaje = cant_personajes
	_reproducir_personaje(id_personaje)
	_actualizar_habilidades(id_personaje)
	
	# Notificar al lobby para que se sincronice con todos
	var lobby = get_tree().get_first_node_in_group("lobby")
	if lobby and lobby.has_method("notificar_cambio_personaje"):
		lobby.notificar_cambio_personaje(peer_id, id_personaje)

func _reproducir_personaje(id_personaje):
	if sprite_personaje:
		sprite_personaje.play("sapo" + str(id_personaje))
	_actualizar_habilidades(id_personaje)
	
func _actualizar_habilidades(id_personaje: int) -> void:
	if not personajes.has(id_personaje):
		return
	
	var stats = personajes[id_personaje]
	_aplicar_opacidad(vida, stats[0])
	_aplicar_opacidad(ataque, stats[1])
	_aplicar_opacidad(defensa, stats[2])

func _aplicar_opacidad(texture_rect: TextureRect, nivel: int) -> void:
	if not texture_rect:
		return
	
	# Mapear nivel 0-3 a un alpha de 0.15 a 1.0
	match nivel:
		0: texture_rect.modulate.a = 0.15   # Casi invisible
		1: texture_rect.modulate.a = 0.4    # Poco visible
		2: texture_rect.modulate.a = 0.7    # Visible
		3: texture_rect.modulate.a = 1.0    # Totalmente visible
		_: texture_rect.modulate.a = 0.15

func actualizar_info(id: int, nombre_jugador: String,personaje: int = 1):
	peer_id = id
	nombre = nombre_jugador
	id_personaje = personaje
	# Determinar si es el panel del jugador local
	es_mi_panel = (peer_id == multiplayer.get_unique_id() or (peer_id == 1 and multiplayer.is_server()))
		
	if nombre_usuario:
		nombre_usuario.text = nombre_jugador
	
	_reproducir_personaje(id_personaje)

	if estoy_listo_boton:
		# Solo habilitar el botón si es mi panel
		estoy_listo_boton.disabled = not es_mi_panel
		estoy_listo_boton.visible = es_mi_panel  # Solo mostrar botón en tu panel
	
	conectar_verificar_botones()
	# Actualizar indicador visual
	_actualizar_indicador()

func actualizar_estado_listo(estado: bool):
	"""Actualiza el estado visual de listo sin emitir RPC"""
	esta_listo = estado
	_actualizar_indicador()
	
	if estoy_listo_boton:
		estoy_listo_boton.cambiar_texto("¡Listo!" if estado else "¿Listo?")

# esto solo sincroniza los perosnajes de los demas
func actualizar_personaje_remoto(id: int) -> void:
	id_personaje = id
	_reproducir_personaje(id)

func _actualizar_indicador():
	if indicador_listo:
		if esta_listo:
			indicador_listo.text = "✓ Listo"
			indicador_listo.modulate = Color.GREEN
			indicador_listo.visible = true
		else:
			if es_mi_panel:
				indicador_listo.text = "○ En espera"
				indicador_listo.modulate = Color.YELLOW
				indicador_listo.visible = true
			else:
				indicador_listo.text = "○ En espera"
				indicador_listo.modulate = Color.GRAY
				indicador_listo.visible = true

func marcar_listo():
	esta_listo = true
	if estoy_listo_boton:
		estoy_listo_boton.cambiar_texto("¡Listo!")
	_actualizar_indicador()
	# Emitir señal para notificar al lobby
	_notificar_estado_listo.rpc(peer_id, true)

func marcar_no_listo():
	esta_listo = false
	if estoy_listo_boton:
		estoy_listo_boton.cambiar_texto("¿Listo?")
	_actualizar_indicador()
	# Emitir señal para notificar al lobby
	_notificar_estado_listo.rpc(peer_id, false)

func _on_estoy_listo_boton_pressed() -> void:
	# Solo permitir si es mi panel
	if not es_mi_panel:
		print("No puedes modificar el panel de otro jugador")
		return
	
	if esta_listo:
		marcar_no_listo()
	else:
		marcar_listo()

# RPC para notificar a todos sobre el estado de listo
@rpc("any_peer", "call_local", "reliable")
func _notificar_estado_listo(peer_id_jugador: int, estado: bool):
	# Buscar el lobby y actualizar
	var lobby = get_tree().get_first_node_in_group("lobby")
	if lobby:
		lobby.actualizar_estado_listo(peer_id_jugador, estado)

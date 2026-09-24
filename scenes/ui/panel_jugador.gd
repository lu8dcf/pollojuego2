extends Panel

@onready var nombre_usuario: Label = $NombreUsuario
@onready var estoy_listo_boton: TextureButtonAnimado = $ContenedorBoton/EstoyListoBoton
@onready var indicador_listo: Label = $IndicadorListo  

#botones adelante y atras
@onready var cambiar_atras_opcion: TextureButton = %CambiarAtrasPersonaje
@onready var cambiar_adelante_opcion: TextureButton = %CambiarAdelantePersonaje

# botones de eleccion de personaje o armas
@onready var arma_eleccion: TextureButton = %ArmaEleccion
@onready var personaje_eleccion: TextureButton = %PersonajeEleccion
@onready var sprite_seleccion: AnimatedSprite2D = %SpriteSeleccion

# personaje
@onready var sprite_personaje: AnimatedSprite2D = %SpritePersonaje
@onready var h_box_habilidades_personaje: HBoxContainer = %HBoxHabilidadesPersonaje
var id_personaje:int=1
var cant_personajes:int = 5
var indice_personaje :int = 1
var peer_id: int = 0

#armas
@onready var sprite_arma: AnimatedSprite2D = %SpriteArma
@onready var h_box_habilidades_arma: HBoxContainer = %HBoxHabilidadesArma
var id_arma:int=1
var cant_armas:int = 3
var indice_arma :int = 1

# cada perosnjae tiene vida, ataque y defensa, 0 = nada, y 3 al maximo
var personajes : Dictionary ={
	1: [1,1,1],
	2: [2,3,0],
	3: [2,0,2],
	4: [0,3,1],
	5: [2,0,1],
	
}
@onready var vida: TextureRect = $HabilidadesPersonaje/HBoxHabilidadesPersonaje/Vida
@onready var ataque: TextureRect = $HabilidadesPersonaje/HBoxHabilidadesPersonaje/Ataque
@onready var defensa: TextureRect = $HabilidadesPersonaje/HBoxHabilidadesPersonaje/Defensa


# cada arma tiene velocidad, explosion y daño, 0 = nada, y 3 al maximo
var armas : Dictionary ={
	1: [1,1,1],
	2: [3,0,2],
	3: [0,3,2],
}
@onready var velocidad: TextureRect = $HabilidadesPersonaje/HBoxHabilidadesArma/Velocidad
@onready var explosivo: TextureRect = $HabilidadesPersonaje/HBoxHabilidadesArma/Explosivo
@onready var daño: TextureRect = $HabilidadesPersonaje/HBoxHabilidadesArma/Daño

# nombre del arma o del perosanje
@onready var nombre_personaje_arma: Label = %NombrePersonajeArma
var nombres_personajes:Dictionary={
	1:"arturo",
	2:"zuly",
	3:"pinky",
	4:"iku",
	5:"claudio"
}

var nombres_armas:Dictionary={
	1:"piu piu",
	2:"Afilatriz",
	3:"¿Bazooca?"
}

# lo que se muestra a los demas jugadores:
@onready var sprite_arma_mostrar: AnimatedSprite2D = %SpriteArmaMostrar



var nombre: String = ""
var esta_listo: bool = false
var es_mi_panel: bool = false

func _ready() -> void:
	$".".hide() # lo oculto apra que cargue perfecto de 0
	sprite_personaje.play("idle1")
	_actualizar_habilidades(indice_personaje)
	_actualizar_nombre(indice_arma)
	nombre_personaje_arma.text="arturo"
	if estoy_listo_boton:
		estoy_listo_boton.disabled = true
	
	if indicador_listo:
		indicador_listo.text = ""
		indicador_listo.visible = false
	
	# los botones deben ser seleccionados solo para su panel
	
	conectar_verificar_botones()

func conectar_verificar_botones() -> void:
	await get_tree().create_timer(0.5).timeout
	$".".show()
	
	# TODOS LOS BOTONES SOLO SE MUESTRAN SI ES EL PANEL CORRESPONDIENTE
	if cambiar_adelante_opcion:
		cambiar_adelante_opcion.disabled = not es_mi_panel
		cambiar_adelante_opcion.visible = es_mi_panel
	
	if cambiar_atras_opcion:
		cambiar_atras_opcion.disabled = not es_mi_panel
		cambiar_atras_opcion.visible = es_mi_panel
		
	if arma_eleccion:
		arma_eleccion.disabled = not es_mi_panel
		arma_eleccion.visible = es_mi_panel
	if personaje_eleccion:
		personaje_eleccion.disabled = not es_mi_panel
		personaje_eleccion.visible = es_mi_panel
	# el sprite arma mostrar es SOLO para los demas jugadores
	# es para que sepan el arma que tiene el otro
	if sprite_arma_mostrar:
		sprite_arma_mostrar.visible = not es_mi_panel
		
	if not cambiar_adelante_opcion.pressed.is_connected(cambiar_personaje_arma):
		cambiar_adelante_opcion.pressed.connect(cambiar_personaje_arma.bind(1))
	if not cambiar_atras_opcion.pressed.is_connected(cambiar_personaje_arma):
		cambiar_atras_opcion.pressed.connect(cambiar_personaje_arma.bind(-1))
		
	if not personaje_eleccion.pressed.is_connected(se_selecciona_personajes):
		personaje_eleccion.pressed.connect(se_selecciona_personajes)
	if not arma_eleccion.pressed.is_connected(se_selecciona_armas):
		arma_eleccion.pressed.connect(se_selecciona_armas)
	# primero mostrar el perosnaje y despues las armas
	sprite_personaje.visible = true
	sprite_arma.visible = false
	sprite_seleccion.visible = false
	
func se_selecciona_personajes() -> void:
	
	sprite_personaje.visible = true
	sprite_arma.visible = false
	sprite_seleccion.visible = false
	h_box_habilidades_arma.visible=false
	h_box_habilidades_personaje.visible=true
	_actualizar_nombre(indice_personaje)
	
func se_selecciona_armas() -> void:
	sprite_personaje.visible = false
	sprite_arma.visible = true
	sprite_seleccion.visible = false
	h_box_habilidades_arma.visible=true
	h_box_habilidades_personaje.visible=false
	_actualizar_nombre(indice_arma)
	

func cambiar_personaje_arma(direccion:int):
	if sprite_personaje.visible:
		id_personaje += direccion
		if id_personaje > cant_personajes:
			id_personaje = 1
		elif id_personaje < 1:
			id_personaje = cant_personajes
		_reproducir_personaje_arma(id_personaje)
		_actualizar_habilidades(id_personaje)
		indice_personaje = id_personaje
		# notificar al lobby para que se sincronice con todos
		var lobby = get_tree().get_first_node_in_group("lobby")
		if lobby and lobby.has_method("notificar_cambio_personaje_arma"):
			lobby.notificar_cambio_personaje_arma(peer_id, id_personaje,id_arma)

		
	elif sprite_arma.visible:
		id_arma += direccion
		if id_arma > cant_armas:
			id_arma = 1
		elif id_arma < 1:
			id_arma = cant_armas
		_reproducir_personaje_arma(id_arma)
		_actualizar_habilidades(id_arma)
		indice_arma = id_arma
		# notificar al lobby para que se sincronice con todos
		var lobby = get_tree().get_first_node_in_group("lobby")
		if lobby and lobby.has_method("notificar_cambio_personaje_arma"):
			lobby.notificar_cambio_personaje_arma(peer_id, id_personaje,id_arma)

	

func _reproducir_personaje_arma(id):
	if sprite_personaje.visible:
		sprite_personaje.play("idle" + str(id))
			
	elif sprite_arma.visible:
		sprite_arma.play("arma"+str(id))
	_actualizar_habilidades(id)
	_actualizar_nombre(id)

func _actualizar_nombre(id:int)->void:
	if sprite_personaje.visible:
		if nombre_personaje_arma.visible:
			if nombres_personajes.has(id):
				nombre_personaje_arma.text = nombres_personajes[id]
	elif sprite_arma.visible:
		if nombre_personaje_arma.visible:
			if nombres_armas.has(id):
				nombre_personaje_arma.text = nombres_armas[id]

func _actualizar_habilidades(id: int) -> void:
	if sprite_personaje.visible:
		if not personajes.has(id):
			return
		
		var stats = personajes[id]
		_aplicar_opacidad(vida, stats[0])
		_aplicar_opacidad(ataque, stats[1])
		_aplicar_opacidad(defensa, stats[2])
	elif sprite_arma.visible:
		if not armas.has(id):
			return
		
		var stats = armas[id]
		_aplicar_opacidad(velocidad, stats[0])
		_aplicar_opacidad(explosivo, stats[1])
		_aplicar_opacidad(daño, stats[2])

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
	# verificar si es el panel del jugador local
	es_mi_panel = (peer_id == multiplayer.get_unique_id() or (peer_id == 1 and multiplayer.is_server()))
		
	if nombre_usuario:
		nombre_usuario.text = nombre_jugador
	
	_reproducir_personaje_arma(id_personaje)
	
	if sprite_arma_mostrar:
		sprite_arma_mostrar.visible = not es_mi_panel # solo mostrar el arma elegida a los demas jugadores, no a  mi
		var info = GlobalJuego.session_info.get(peer_id,{})
		var armas_actuales:Array = info.get("armas_actuales",[])
		var arma = 1 # fallback, en caso de que no se hayan guardado armas
		if armas_actuales.size()>0:
			arma= armas_actuales[0] # toma la primer arma que encuentra
		
		actualizar_arma_remoto(arma)
			
	if estoy_listo_boton:
		# Solo habilitar el botón si es mi panel
		estoy_listo_boton.disabled = not es_mi_panel
		estoy_listo_boton.visible = es_mi_panel  # Solo mostrar botón en tu panel
	
	conectar_verificar_botones()
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
	_reproducir_personaje_arma(id)

func actualizar_arma_remoto(id:int)->void:
	id_arma = id
	if sprite_arma_mostrar:
		sprite_arma_mostrar.play("arma" + str(id))
	
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

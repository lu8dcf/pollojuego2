extends Panel

@onready var nombre_usuario: Label = $NombreUsuario
@onready var estoy_listo_boton: TextureButtonAnimado = $ContenedorBoton/EstoyListoBoton
# Añade un label o indicador visual para el estado
@onready var indicador_listo: Label = $IndicadorListo  # Necesitas crear este Label en la escena

var peer_id: int = 0
var nombre: String = ""
var esta_listo: bool = false
var es_mi_panel: bool = false

func _ready() -> void:
	print("Panel jugador _ready() - peer_id: ", peer_id)
	
	if nombre_usuario:
		print("  - Label nombre_usuario encontrado")
	
	if estoy_listo_boton:
		estoy_listo_boton.disabled = true
	
	# Configurar indicador visual
	if indicador_listo:
		indicador_listo.text = ""
		indicador_listo.visible = false

func actualizar_info(id: int, nombre_jugador: String):
	peer_id = id
	nombre = nombre_jugador
	
	# Determinar si es el panel del jugador local
	es_mi_panel = (peer_id == multiplayer.get_unique_id() or (peer_id == 1 and multiplayer.is_server()))
	
	print("Panel actualizado - ID: ", peer_id, " Nombre: ", nombre_jugador, " Es mío: ", es_mi_panel)
	
	if nombre_usuario:
		nombre_usuario.text = nombre_jugador
	
	if estoy_listo_boton:
		# Solo habilitar el botón si es mi panel
		estoy_listo_boton.disabled = not es_mi_panel
		estoy_listo_boton.visible = es_mi_panel  # Solo mostrar botón en tu panel
	
	# Actualizar indicador visual
	_actualizar_indicador()

func actualizar_estado_listo(estado: bool):
	"""Actualiza el estado visual de listo sin emitir RPC"""
	esta_listo = estado
	_actualizar_indicador()
	
	if estoy_listo_boton:
		estoy_listo_boton.cambiar_texto("¡Listo!" if estado else "¿Listo?")

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

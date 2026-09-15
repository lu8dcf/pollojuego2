extends Node3D

#Pruebo la fabrica de armas
@onready
var crear_armas_derecho = $derecho

@onready var mano_izquierda: Marker3D = $izquierdo/mark_izq
@onready var mano_derecha: Marker3D =$derecho/mark_der

var peer_id_jugador: int

enum Manos {
	IZQUIERDA,
	DERECHA
}
var ultima_mano: Manos = Manos.IZQUIERDA

#func _ready() -> void:
	##var arma = crear_armas_derecho.crear_arma(1)
	#equipar_arma(2)
	#equipar_arma(1)
	#await get_tree().create_timer(3).timeout
	#equipar_arma(3)

@warning_ignore("unused_parameter")
func _input(event: InputEvent) -> void:
	if(Input.is_key_pressed(KEY_L)):
		#var arma = crear_armas_derecho.crear_arma(1)
		#equipar_arma(1)
		solicitar_equipar_arma(3)

func obtener_arma(mano: Manos) -> Node:
	if mano == Manos.IZQUIERDA:
		if mano_izquierda.get_child_count() > 0:
			return mano_izquierda.get_child(0)
	else:
		if mano_derecha.get_child_count() > 0:
			return mano_derecha.get_child(0)
	return null


func equipar_arma(id_arma: int) -> void:
	var mano: Marker3D
	if ultima_mano == Manos.IZQUIERDA:
		mano = mano_izquierda
	else:
		mano = mano_derecha
	# si esa mano tiene un arma...
	if mano.get_child_count() > 0:
		var arma_actual = mano.get_child(0)
		# si se intenta la misma arma que retorne
		if arma_actual.get("id_arma") == id_arma:
			return
		# si es otra, que la saque
		arma_actual.queue_free()
	# creo una nueva arma
	var nueva_arma = crear_armas_derecho.crear_arma(id_arma)
	mano.add_child(nueva_arma)
	nueva_arma.transform = Transform3D.IDENTITY
	# cambia de mano para la siguiente arma
	if ultima_mano == Manos.IZQUIERDA:
		ultima_mano = Manos.DERECHA
	else:
		ultima_mano = Manos.IZQUIERDA
		
#----------------------------------------------------------------------SERVER

func solicitar_equipar_arma(id_arma: int) -> void:
	var mano = ultima_mano

	if multiplayer.is_server():
		# el servidor es uno de los jugadores
		avisar_arma_equipada.rpc(
			multiplayer.get_unique_id(),
			mano,
			id_arma
		)
	else:
		# le pide al servidor que avise a todos
		solicitar_equipar_arma_rpc.rpc_id(
			1,
			mano,
			id_arma
		)


@rpc("any_peer", "reliable")
func solicitar_equipar_arma_rpc(mano: Manos, id_arma: int) -> void:
	if !multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()


	# Avisamos a todos los jugadores:
	# "el jugador peer_id equipó id_arma en esta mano".
	avisar_arma_equipada.rpc(
		peer_id,
		mano,
		id_arma
	)


@rpc("any_peer", "call_local", "reliable")
func avisar_arma_equipada(
	peer_id: int,
	mano: Manos,
	id_arma: int
) -> void:

	# Buscamos al Jugador al que pertenece este Brazo.
	var jugador = get_parent()

	# Comprobamos que este Brazo pertenece al jugador
	# que realmente equipó el arma.
	if jugador.get_multiplayer_authority() != peer_id:
		return

	# Este es el Brazo correcto.
	ultima_mano = mano
	equipar_arma(id_arma)
